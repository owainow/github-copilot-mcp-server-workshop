# Part 2: Local Development & Building MCP Server (Linux/Codespaces)

> **Workshop Navigation**: [← Part 1: Understanding MCP](part-1-setup-and-understanding.md) | [Part 3: Azure Deployment →](part-3-azure-deployment.md) | **Platform**: 🐧 Linux/Bash & 🌟 Codespaces

## 🎯 Objective

Build and test the MCP server locally with three custom tools, understanding the difference between educational and production MCP patterns.

---

## ✅ Prerequisites Verification

Before we begin, let's verify that you have all the required tools installed using Bash:

### 1. Node.js Version Check

```bash
node --version
# Should show v18.x.x or later
```

### 🌟 **Codespaces Users**: Tools are pre-installed!
If you're using Codespaces, all tools are already configured. You can skip to the Project Setup section.

### 🐧 **Local Linux/macOS Users**: Install if needed

If you need to install or update Node.js:
```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# macOS with Homebrew
brew install node@18

# Verify installation
node --version
npm --version
```

### 2. Azure CLI Authentication

```bash
# Check if Azure CLI is installed
az --version

# Login to Azure (this will open a browser)
az login

# Verify you're logged in
az account show
```

### 3. Azure Functions Core Tools

```bash
# Check if Functions Core Tools are installed
func --version
# Should show 4.x.x or later

# If not installed, install globally
npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

### 4. VS Code Extensions

Ensure you have these VS Code extensions installed:
- **Azure Functions** (ms-azuretools.vscode-azurefunctions)
- **GitHub Copilot** (GitHub.copilot)
- **Azure Account** (ms-vscode.azure-account)

---

## 🛠️ Project Setup (Linux/Codespaces)

### 🌟 **Codespaces Users**

You're already in the project directory! Just verify and install dependencies:

```bash
# Check you're in the right place
pwd
# Should show: /workspaces/github-copilot-mcp-server-workshop

# Install dependencies and build
npm install && npm run build

# Copy environment configuration
cp local.settings.json.example local.settings.json
```

### 🐧 **Local Linux/macOS Users**

```bash
# Navigate to the project directory
cd serverless_mcp_on_functions_for_github_copilot

# Install dependencies
npm install

# Copy environment configuration
cp local.settings.json.example local.settings.json
```


---

## 🏗️ Understanding the MCP Implementation

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

  async handleRequest(request: HttpRequest): Promise<HttpResponseInit> {
    try {
      const body = await request.json();
      
      switch (body.method) {
        case 'tools/list':
          return this.listTools();
        case 'tools/call':
          return this.callTool(body.params);
        default:
          return this.methodNotFound(body.method);
      }
    } catch (error) {
      return this.internalError(error);
    }
  }
}
```

### 2. Azure Functions Wrapper (`src/functions/mcp-server.ts`)

```typescript
import { app, HttpRequest, HttpResponseInit } from '@azure/functions';
import { MCPServer } from '../mcp/server';

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

---

## 🔧 Building the Tools

Our three tools demonstrate different MCP patterns:

### Educational Tool 1: Markdown Review

This tool analyzes markdown content locally using algorithms:

```typescript
export class MarkdownReviewTool implements MCPTool {
  name = 'markdown_review';
  description = 'Analyzes markdown content for structure, links, and quality';

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
          recommendations,
          analysis_type,
          word_count: content.split(/\s+/).length
        })
      }]
    };
  }

  private findIssues(content: string): string[] {
    const issues = [];
    
    // Check for broken internal links
    const internalLinks = content.match(/\[.*?\]\([^http][^)]*\)/g) || [];
    if (internalLinks.length > 0) {
      issues.push(`Found ${internalLinks.length} internal link(s) that should be validated`);
    }
    
    // Check for missing alt text in images
    const imagesWithoutAlt = content.match(/!\[\s*\]/g) || [];
    if (imagesWithoutAlt.length > 0) {
      issues.push(`Found ${imagesWithoutAlt.length} image(s) missing alt text`);
    }
    
    // Check for very long lines (>100 chars)
    const lines = content.split('\n');
    const longLines = lines.filter(line => line.length > 100);
    if (longLines.length > 0) {
      issues.push(`Found ${longLines.length} lines longer than 100 characters`);
    }
    
    return issues;
  }
}
```

### Educational Tool 2: Dependency Check

This tool analyzes package.json for security and updates:

```typescript
export class DependencyCheckTool implements MCPTool {
  name = 'dependency_check';
  description = 'Analyzes npm dependencies for security and update recommendations';

  async call(args: any): Promise<ToolResult> {
    const { package_json, check_type = 'comprehensive' } = args;
    
    try {
      const packageData = JSON.parse(package_json);
      const analysis = this.analyzePackages(packageData);
      
      return {
        content: [{
          type: "text", 
          text: JSON.stringify(analysis)
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: "text",
          text: JSON.stringify({
            error: "Invalid package.json format",
            message: error.message
          })
        }],
        isError: true
      };
    }
  }

  private analyzePackages(packageData: any) {
    const dependencies = packageData.dependencies || {};
    const devDependencies = packageData.devDependencies || {};
    const allDeps = { ...dependencies, ...devDependencies };
    
    const knownVulnerablePackages = [
      'lodash', 'moment', 'request', 'bower'
    ];
    
    const outdatedPatterns = ['^0.', '^1.', '^2.'];
    
    const vulnerablePackages = Object.keys(allDeps).filter(pkg => 
      knownVulnerablePackages.includes(pkg.toLowerCase())
    );
    
    const potentiallyOutdated = Object.entries(allDeps).filter(([pkg, version]) =>
      outdatedPatterns.some(pattern => String(version).startsWith(pattern))
    );
    
    return {
      total_dependencies: Object.keys(allDeps).length,
      potentially_vulnerable: vulnerablePackages,
      potentially_outdated: potentiallyOutdated.map(([pkg, version]) => ({
        package: pkg,
        current_version: version
      })),
      recommendations: this.generateRecommendations(vulnerablePackages, potentiallyOutdated)
    };
  }
}
```

### Production Tool: AI Code Review

This tool integrates with Azure AI for intelligent analysis:

```typescript
export class AiCodeReviewTool implements MCPTool {
  name = 'ai_code_review';
  description = 'AI-powered code analysis using Azure OpenAI';

  async call(args: any): Promise<ToolResult> {
    const { code, language = 'typescript', review_type = 'comprehensive' } = args;
    
    // Check if AI integration is enabled
    if (process.env.ENABLE_AI_TOOL === 'false') {
      return this.getMockResponse(code, language, review_type);
    }
    
    try {
      // In a real implementation, this would call Azure OpenAI
      const analysis = await this.performAIAnalysis(code, language, review_type);
      return {
        content: [{
          type: "text",
          text: JSON.stringify(analysis)
        }]
      };
    } catch (error) {
      // Graceful fallback to mock analysis
      return this.getMockResponse(code, language, review_type);
    }
  }
  
  private getMockResponse(code: string, language: string, reviewType: string) {
    return {
      content: [{
        type: "text",
        text: JSON.stringify({
          analysis_type: "mock_ai_analysis",
          language,
          review_type: reviewType,
          code_quality_score: 85,
          issues: [
            "Consider adding more descriptive variable names",
            "Function complexity could be reduced by breaking into smaller functions"
          ],
          suggestions: [
            "Add TypeScript type annotations for better type safety",
            "Consider using async/await for better readability"
          ],
          security_concerns: [],
          performance_notes: [
            "Code appears to have good performance characteristics"
          ]
        })
      }]
    };
  }
}
```

---

## 🚀 Building and Testing (Linux/Codespaces)

### 1. Build the Project

```bash
# Compile TypeScript to JavaScript
npm run build

# Verify build output exists
ls -la dist/
# Should show index.js and other compiled files
```

### 2. Start the Local Development Server

```bash
# Start Azure Functions locally
func start --port 7071

# Keep this terminal open - you should see:
# Azure Functions Core Tools
# Core Tools Version: 4.x.x
# Functions:
#   mcp-server: [POST,GET] http://localhost:7071/api/mcp-server
```

## 🧪 Quick Testing with Automated Script

We've included a comprehensive test script to verify all functionality:

```bash
# Make the test script executable
chmod +x test-local-functions.sh

# Run all local tests
./test-local-functions.sh
```

This script will test:
- ✅ **Tool Discovery**: Verify all tools are registered
- ✅ **Markdown Review**: Test content analysis functionality  
- ✅ **Dependency Check**: Test package.json analysis
- ✅ **AI Code Review**: Test mock AI analysis mode
- ✅ **Error Handling**: Verify graceful error responses

Expected output:
```
🧪 Testing MCP Server Local Development
======================================

✅ MCP server is running

Testing: Tool Discovery
✅ PASSED: Tool Discovery

Testing: Markdown Review Tool
✅ PASSED: Markdown Review Tool

Testing: Dependency Check Tool
✅ PASSED: Dependency Check Tool

Testing: AI Code Review Tool (Mock)
✅ PASSED: AI Code Review Tool (Mock)

🎉 All local development tests completed!
```

### 3. Manual Testing (Alternative)

If you prefer to test manually, you can run individual curl commands:

#### Test Tool Discovery

In a new terminal window (to not stop the local running function):

```bash
curl -X POST http://localhost:7071/api/mcp-server \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
  }'
```

Expected response:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [
      {
        "name": "markdown_review",
        "description": "Analyzes markdown content for structure, links, and quality"
      },
      {
        "name": "dependency_check", 
        "description": "Analyzes npm dependencies for security and update recommendations"
      },
      {
        "name": "ai_code_review",
        "description": "AI-powered code analysis using Azure OpenAI"
      }
    ]
  }
}
```

#### Test Markdown Review Tool

```bash
curl -X POST http://localhost:7071/api/mcp-server \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "markdown_review",
      "arguments": {
        "content": "# Test\n\nThis is a [broken link](nonexistent.md) and an image ![](test.jpg)."
      }
    }
  }'
```

#### Test Dependency Check Tool

```bash
curl -X POST http://localhost:7071/api/mcp-server \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0", 
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "dependency_check",
      "arguments": {
        "package_json": "{\"dependencies\":{\"lodash\":\"^3.10.1\",\"express\":\"^4.18.2\"}}"
      }
    }
  }'
```

---

## 🔍 Understanding Tool Patterns

### Educational vs Production Tools

| Aspect | Educational Tools | Production Tools |
|--------|------------------|------------------|
| **Data Source** | Local algorithms | External APIs/AI |
| **Dependencies** | None | Azure AI, databases |
| **Reliability** | 100% available | Depends on external services |
| **Intelligence** | Rule-based | AI-powered analysis |
| **Use Case** | Learning MCP | Real-world applications |

### MCP Protocol Flow

```mermaid
sequenceDiagram
    participant C as GitHub Copilot
    participant M as MCP Server
    participant T as Tool

    C->>M: tools/list
    M->>C: Available tools
    
    C->>M: tools/call (markdown_review)
    M->>T: Execute analysis
    T->>M: Analysis results
    M->>C: Formatted response
    
    Note over C,M: Copilot processes results and<br/>provides intelligent recommendations
```

---

## ✅ Verification Checklist

- [ ] All dependencies installed successfully
- [ ] Project builds without errors (`npm run build`)
- [ ] Local Azure Functions server starts (`func start`)
- [ ] MCP endpoints respond to HTTP requests
- [ ] All three tools return expected results
- [ ] **Automated tests pass** (`./test-local-functions.sh`)

---

## 🎉 Ready for Azure Deployment!

Your MCP server is now working locally with three custom tools. You've learned:

- ✅ **MCP protocol implementation** with JSON-RPC 2.0
- ✅ **Tool pattern differences** (educational vs production)
- ✅ **Local testing strategies** for MCP servers
- ✅ **Azure Functions integration** for serverless hosting

---

> **Next Step**: Continue to [Part 3: Azure Deployment →](part-3-azure-deployment.md) where we'll deploy your MCP server to Azure Functions for global access using bash and Azure CLI.

---

## 🐛 Troubleshooting (Linux/Codespaces)

### Common Issues

**Functions won't start:**
```bash
# Clear npm cache and reinstall
npm cache clean --force
npm install && npm run build
```

**Port already in use:**
```bash
# Use different port
func start --port 7072

# Or find what's using the port
lsof -i :7071
```

**TypeScript compilation errors:**
```bash
# Check Node.js version
node --version
# Ensure you have Node.js 18+

# Clear build cache
rm -rf dist/
npm run build
```

**Permission issues (local Linux):**
```bash
# Fix npm permissions
sudo chown -R $(whoami) ~/.npm
sudo chown -R $(whoami) /usr/local/lib/node_modules
```

### 🌟 **Codespaces-Specific Issues**

**Environment not ready:**
```bash
# Run setup script
./.devcontainer/setup-workshop.sh

# Restart VS Code if needed
# Use Command Palette: "Codespaces: Reload Window"
```

**Port forwarding issues:**
```bash
# Check port forwarding
curl http://localhost:7071/api/mcp-server

# If issues, restart the function
Ctrl+C
func start --port 7071
```

---

## 📚 Additional Resources

- [Azure Functions Local Development](https://docs.microsoft.com/azure/azure-functions/functions-develop-local)
- [MCP Protocol Specification](https://modelcontextprotocol.io/specification/)
- [TypeScript Azure Functions Guide](https://docs.microsoft.com/azure/azure-functions/functions-reference-node)
- [GitHub Codespaces Documentation](https://docs.github.com/en/codespaces)
- [Linux Azure Functions Development](https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-azure-function-azure-cli?tabs=bash%2Cbrowser&pivots=programming-language-typescript)