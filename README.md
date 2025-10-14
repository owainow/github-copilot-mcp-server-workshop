# GitHub Copilot Custom MCP Server with Azure Functions Workshop

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/owainow/github-copilot-mcp-server-workshop)
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fyour-repo%2Fserverless-mcp-on-functions%2Fmain%2Finfra%2Fmain.json)

## 🚀 Overview

Welcome to this comprehensive workshop where you'll learn to extend GitHub Copilot's capabilities by building and deploying a custom Model Context Protocol (MCP) server on Azure Functions. This workshop demonstrates the complete journey from local development to production AI integration.

### What You'll Build

- **Custom MCP Server**: A serverless MCP server with three types of tools
- **Educational Tools**: Markdown review and dependency checking with local algorithms
- **Production AI Tool**: Azure AI-powered code review demonstrating true MCP architecture
- **Azure Functions Deployment**: Scalable, serverless hosting for your MCP server
- **GitHub Copilot Integration**: Seamless connection between Copilot and your custom tools

### Learning Outcomes

By the end of this workshop, you'll understand:
- ✅ The difference between educational and production MCP tools
- ✅ How to build and deploy serverless MCP servers on Azure Functions
- ✅ True MCP architecture: tools provide context, AI provides intelligence
- ✅ GitHub Copilot integration patterns and best practices
- ✅ Azure AI Foundry integration with graceful fallback patterns

## ⚡ Quick Start Options

### 🌟 **Option 1: GitHub Codespaces (Recommended - Zero Setup)**
Click the **"Open in GitHub Codespaces"** badge above for instant setup!
- ✅ **No local installation required**
- ✅ **Pre-configured Linux environment with all tools**
- ✅ **Works on any device with a browser**
- ✅ **Ready in 2-3 minutes**
- 📖 **Follow the [Linux/Bash Documentation Path](docs/linux/)**

### 💻 **Option 2: Local Development**
Choose your platform for local development:

#### 🪟 **Windows (PowerShell)**
- 📖 **[Windows Workshop Documentation](docs/windows/)** - Complete Windows setup with PowerShell commands
- 🛠️ **Requirements**: Node.js, Azure CLI, Azure Functions Core Tools, VS Code
- 💡 **Best for**: Windows developers, PowerShell users, local development preference

#### 🐧 **Linux/macOS (Bash)**  
- 📖 **[Linux Workshop Documentation](docs/linux/)** - Complete Linux setup with Bash commands
- 🛠️ **Requirements**: Node.js, Azure CLI, Azure Functions Core Tools, VS Code
- 💡 **Best for**: Linux/macOS developers, Bash users, script automation

---

## 📚 Choose Your Workshop Path

| Platform | Quick Start | Documentation | Best For |
|----------|-------------|---------------|----------|
| **🌟 Codespaces** | [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/owainow/github-copilot-mcp-server-workshop) | [📖 Linux/Bash Docs](docs/linux/) | Zero setup, any device |
| **🪟 Windows** | [Setup Guide](docs/windows/setup.md) | [📖 Windows/PowerShell Docs](docs/windows/) | Windows developers |
| **🐧 Linux/macOS** | [Setup Guide](docs/linux/setup.md) | [📖 Linux/Bash Docs](docs/linux/) | Linux/macOS developers |

## 🛠️ Prerequisites

### Required Software
- [Node.js](https://nodejs.org/) (v18 or later)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- [GitHub Copilot](https://github.com/features/copilot) subscription
- [VS Code](https://code.visualstudio.com/) with Copilot extension

### Azure Account
- Azure subscription (free tier works!)
- Contributor access to create resources

### Knowledge Level
- Intermediate JavaScript/TypeScript
- Basic Azure Functions knowledge
- Familiarity with GitHub Copilot

## 📋 Workshop Flow (3 Hours Total)

*Choose your platform path above, then follow these sequential steps:*

### [Part 1: Setup and Understanding](docs/{platform}/part-1-setup-and-understanding.md) (30 minutes)
1. Understanding MCP and Architecture Patterns
2. Environment Setup and Prerequisites  
3. Project Structure and Dependencies

### [Part 2: Local Development](docs/{platform}/part-2-local-development.md) (45 minutes)
1. Building the MCP Server Core
2. Creating Educational Tools (markdown review, dependency check)
3. Implementing Production AI Tool Architecture
4. Testing Locally with Azure Functions

### [Part 3: Azure Deployment](docs/{platform}/part-3-azure-deployment.md) (30 minutes)
1. Infrastructure as Code with Bicep
2. Deploying to Azure Functions
3. Monitoring and Troubleshooting

### [Part 4: GitHub Copilot Integration](docs/{platform}/part-4-copilot-integration.md) (30 minutes)
1. Configuring MCP in VS Code
2. Testing Tool Discovery and Usage
3. Advanced Integration Patterns

### [Part 5: AI Integration](docs/{platform}/part-5-ai-integration.md) (45 minutes) 🤖
1. Setting Up Azure AI Foundry Free Tier
2. Implementing Real AI Analysis
3. Comparing Educational vs Production Tools
4. Understanding True MCP Architecture

## 🚀 Quick Start Examples

### GitHub Codespaces (Linux/Bash)
```bash
# Automatically configured - just open and run:
npm install && npm run build
func start --port 7071
./test-workshop.sh
```

### Windows (PowerShell)
```powershell
# Clone and setup
git clone <your-repo-url>
cd serverless_mcp_on_functions_for_github_copilot
npm install ; npm run build
func start --port 7071
.\test-workshop.ps1 -TestLevel local
```

### Linux/macOS (Bash)
```bash
# Clone and setup
git clone <your-repo-url>
cd serverless_mcp_on_functions_for_github_copilot
npm install && npm run build
func start --port 7071
./test-workshop.sh --level local
```

### 3. Deploy to Azure

#### Windows (PowerShell)
```powershell
az login
az group create --name mcp-workshop-rg --location eastus
az deployment group create --resource-group mcp-workshop-rg --template-file infra/main.bicep
func azure functionapp publish mcp-workshop-func --typescript
```

#### Linux/Bash (including Codespaces)
```bash
az login
az group create --name mcp-workshop-rg --location eastus
az deployment group create --resource-group mcp-workshop-rg --template-file infra/main.bicep
func azure functionapp publish mcp-workshop-func --typescript
```

### 4. Add AI Integration (Optional)
Follow **Part 5** of the workshop documentation in `docs/part-5-ai-integration.md` to set up Azure AI Foundry integration through the portal.

### 5. Connect to GitHub Copilot
Add to VS Code settings.json:
```json
{
  "github.copilot.chat.mcp.servers": {
    "mcp-workshop": {
      "endpoint": "https://your-function-app.azurewebsites.net/api/mcp-server"
    }
  }
}
```

## 🏗️ Architecture Overview

```mermaid
graph LR
    A[GitHub Copilot] -->|MCP Protocol| B[Azure Functions]
    B --> C[Markdown Tool - Educational]
    B --> D[Dependency Tool - Educational]
    B --> E[AI Code Review - Production]
    
    E -->|API Calls| F[Azure AI Foundry]
    B --> G[Azure Monitor]
    B --> H[Azure Key Vault]
    B --> I[Azure Storage]
```

### Tool Categories

This workshop demonstrates **three distinct tool patterns**:

#### 🎓 Educational Tools
- **`markdown_review`**: Local analysis algorithms, quality scoring
- **`dependency_check`**: Static package analysis, security checks
- **Purpose**: Learn MCP concepts, no external dependencies

#### 🚀 Production Tools  
- **`ai_code_review`**: Azure AI integration with intelligent analysis
- **Purpose**: Demonstrate true MCP architecture (tools provide context, AI provides intelligence)
- **Features**: Real LLM analysis, graceful fallback to mock analysis

#### 🔄 Hybrid Approach
All tools work **without Azure costs** through intelligent fallback patterns, making the workshop accessible to everyone while demonstrating production capabilities.

# Set your subscription (if you have multiple)
az account set --subscription "your-subscription-id"
```

## 📁 Project Structure

```
├── docs/                           # Workshop documentation
│   ├── windows/                    # Windows/PowerShell path
│   │   ├── part-1-setup-and-understanding.md
│   │   ├── part-2-local-development.md
│   │   ├── part-3-azure-deployment.md
│   │   ├── part-4-copilot-integration.md
│   │   └── part-5-ai-integration.md
│   └── linux/                      # Linux/Bash path (& Codespaces)
│       ├── part-1-setup-and-understanding.md
│       ├── part-2-local-development.md
│       ├── part-3-azure-deployment.md
│       ├── part-4-copilot-integration.md
│       └── part-5-ai-integration.md
├── src/                            # MCP server source code
│   ├── functions/mcp-server.ts     # Azure Functions HTTP trigger
│   ├── mcp/server.ts              # MCP protocol implementation
│   ├── tools/                     # Custom MCP tools
│   │   ├── markdown-review.ts     # Educational: Local analysis
│   │   ├── dependency-check.ts    # Educational: Package analysis  
│   │   └── ai-code-review.ts      # Production: Azure AI integration
│   └── utils/                     # Shared utilities
├── infra/                         # Azure infrastructure (Bicep)
├── tests/                         # Test suites
├── test-workshop.ps1              # Comprehensive workshop test script
├── test-ai-integration.ps1        # AI integration tests
└── test-all-tools.ps1             # Individual tool testing
```

## 🧪 Testing Your Setup

### Windows (PowerShell)
```powershell
# Test local development
.\test-workshop.ps1 -TestLevel local

# Test Azure deployment  
.\test-workshop.ps1 -TestLevel azure -FunctionUrl "https://your-app.azurewebsites.net/api/mcp-server"

# Test AI integration
.\test-ai-integration.ps1
```

### Linux/Bash (including Codespaces)
```bash
# Test local development
./test-workshop.sh --level local

# Test Azure deployment  
./test-workshop.sh --level azure --url "https://your-app.azurewebsites.net/api/mcp-server"

# Test AI integration
./test-ai-integration.sh
```

## 🎯 Key Learning Outcomes

### Technical Skills
- ✅ MCP protocol implementation with JSON-RPC 2.0
- ✅ Azure Functions serverless development
- ✅ TypeScript development with Azure tooling
- ✅ Infrastructure as Code with Bicep
- ✅ Azure AI service integration

### Architectural Understanding  
- ✅ Educational vs Production MCP tool patterns
- ✅ Graceful degradation and fallback strategies
- ✅ True MCP architecture: tools provide context, AI provides intelligence
- ✅ Serverless cost optimization strategies
- ✅ Security considerations for production MCP servers

### GitHub Copilot Integration
- ✅ MCP server configuration in VS Code
- ✅ Tool discovery and usage patterns
- ✅ Advanced integration scenarios
- ✅ Troubleshooting and monitoring

## 🏁 Workshop Navigation

### 🌟 **Codespaces Users (Recommended)**
**Start Here**: [Part 1: Setup and Understanding](docs/linux/part-1-setup-and-understanding.md)

### 🪟 **Windows Users**  
**Start Here**: [Part 1: Setup and Understanding](docs/windows/part-1-setup-and-understanding.md)

### 🐧 **Linux/macOS Users**
**Start Here**: [Part 1: Setup and Understanding](docs/linux/part-1-setup-and-understanding.md)

---

**Need AI Integration Fast?** See platform-specific quick setup:
- 🪟 [Windows AI Quickstart](docs/windows/quickstart-ai.md)
- 🐧 [Linux AI Quickstart](docs/linux/quickstart-ai.md)

## 🌟 What Makes This Workshop Special

1. **Progressive Complexity**: From simple local tools to production AI integration
2. **Cost Conscious**: Free tier options with graceful fallbacks
3. **Real-World Ready**: Production patterns with security considerations  
4. **Complete Coverage**: Local development → Azure deployment → Copilot integration → AI enhancement
5. **Hands-On Testing**: Comprehensive test scripts for every stage

## 🤝 Support and Contributing

- **Issues**: Found a bug? [Open an issue](https://github.com/your-repo/issues)
- **Discussions**: Questions? [Start a discussion](https://github.com/your-repo/discussions) 
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

🚀 **Ready to extend GitHub Copilot with custom tools?** Start with [Part 1: Setup and Understanding](docs/part-1-understanding-mcp-and-setup.md)!
