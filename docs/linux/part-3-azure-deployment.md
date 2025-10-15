# Part 3: Azure Deployment

> **Navigation**: [Workshop Home](../README.md) | [Linux Path](README.md) | [← Part 2](part-2-local-development.md) | [Part 4 →](part-4-copilot-integration.md)

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

### 1. Login to Azure

```bash
az login
```

This opens a browser window for authentication. In Codespaces, you may need to use device code flow:

```bash
# If browser login doesn't work in Codespaces
az login --use-device-code
```

After successful login, you'll see your subscription details.

### 2. Set Default Subscription (if you have multiple)

```bash
# List available subscriptions
az account list --output table

# Set default subscription
az account set --subscription "Your-Subscription-Name-Or-ID"
```

## Infrastructure Deployment

We'll use Infrastructure as Code (Bicep) to deploy all Azure resources with proper Flex Consumption configuration. This ensures consistent, repeatable deployments with all the latest Azure Functions features.

### 1. Review Infrastructure Configuration

First, let's examine our Bicep template that defines the infrastructure:

```bash
# Review the main Bicep template
cat infra/main.bicep | head -30

# Review the parameters file
cat infra/main.parameters.json
```

Our Bicep template includes:
- **Flex Consumption Plan (FC1 SKU)** - Modern serverless hosting
- **Storage Account** - With managed identity authentication (no connection strings!)
- **Application Insights** - For comprehensive monitoring
- **Proper RBAC** - Secure role assignments for managed identity
- **Security Settings** - HTTPS only, latest TLS, secure storage configuration

### 2. Create Resource Group

```bash
RESOURCE_GROUP="rg-mcp-workshop"
LOCATION="eastus"

az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 3. Deploy Infrastructure with Bicep

Instead of creating resources manually, we'll deploy everything at once using our Bicep template:

```bash
# Deploy all infrastructure using Bicep
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json

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

```bash
# Get the function app name and URL from deployment outputs
FUNCTION_APP=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name main \
  --query "properties.outputs.functionAppName.value" \
  --output tsv)

FUNCTION_URL=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name main \
  --query "properties.outputs.functionAppUrl.value" \
  --output tsv)

echo "Function App: $FUNCTION_APP"
echo "Function URL: $FUNCTION_URL"

# Store these for later use
echo "export FUNCTION_APP='$FUNCTION_APP'" >> ~/.bashrc
echo "export FUNCTION_URL='$FUNCTION_URL'" >> ~/.bashrc
source ~/.bashrc
```

## Deploy Function App

Now deploy your application to the newly created infrastructure:

```bash
# Build the application
npm run build

# Deploy to Azure Functions using the Bicep-created infrastructure
func azure functionapp publish $FUNCTION_APP --typescript
```

This command:
- Builds your TypeScript code (if not already done)
- Packages the application
- Uploads to the Azure Function App created by Bicep
- Configures the runtime environment
- Uses the secure managed identity configuration from our Bicep template

### Why This Works Better Than Manual Setup

Our Bicep template configured the Function App with:

1. **Secure Storage Access**: Uses managed identity instead of connection strings
2. **Optimal Performance**: Flex Consumption (FC1) with 2GB memory allocation
3. **Proper Monitoring**: Application Insights with connection string authentication
4. **Security Settings**: HTTPS only, latest TLS, secure CORS configuration
5. **Environment Variables**: Pre-configured MCP server settings

### Verify Deployment Status

```bash
# Check deployment status
az functionapp show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --query "state" --output tsv

# View function app configuration
az functionapp config show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP
```

## Verification and Testing

### 1. Get Function URLs

```bash
# The function app hostname is available from our deployment
echo "Function App URLs:"
echo "Base URL: $FUNCTION_URL"
echo "MCP Endpoint: $FUNCTION_URL/api/mcp"

```

### 2. Test Deployed Functions

Create a bash test script for the deployed functions:

```bash
# Create test script
cat > test-deployed-functions.sh << 'EOF'
#!/bin/bash

# Use the function URL from our deployment
FUNCTION_URL="$FUNCTION_URL/api/mcp"

echo "Function URL: $FUNCTION_URL"
echo "=================================="


# Test 1: MCP initialize
echo "Testing MCP initialize..."
INIT_RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {
        "tools": {}
      },
      "clientInfo": {
        "name": "test-client",
        "version": "1.0.0"
      }
    }
  }')

if echo "$INIT_RESPONSE" | jq -e '.result.serverInfo.name' > /dev/null 2>&1; then
    echo "✅ Initialize successful"
    echo "   Server: $(echo "$INIT_RESPONSE" | jq -r '.result.serverInfo.name') v$(echo "$INIT_RESPONSE" | jq -r '.result.serverInfo.version')"
    echo "   Tools available: $(echo "$INIT_RESPONSE" | jq -r '.result.capabilities.tools.listChanged // false')"
else
    echo "❌ Initialize failed"
    echo "   Response: $INIT_RESPONSE"
fi

echo ""

# Test 2: List tools
echo "Testing tools list..."
TOOLS_RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/list",
    "params": {}
  }')

if echo "$TOOLS_RESPONSE" | jq -e '.result.tools' > /dev/null 2>&1; then
    echo "✅ Tools list successful"
    echo "   Available tools:"
    echo "$TOOLS_RESPONSE" | jq -r '.result.tools[] | "   - \(.name): \(.description)"'
else
    echo "❌ Tools list failed"
    echo "   Response: $TOOLS_RESPONSE"
fi

echo ""

# Test 3: Call markdown_review tool
echo "Testing markdown_review tool..."
MARKDOWN_CONTENT="# Test Document
This is a test document with some issues.
- Missing periods
- inconsistent formatting"

REVIEW_RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"id\": 3,
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"markdown_review\",
      \"arguments\": {
        \"content\": $(echo "$MARKDOWN_CONTENT" | jq -Rs .)
      }
    }
  }")

if echo "$REVIEW_RESPONSE" | jq -e '.result.content[0].text' > /dev/null 2>&1; then
    echo "✅ Markdown review successful"
    SUGGESTIONS_COUNT=$(echo "$REVIEW_RESPONSE" | jq -r '.result.content[0].text' | jq '.suggestions | length')
    echo "   Suggestions count: $SUGGESTIONS_COUNT"
else
    echo "❌ Markdown review failed"
    echo "   Response: $REVIEW_RESPONSE"
fi
EOF

# Make executable and run
chmod +x test-deployed-functions.sh
./test-deployed-functions.sh
```

### 3. Monitor Function Execution

```bash

# Open Azure portal to the function app and view your function
echo "View in Azure Portal:"
echo "https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/$FUNCTION_APP"
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

## Next Steps

Great! You've successfully deployed your MCP server to Azure Functions. Your custom tools are now running in the cloud and ready for integration.

### What We Accomplished

- ✅ Created Azure resources (Resource Group, Storage Account, Function App)
- ✅ Deployed TypeScript Azure Functions to the cloud
- ✅ Configured Function App with optimal settings (FC1 SKU, Node.js 20)
- ✅ Tested deployed functions with HTTP requests
- ✅ Set up monitoring and logging
- ✅ Learned troubleshooting techniques
- ✅ Created useful scripts for future deployments

### Key Takeaways

1. **Serverless Architecture**: Azure Functions provide scalable, cost-effective hosting for MCP servers
2. **FC1 SKU Benefits**: Better cold start performance and predictable pricing
3. **MCP Protocol**: Works seamlessly in serverless environments with proper error handling
4. **Testing Strategy**: Comprehensive testing ensures reliability in production
5. **Monitoring**: Application Insights provides valuable insights for optimization
6. **Cross-Platform**: Works great in both local Linux environments and GitHub Codespaces

### Ready for Copilot Integration

Your function URLs are now ready for GitHub Copilot integration:
- **Function App URL**: `https://{your-function-app}.azurewebsites.net`
- **MCP Endpoint**: `https://{your-function-app}.azurewebsites.net/api/mcp`

Continue to [Part 4: Copilot Integration](part-4-copilot-integration.md) to connect your deployed MCP server with GitHub Copilot!

---

> **Navigation**: [Workshop Home](../README.md) | [Linux Path](README.md) | [← Part 2](part-2-local-development.md) | [Part 4 →](part-4-copilot-integration.md)

## Troubleshooting

### Common Deployment Issues


### Debugging with Azure Portal

1. **Navigate to Function App**:
   ```bash
   echo "Azure Portal: https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/$FUNCTION_APP"
   ```

2. **Check Function Execution**:
   - Go to Functions → mcp → Code + Test
   - Use "Test/Run" to test directly in portal
   - View execution history in Monitor tab

3. **Application Insights** (pre-configured by Bicep):
   - View performance metrics and error traces
   - Set up alerts for failures
   - Check cold start performance

4. **Managed Identity Status**:
   - Go to Identity tab to verify system-assigned identity is enabled
   - Check role assignments under Access control (IAM)

### Network and CORS Issues

If testing from browser applications:

```bash
# Configure CORS for development
az functionapp cors add --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --allowed-origins "*"

# For production, be more specific:
az functionapp cors add --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --allowed-origins "https://github.com"
```

### Codespaces-Specific Issues

#### Issue: Browser authentication not working

**Solution**: Use device code authentication:

```bash
az login --use-device-code
```

#### Issue: Port forwarding for local testing

If you need to test local functions in Codespaces:

```bash
# Start local functions (in another terminal)
func start --port 7071

# The port will be automatically forwarded in Codespaces
# Access via: https://your-codespace-name-7071.app.github.dev/api/mcp
```

## Performance Optimization

### Function App Settings

Our Bicep template has already configured optimal settings, but you can verify them:

```bash
# View current app settings configured by Bicep
az functionapp config appsettings list --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --output table

# Key settings already configured:
# - FUNCTIONS_EXTENSION_VERSION=~4
# - Node.js 20 runtime
# - Managed identity for storage access
# - Application Insights connection
# - CORS settings for GitHub integration
```

### Infrastructure Advantages

Our Bicep-deployed infrastructure provides:

1. **Flex Consumption (FC1)** benefits:
   - Better cold start performance than Consumption plan
   - 2GB memory allocation (vs 1.5GB in Consumption)
   - More predictable performance

2. **Managed Identity** security:
   - No connection strings in configuration
   - Automatic role-based access to storage
   - Reduced security attack surface

3. **Monitoring Ready**:
   - Application Insights pre-configured
   - Performance counters enabled
   - Error tracking built-in

### Advanced Configuration

If you need to modify settings, update the Bicep template rather than using CLI:

```bash
# Example: Update memory allocation in infra/main.bicep
# scaleAndConcurrency: {
#   maximumInstanceCount: 100
#   instanceMemoryMB: 4096  // Increase from 2048 if needed
# }

# Then redeploy
az deployment group create --resource-group $RESOURCE_GROUP --template-file infra/main.bicep --parameters @infra/main.parameters.json
```

## Security Considerations

### Built-in Security from Bicep Template

Our infrastructure deployment includes several security best practices:

1. **Managed Identity**: No connection strings stored in configuration
2. **HTTPS Only**: All traffic encrypted in transit
3. **Latest TLS**: TLS 1.2 minimum enforced
4. **Secure Storage**: Blob public access disabled, shared key access disabled
5. **CORS Configuration**: Limited to GitHub domains
6. **RBAC**: Principle of least privilege with specific role assignments

### View Security Configuration

```bash
# Check security settings applied by Bicep
az functionapp config show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --query "httpsOnly,minTlsVersion"

# View CORS settings
az functionapp cors show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP

# Check managed identity configuration
az functionapp identity show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP
```

### Additional Security (Optional)

For production environments, consider additional security:

1. **Authentication**: Enable if needed
   ```bash
   az functionapp auth update --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --enabled true --action LoginWithAzureActiveDirectory
   ```

2. **Access Keys**: Our template uses anonymous auth level for GitHub Copilot compatibility
   ```bash
   # View function keys if authentication is needed
   az functionapp keys list --name $FUNCTION_APP --resource-group $RESOURCE_GROUP
   ```

3. **Network Security**: Add IP restrictions if needed
   ```bash
   # Example: Restrict to GitHub IP ranges
   az functionapp config access-restriction add \
     --name $FUNCTION_APP \
     --resource-group $RESOURCE_GROUP \
     --rule-name "GitHub" \
     --action Allow \
     --ip-address "140.82.112.0/20" \
     --priority 100
   ```

### Security Monitoring

```bash
# View security recommendations in Azure Security Center
az security assessment list --scope "/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$RESOURCE_GROUP"
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
   ```bash
   # View cost analysis in portal
   echo "Cost Analysis: https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id --output tsv)/providers/Microsoft.CostManagement/costByResource"
   ```

3. **Set up budget alerts**:
   ```bash
   # Create budget (adjust amount as needed)
   az consumption budget create --resource-group $RESOURCE_GROUP --budget-name "mcp-workshop-budget" --amount 10 --time-grain Monthly
   ```

## Useful Commands Reference

Save these commands for future reference:

```bash
# Export environment variables for reuse
echo "export RESOURCE_GROUP='$RESOURCE_GROUP'" >> ~/.bashrc
echo "export FUNCTION_APP='$FUNCTION_APP'" >> ~/.bashrc
echo "export STORAGE_ACCOUNT='$STORAGE_ACCOUNT'" >> ~/.bashrc
source ~/.bashrc

# Quick deployment script
cat > deploy.sh << 'EOF'
#!/bin/bash
npm run build && func azure functionapp publish $FUNCTION_APP --typescript
EOF
chmod +x deploy.sh

# Quick test script
cat > quick-test.sh << 'EOF'
#!/bin/bash
HOSTNAME=$(az functionapp show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --query "defaultHostName" --output tsv)
curl -s "https://$HOSTNAME/api/mcp" | jq
EOF
chmod +x quick-test.sh
```

