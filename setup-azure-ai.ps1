# Azure AI Foundry Setup Script for MCP Workshop
# This script sets up Azure AI Foundry free tier for the MCP workshop

param(
    [string]$ResourceGroupName = "mcp-workshop-rg",
    [string]$Location = "eastus",
    [switch]$SkipResourceCreation,
    [switch]$ShowCredentialsOnly
)

Write-Host "🚀 Azure AI Foundry Setup for MCP Workshop" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# Check if Azure CLI is installed
try {
    $azVersion = az --version
    Write-Host "✅ Azure CLI detected" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI not found. Please install Azure CLI first." -ForegroundColor Red
    Write-Host "Download from: https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Check if logged in
try {
    $account = az account show | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
} catch {
    Write-Host "❌ Not logged in to Azure. Running 'az login'..." -ForegroundColor Yellow
    az login
}

if ($ShowCredentialsOnly) {
    Write-Host "`n🔍 Looking for existing Azure AI resources..." -ForegroundColor Cyan
    
    $existingResources = az cognitiveservices account list --query "[?kind=='OpenAI']" | ConvertFrom-Json
    
    if ($existingResources.Count -eq 0) {
        Write-Host "❌ No existing Azure AI resources found." -ForegroundColor Red
        Write-Host "Run this script without -ShowCredentialsOnly to create resources." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "📋 Found $($existingResources.Count) Azure AI resource(s):" -ForegroundColor Green
    
    for ($i = 0; $i -lt $existingResources.Count; $i++) {
        Write-Host "  $($i + 1). $($existingResources[$i].name) (Resource Group: $($existingResources[$i].resourceGroup))" -ForegroundColor White
    }
    
    if ($existingResources.Count -eq 1) {
        $selectedResource = $existingResources[0]
    } else {
        $selection = Read-Host "`nSelect resource number (1-$($existingResources.Count))"
        $selectedResource = $existingResources[$selection - 1]
    }
    
    $resourceName = $selectedResource.name
    $resourceGroup = $selectedResource.resourceGroup
} else {
    if (-not $SkipResourceCreation) {
        Write-Host "`n📦 Creating Azure Resources..." -ForegroundColor Cyan
        
        # Create resource group
        Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
        az group create --name $ResourceGroupName --location $Location | Out-Null
        
        # Generate unique resource name
        $randomSuffix = Get-Random -Minimum 1000 -Maximum 9999
        $resourceName = "mcp-workshop-ai-$randomSuffix"
        
        Write-Host "Creating Azure AI service: $resourceName" -ForegroundColor Yellow
        $createResult = az cognitiveservices account create `
            --name $resourceName `
            --resource-group $ResourceGroupName `
            --kind OpenAI `
            --sku F0 `
            --location $Location `
            --custom-domain $resourceName | ConvertFrom-Json
        
        if ($createResult) {
            Write-Host "✅ Azure AI service created successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to create Azure AI service" -ForegroundColor Red
            exit 1
        }
        
        # Deploy GPT model
        Write-Host "Deploying GPT-3.5-turbo model..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30  # Wait for resource to be ready
        
        $deployResult = az cognitiveservices account deployment create `
            --resource-group $ResourceGroupName `
            --account-name $resourceName `
            --deployment-name "gpt-35-turbo" `
            --model-name "gpt-35-turbo" `
            --model-version "0613" `
            --model-format OpenAI `
            --sku-capacity 1 `
            --sku-name Standard | ConvertFrom-Json
        
        if ($deployResult) {
            Write-Host "✅ GPT-3.5-turbo model deployed successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Model deployment may have failed, but you can deploy manually later" -ForegroundColor Yellow
        }
    } else {
        $resourceName = Read-Host "Enter your Azure AI resource name"
        $ResourceGroupName = Read-Host "Enter your resource group name"
    }
}

Write-Host "`n🔑 Retrieving Credentials..." -ForegroundColor Cyan

# Get endpoint and keys
$endpoint = az cognitiveservices account show `
    --name $resourceName `
    --resource-group $ResourceGroupName `
    --query properties.endpoint -o tsv

$apiKey = az cognitiveservices account keys list `
    --name $resourceName `
    --resource-group $ResourceGroupName `
    --query key1 -o tsv

if (-not $endpoint -or -not $apiKey) {
    Write-Host "❌ Failed to retrieve credentials" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Credentials retrieved successfully" -ForegroundColor Green

# Update local.settings.json
$localSettingsPath = "local.settings.json"

if (Test-Path $localSettingsPath) {
    Write-Host "`n📝 Updating local.settings.json..." -ForegroundColor Cyan
    
    $settings = Get-Content $localSettingsPath | ConvertFrom-Json
    
    # Add or update AI configuration
    $settings.Values.AZURE_AI_ENDPOINT = $endpoint
    $settings.Values.AZURE_AI_KEY = $apiKey
    $settings.Values.AZURE_AI_DEPLOYMENT = "gpt-35-turbo"
    $settings.Values.ENABLE_AI_TOOL = "true"
    
    # Save updated settings
    $settings | ConvertTo-Json -Depth 10 | Set-Content $localSettingsPath
    
    Write-Host "✅ local.settings.json updated successfully" -ForegroundColor Green
} else {
    Write-Host "`n📝 Creating local.settings.json..." -ForegroundColor Cyan
    
    $newSettings = @{
        IsEncrypted = $false
        Values = @{
            AzureWebJobsStorage = ""
            FUNCTIONS_WORKER_RUNTIME = "node"
            AZURE_AI_ENDPOINT = $endpoint
            AZURE_AI_KEY = $apiKey
            AZURE_AI_DEPLOYMENT = "gpt-35-turbo"
            ENABLE_AI_TOOL = "true"
        }
    }
    
    $newSettings | ConvertTo-Json -Depth 10 | Set-Content $localSettingsPath
    
    Write-Host "✅ local.settings.json created successfully" -ForegroundColor Green
}

Write-Host "`n🎉 Setup Complete!" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host "Resource Name: $resourceName" -ForegroundColor White
Write-Host "Endpoint: $endpoint" -ForegroundColor White
Write-Host "Deployment: gpt-35-turbo" -ForegroundColor White
Write-Host ""
Write-Host "🧪 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Restart your Azure Functions (func start)" -ForegroundColor White
Write-Host "2. Run: .\test-ai-integration.ps1" -ForegroundColor White
Write-Host "3. Your AI tool will now provide real analysis!" -ForegroundColor White
Write-Host ""
Write-Host "💰 Free Tier Info:" -ForegroundColor Yellow
Write-Host "• F0 tier includes limited monthly requests" -ForegroundColor White
Write-Host "• Monitor usage in Azure portal" -ForegroundColor White
Write-Host "• Upgrade to S0 for production use" -ForegroundColor White
