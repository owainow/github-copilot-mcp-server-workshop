# Linux Workshop Path 🐧 & Codespaces 🌟

> **Platform**: Linux/macOS with Bash + GitHub Codespaces | **Total Time**: ~3 hours

## 📋 Workshop Sequence

Follow these parts in order for the complete Linux/Codespaces experience:

### [Part 1: Setup and Understanding](part-1-setup-and-understanding.md) ⏱️ 30 min
- Understanding MCP and Architecture Patterns
- Linux/Codespaces environment setup with Bash
- Project structure and dependencies
- Bash test scripts validation

### [Part 2: Local Development](part-2-local-development.md) ⏱️ 45 min
- Building the MCP Server Core
- Creating Educational Tools (markdown review, dependency check)
- Implementing Production AI Tool Architecture
- Testing locally with Azure Functions on Linux

### [Part 3: Azure Deployment](part-3-azure-deployment.md) ⏱️ 30 min
- Infrastructure as Code with Bicep
- Deploying to Azure Functions using Bash
- Monitoring and troubleshooting with Azure CLI

### [Part 4: GitHub Copilot Integration](part-4-copilot-integration.md) ⏱️ 30 min
- Configuring MCP in VS Code on Linux/Codespaces
- Testing tool discovery and usage
- Advanced integration patterns

### [Part 5: AI Integration](part-5-ai-integration.md) ⏱️ 45 min 🤖
- Setting up Azure AI Foundry Free Tier
- Implementing real AI analysis
- Comparing educational vs production tools
- Understanding true MCP architecture

## 🌟 Codespaces vs Local Linux

### 🌟 **GitHub Codespaces (Recommended)**
- ✅ **Zero setup required** - everything pre-configured
- ✅ **Consistent environment** - same for all users
- ✅ **Cloud-powered** - fast and reliable
- ✅ **Any device** - works on tablets, Chromebooks, etc.

### 🐧 **Local Linux/macOS**
- ✅ **Full control** - customize your environment
- ✅ **Offline capable** - work without internet
- ✅ **Performance** - native hardware performance
- ✅ **Privacy** - everything stays local

## 🛠️ Linux-Specific Features

### Bash Commands
All commands are optimized for Bash shell:
```bash
# Install and setup
npm install && npm run build
func start --port 7071

# Testing
./test-workshop.sh --level local
./test-all-tools.sh
./test-ai-integration.sh

# Azure deployment
az login
az group create --name mcp-workshop-rg --location eastus
az deployment group create --resource-group mcp-workshop-rg --template-file infra/main.bicep
```

### Linux Environment
- **File paths**: Uses Unix-style paths (forward slashes)
- **Environment variables**: Bash variable syntax
- **Scripts**: Bash (.sh) test and deployment scripts
- **Package management**: Works with apt, yum, brew, etc.
- **VS Code**: Linux/Codespaces-specific configuration

## 🚀 Quick Start

### 🌟 **Codespaces** (Click badge in main README)
```bash
# You're already set up! Just run:
npm install && npm run build
./test-workshop.sh --level local
func start --port 7071
```

### 🐧 **Local Linux/macOS**
```bash
# Clone and setup
git clone <your-repo-url>
cd serverless_mcp_on_functions_for_github_copilot

# Install and build
npm install && npm run build

# Test environment
./test-workshop.sh --level local

# Start local development
func start --port 7071
```

## 🔧 Codespaces-Specific Tools

When using Codespaces, you have additional tools:

```bash
# Test Codespaces environment
./.devcontainer/test-environment.sh

# Setup workshop tools (if needed)
./.devcontainer/setup-workshop.sh

# Check port forwarding
curl http://localhost:7071/api/mcp-server
```

## 📚 Linux/Codespaces Resources

- [Bash Scripting Guide](https://tldp.org/LDP/abs/html/)
- [Azure CLI for Linux](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux)
- [Azure Functions on Linux](https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-azure-function-azure-cli?tabs=bash%2Cbrowser&pivots=programming-language-typescript)
- [GitHub Codespaces Documentation](https://docs.github.com/en/codespaces)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)

---

## 🏁 Ready to Start?

### 🌟 **Codespaces Users**
Click the Codespaces badge in the main README, then start with [Part 1: Setup and Understanding](part-1-setup-and-understanding.md)

### 🐧 **Local Linux/macOS Users**  
**Begin with**: [Part 1: Setup and Understanding](part-1-setup-and-understanding.md)

Need help? Check the [main README](../../README.md) or the [reference architecture](../reference-architecture-patterns.md).