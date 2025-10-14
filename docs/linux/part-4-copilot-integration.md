# Part 4: Copilot Integration

> **Navigation**: [Workshop Home](../README.md) | [Linux Path](README.md) | [← Part 3](part-3-azure-deployment.md) | [Part 5 →](part-5-ai-integration.md)

## Overview

Now that your MCP server is deployed to Azure Functions, it's time to integrate it with GitHub Copilot! This integration allows Copilot to use your custom tools during chat conversations, giving you access to markdown review, dependency checking, and AI code review capabilities directly within VS Code.

## Learning Objectives

- Configure GitHub Copilot with custom MCP servers
- Test MCP tool integration with Copilot
- Use custom tools in Copilot chat sessions
- Troubleshoot integration issues
- Understand MCP configuration best practices

## Prerequisites

- Completed [Part 3: Azure Deployment](part-3-azure-deployment.md)
- GitHub Copilot subscription (Individual or Business)
- VS Code with GitHub Copilot extension installed
- Your deployed Azure Function URL

## GitHub Copilot Configuration

### 1. Understanding MCP in GitHub Copilot

GitHub Copilot supports Model Context Protocol (MCP) servers to extend its capabilities with custom tools. Your deployed Azure Function acts as an MCP server that Copilot can call to perform specific tasks.

Key concepts:
- **MCP Server**: Your Azure Function hosting custom tools
- **MCP Client**: GitHub Copilot acting as the client
- **Tools**: Your `markdown_review`, `dependency_check`, and `ai_code_review` functions
- **Protocol**: JSON-RPC 2.0 over HTTP

### 2. Echo Your Function URL

From Part 3 we have already set our Functions env vars, echo your Function URL's:

```bash


# Get the function URL
echo "Base URL: $FUNCTION_URL"
echo "MCP Endpoint: $FUNCTION_URL/api/mcp-server"
```
### 3. Configure VS Code Settings

GitHub Copilot can be configured to use custom MCP servers through VS Code settings.


### 2. Configure MCP in VS Code

#### Method 1: VS Code Settings UI

1. Click on the tools Icon in your CoPilot Chat (Can also press Ctrl+shift+p and type MCP then select the option "Add MCP Server")
2. Click the "Add MCP Server" Icon in the top right corner of the tools box
3. Select to connect to a remote MCP server using HTTP
4. Pass in the URL of your function and press enter.
5. Name the MCP server and select "Global".
6. Review the created mcp.json and the status shown of the server. You should see it say "Running"
7. Ask your copilot chat what MCP servers it has available, it should respond with your custom MCP server and the tools. 


## Testing the Integration

### 1. Verify Copilot Connection

1. **Open GitHub Copilot Chat** (`Ctrl+Shift+I` or click the chat icon)
2. **Check for MCP server connection** in the chat interface

### 2. Test MCP Tools in Copilot

#### Test 1: Markdown Review

In Copilot Chat, try:

```
Can you review this markdown content for issues?

# Sample Document
This is a sample document with some potential issues
- missing punctuation
- Inconsistent capitalization
- maybe some formatting problems

```

#### Test 2: Dependency Check

Create a sample `package.json` and ask Copilot:

```
Can you check the dependencies in my package.json file for security vulnerabilities and outdated packages?
```

#### Test 3: AI Code Review

Share some code and ask:

```
Can you review this TypeScript code for potential issues, security concerns, and best practices?

```typescript
function processUserData(data: any) {
    return data.map(item => {
        return {
            id: item.id,
            name: item.name.toLowerCase(),
            email: item.email
        };
    });
}
```

### 3. Verify Tool Calls

When Copilot uses your MCP tools, you should see:

1. **Tool invocation messages** in the chat
2. **Results from your Azure Function** integrated into Copilot's responses
3. **Structured suggestions** based on your tool outputs

## Advanced Configuration

Here are some examples of advanced MCP CoPilot use:

### 1. Multiple MCP Servers

You can configure multiple MCP servers:

```json
{
    "github.copilot.chat.mcpServers": {
        "azure-mcp-workshop": {
            "url": "https://your-function-app.azurewebsites.net/api/mcp",
            "description": "Azure Functions MCP Server"
        },
        "local-mcp-server": {
            "command": "node",
            "args": ["path/to/local/mcp/server.js"]
        }
    }
}
```

### 2. Environment-Specific Configuration

Create different configurations for development and production:

```json
{
    "github.copilot.chat.mcpServers": {
        "mcp-dev": {
            "url": "http://localhost:7071/api/mcp",
            "description": "Local development MCP server"
        },
        "mcp-prod": {
            "url": "https://your-prod-function.azurewebsites.net/api/mcp",
            "description": "Production MCP server"
        }
    }
}
```

### 3. Tool-Specific Configuration

Configure specific tools with custom parameters:

```json
{
    "github.copilot.chat.mcpServers": {
        "azure-mcp-workshop": {
            "url": "https://your-function-app.azurewebsites.net/api/mcp",
            "description": "Azure Functions MCP Server",
            "tools": {
                "markdown_review": {
                    "enabled": true,
                    "description": "Review markdown content for quality and formatting"
                },
                "dependency_check": {
                    "enabled": true,
                    "description": "Check project dependencies for security issues"
                },
                "ai_code_review": {
                    "enabled": true,
                    "description": "AI-powered code review for best practices"
                }
            }
        }
    }
}
```


## Real-World Usage Examples

### 1. Code Review Workflow

Use Copilot with your MCP tools for comprehensive code reviews:

```
@workspace I'm working on a new feature. Can you:
1. Review this TypeScript code using ai_code_review tool
2. Check dependencies in package.json with dependency_check tool  
3. Review the README.md file with markdown_review tool

Please provide a comprehensive analysis with recommendations.
```

### 2. Documentation Improvement

```
@workspace Help me improve this documentation:
1. Use markdown_review to identify formatting and content issues
2. Suggest improvements based on the analysis
3. Provide a revised version following best practices
```

### 3. Security Analysis

```
@workspace Perform a security analysis of my project:
1. Use dependency_check to identify vulnerable packages
2. Use ai_code_review to check for security issues in the code
3. Provide prioritized recommendations for fixing issues
```

## Next Steps

Congratulations! You've successfully integrated your custom MCP server with GitHub Copilot. Your AI assistant now has access to powerful custom tools for markdown review, dependency checking, and AI code review.

### What We Accomplished

- ✅ Configured GitHub Copilot to use custom MCP servers
- ✅ Set up VS Code integration with your Azure Function
- ✅ Tested MCP tool integration with Copilot
- ✅ Learned troubleshooting techniques for integration issues
- ✅ Implemented best practices for configuration and monitoring
- ✅ Created automation scripts for workflow management
- ✅ Optimized configuration for both local and Codespaces environments

### Key Takeaways

1. **MCP Protocol**: Provides a standardized way to extend AI capabilities
2. **Azure Functions Integration**: Serverless hosting works excellently with MCP
3. **VS Code Configuration**: Proper configuration is crucial for seamless integration
4. **Tool Discovery**: Copilot automatically discovers and uses available tools
5. **Error Handling**: Robust error handling ensures reliable tool usage
6. **Cross-Platform**: Configuration works in both local Linux and GitHub Codespaces

### Ready for Advanced AI Integration

Your MCP server is now fully integrated with GitHub Copilot and ready for advanced AI scenarios. Continue to [Part 5: AI Integration](part-5-ai-integration.md) to explore Azure AI Foundry integration and advanced AI-powered workflows!

---

> **Navigation**: [Workshop Home](../README.md) | [Linux Path](README.md) | [← Part 3](part-3-azure-deployment.md) | [Part 5 →](part-5-ai-integration.md)

## Troubleshooting

### Common Integration Issues

#### Issue: Copilot doesn't recognize MCP server

**Symptoms**:
- No mention of custom tools in chat
- Standard Copilot responses without tool usage

**Solutions**:

1. **Check VS Code settings**:
   ```bash
   # Open VS Code settings directory
   ls -la ~/.config/Code/User/settings.json
   
   # Or for Codespaces
   ls -la ~/.vscode-remote/data/Machine/settings.json
   ```

2. **Verify URL accessibility**:
   ```bash
   # Test the function URL directly
   curl -s "$FUNCTION_URL" | jq
   ```

3. **Restart VS Code completely**:
   ```bash
   # Kill all VS Code processes and restart
   pkill -f "code"
   code .
   ```

4. **Check Copilot logs**:
   - Open **Developer Tools** (`Ctrl+Shift+I`)
   - Check **Console** and **Network** tabs for errors

#### Issue: MCP proxy connection errors

**Symptoms**:
- Connection timeouts
- 500 errors in proxy

**Solutions**:

1. **Verify proxy is running**:
   ```bash
   netstat -tlnp | grep 3001
   # Or
   lsof -i :3001
   ```

2. **Check proxy logs**:
   ```bash
   tail -f mcp-proxy.log
   ```

3. **Test proxy directly**:
   ```bash
   curl -s "http://localhost:3001" | jq
   ```

4. **Restart proxy if needed**:
   ```bash
   pkill -f "mcp-proxy.js"
   export MCP_TARGET_URL="$FUNCTION_URL"
   nohup node mcp-proxy.js > mcp-proxy.log 2>&1 &
   ```

#### Issue: Tools not appearing in Copilot

**Symptoms**:
- MCP server connected but tools not available
- Copilot doesn't suggest using custom tools

**Solutions**:

1. **Test MCP initialize endpoint**:
   ```bash
   curl -s -X POST "$FUNCTION_URL" \
     -H "Content-Type: application/json" \
     -d '{
       "jsonrpc": "2.0",
       "id": 1,
       "method": "initialize",
       "params": {
         "protocolVersion": "2024-11-05",
         "capabilities": {"tools": {}},
         "clientInfo": {"name": "test", "version": "1.0.0"}
       }
     }' | jq
   ```

2. **Test tools list endpoint**:
   ```bash
   curl -s -X POST "$FUNCTION_URL" \
     -H "Content-Type: application/json" \
     -d '{
       "jsonrpc": "2.0",
       "id": 2,
       "method": "tools/list",
       "params": {}
     }' | jq
   ```

3. **Check Azure Function logs**:
   ```bash
   az functionapp logs tail --name $FUNCTION_APP --resource-group $RESOURCE_GROUP
   ```

### VS Code Extension Issues

#### Issue: GitHub Copilot extension not responding

**Solutions**:

1. **Reload VS Code window**:
   - `Ctrl+Shift+P` → "Developer: Reload Window"

2. **Restart Copilot extension**:
   - `Ctrl+Shift+P` → "GitHub Copilot: Restart Extension"

3. **Check Copilot status**:
   - Look for Copilot icon in status bar
   - Ensure you're signed in to GitHub

4. **Update extensions**:
   ```bash
   # Check for VS Code and extension updates
   code --list-extensions --show-versions
   ```

### Network and Connectivity Issues

#### Issue: CORS errors in browser/VS Code

**Solutions**:

1. **Configure CORS on Azure Function**:
   ```bash
   az functionapp cors add --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --allowed-origins "*"
   ```

2. **Add CORS headers to function response**:
   Ensure your Azure Function includes proper CORS headers (this should already be in the code).

#### Issue: Authentication errors

**Solutions**:

1. **Check function authentication settings**:
   ```bash
   az functionapp auth show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP
   ```

2. **Ensure anonymous access**:
   ```bash
   az functionapp config appsettings set --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --settings "AzureWebJobsSecretStorageType=files"
   ```

### Codespaces-Specific Issues

#### Issue: Port forwarding conflicts

**Solutions**:

1. **Check port status**:
   ```bash
   # Check if port 3001 is in use
   lsof -i :3001
   ```

2. **Use different port**:
   ```bash
   export PORT=3002
   node mcp-proxy.js &
   ```

3. **Configure Codespaces port forwarding**:
   - Go to **Ports** tab in VS Code
   - Add port 3001 (or your chosen port)
   - Set visibility to **Public** if needed

#### Issue: VS Code settings not persisting

**Solutions**:

1. **Use workspace settings**:
   ```bash
   # Create .vscode/settings.json in project root
   mkdir -p .vscode
   cat > .vscode/settings.json << 'EOF'
   {
       "github.copilot.chat.mcpServers": {
           "azure-mcp-workshop": {
               "url": "YOUR_FUNCTION_URL_HERE",
               "description": "Azure Functions MCP Server"
           }
       }
   }
   EOF
   ```

2. **Use user settings in Codespaces**:
   ```bash
   # Settings sync should handle this automatically
   # But you can manually edit if needed
   mkdir -p ~/.vscode-remote/data/Machine
   # Edit ~/.vscode-remote/data/Machine/settings.json
   ```

## Best Practices

### 1. Configuration Management

- **Environment Variables**: Use environment variables for URLs
- **Multiple Environments**: Configure separate dev/prod servers
- **Version Control**: Keep MCP configuration in version control
- **Documentation**: Document tool purposes and usage

```bash
# Create environment script
cat > setup-mcp-env.sh << 'EOF'
#!/bin/bash
export FUNCTION_APP="func-mcp-server-XXXX"
export RESOURCE_GROUP="rg-mcp-workshop"
export FUNCTION_URL="https://$(az functionapp show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --query 'defaultHostName' --output tsv)/api/mcp"
echo "MCP Environment configured:"
echo "Function URL: $FUNCTION_URL"
EOF

chmod +x setup-mcp-env.sh
source setup-mcp-env.sh
```

### 2. Performance Optimization

- **Connection Pooling**: Reuse connections when possible
- **Caching**: Cache tool responses for repeated calls
- **Timeout Configuration**: Set appropriate timeouts
- **Error Handling**: Graceful degradation when tools fail

### 3. Security Considerations

- **Authentication**: Consider adding authentication for production
- **Rate Limiting**: Implement rate limiting on Azure Functions
- **Input Validation**: Validate all tool inputs
- **Logging**: Log tool usage for auditing

```bash
# Example: Set up Application Insights for monitoring
APP_INSIGHTS="ai-mcp-workshop"
az monitor app-insights component create --app $APP_INSIGHTS --location "eastus" --resource-group $RESOURCE_GROUP

INSTRUMENTATION_KEY=$(az monitor app-insights component show --app $APP_INSIGHTS --resource-group $RESOURCE_GROUP --query "instrumentationKey" --output tsv)

az functionapp config appsettings set --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$INSTRUMENTATION_KEY"
```
