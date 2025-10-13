# Part 5: AI Integration with Azure AI Foundry

## 🎯 Workshop Objective

Transform your MCP server from educational demos to production-ready AI integration by connecting the `ai_code_review` tool to Azure AI Foundry's free tier.

## 🔍 Understanding the Difference

Currently, your `ai_code_review` tool returns mock analysis:

```json
{
  "status": "mock_analysis",
  "message": "Azure AI not configured - showing mock analysis for demonstration",
  "analysis": {
    "overall_assessment": "This javascript code appears to be concise...",
    "issues": ["Remove console.log statements before production"]
  }
}
```

After this workshop, it will provide real AI-powered analysis:

```json
{
  "status": "ai_analysis", 
  "analysis": {
    "overall_assessment": "The code shows good structure but has potential type safety issues...",
    "issues": ["Line 3: Implicit string-to-number conversion may cause unexpected behavior"],
    "recommendations": ["Add TypeScript for better type safety", "Implement input validation"]
  }
}
```

## 🆓 Free Tier Setup

### Step 1: Create Azure AI Resource

```bash
# Login to Azure (if not already logged in)
az login

# Create resource group
az group create \
  --name mcp-workshop-rg \
  --location eastus

# Create Azure AI service (free tier)
az cognitiveservices account create \
  --name mcp-workshop-ai-$(Get-Random) \
  --resource-group mcp-workshop-rg \
  --kind OpenAI \
  --sku F0 \
  --location eastus
```

**💡 Note**: The `F0` SKU provides free tier access with limited monthly quotas - perfect for workshop testing!

### Step 2: Deploy GPT Model

```bash
# Get your resource name
$resourceName = az cognitiveservices account list --resource-group mcp-workshop-rg --query "[0].name" -o tsv

# Deploy GPT-3.5-turbo model (free tier)
az cognitiveservices account deployment create \
  --resource-group mcp-workshop-rg \
  --account-name $resourceName \
  --deployment-name gpt-35-turbo \
  --model-name gpt-35-turbo \
  --model-version "0613" \
  --model-format OpenAI \
  --sku-capacity 1 \
  --sku-name Standard
```

### Step 3: Get API Credentials

```bash
# Get endpoint URL
$endpoint = az cognitiveservices account show \
  --name $resourceName \
  --resource-group mcp-workshop-rg \
  --query properties.endpoint -o tsv

# Get API key
$apiKey = az cognitiveservices account keys list \
  --name $resourceName \
  --resource-group mcp-workshop-rg \
  --query key1 -o tsv

Write-Host "Endpoint: $endpoint"
Write-Host "API Key: $apiKey"
```

### Step 4: Configure Local Environment

Update your `local.settings.json`:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "AZURE_AI_ENDPOINT": "https://your-resource-name.openai.azure.com/",
    "AZURE_AI_KEY": "your-api-key-here",
    "AZURE_AI_DEPLOYMENT": "gpt-35-turbo",
    "ENABLE_AI_TOOL": "true"
  }
}
```

**🔒 Security Note**: Never commit API keys to source control. For production, use Azure Key Vault or Managed Identity.

## 🧪 Testing AI Integration

### Test 1: Verify Configuration

```powershell
# Test that AI tool now uses real analysis
$testBody = @{
    jsonrpc = "2.0"
    id = 1
    method = "tools/call"
    params = @{
        name = "ai_code_review"
        arguments = @{
            code = "function add(a, b) { return a + b; } console.log(add('5', 10));"
            language = "javascript"
            review_type = "comprehensive"
        }
    }
} | ConvertTo-Json -Depth 10

$result = Invoke-RestMethod -Uri "http://localhost:7071/api/mcp-server" -Method POST -ContentType "application/json" -Body $testBody

# Check if we got real AI analysis
$analysis = ($result.result.content[0].text | ConvertFrom-Json)
Write-Host "Analysis Type: $($analysis.status)"

if ($analysis.status -eq "ai_analysis") {
    Write-Host "✅ Real AI analysis working!" -ForegroundColor Green
    Write-Host "Assessment: $($analysis.analysis.overall_assessment)"
} else {
    Write-Host "❌ Still using mock analysis" -ForegroundColor Red
}
```

### Test 2: Compare Different Code Quality

Test with problematic code:

```powershell
$problematicCode = @"
function processUserData(data) {
    // No validation
    let result = eval(data.script);
    document.innerHTML = data.content;
    return result;
}
"@

$testBody = @{
    jsonrpc = "2.0"
    id = 2
    method = "tools/call"
    params = @{
        name = "ai_code_review"
        arguments = @{
            code = $problematicCode
            language = "javascript"
            review_type = "security"
        }
    }
} | ConvertTo-Json -Depth 10

$result = Invoke-RestMethod -Uri "http://localhost:7071/api/mcp-server" -Method POST -ContentType "application/json" -Body $testBody
$analysis = ($result.result.content[0].text | ConvertFrom-Json)

Write-Host "Security Issues Found:" -ForegroundColor Yellow
$analysis.analysis.issues | ForEach-Object { Write-Host "  • $_" }
```

## 🔄 Understanding the AI Tool Implementation

Let's examine how the tool works:

```typescript
// In src/tools/ai-code-review.ts
export class AiCodeReviewTool implements MCPTool {
  async call(args: any): Promise<ToolResult> {
    const { code, language = 'typescript', review_type = 'comprehensive' } = args;

    // Check if Azure AI is configured
    const endpoint = process.env.AZURE_AI_ENDPOINT;
    const apiKey = process.env.AZURE_AI_KEY;
    
    if (!endpoint || !apiKey) {
      // Fall back to mock analysis
      return this.getMockAnalysis(code, language, review_type);
    }

    try {
      // Use real Azure AI
      const analysis = await this.getAIAnalysis(code, language, review_type);
      return {
        content: [{
          type: "text",
          text: JSON.stringify({
            status: "ai_analysis",
            analysis
          })
        }]
      };
    } catch (error) {
      // Graceful fallback on API errors
      return this.getMockAnalysis(code, language, review_type);
    }
  }
}
```

## 🏗️ Production Deployment Considerations

### Environment Variables for Azure Functions

For production deployment, add these to your Bicep template:

```bicep
resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  // ... existing configuration
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'AZURE_AI_ENDPOINT'
          value: cognitiveService.properties.endpoint
        }
        {
          name: 'AZURE_AI_KEY'
          value: cognitiveService.listKeys().key1
        }
        {
          name: 'AZURE_AI_DEPLOYMENT'
          value: 'gpt-35-turbo'
        }
        {
          name: 'ENABLE_AI_TOOL'
          value: 'true'
        }
      ]
    }
  }
}

resource cognitiveService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: 'mcp-ai-${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'S0'  // Standard tier for production
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: 'mcp-ai-${uniqueString(resourceGroup().id)}'
  }
}
```

### Cost Management

Monitor your usage:

```bash
# Check current usage
az monitor metrics list \
  --resource $resourceName \
  --resource-group mcp-workshop-rg \
  --metric "TotalTokens" \
  --start-time $(Get-Date).AddDays(-1).ToString("yyyy-MM-dd") \
  --end-time $(Get-Date).ToString("yyyy-MM-dd")
```

## 🎓 Learning Outcomes

After completing this workshop section, you'll understand:

1. **True MCP Architecture**: Tools provide context, AI provides analysis
2. **Graceful Degradation**: Fallback patterns for reliability
3. **Azure AI Integration**: Real-world cloud AI service usage
4. **Cost Management**: Free tier usage and monitoring
5. **Production Patterns**: Environment configuration and security

## 🔄 Fallback Strategy

The AI tool is designed with multiple fallback levels:

1. **Primary**: Azure AI Foundry analysis
2. **Secondary**: Mock analysis with educational content
3. **Tertiary**: Error handling with graceful messages

This ensures the workshop works for ALL participants, regardless of their Azure setup or budget constraints.

## 🎯 Workshop Challenge

**Challenge**: Modify the AI tool to support multiple AI providers (Azure OpenAI, OpenAI, local models) with a configuration-driven approach.

**Extension**: Add tool selection based on code complexity - use simple analysis for basic code, AI analysis for complex scenarios.

## 📝 Summary

You've now transformed your MCP server from an educational demo to a production-ready system that demonstrates the true power of Model Context Protocol - providing intelligent, context-aware analysis through AI integration while maintaining reliability through smart fallback patterns.

This represents the **real value** of MCP: tools that enhance AI capabilities rather than replacing them!
