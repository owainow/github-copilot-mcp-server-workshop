# Windows Workshop Path 🪟

> **Platform**: Windows with PowerShell | **Total Time**: ~3 hours

## 📋 Workshop Sequence

Follow these parts in order for the complete Windows experience:

### [Part 1: Setup and Understanding](part-1-setup-and-understanding.md) ⏱️ 30 min
- Understanding MCP and Architecture Patterns
- Windows environment setup with PowerShell
- Project structure and dependencies
- PowerShell test scripts validation

### [Part 2: Local Development](part-2-local-development.md) ⏱️ 45 min
- Building the MCP Server Core
- Creating Educational Tools (markdown review, dependency check)
- Implementing Production AI Tool Architecture
- Testing locally with Azure Functions on Windows

### [Part 3: Azure Deployment](part-3-azure-deployment.md) ⏱️ 30 min
- Infrastructure as Code with Bicep
- Deploying to Azure Functions using PowerShell
- Monitoring and troubleshooting with Azure CLI

### [Part 4: GitHub Copilot Integration](part-4-copilot-integration.md) ⏱️ 30 min
- Configuring MCP in VS Code on Windows
- Testing tool discovery and usage
- Advanced integration patterns

### [Part 5: AI Integration](part-5-ai-integration.md) ⏱️ 45 min 🤖
- Setting up Azure AI Foundry Free Tier
- Implementing real AI analysis
- Comparing educational vs production tools
- Understanding true MCP architecture

## 🛠️ Windows-Specific Features

### PowerShell Commands
All commands are optimized for Windows PowerShell:
```powershell
# Install and setup
npm install ; npm run build
func start --port 7071

# Testing
.\test-workshop.ps1 -TestLevel local
.\test-all-tools.ps1
.\test-ai-integration.ps1

# Azure deployment
az login
az group create --name mcp-workshop-rg --location eastus
az deployment group create --resource-group mcp-workshop-rg --template-file infra/main.bicep
```

### Windows Environment
- **File paths**: Uses Windows-style paths (backslashes)
- **Environment variables**: PowerShell variable syntax
- **Scripts**: PowerShell (.ps1) test and deployment scripts
- **Package management**: Works with Windows package managers
- **VS Code**: Windows-specific configuration tips

## 🚀 Quick Start (Windows)

```powershell
# Clone and setup
git clone <your-repo-url>
Set-Location serverless_mcp_on_functions_for_github_copilot

# Install and build
npm install ; npm run build

# Test environment
.\test-workshop.ps1 -TestLevel local

# Start local development
func start --port 7071
```

## 📚 Windows Resources

- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [Azure CLI for Windows](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows)
- [Azure Functions on Windows](https://docs.microsoft.com/en-us/azure/azure-functions/functions-develop-vs-code?tabs=csharp)
- [VS Code Windows Setup](https://code.visualstudio.com/docs/setup/windows)

---

## 🏁 Ready to Start?

**Begin with**: [Part 1: Setup and Understanding](part-1-setup-and-understanding.md)

Need help? Check the [main README](../../README.md) or the [reference architecture](../reference-architecture-patterns.md).