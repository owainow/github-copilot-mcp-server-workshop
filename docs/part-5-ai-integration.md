# Part 5: AI Integration with Azure AI Foundry

## 🎯 Workshop Objective

Transform your MCP server from educational demos to production-ready AI integration by connecting the `ai_code_review` tool to **Azure AI Foundry** with a deployed model endpoint.

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

## �️ Azure AI Foundry Setup

### Step 1: Create Azure AI Foundry Project

1. **Navigate to Azure AI Foundry**
   - Go to [https://ai.azure.com](https://ai.azure.com)
   - Sign in with your Azure account

2. **Create New Project**
   - Click **"Create new"** in the top right
   - Select **"Azure AI Foundry resource"**
   - Click **"Next"**

3. **Configure Project Settings**
   - **Project name**: `mcp-workshop-ai`
   - **Subscription**: Select your Azure subscription
   - **Resource group**: `mcp-workshop-rg` (same as Functions)
   - **Location**: `East US` (same as Functions)
   - Click **"Create"**

4. **Wait for Deployment**
   - This creates both an AI Foundry resource and project
   - Takes 2-3 minutes to complete

### Step 2: Deploy a Model

1. **Navigate to Model Catalog**
   - In your new project, click **"Model catalog"** in the left menu
   - Or go to **"Explore"** > **"Model catalog"**

2. **Find GPT-4o Mini**
   - Search for `gpt-4o-mini`
   - Click on **"gpt-4o-mini"** from the Azure OpenAI collection
   - This is cost-effective and perfect for code review

3. **Deploy Model**
   - Click **"Deploy"**
   - **Deployment name**: `gpt-4o-mini`
   - **Version**: Keep default (latest)
   - **Deployment type**: `Standard`
   - **Rate limit (Tokens per minute)**: `30K` (sufficient for workshop)
   - Click **"Deploy"**

4. **Wait for Deployment**
   - Takes 1-2 minutes
   - You'll see it in **"My deployments"** when ready

### Step 3: Get Connection Details

1. **Navigate to Deployments**
   - Go to **"Components"** > **"Deployments"** in left menu
   - Click on your `gpt-4o-mini` deployment

2. **Copy Connection Information**
   - **Target URL**: Copy the full endpoint URL
   - **Key**: Click **"Show"** and copy the key
   - **Deployment**: Note the deployment name (`gpt-4o-mini`)

   Example values:
   ```
   Target URL: https://mcp-workshop-ai-abc123.eastus.models.ai.azure.com/v1/chat/completions
   Key: 1234567890abcdef...
   Deployment: gpt-4o-mini
   ```

### Step 4: Configure Local Environment

Update your `local.settings.json`:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "AZURE_AI_ENDPOINT": "https://mcp-workshop-ai-abc123.eastus.models.ai.azure.com",
    "AZURE_AI_KEY": "your-key-here",
    "AZURE_AI_DEPLOYMENT": "gpt-4o-mini",
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

For production deployment, you'll need to add the AI Foundry connection details to your Azure Function's environment variables.

**Option 1: Azure Portal**
1. Go to your Function App in Azure Portal
2. Navigate to **"Configuration"** > **"Application settings"**
3. Add these new settings:
   ```
   AZURE_AI_ENDPOINT = https://your-foundry-project.eastus.models.ai.azure.com
   AZURE_AI_KEY = your-api-key
   AZURE_AI_DEPLOYMENT = gpt-4o-mini
   ENABLE_AI_TOOL = true
   ```

**Option 2: Azure CLI**
```powershell
# Get your Function App name
$functionAppName = "mcp-server-functions"

# Set the AI configuration
az functionapp config appsettings set `
  --name $functionAppName `
  --resource-group mcp-workshop-rg `
  --settings `
  "AZURE_AI_ENDPOINT=https://your-foundry-project.eastus.models.ai.azure.com" `
  "AZURE_AI_KEY=your-api-key" `
  "AZURE_AI_DEPLOYMENT=gpt-4o-mini" `
  "ENABLE_AI_TOOL=true"
```

### Cost Management

Monitor your AI Foundry usage:

1. **In AI Foundry Portal**
   - Go to **"Management center"** > **"Usage and billing"**
   - Monitor token usage and costs
   - Set up alerts for spending thresholds

2. **Azure Portal**
   - Go to **"Cost Management + Billing"**
   - Filter by your resource group (`mcp-workshop-rg`)
   - Monitor AI Foundry costs separately from Functions costs

## 🎓 Learning Outcomes

After completing this workshop section, you'll understand:

1. **Azure AI Foundry**: Modern AI platform for model deployment and management
2. **Model Endpoints**: Direct API access to deployed AI models
3. **True MCP Architecture**: Tools provide context, AI provides analysis
4. **Graceful Degradation**: Fallback patterns for reliability
5. **Production Integration**: Real-world cloud AI service usage
6. **Cost Management**: Understanding AI model usage and billing

## 🔄 Fallback Strategy

The AI tool is designed with multiple fallback levels:

1. **Primary**: Azure AI Foundry model endpoint analysis
2. **Secondary**: Mock analysis with educational content  
3. **Tertiary**: Error handling with graceful messages

This ensures the workshop works for ALL participants, regardless of their Azure AI Foundry setup.

## 🎯 Workshop Challenge

**Challenge**: Modify the AI tool to support multiple AI providers (Azure AI Foundry, OpenAI, local models) with a configuration-driven approach.

**Extension**: Add prompt engineering for different review types (security, performance, accessibility) with specialized prompts per scenario.

## 📝 Summary

You've now transformed your MCP server from an educational demo to a production-ready system that demonstrates the true power of Model Context Protocol - providing intelligent, context-aware analysis through **Azure AI Foundry** integration while maintaining reliability through smart fallback patterns.

This represents the **real value** of MCP: tools that enhance AI capabilities rather than replacing them!
