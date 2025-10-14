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

### 2. Get Your Function URL

From Part 3, retrieve your Azure Function URL:

```bash
# If you haven't saved these variables, recreate them
FUNCTION_APP="func-mcp-server-XXXX"  # Replace with your actual function app name
RESOURCE_GROUP="rg-mcp-workshop"

# Get the function URL
FUNCTION_URL="https://$(az functionapp show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --query 'defaultHostName' --output tsv)/api/mcp"
echo "Your MCP Server URL: $FUNCTION_URL"

# Save for reuse
echo "export FUNCTION_URL='$FUNCTION_URL'" >> ~/.bashrc
source ~/.bashrc
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

```bash
# Set your function URL
export MCP_TARGET_URL="$FUNCTION_URL"
node mcp-proxy.js &

# Or run in background with logging
nohup node mcp-proxy.js > mcp-proxy.log 2>&1 &
echo "MCP Proxy started with PID: $!"
```

Then configure VS Code to use `http://localhost:3001` as the MCP server.

#### Stop the proxy when done:

```bash
# Find and stop the proxy process
pkill -f "mcp-proxy.js"
```

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

```bash
# Create a monitoring script
cat > monitor-mcp-usage.sh << 'EOF'
#!/bin/bash

echo "MCP Server Monitoring Dashboard"
echo "================================"

# Check function app status
echo "Function App Status:"
az functionapp show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --query "state" --output tsv

# Check recent invocations (requires Application Insights)
echo "Recent Function Invocations:"
az monitor app-insights query --app $APP_INSIGHTS --analytics-query "
requests
| where name == 'mcp'
| summarize count() by bin(timestamp, 1h)
| order by timestamp desc
| take 24
"

# Check proxy status if running
echo "Proxy Status:"
if pgrep -f "mcp-proxy.js" > /dev/null; then
    echo "✅ MCP Proxy is running (PID: $(pgrep -f 'mcp-proxy.js'))"
    echo "📊 Proxy URL: http://localhost:3001"
else
    echo "❌ MCP Proxy is not running"
fi

# Test MCP endpoint
echo "MCP Endpoint Test:"
if curl -s "$FUNCTION_URL" > /dev/null; then
    echo "✅ MCP endpoint is accessible"
else
    echo "❌ MCP endpoint is not accessible"
fi
EOF

chmod +x monitor-mcp-usage.sh
```

### 2. Performance Metrics

Track tool performance:

```bash
# Function execution metrics
az monitor metrics list \
  --resource "/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/$FUNCTION_APP" \
  --metric "FunctionExecutionCount" \
  --interval PT1H
```

### 3. Error Analysis

Monitor and analyze errors:

```bash
# Check for errors in the last 24 hours
az functionapp logs tail --name $FUNCTION_APP --resource-group $RESOURCE_GROUP | grep -i error

# Or create an error monitoring script
cat > check-mcp-errors.sh << 'EOF'
#!/bin/bash
echo "Checking MCP Server Errors..."
echo "============================="

# Check Azure Function errors
echo "Azure Function Errors:"
az functionapp logs tail --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --time-period last-24hours | grep -i error | tail -10

# Check proxy errors if log file exists
if [ -f mcp-proxy.log ]; then
    echo "Proxy Errors:"
    grep -i error mcp-proxy.log | tail -5
fi
EOF

chmod +x check-mcp-errors.sh
```

## Automation Scripts

Create helpful automation scripts for daily workflow:

```bash
# Create an all-in-one MCP management script
cat > mcp-manager.sh << 'EOF'
#!/bin/bash

function start_proxy() {
    if ! pgrep -f "mcp-proxy.js" > /dev/null; then
        export MCP_TARGET_URL="$FUNCTION_URL"
        nohup node mcp-proxy.js > mcp-proxy.log 2>&1 &
        echo "✅ MCP Proxy started (PID: $!)"
    else
        echo "ℹ️  MCP Proxy already running"
    fi
}

function stop_proxy() {
    if pgrep -f "mcp-proxy.js" > /dev/null; then
        pkill -f "mcp-proxy.js"
        echo "✅ MCP Proxy stopped"
    else
        echo "ℹ️  MCP Proxy not running"
    fi
}

function test_mcp() {
    echo "Testing MCP endpoint..."
    if curl -s "$FUNCTION_URL" | jq -e '.status' > /dev/null; then
        echo "✅ MCP endpoint is working"
    else
        echo "❌ MCP endpoint test failed"
    fi
}

function show_status() {
    echo "MCP Server Status"
    echo "================="
    echo "Function URL: $FUNCTION_URL"
    echo "Function App: $FUNCTION_APP"
    echo "Resource Group: $RESOURCE_GROUP"
    
    if pgrep -f "mcp-proxy.js" > /dev/null; then
        echo "Proxy Status: ✅ Running (PID: $(pgrep -f 'mcp-proxy.js'))"
    else
        echo "Proxy Status: ❌ Not running"
    fi
}

case "$1" in
    start)
        start_proxy
        ;;
    stop)
        stop_proxy
        ;;
    restart)
        stop_proxy
        sleep 2
        start_proxy
        ;;
    test)
        test_mcp
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|test|status}"
        exit 1
        ;;
esac
EOF

chmod +x mcp-manager.sh

# Usage examples:
# ./mcp-manager.sh start
# ./mcp-manager.sh status
# ./mcp-manager.sh test
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