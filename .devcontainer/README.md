# GitHub Codespaces Setup for MCP Workshop

This directory contains the configuration for running the GitHub Copilot MCP Server Workshop in GitHub Codespaces.

## 🚀 Quick Start with Codespaces

1. **Click to Launch**: Use the "Code" button → "Codespaces" → "Create codespace on main"
2. **Automatic Setup**: Wait 2-3 minutes for environment setup
3. **Start Workshop**: Open `docs/README.md` and begin!

## 🛠️ What's Pre-configured

### **Development Tools**
- ✅ Node.js 20 (LTS)
- ✅ Azure CLI (latest)
- ✅ Azure Functions Core Tools v4
- ✅ npm and all project dependencies

### **VS Code Extensions**
- ✅ Azure Functions
- ✅ GitHub Copilot + Copilot Chat
- ✅ Azure Account
- ✅ TypeScript/JavaScript support
- ✅ ESLint for code quality

### **Environment Setup**
- ✅ Port forwarding for Azure Functions (7071, 7072)
- ✅ Template configuration files
- ✅ Build automation
- ✅ Development settings optimized

## 📋 Manual Setup Steps (After Codespace Starts)

The only thing you need to do manually:

### 1. Azure CLI Login
```bash
az login
```

### 2. Update Configuration
Edit `local.settings.json` with your Azure details:
```json
{
  "Values": {
    "AZURE_SUBSCRIPTION_ID": "your-subscription-id",
    "AZURE_FUNCTION_APP_NAME": "mcp-server-functions-yourname"
  }
}
```

### 3. Start the Workshop
Open `docs/README.md` and follow the complete workshop guide!

## 🔧 Available Commands

```bash
# Build the project
npm run build

# Start Azure Functions locally
func start

# Run tests
npm test

# Workshop-specific tests
npm run test:workshop

# Deploy to Azure (after setup)
npm run deploy
```

## 🌍 Cross-Platform Support

This Codespace works on:
- ✅ **Any browser** (Chrome, Firefox, Safari, Edge)
- ✅ **Windows, Mac, Linux** (via browser)
- ✅ **VS Code Desktop** (Remote - Containers)
- ✅ **Mobile devices** (limited functionality)

## 💰 Codespaces Usage

- **Free tier**: 120 core hours/month for personal accounts
- **This workshop**: ~3-4 hours total
- **Cost**: FREE for most users!

## 🐛 Troubleshooting

### Codespace won't start
- Check GitHub Codespaces limits
- Try creating in different region
- Contact GitHub Support

### Tools not working
- Run: `.devcontainer/setup-workshop.sh`
- Restart the Codespace
- Check terminal for error messages

### Azure CLI issues
- Ensure you're logged in: `az login`
- Check subscription: `az account show`
- Verify permissions for resource creation

## 🎯 Workshop Benefits in Codespaces

- ✅ **No local setup required**
- ✅ **Consistent environment for all participants**
- ✅ **Works on any device with browser**
- ✅ **Pre-configured tools and extensions**
- ✅ **Fast workshop startup (2 minutes vs 30+ minutes)**
- ✅ **Perfect for corporate environments**

---

**Ready to start?** Open `docs/README.md` and begin your GitHub Copilot MCP Server journey! 🚀