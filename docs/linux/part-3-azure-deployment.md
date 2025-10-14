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

## Environment Setup

### For GitHub Codespaces Users

If you're using GitHub Codespaces, Azure CLI is already installed! You can proceed directly to the login step.

### For Local Linux Users

Install Azure CLI if needed:

```bash
# Ubuntu/Debian
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# CentOS/RHEL/Fedora
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf install -y azure-cli

# macOS
brew install azure-cli
```

Verify installation:

```bash
az --version
```

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

## Resource Creation

### 1. Create Resource Group

```bash
RESOURCE_GROUP="rg-mcp-workshop"
LOCATION="eastus"

az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 2. Create Storage Account

Azure Functions requires a storage account for metadata and triggers:

```bash
STORAGE_ACCOUNT="stmcpworkshop$RANDOM"

az storage account create \
  --name $STORAGE_ACCOUNT \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --sku Standard_LRS \
  --allow-blob-public-access false
```

### 3. Create Function App

```bash
FUNCTION_APP="func-mcp-server-$RANDOM"

az functionapp create \
  --resource-group $RESOURCE_GROUP \
  --consumption-plan-location $LOCATION \
  --runtime node \
  --runtime-version 20 \
  --functions-version 4 \
  --name $FUNCTION_APP \
  --storage-account $STORAGE_ACCOUNT \
  --os-type Linux \
  --sku FC1
```

**Note**: The FC1 SKU provides Flex Consumption which offers better cold start performance and more predictable pricing.

## Deployment Process

### 1. Prepare for Deployment

Ensure your project is built and ready:

```bash
# Navigate to project root (adjust path if different)
cd ~/mcp_projects/serverless_mcp_on_functions_for_github_copilot

# Install dependencies and build
npm install
npm run build
```

### 2. Deploy Function App

```bash
# Deploy to Azure Functions
func azure functionapp publish $FUNCTION_APP --typescript
```

This command:
- Builds your TypeScript code
- Packages the application
- Uploads to Azure Functions
- Configures the runtime environment

### 3. Configure Function App Settings

```bash
# Set Node.js version
az functionapp config appsettings set \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --settings "WEBSITE_NODE_DEFAULT_VERSION=~20"

# Enable detailed logging
az functionapp config appsettings set \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --settings "FUNCTIONS_WORKER_RUNTIME=node"
```

## Verification and Testing

### 1. Get Function URLs

```bash
# Get the function app hostname
HOSTNAME=$(az functionapp show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --query "defaultHostName" --output tsv)

# Display function URLs
echo "Function App URLs:"
echo "Base URL: https://$HOSTNAME"
echo "MCP Endpoint: https://$HOSTNAME/api/mcp"
```

### 2. Test Deployed Functions

Create a bash test script for the deployed functions:

```bash
# Create test script
cat > test-deployed-functions.sh << 'EOF'
#!/bin/bash

FUNCTION_URL="https://$HOSTNAME/api/mcp"

echo "Function URL: $FUNCTION_URL"
echo "=================================="

# Test 1: Health check
echo "Testing health check..."
if curl -s -o /dev/null -w "%{http_code}" "$FUNCTION_URL" | grep -q "200"; then
    echo "✅ Health check successful"
    curl -s "$FUNCTION_URL" | jq -r '.status'
else
    echo "❌ Health check failed"
fi

echo ""

# Test 2: MCP initialize
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

# Test 3: List tools
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

# Test 4: Call markdown_review tool
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
# View recent logs
az functionapp logs tail --name $FUNCTION_APP --resource-group $RESOURCE_GROUP

# Or open Azure portal to the function app
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

## Troubleshooting

### Common Deployment Issues

#### Issue: Deployment fails with "Storage account not found"

**Solution**: Verify the storage account was created successfully:

```bash
az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP
```

If missing, recreate:

```bash
az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_LRS
```

#### Issue: Function app returns 500 errors

**Solution**: Check application logs:

```bash
# View detailed logs
az functionapp logs tail --name $FUNCTION_APP --resource-group $RESOURCE_GROUP

# Check deployment status
az functionapp deployment list --name $FUNCTION_APP --resource-group $RESOURCE_GROUP
```

#### Issue: TypeScript compilation errors

**Solution**: Ensure clean build before deployment:

```bash
# Clean and rebuild
rm -rf dist
npm run build

# Verify dist folder contains compiled JavaScript
ls -la dist/
```

#### Issue: Cold start performance

**Solution**: The FC1 SKU should minimize cold starts, but you can also:

1. **Use Application Insights** for monitoring:
   ```bash
   az functionapp config appsettings set --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --settings "APPINSIGHTS_INSTRUMENTATIONKEY=your-key"
   ```

2. **Monitor performance**:
   ```bash
   # Check function performance metrics
   az monitor metrics list --resource "/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/$FUNCTION_APP" --metric "FunctionExecutionCount"
   ```

### Debugging with Azure Portal

1. **Navigate to Function App**:
   ```bash
   echo "https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/$FUNCTION_APP"
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

Optimize performance with these settings:

```bash
# Set optimal Node.js settings
az functionapp config appsettings set --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --settings \
  "WEBSITE_NODE_DEFAULT_VERSION=~20" \
  "FUNCTIONS_WORKER_RUNTIME=node" \
  "SCM_DO_BUILD_DURING_DEPLOYMENT=true" \
  "WEBSITE_RUN_FROM_PACKAGE=1"
```

### Monitoring Setup

```bash
# Create Application Insights
APP_INSIGHTS="ai-mcp-workshop"
az monitor app-insights component create --app $APP_INSIGHTS --location $LOCATION --resource-group $RESOURCE_GROUP

# Get instrumentation key
INSTRUMENTATION_KEY=$(az monitor app-insights component show --app $APP_INSIGHTS --resource-group $RESOURCE_GROUP --query "instrumentationKey" --output tsv)

# Configure Function App to use Application Insights
az functionapp config appsettings set --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$INSTRUMENTATION_KEY"
```

## Security Considerations

### Function App Security

1. **Authentication**: For production, consider enabling authentication:
   ```bash
   az functionapp auth update --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --enabled true --action LoginWithAzureActiveDirectory
   ```

2. **Access Keys**: Secure function keys if needed:
   ```bash
   # List function keys
   az functionapp keys list --name $FUNCTION_APP --resource-group $RESOURCE_GROUP
   
   # Create custom key
   az functionapp keys set --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --key-name "copilot-key" --key-value "your-secure-key"
   ```

3. **Network Security**: Configure network restrictions:
   ```bash
   # Restrict access to specific IPs (example for GitHub)
   az functionapp config access-restriction add --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --rule-name "GitHub" --action Allow --ip-address "140.82.112.0/20" --priority 100
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