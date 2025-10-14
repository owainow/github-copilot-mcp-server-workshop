#!/bin/bash

# GitHub Copilot MCP Server Workshop - Codespace Setup
# This script sets up the development environment for the workshop

echo "🚀 Setting up GitHub Copilot MCP Server Workshop environment..."

# Create local.settings.json from template
if [ ! -f "local.settings.json" ]; then
    echo "📝 Creating local.settings.json template..."
    cat > local.settings.json << 'EOF'
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "ENABLE_AI_TOOL": "false",
    "AZURE_SUBSCRIPTION_ID": "",
    "AZURE_FUNCTION_APP_NAME": "",
    "AZURE_REGION": "eastus",
    "AZURE_OPENAI_ENDPOINT": "",
    "AZURE_OPENAI_API_KEY": "",
    "AZURE_OPENAI_DEPLOYMENT_NAME": "",
    "AZURE_OPENAI_API_VERSION": "2024-02-15-preview"
  }
}
EOF
    echo "✅ Created local.settings.json - Update with your Azure configuration"
fi

# Create .env file for environment variables
if [ ! -f ".env" ]; then
    echo "📝 Creating .env template..."
    cat > .env << 'EOF'
# Azure Configuration
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_FUNCTION_APP_NAME=mcp-server-functions-yourname
AZURE_REGION=eastus

# AI Configuration (Optional - for Part 5)
AZURE_OPENAI_ENDPOINT=
AZURE_OPENAI_API_KEY=
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-35-turbo-mcp
EOF
    echo "✅ Created .env template - Update with your Azure details"
fi

# Verify installations
echo "🔍 Verifying tool installations..."

echo -n "Node.js: "
if node --version; then
    echo "✅ Node.js is available"
else
    echo "❌ Node.js not found"
fi

echo -n "Azure CLI: "
if az --version > /dev/null 2>&1; then
    echo "✅ Azure CLI is available"
else
    echo "❌ Azure CLI not found"
fi

echo -n "Azure Functions Core Tools: "
if func --version > /dev/null 2>&1; then
    echo "✅ Azure Functions Core Tools is available"
else
    echo "❌ Azure Functions Core Tools not found"
fi

echo -n "npm: "
if npm --version > /dev/null 2>&1; then
    echo "✅ npm is available"
else 
    echo "❌ npm not found"
fi

# Build the project
echo "🔨 Building the project..."
if npm run build; then
    echo "✅ Project built successfully"
else
    echo "❌ Build failed - check error messages above"
fi

echo ""
echo "🎉 Workshop environment setup complete!"
echo ""
echo "📚 Next steps:"
echo "1. Open docs/README.md to start the workshop"
echo "2. Follow Part 1 to configure Azure CLI: az login" 
echo "3. Update local.settings.json with your Azure details"
echo "4. Start local development: func start"
echo ""
echo "🔗 Quick links:"
echo "   📖 Workshop Guide: docs/README.md"
echo "   🚀 Part 1: docs/part-1-understanding-mcp-and-setup.md"
echo "   💻 VS Code already has GitHub Copilot and Azure extensions!"
echo ""
echo "Happy coding! 🎯"