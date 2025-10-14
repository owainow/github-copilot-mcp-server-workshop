# Part 4: Copilot Integration

> **Navigation**: [Workshop Home](../README.md) | [Windows Path](README.md) | [← Part 3](part-3-azure-deployment.md) | [Part 5 →](part-5-ai-integration.md)

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

### 2. Get Your Function URL

From Part 3, retrieve your Azure Function URL:

```powershell
# If you haven't saved these variables, recreate them
$functionApp = "func-mcp-server-XXXX"  # Replace with your actual function app name
$resourceGroup = "rg-mcp-workshop"

# Get the function URL
$functionUrl = "https://$(az functionapp show --name $functionApp --resource-group $resourceGroup --query 'defaultHostName' --output tsv)/api/mcp"
Write-Host "Your MCP Server URL: $functionUrl"
```

Save this URL - you'll need it for the configuration.

### 3. Configure VS Code Settings

GitHub Copilot can be configured to use custom MCP servers through VS Code settings.

#### Method 1: VS Code Settings UI

1. Open VS Code
2. Go to **File > Preferences > Settings** (or `Ctrl+,`)
3. Search for "copilot mcp"
4. Look for **GitHub Copilot › Chat: MCP Servers** setting
5. Add your server configuration

#### Method 2: Settings JSON

Open VS Code settings JSON (`Ctrl+Shift+P` → "Preferences: Open Settings (JSON)") and add:

```json
{
    "github.copilot.chat.mcpServers": {
        "azure-mcp-workshop": {
            "command": "node",
            "args": ["-e", "require('http').createServer((req,res)=>{const chunks=[];req.on('data',chunk=>chunks.push(chunk));req.on('end',()=>{const body=chunks.length?Buffer.concat(chunks).toString():'';const url=require('url').parse(req.url,true);if(req.method==='GET'){res.writeHead(200,{'Content-Type':'application/json'});res.end(JSON.stringify({status:'MCP Proxy Active',target:process.env.MCP_TARGET_URL}));return;}if(req.method==='POST'){require('https').request(process.env.MCP_TARGET_URL,{method:'POST',headers:{'Content-Type':'application/json'}},proxyRes=>{let data='';proxyRes.on('data',chunk=>data+=chunk);proxyRes.on('end',()=>{res.writeHead(proxyRes.statusCode,proxyRes.headers);res.end(data);});}).on('error',err=>{res.writeHead(500);res.end(JSON.stringify({error:err.message}));}).end(body);return;}res.writeHead(405);res.end();});}).listen(process.env.PORT||3000)"],
            "env": {
                "MCP_TARGET_URL": "YOUR_FUNCTION_URL_HERE",
                "PORT": "3001"
            }
        }
    }
}
```

Replace `YOUR_FUNCTION_URL_HERE` with your actual Azure Function URL.

#### Method 3: Direct HTTP Configuration (Preferred)

If GitHub Copilot supports direct HTTP MCP servers (check latest documentation), use:

```json
{
    "github.copilot.chat.mcpServers": {
        "azure-mcp-workshop": {
            "url": "YOUR_FUNCTION_URL_HERE",
            "description": "Azure Functions MCP Server with markdown review, dependency check, and AI code review tools"
        }
    }
}
```

### 4. Alternative: Local MCP Proxy

If direct HTTP configuration isn't supported, create a local proxy:

Create `mcp-proxy.js`:

```javascript
const http = require('http');
const https = require('https');
const url = require('url');

const TARGET_URL = process.env.MCP_TARGET_URL || 'YOUR_FUNCTION_URL_HERE';
const PORT = process.env.PORT || 3001;

const server = http.createServer((req, res) => {
    // Enable CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }

    if (req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ 
            status: 'MCP Proxy Active', 
            target: TARGET_URL,
            proxy: `http://localhost:${PORT}`
        }));
        return;
    }

    if (req.method === 'POST') {
        const chunks = [];
        req.on('data', chunk => chunks.push(chunk));
        req.on('end', () => {
            const body = chunks.length ? Buffer.concat(chunks).toString() : '';
            
            const options = {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(body)
                }
            };

            const proxyReq = https.request(TARGET_URL, options, (proxyRes) => {
                let data = '';
                proxyRes.on('data', chunk => data += chunk);
                proxyRes.on('end', () => {
                    res.writeHead(proxyRes.statusCode, proxyRes.headers);
                    res.end(data);
                });
            });

            proxyReq.on('error', (err) => {
                console.error('Proxy request error:', err);
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: err.message }));
            });

            proxyReq.end(body);
        });
        return;
    }

    res.writeHead(405);
    res.end();
});

server.listen(PORT, () => {
    console.log(`MCP Proxy running on http://localhost:${PORT}`);
    console.log(`Proxying to: ${TARGET_URL}`);
});
```

Run the proxy:

```powershell
# Set your function URL
$env:MCP_TARGET_URL = "YOUR_FUNCTION_URL_HERE"
node mcp-proxy.js
```

Then configure VS Code to use `http://localhost:3001` as the MCP server.

## Testing the Integration

### 1. Verify Copilot Connection

1. **Restart VS Code** after changing settings
2. **Open GitHub Copilot Chat** (`Ctrl+Shift+I` or click the chat icon)
3. **Check for MCP server connection** in the chat interface

### 2. Test MCP Tools in Copilot

#### Test 1: Markdown Review

In Copilot Chat, try:

```
@workspace Can you review this markdown content for issues?

# Sample Document
This is a sample document with some potential issues
- missing punctuation
- Inconsistent capitalization
- maybe some formatting problems

Please use the markdown_review tool to analyze this content.
```

#### Test 2: Dependency Check

Create a sample `package.json` and ask Copilot:

```
@workspace Can you check the dependencies in my package.json file for security vulnerabilities and outdated packages? Use the dependency_check tool.
```

#### Test 3: AI Code Review

Share some code and ask:

```
@workspace Can you review this TypeScript code for potential issues, security concerns, and best practices? Use the ai_code_review tool.

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

## Troubleshooting

### Common Integration Issues

#### Issue: Copilot doesn't recognize MCP server

**Symptoms**:
- No mention of custom tools in chat
- Standard Copilot responses without tool usage

**Solutions**:

1. **Check VS Code settings**:
   ```powershell
   # Open VS Code settings JSON
   code $env:APPDATA\Code\User\settings.json
   ```

2. **Verify URL accessibility**:
   ```powershell
   # Test the function URL directly
   $functionUrl = "YOUR_FUNCTION_URL_HERE"
   Invoke-RestMethod -Uri $functionUrl -Method GET
   ```

3. **Restart VS Code completely**:
   ```powershell
   # Close all VS Code instances and restart
   taskkill /F /IM "code.exe"
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
   ```powershell
   netstat -an | findstr "3001"
   ```

2. **Check firewall settings**:
   ```powershell
   # Allow Node.js through Windows Firewall
   netsh advfirewall firewall add rule name="Node.js MCP Proxy" dir=in action=allow program="$env:ProgramFiles\nodejs\node.exe"
   ```

3. **Test proxy directly**:
   ```powershell
   Invoke-RestMethod -Uri "http://localhost:3001" -Method GET
   ```

#### Issue: Tools not appearing in Copilot

**Symptoms**:
- MCP server connected but tools not available
- Copilot doesn't suggest using custom tools

**Solutions**:

1. **Test MCP initialize endpoint**:
   ```powershell
   $initBody = @{
       jsonrpc = "2.0"
       id = 1
       method = "initialize"
       params = @{
           protocolVersion = "2024-11-05"
           capabilities = @{ tools = @{} }
           clientInfo = @{ name = "test"; version = "1.0.0" }
       }
   } | ConvertTo-Json -Depth 10

   Invoke-RestMethod -Uri $functionUrl -Method POST -Body $initBody -ContentType "application/json"
   ```

2. **Test tools list endpoint**:
   ```powershell
   $toolsBody = @{
       jsonrpc = "2.0"
       id = 2
       method = "tools/list"
       params = @{}
   } | ConvertTo-Json -Depth 10

   Invoke-RestMethod -Uri $functionUrl -Method POST -Body $toolsBody -ContentType "application/json"
   ```

3. **Check Azure Function logs**:
   ```powershell
   az functionapp logs tail --name $functionApp --resource-group $resourceGroup
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
   ```powershell
   # Check for VS Code and extension updates
   code --list-extensions --show-versions
   ```

### Network and Connectivity Issues

#### Issue: CORS errors in browser/VS Code

**Solutions**:

1. **Configure CORS on Azure Function**:
   ```powershell
   az functionapp cors add --name $functionApp --resource-group $resourceGroup --allowed-origins "*"
   ```

2. **Add CORS headers to function response**:
   Ensure your Azure Function includes proper CORS headers (this should already be in the code).

#### Issue: Authentication errors

**Solutions**:

1. **Check function authentication settings**:
   ```powershell
   az functionapp auth show --name $functionApp --resource-group $resourceGroup
   ```

2. **Ensure anonymous access**:
   ```powershell
   az functionapp config appsettings set --name $functionApp --resource-group $resourceGroup --settings "AzureWebJobsSecretStorageType=files"
   ```

## Best Practices

### 1. Configuration Management

- **Environment Variables**: Use environment variables for URLs
- **Multiple Environments**: Configure separate dev/prod servers
- **Version Control**: Keep MCP configuration in version control
- **Documentation**: Document tool purposes and usage

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

```powershell
# Example: Set up Application Insights for monitoring
$appInsights = "ai-mcp-workshop"
az monitor app-insights component create --app $appInsights --location "East US" --resource-group $resourceGroup

$instrumentationKey = az monitor app-insights component show --app $appInsights --resource-group $resourceGroup --query "instrumentationKey" --output tsv

az functionapp config appsettings set --name $functionApp --resource-group $resourceGroup --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$instrumentationKey"
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

## Monitoring and Analytics

### 1. Usage Tracking

Monitor how Copilot uses your MCP tools:

```powershell
# Create a dashboard query for Application Insights
$query = @"
requests
| where name == "mcp"
| extend toolName = tostring(customDimensions.tool_name)
| summarize count() by toolName, bin(timestamp, 1h)
| order by timestamp desc
"@

# View in Application Insights
Write-Host "Query for Application Insights:"
Write-Host $query
```

### 2. Performance Metrics

Track tool performance:

```powershell
# Function execution metrics
az monitor metrics list --resource "/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$functionApp" --metric "FunctionExecutionCount" --interval PT1H
```

### 3. Error Analysis

Monitor and analyze errors:

```powershell
# Check for errors in the last 24 hours
az functionapp logs tail --name $functionApp --resource-group $resourceGroup | Select-String "ERROR"
```

## Next Steps

Congratulations! You've successfully integrated your custom MCP server with GitHub Copilot. Your AI assistant now has access to powerful custom tools for markdown review, dependency checking, and AI code review.

### What We Accomplished

- ✅ Configured GitHub Copilot to use custom MCP servers
- ✅ Set up VS Code integration with your Azure Function
- ✅ Tested MCP tool integration with Copilot
- ✅ Learned troubleshooting techniques for integration issues
- ✅ Implemented best practices for configuration and monitoring

### Key Takeaways

1. **MCP Protocol**: Provides a standardized way to extend AI capabilities
2. **Azure Functions Integration**: Serverless hosting works excellently with MCP
3. **VS Code Configuration**: Proper configuration is crucial for seamless integration
4. **Tool Discovery**: Copilot automatically discovers and uses available tools
5. **Error Handling**: Robust error handling ensures reliable tool usage

### Ready for Advanced AI Integration

Your MCP server is now fully integrated with GitHub Copilot and ready for advanced AI scenarios. Continue to [Part 5: AI Integration](part-5-ai-integration.md) to explore Azure AI Foundry integration and advanced AI-powered workflows!

---

> **Navigation**: [Workshop Home](../README.md) | [Windows Path](README.md) | [← Part 3](part-3-azure-deployment.md) | [Part 5 →](part-5-ai-integration.md)