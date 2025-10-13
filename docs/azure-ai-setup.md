# Azure AI Foundry Integration Guide

This guide shows how to integrate your MCP server with Azure AI Foundry's free tier to demonstrate true LLM-powered tool functionality.

## 🆓 Free Tier Setup

Azure AI Foundry provides a free tier that includes:
- **Free trial credits** for new Azure accounts
- **Basic quotas** for GPT-3.5-turbo model
- **Limited requests per month** (sufficient for workshop testing)

## 🔧 Quick Setup

### 1. Create Azure AI Resource (Free)

```bash
# Login to Azure
az login

# Create resource group
az group create --name mcp-workshop-rg --location eastus

# Create Azure AI service (free tier)
az cognitiveservices account create \
  --name mcp-workshop-ai \
  --resource-group mcp-workshop-rg \
  --kind OpenAI \
  --sku F0 \
  --location eastus
```

### 2. Get API Credentials

```bash
# Get endpoint
az cognitiveservices account show \
  --name mcp-workshop-ai \
  --resource-group mcp-workshop-rg \
  --query properties.endpoint

# Get API key
az cognitiveservices account keys list \
  --name mcp-workshop-ai \
  --resource-group mcp-workshop-rg \
  --query key1
```

### 3. Configure Local Settings

Update your `local.settings.json`:

```json
{
  "Values": {
    "AZURE_AI_ENDPOINT": "https://mcp-workshop-ai.openai.azure.com/",
    "AZURE_AI_KEY": "your-api-key-here",
    "ENABLE_AI_TOOL": "true"
  }
}
```

## 🧪 Testing the AI Tool

Once configured, test the AI code review tool:

```powershell
# Test with sample code
$testCode = @'
function calculateSum(a, b) {
    return a + b;
}

// TODO: Add validation
let result = calculateSum(5, "10");
console.log(result);
'@

$body = @{
    jsonrpc = "2.0"
    id = 1
    method = "tools/call"
    params = @{
        name = "ai_code_review"
        arguments = @{
            code = $testCode
            language = "javascript"
            review_type = "comprehensive"
        }
    }
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Uri "http://localhost:7071/api/mcp-server" -Method POST -ContentType "application/json" -Body $body
```

## 🔄 Fallback Behavior

The AI tool provides graceful fallback:

1. **With Azure AI configured**: Real LLM analysis
2. **Without Azure AI**: Mock analysis with educational content
3. **On API errors**: Automatic fallback to mock mode

This ensures the workshop works for all participants regardless of Azure setup.

## 📊 Understanding the Difference

### Mock Analysis (Fallback)
```json
{
  "status": "mock_analysis",
  "analysis": {
    "overall_assessment": "This javascript code appears to be well-structured...",
    "issues": ["Remove console.log statements before production"],
    "recommendations": ["Add comprehensive documentation"]
  }
}
```

### Real AI Analysis (Azure AI)
```text
## Code Review: JavaScript Function

### Overall Assessment
The code has a type safety issue that could lead to unexpected behavior...

### Specific Issues
1. **Line 6**: Mixing number and string types in `calculateSum(5, "10")`
2. **Missing validation**: Function doesn't validate input types
3. **TODO comment**: Indicates incomplete implementation

### Recommendations
1. Add TypeScript for better type safety
2. Implement input validation
3. Use parseInt() or Number() for string conversion
```

## 💡 Workshop Teaching Points

This AI tool demonstrates:

1. **True MCP behavior**: Tools provide data, LLM provides analysis
2. **Graceful degradation**: Works with or without external APIs
3. **Real-world integration**: Shows production MCP patterns
4. **Cost awareness**: Uses free tier to minimize expenses

## 🛠 Deployment Considerations

For production deployment:

```bicep
// Add to main.bicep
resource cognitiveService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: 'mcp-ai-service'
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

This setup provides a complete demonstration of MCP's true capabilities while maintaining accessibility for all workshop participants.
