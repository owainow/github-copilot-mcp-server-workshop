# Part 2: Local Development

## Objective

Build and test the MCP server locally with three custom tools, understanding the difference between educational and production MCP patterns.

## Understanding the MCP Implementation

Let's examine the core components of our MCP server:

### 1. MCP Server Core (`src/mcp/server.ts`)

```typescript
export class MCPServer {
  private tools: Map<string, MCPTool> = new Map();

  constructor() {
    this.registerTools();
  }

  private registerTools() {
    // Educational tools - always available
    this.tools.set('markdown_review', new MarkdownReviewTool());
    this.tools.set('dependency_check', new DependencyCheckTool());
    
    // Production tool - configurable
    if (process.env.ENABLE_AI_TOOL !== 'false') {
      this.tools.set('ai_code_review', new AiCodeReviewTool());
    }
  }
}
```

### 2. Azure Functions Wrapper (`src/functions/mcp-server.ts`)

```typescript
import { app, HttpRequest, HttpResponseInit } from '@azure/functions';

app.http('mcp-server', {
  methods: ['GET', 'POST'],
  authLevel: 'anonymous',
  handler: async (request: HttpRequest): Promise<HttpResponseInit> => {
    // Handle MCP protocol requests
    const server = new MCPServer();
    return await server.handleRequest(request);
  }
});
```

## Building the Tools

Our three tools demonstrate different MCP patterns:

### Educational Tool 1: Markdown Review

This tool analyzes markdown content locally using algorithms:

```typescript
export class MarkdownReviewTool implements MCPTool {
  async call(args: any): Promise<ToolResult> {
    const { content, analysis_type = 'comprehensive' } = args;
    
    // Local analysis algorithms
    const issues = this.findIssues(content);
    const recommendations = this.generateRecommendations(content);
    const qualityScore = this.calculateQualityScore(content, issues);
    
    return {
      content: [{
        type: "text",
        text: JSON.stringify({
          quality_score: qualityScore,
          issues,
          recommendations
        })
      }]
    };
  }
}
```

### Educational Tool 2: Dependency Check

This tool analyzes package.json for security and updates:

```typescript
export class DependencyCheckTool implements MCPTool {
  async call(args: any): Promise<ToolResult> {
    const { package_json, check_type = 'comprehensive' } = args;
    
    const packageData = JSON.parse(package_json);
    const analysis = this.analyzePackages(packageData);
    
    return {
      content: [{
        type: "text", 
        text: JSON.stringify(analysis)
      }]
    };
  }
}
```

### Production Tool: AI Code Review

This tool demonstrates true MCP architecture - it provides context to AI:

```typescript
export class AiCodeReviewTool implements MCPTool {
  async call(args: any): Promise<ToolResult> {
    const { code, language, review_type } = args;
    
    // Check if Azure AI is configured
    if (!process.env.AZURE_AI_ENDPOINT) {
      return this.getMockAnalysis(code, language);
    }
    
    // Provide context to AI for analysis
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
  }
}
```

## Testing Locally

### 1. Start the Function App

```bash
# Start Azure Functions locally
func start --port 7071
```

You should see output similar to:
```
Azure Functions Core Tools
Core Tools Version: 4.x.x
Function Runtime Version: 4.x.x

Functions:
  mcp-server: [GET,POST] http://localhost:7071/api/mcp-server
```

### 2. Test MCP Protocol

```bash
# Test the ping endpoint
curl -X POST http://localhost:7071/api/mcp-server \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"ping"}'

# Expected response:
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "status": "ok",
    "server": "GitHub Copilot MCP Server",
    "version": "1.0.0"
  }
}
```

### 3. Test Tool Discovery

```bash
# List available tools
curl -X POST http://localhost:7071/api/mcp-server \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
```

### 4. Run Comprehensive Tests

Use our test script to verify everything works:

```powershell
# Run local development tests
.\test-workshop.ps1 -TestLevel local
```

Expected output:
```
🧪 MCP Workshop Complete Test Suite
====================================
Test Level: local

1️⃣ Testing MCP Protocol Basics
✅ Ping successful: GitHub Copilot MCP Server
✅ Found 3 tools available
   📦 markdown_review
   📦 dependency_check  
   📦 ai_code_review

2️⃣ Testing Educational Tools
✅ Markdown review completed - Quality: 85/100
✅ Dependency check completed - 2 packages analyzed

3️⃣ Testing AI Integration
✅ AI code review completed
   Status: mock_analysis

📊 Test Results Summary
=======================
Passed: 3/3 tests

🎉 All tests passed! MCP server is working correctly.
📚 Next: Deploy to Azure and test with -TestLevel azure
```

## Understanding the Results

### Educational Tools
- **Markdown Review**: Returns quality score (0-100) based on structure, content, and best practices
- **Dependency Check**: Analyzes packages for security vulnerabilities and update recommendations
- **Local Processing**: No external API calls required

### AI Tool (Mock Mode)
- **Status**: `mock_analysis` (Azure AI not configured yet)
- **Educational Value**: Shows how the tool structure works
- **Production Ready**: Will use real AI when Azure AI is configured

## Tool Testing Examples

### Test Markdown Analysis

```powershell
$markdownTest = @{
    jsonrpc = "2.0"
    id = 1
    method = "tools/call"
    params = @{
        name = "markdown_review"
        arguments = @{
            content = @"
# My Project

This is a great project with:
- Feature 1
- Feature 2

## Installation
``bash
npm install
``

TODO: Add more docs
"@
            analysis_type = "comprehensive"
        }
    }
} | ConvertTo-Json -Depth 10

$result = Invoke-RestMethod -Uri "http://localhost:7071/api/mcp-server" -Method POST -ContentType "application/json" -Body $markdownTest
($result.result.content[0].text | ConvertFrom-Json) | Format-List
```

### Test Dependency Analysis

```powershell
$depTest = @{
    jsonrpc = "2.0"
    id = 2
    method = "tools/call"
    params = @{
        name = "dependency_check"
        arguments = @{
            package_json = '{"dependencies":{"express":"^4.18.0","lodash":"^4.17.21"}}'
            check_type = "security_and_updates"
        }
    }
} | ConvertTo-Json -Depth 10

$result = Invoke-RestMethod -Uri "http://localhost:7071/api/mcp-server" -Method POST -ContentType "application/json" -Body $depTest
($result.result.content[0].text | ConvertFrom-Json) | Format-List
```

## Troubleshooting

### Function Won't Start
```bash
# Check if port is in use
netstat -an | findstr :7071

# Try different port
func start --port 7072
```

### TypeScript Compilation Errors
```bash
# Clean and rebuild
npm run clean
npm run build
```

### Tool Not Found
- Check that all tools are registered in `MCPServer` constructor
- Verify tool classes implement the `MCPTool` interface
- Ensure TypeScript compilation succeeded

## Key Learning Points

1. **MCP Protocol**: JSON-RPC 2.0 based with standard methods (`ping`, `tools/list`, `tools/call`)
2. **Tool Architecture**: Each tool is a self-contained class with defined input/output schemas
3. **Educational vs Production**: Local algorithms vs AI integration patterns
4. **Error Handling**: Graceful degradation and fallback mechanisms

## Next Steps

Your MCP server is working locally! Next, let's deploy it to Azure in [Part 3: Azure Deployment](part-3-azure-deployment.md).

## Workshop Progress

✅ **Part 1**: Setup and Understanding  
✅ **Part 2**: Local Development ← **You are here**  
⏭️ **Part 3**: Azure Deployment  
⏭️ **Part 4**: GitHub Copilot Integration  
⏭️ **Part 5**: AI Integration
