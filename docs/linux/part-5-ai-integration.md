# Part 5: AI Integration with Azure AI Foundry

> **Workshop Navigation**: [← Part 4: Copilot Integration](part-4-copilot-integration.md)

## Prerequisites

- Completed [Part 4: Copilot Integration](part-4-copilot-integration.md)
- Environment variables from previous parts:
  - `$FUNCTION_APP` - Your Azure Function App name
  - `$FUNCTION_URL` - Your Azure Function URL  
  - `$RESOURCE_GROUP` - Your resource group name (rg-mcp-workshop)

## 🎯 Workshop Objective

Transform your MCP server from educational demos to production-ready AI integration by connecting the `ai_code_review` tool to **Azure AI Foundry** with a deployed model endpoint.

---

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
    "recommendations": ["Add TypeScript for better type safety", "Implement input validation"],
    "security_analysis": "No immediate security concerns detected",
    "performance_notes": "Consider caching for repeated operations"
  }
}
```

---

## 🚀 Quick Setup Guide

### 1. Create Azure AI Hub (Portal Method)

1. **Open Azure Portal**: Navigate to [portal.azure.com](https://portal.azure.com)

2. **Create Azure AI Foundry Resource**:
   - Search for "Azure AI Foundry" in the search bar
   - Click "Create a resource"
   - Fill in the details:
     - **Subscription**: Your Azure subscription
     - **Resource Group**: `$RESOURCE_GROUP` (same as your Function App from Parts 3-4)
     - **Foundry Name**: `mcp-workshop-ai-hub`
     - **Location**: `East US` (or your preferred region)
     - **Project Name**: `mcp-code-review-project`
   - Click "Next"

3. **Additional Settings**:
   - Inbound Access -> All Networks -> Next
   - Identity -> System Assigned -> Next
   - Data Encryption (Leave blank) -> Next
   - Tags -> Next
  
  - Finally click "Create"!

### 3. Deploy Model
Once your resource has provisioned click on it in the Azure portal and then in the overview blade click "Go to Azure AI Foundry Portal" and log in.
1. **In AI Foundry Portal**:
   - Go to "Model Catalog"
   - Search for "GPT-3.5-turbo" 
   - Click on the model → "Use this model"

2. **Configure Deployment**:
   - **Deployment Name**: `gpt-35-turbo-mcp`
   - **Deployment Type**: Standard
   - Click "Deploy"

3. **Get Endpoint Details**:
   - Once deployed, go to "Deployments"
   - Click on `gpt-35-turbo-mcp`
   - Copy the **Target URI** and **Key**

---

## 🔧 Configure Your MCP Server

### 1. Verify Environment Variables from Part 4

First, make sure you have the environment variables from Part 4:

```bash
# Check that your environment variables are set
echo "Function App: $FUNCTION_APP"
echo "Function URL: $FUNCTION_URL"
RESOURCE_GROUP="rg-mcp-workshop"

# If not set, reload them from Part 3 deployment outputs
if [ -z "$FUNCTION_APP" ]; then
    FUNCTION_APP=$(az deployment group show \
      --resource-group rg-mcp-workshop \
      --name main \
      --query "properties.outputs.functionAppName.value" \
      --output tsv)
    
    FUNCTION_URL=$(az deployment group show \
      --resource-group rg-mcp-workshop \
      --name main \
      --query "properties.outputs.functionAppUrl.value" \
      --output tsv)
    

    
    # Store for this session
    export FUNCTION_APP FUNCTION_URL RESOURCE_GROUP
    echo "Environment variables reloaded from deployment"
fi
```

### 2. Update Azure Function App Settings

```bash
# Set the Azure AI configuration using environment variables
az functionapp config appsettings set \
  --name $FUNCTION_APP \
  --resource-group rg-mcp-workshop \
  --settings \
    AZURE_AI_ENDPOINT="<https://your-endpoint.openai.azure.com/>" \
    AZURE_AI_KEY="<your-api-key>" \
    AZURE_AI_DEPLOYMENT_NAME="gpt-35-turbo-mcp" \
    AZURE_OPENAI_API_VERSION="2025-01-01-preview" \
    ENABLE_AI_TOOL="true"

# Wait for function app to restart and pick up new settings
echo "Waiting for function app to restart with new settings..."
sleep 30
```

> **💡 Important**: Azure Function Apps automatically restart when application settings are updated. This ensures your function picks up the new Azure AI configuration. The restart typically takes 15-30 seconds.

### 2. Update Local Settings (for testing)

Update your `local.settings.json` and add values to the API key and API Endpoint settings:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "MCP_SERVER_NAME": "GitHub Copilot MCP Server",
    "MCP_SERVER_VERSION": "1.0.0",
    "ENABLE_MARKDOWN_TOOL": "true",
    "ENABLE_DEPENDENCY_TOOL": "true",
    "ENABLE_AI_TOOL": "true",
    "AZURE_AI_ENDPOINT": "<YOUR URI>",
    "AZURE_AI_KEY": "<YOUR KEY>",
    "MCP_LOG_LEVEL": "info"
  },
  "ConnectionStrings": {}
}
```

---

## 💻 Understanding the AI Code Review Tool

The AI integration is already implemented in your project! Take a moment to review the actual implementation:

📁 **Open and examine**: `src/tools/ai-code-review.ts`

### Key Features to Notice:

1. **Smart Configuration Detection**: The tool automatically detects if Azure AI is configured via environment variables
2. **Graceful Fallback**: Falls back to mock analysis if Azure AI is unavailable or fails
3. **Azure OpenAI Integration**: Uses the `@azure/openai` client for real AI analysis when configured
4. **Structured Prompts**: Sends well-structured prompts to get consistent, useful code reviews
5. **Error Handling**: Robust error handling ensures the tool always returns a useful response

### How It Works:

- **Without Azure AI**: Returns `"status": "mock_analysis"` with educational examples
- **With Azure AI**: Returns `"status": "ai_analysis"` with real AI-powered insights
- **On Error**: Gracefully falls back to mock mode with error logging

The beauty of this design is that **no code changes are needed** - just adding the environment variables will automatically enable real AI analysis!

---

## 🧪 Testing Azure AI Integration

### 1. Local Testing

```bash
# Build and start locally
npm run build
func start --port 7071

# Test the AI tool
curl -X POST http://localhost:7071/api/mcp-server \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "ai_code_review",
      "arguments": {
        "code": "function add(a, b) {\n  console.log(a + b);\n  return a + b;\n}",
        "language": "javascript",
        "review_type": "comprehensive"
      }
    }
  }'
```

### 2. Test the AI Integration

Now that the environment variables are configured, your existing deployed function will automatically use the Azure AI service:

```bash
# Test on Azure using your function URL (no redeployment needed!)
curl -X POST $FUNCTION_URL/api/mcp-server \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "ai_code_review",
      "arguments": {
        "code": "const user = { name: name, age: age }; console.log(user);",
        "language": "javascript"
      }
    }
  }'
```

The response should now show `"status": "ai_analysis"` instead of `"status": "mock_analysis"`!

### 3. Test in GitHub Copilot

Now let's test the AI code review with a real example. We've included a sample JavaScript file with intentional issues:

📁 **Open the sample file**: `sample-code-for-review.js`

This file contains various code quality issues including:
- Missing input validation
- Weak error handling
- Type safety issues
- Performance problems
- Security concerns

**Test the AI code review in VS Code:**

1. **Open** `sample-code-for-review.js` in VS Code
2. **Ask GitHub Copilot**:
   ```
   "Can you review this JavaScript code using AI analysis.
   ```

You should see Copilot provide detailed, AI-generated analysis pointing out:
- Input validation issues
- Type safety problems
- Security vulnerabilities
- Performance improvements
- Modern JavaScript best practices

**Compare the responses:**
- **Before Part 5**: Mock analysis with generic suggestions
- **After Part 5**: Detailed, specific AI analysis of the actual code issues

Copilot will now use the real Azure AI-powered code review tool!

---

## 📊 Monitoring AI Usage

### View Usage in Azure Portal

1. **Navigate to AI Foundry Portal**: [ai.azure.com](https://ai.azure.com)
2. **Go to your project** → "Monitoring"
3. **View metrics**:
   - Request count and latency
   - Token usage (input/output)
   - Error rates
   - Cost analysis


---

## 💰 Cost Management

- **GPT-3.5-turbo**: 1M of input and output, roughly $10
- **Typical code review**: ~500-1000 tokens per analysis
- **Estimated capacity**: 120-240 code reviews per month

### Cost Optimization Tips

1. **Use appropriate model**: GPT-3.5-turbo for most reviews
2. **Limit token usage**: Set maxTokens parameter
3. **Implement caching**: Cache results for identical code
4. **Graceful fallbacks**: Fall back to mock analysis if quotas exceeded

---

## ✅ AI Integration Verification

Test these scenarios in GitHub Copilot:

- [ ] **Simple function review**: "Review this function for best practices"
- [ ] **Security analysis**: "Check this code for security issues"  
- [ ] **Performance review**: "Analyze this code for performance improvements"
- [ ] **Type safety**: "Review this JavaScript for type safety issues"
- [ ] **Error handling**: "Check error handling in this code"

Each should now return detailed, AI-generated analysis!

---

## 🎉 Workshop Complete!

Congratulations! You've built a complete **production-ready MCP server** with:

- ✅ **Three custom tools** (markdown, dependency, AI code review)
- ✅ **Azure Functions deployment** with serverless scaling
- ✅ **GitHub Copilot integration** with VS Code
- ✅ **Real AI capabilities** powered by Azure AI Foundry
- ✅ **Production monitoring** and error handling
- ✅ **Cost-effective architecture** 

### 🚀 What You've Achieved

Your MCP server now provides:
- **Intelligent markdown analysis** with local algorithms
- **Security-focused dependency checking** with known vulnerability databases
- **AI-powered code reviews** with real language model analysis
- **Seamless Copilot integration** for enhanced development workflow

### 🔮 Next Steps

**Extend your MCP server:**
- Add more specialized tools (database queries, API testing, documentation generation)
- Integrate with other Azure AI services (Computer Vision, Speech, etc.)
- Implement team-sharing with authentication and rate limiting
- Create custom deployment pipelines for your organization

**Share your success:**
- Document your custom tools for team adoption
- Contribute patterns back to the MCP community
- Build organization-specific tool libraries

---

## 🐛 Troubleshooting AI Integration

### Common Issues

**AI tool returns mock analysis:**
```bash
# Verify environment variables are set
az functionapp config appsettings list \
  --name mcp-server-functions-<your-name> \
  --resource-group mcp-workshop-rg \
  --query "[?name=='AZURE_OPENAI_ENDPOINT']"
```

**API quota exceeded:**
- Check usage in AI Foundry portal
- Implement request throttling
- Add fallback to mock analysis

**Authentication errors:**
- Verify API key is correct
- Check endpoint URL format
- Ensure deployment name matches

---

## 📚 Additional Resources

- [Azure AI Foundry Documentation](https://docs.microsoft.com/azure/ai-services/openai/)
- [OpenAI Client Library](https://www.npmjs.com/package/@azure/openai)
- [MCP Production Patterns](reference-architecture-patterns.md)
- [Cost Management for AI Services](https://docs.microsoft.com/azure/cost-management-billing/)

---

**🎯 You've successfully created a sophisticated AI-enhanced development assistant that scales from personal use to enterprise deployment!**