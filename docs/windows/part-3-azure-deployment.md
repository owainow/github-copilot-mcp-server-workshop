# Part 3: Azure Deployment

> **Navigation**: [Workshop Home](../README.md) | [Windows Path](README.md) | [← Part 2](part-2-local-development.md) | [Part 4 →](part-4-copilot-integration.md)

## Overview

In this part, we'll deploy our MCP server to Azure Functions. This enables our custom tools to run in the cloud and be accessible to GitHub Copilot from anywhere. We'll use Azure Functions v4 with the Flex Consumption (FC1) SKU for optimal performance and cost efficiency.

## Learning Objectives

- Deploy TypeScript Azure Functions to the cloud
- Configure Azure Functions with proper settings
- Test deployed functions with real HTTP requests
- Troubleshoot common deployment issues
- Understand Azure Functions monitoring and logging

## Prerequisites

- Completed [Part 2: Local Development](part-2-local-development.md)
- Azure subscription with appropriate permissions
- Azure CLI installed and configured

## Azure Setup

### 1. Install Azure CLI (if needed)

First, verify if Azure CLI is installed:

```powershell
az --version
```

If not installed, download and install from [Azure CLI installation guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

### 2. Login to Azure

```powershell
az login
```

This opens a browser window for authentication. After successful login, you'll see your subscription details.

### 3. Set Default Subscription (if you have multiple)

```powershell
# List available subscriptions
az account list --output table

# Set default subscription
az account set --subscription "Your-Subscription-Name-Or-ID"
```

## Infrastructure Deployment

We'll use Infrastructure as Code (Bicep) to deploy all Azure resources with proper Flex Consumption configuration. This ensures consistent, repeatable deployments with all the latest Azure Functions features.

### 1. Review Infrastructure Configuration

First, let's examine our Bicep template that defines the infrastructure:

```powershell
# Review the main Bicep template
Get-Content infra/main.bicep | Select-Object -First 30

# Review the parameters file
Get-Content infra/main.parameters.json
```

Our Bicep template includes:
- **Flex Consumption Plan (FC1 SKU)** - Modern serverless hosting
- **Storage Account** - With managed identity authentication (no connection strings!)
- **Application Insights** - For comprehensive monitoring
- **Proper RBAC** - Secure role assignments for managed identity
- **Security Settings** - HTTPS only, latest TLS, secure storage configuration

### 2. Create Resource Group

```powershell
$resourceGroup = "rg-mcp-workshop"
$location = "East US"

az group create --name $resourceGroup --location $location
```

### 3. Deploy Infrastructure with Bicep

Instead of creating resources manually, we'll deploy everything at once using our Bicep template:

```powershell
# Deploy all infrastructure using Bicep
az deployment group create `
  --resource-group $resourceGroup `
  --template-file infra/main.bicep `
  --parameters '@infra/main.parameters.json'

# This single command creates:
# - Storage Account (with secure configuration)
# - Flex Consumption Plan (FC1 SKU)
# - Function App (with Node.js 20, Linux)
# - Application Insights (for monitoring)
# - All required role assignments (for managed identity)
```

**Why Bicep over Manual Commands?**
- ✅ **Consistent deployments** - Same configuration every time
- ✅ **Modern features** - Properly configured Flex Consumption with managed identity
- ✅ **Security by default** - No connection strings, proper RBAC
- ✅ **Version controlled** - Infrastructure changes are tracked
- ✅ **Easier maintenance** - Update template, redeploy

### 4. Get Deployment Outputs

After deployment, get the function app details:

```powershell
# Get the function app name and URL from deployment outputs
$functionApp = az deployment group show `
  --resource-group $resourceGroup `
  --name main `
  --query "properties.outputs.functionAppName.value" `
  --output tsv

$functionUrl = az deployment group show `
  --resource-group $resourceGroup `
  --name main `
  --query "properties.outputs.functionAppUrl.value" `
  --output tsv

Write-Host "Function App: $functionApp"
Write-Host "Function URL: $functionUrl"

# Store these for later use
$env:FUNCTION_APP = $functionApp
$env:FUNCTION_URL = $functionUrl
```

## Deployment Process

### 1. Prepare for Deployment

Ensure your project is built and ready:

```powershell
# Navigate to project root
cd C:\Users\$env:USERNAME\mcp_projects\serverless_mcp_on_functions_for_github_copilot

# Install dependencies and build
npm install
npm run build
```

### 2. Deploy Function App

```powershell
# Deploy to Azure Functions
func azure functionapp publish $functionApp --typescript
```

This command:
- Builds your TypeScript code
- Packages the application
- Uploads to Azure Functions
- Configures the runtime environment

### 3. Configure Function App Settings

```powershell
# Set Node.js version
az functionapp config appsettings set `
  --name $functionApp `
  --resource-group $resourceGroup `
  --settings "WEBSITE_NODE_DEFAULT_VERSION=~20"

# Enable detailed logging
az functionapp config appsettings set `
  --name $functionApp `
  --resource-group $resourceGroup `
  --settings "FUNCTIONS_WORKER_RUNTIME=node"
```

## Verification and Testing

### 1. Get Function URLs

```powershell
# Get the function app hostname
$hostname = az functionapp show --name $functionApp --resource-group $resourceGroup --query "defaultHostName" --output tsv

# Display function URLs
Write-Host "Function App URLs:"
Write-Host "Base URL: https://$hostname"
Write-Host "MCP Endpoint: https://$hostname/api/mcp"
```

### 2. Test Deployed Functions

Create a PowerShell test script for the deployed functions:

```powershell
# Save this as test-deployed-functions.ps1
$functionUrl = "https://$hostname/api/mcp"

# Test 1: Health check
Write-Host "Testing health check..."
try {
    $response = Invoke-RestMethod -Uri $functionUrl -Method GET -ContentType "application/json"
    Write-Host "✅ Health check successful: $($response.status)"
} catch {
    Write-Host "❌ Health check failed: $($_.Exception.Message)"
}

# Test 2: MCP initialize
Write-Host "`nTesting MCP initialize..."
$initBody = @{
    jsonrpc = "2.0"
    id = 1
    method = "initialize"
    params = @{
        protocolVersion = "2024-11-05"
        capabilities = @{
            tools = @{}
        }
        clientInfo = @{
            name = "test-client"
            version = "1.0.0"
        }
    }
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri $functionUrl -Method POST -Body $initBody -ContentType "application/json"
    Write-Host "✅ Initialize successful"
    Write-Host "   Server: $($response.result.serverInfo.name) v$($response.result.serverInfo.version)"
    Write-Host "   Tools available: $($response.result.capabilities.tools.listChanged)"
} catch {
    Write-Host "❌ Initialize failed: $($_.Exception.Message)"
}

# Test 3: List tools
Write-Host "`nTesting tools list..."
$toolsBody = @{
    jsonrpc = "2.0"
    id = 2
    method = "tools/list"
    params = @{}
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri $functionUrl -Method POST -Body $toolsBody -ContentType "application/json"
    Write-Host "✅ Tools list successful"
    Write-Host "   Available tools:"
    foreach ($tool in $response.result.tools) {
        Write-Host "   - $($tool.name): $($tool.description)"
    }
} catch {
    Write-Host "❌ Tools list failed: $($_.Exception.Message)"
}

# Test 4: Call markdown_review tool
Write-Host "`nTesting markdown_review tool..."
$markdownContent = @"
# Test Document
This is a test document with some issues.
- Missing periods
- inconsistent formatting
"@

$reviewBody = @{
    jsonrpc = "2.0"
    id = 3
    method = "tools/call"
    params = @{
        name = "markdown_review"
        arguments = @{
            content = $markdownContent
        }
    }
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri $functionUrl -Method POST -Body $reviewBody -ContentType "application/json"
    Write-Host "✅ Markdown review successful"
    Write-Host "   Suggestions count: $($response.result.content[0].text | ConvertFrom-Json | Select-Object -ExpandProperty suggestions | Measure-Object | Select-Object -ExpandProperty Count)"
} catch {
    Write-Host "❌ Markdown review failed: $($_.Exception.Message)"
}
```

Run the test script:

```powershell
.\test-deployed-functions.ps1
```

### 3. Monitor Function Execution

```powershell
# View recent logs
az functionapp logs tail --name $functionApp --resource-group $resourceGroup

# Or view logs in Azure portal
az functionapp show --name $functionApp --resource-group $resourceGroup --query "defaultHostName" --output tsv | ForEach-Object { Start-Process "https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$functionApp/logStream" }
```

## Architecture Deep Dive

### Function App Configuration

Our Azure Function App uses several key configurations:

1. **Runtime**: Node.js 20 for modern JavaScript features
2. **Functions Version**: v4 for latest MCP protocol support
3. **SKU**: FC1 (Flex Consumption) for optimal performance
4. **OS**: Linux for better Node.js performance and cost

### HTTP Trigger Configuration

The function uses an HTTP trigger with these characteristics:

```typescript
// From src/index.ts
app.http('mcp', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous',
    route: 'mcp',
    handler: mcpHandler
});
```

Key points:
- **GET**: Returns health status
- **POST**: Handles MCP JSON-RPC requests  
- **Anonymous auth**: No API key required (suitable for Copilot integration)
- **Route**: `/api/mcp` endpoint

### MCP Protocol in Azure Functions

The serverless architecture handles MCP protocol through:

1. **Stateless Design**: Each request is independent
2. **JSON-RPC 2.0**: Standard protocol for tool communication
3. **Error Handling**: Robust error responses with proper HTTP status codes
4. **Logging**: Comprehensive logging for debugging

```typescript
// Example request flow
POST /api/mcp
{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call", 
    "params": {
        "name": "markdown_review",
        "arguments": { "content": "# My Document..." }
    }
}

// Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "content": [
            {
                "type": "text",
                "text": "{\"suggestions\": [...], \"score\": 85}"
            }
        ]
    }
}
```

## Troubleshooting

### Common Deployment Issues

#### Issue: Deployment fails with "Storage account not found"

**Solution**: Verify the storage account was created successfully:

```powershell
az storage account show --name $storageAccount --resource-group $resourceGroup
```

If missing, recreate:

```powershell
az storage account create --name $storageAccount --resource-group $resourceGroup --location $location --sku Standard_LRS
```

#### Issue: Function app returns 500 errors

**Solution**: Check application logs:

```powershell
# View detailed logs
az functionapp logs tail --name $functionApp --resource-group $resourceGroup

# Check if dependencies are installed
az functionapp deployment source config-zip --name $functionApp --resource-group $resourceGroup --src dist.zip
```

#### Issue: TypeScript compilation errors

**Solution**: Ensure clean build before deployment:

```powershell
# Clean and rebuild
Remove-Item -Recurse -Force dist -ErrorAction SilentlyContinue
npm run build

# Verify dist folder contains compiled JavaScript
Get-ChildItem -Path dist -Recurse
```

#### Issue: Cold start performance

**Solution**: The FC1 SKU should minimize cold starts, but you can also:

1. **Enable Always On** (if using dedicated plan):
   ```powershell
   az functionapp config set --name $functionApp --resource-group $resourceGroup --always-on true
   ```

2. **Use Application Insights** for monitoring:
   ```powershell
   az functionapp config appsettings set --name $functionApp --resource-group $resourceGroup --settings "APPINSIGHTS_INSTRUMENTATIONKEY=your-key"
   ```

### Debugging with Azure Portal

1. **Navigate to Function App**:
   ```powershell
   Start-Process "https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$functionApp"
   ```

2. **Check Function Execution**:
   - Go to Functions → mcp → Code + Test
   - Use "Test/Run" to test directly in portal
   - View execution history in Monitor tab

3. **Application Insights**:
   - Enable Application Insights for detailed telemetry
   - View performance metrics and error traces
   - Set up alerts for failures

### Network and CORS Issues

If testing from browser applications:

```powershell
# Configure CORS for development
az functionapp cors add --name $functionApp --resource-group $resourceGroup --allowed-origins "*"

# For production, be more specific:
az functionapp cors add --name $functionApp --resource-group $resourceGroup --allowed-origins "https://github.com"
```

## Performance Optimization

### Function App Settings

Optimize performance with these settings:

```powershell
# Set optimal Node.js settings
az functionapp config appsettings set --name $functionApp --resource-group $resourceGroup --settings @(
    "WEBSITE_NODE_DEFAULT_VERSION=~20",
    "FUNCTIONS_WORKER_RUNTIME=node",
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING=DefaultEndpointsProtocol=https;AccountName=$storageAccount;...",
    "SCM_DO_BUILD_DURING_DEPLOYMENT=true",
    "WEBSITE_RUN_FROM_PACKAGE=1"
)
```

### Monitoring Setup

```powershell
# Create Application Insights
$appInsights = "ai-mcp-workshop"
az monitor app-insights component create --app $appInsights --location $location --resource-group $resourceGroup

# Get instrumentation key
$instrumentationKey = az monitor app-insights component show --app $appInsights --resource-group $resourceGroup --query "instrumentationKey" --output tsv

# Configure Function App to use Application Insights
az functionapp config appsettings set --name $functionApp --resource-group $resourceGroup --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$instrumentationKey"
```

## Security Considerations

### Function App Security

1. **Authentication**: For production, consider enabling authentication:
   ```powershell
   az functionapp auth update --name $functionApp --resource-group $resourceGroup --enabled true --action LoginWithAzureActiveDirectory
   ```

2. **Access Keys**: Secure function keys if needed:
   ```powershell
   # List function keys
   az functionapp keys list --name $functionApp --resource-group $resourceGroup
   
   # Create custom key
   az functionapp keys set --name $functionApp --resource-group $resourceGroup --key-name "copilot-key" --key-value "your-secure-key"
   ```

3. **Network Security**: Configure network restrictions:
   ```powershell
   # Restrict access to specific IPs (example for GitHub)
   az functionapp config access-restriction add --name $functionApp --resource-group $resourceGroup --rule-name "GitHub" --action Allow --ip-address "140.82.112.0/20" --priority 100
   ```

## Cost Management

### Understanding FC1 Pricing

The Flex Consumption (FC1) plan charges based on:
- **Execution time**: Per 100ms of execution
- **Memory usage**: Based on allocated memory
- **Requests**: Per million requests

### Cost Optimization Tips

1. **Optimize function execution time**:
   ```typescript
   // Use efficient algorithms
   // Minimize external API calls
   // Cache results when possible
   ```

2. **Monitor usage**:
   ```powershell
   # View cost analysis
   Start-Process "https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id --output tsv)/providers/Microsoft.CostManagement/costByResource"
   ```

3. **Set up budget alerts**:
   ```powershell
   # Create budget (adjust amount as needed)
   az consumption budget create --resource-group $resourceGroup --budget-name "mcp-workshop-budget" --amount 10 --time-grain Monthly
   ```

## Next Steps

Great! You've successfully deployed your MCP server to Azure Functions. Your custom tools are now running in the cloud and ready for integration.

### What We Accomplished

- ✅ Created Azure resources (Resource Group, Storage Account, Function App)
- ✅ Deployed TypeScript Azure Functions to the cloud
- ✅ Configured Function App with optimal settings (FC1 SKU, Node.js 20)
- ✅ Tested deployed functions with HTTP requests
- ✅ Set up monitoring and logging
- ✅ Learned troubleshooting techniques

### Key Takeaways

1. **Serverless Architecture**: Azure Functions provide scalable, cost-effective hosting for MCP servers
2. **FC1 SKU Benefits**: Better cold start performance and predictable pricing
3. **MCP Protocol**: Works seamlessly in serverless environments with proper error handling
4. **Testing Strategy**: Comprehensive testing ensures reliability in production
5. **Monitoring**: Application Insights provides valuable insights for optimization

### Ready for Copilot Integration

Your function URLs are now ready for GitHub Copilot integration:
- **Function App URL**: `https://{your-function-app}.azurewebsites.net`
- **MCP Endpoint**: `https://{your-function-app}.azurewebsites.net/api/mcp`

Continue to [Part 4: Copilot Integration](part-4-copilot-integration.md) to connect your deployed MCP server with GitHub Copilot!

---

> **Navigation**: [Workshop Home](../README.md) | [Windows Path](README.md) | [← Part 2](part-2-local-development.md) | [Part 4 →](part-4-copilot-integration.md)