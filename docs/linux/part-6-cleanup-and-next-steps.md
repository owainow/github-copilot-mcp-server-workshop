# Part 6: Resource Cleanup & Next Steps

> **Workshop Navigation**: [← Part 5: AI Integration](part-5-ai-integration.md)

## 🎯 Objective

Clean up all Azure resources created during the workshop to avoid ongoing charges and explore next steps for extending your MCP server.

---

## 🧹 Complete Resource Cleanup

### Full Cleanup (Recommended)

The fastest way to clean up all workshop resources:

#### Step 1: Delete Azure Resources

```bash
# Verify you have the resource group variable set
echo "Resource Group: $RESOURCE_GROUP"

# If not set, use the default
if [ -z "$RESOURCE_GROUP" ]; then
    RESOURCE_GROUP="rg-mcp-workshop"
fi

# List all resources in the group (optional - to see what will be deleted)
echo "Resources that will be deleted:"
az resource list --resource-group $RESOURCE_GROUP --output table

# Delete the entire resource group and all its resources
echo "Deleting resource group: $RESOURCE_GROUP"
az group delete --name $RESOURCE_GROUP --yes --no-wait

echo "✅ Cleanup initiated! Resources will be deleted in the background."
echo "This may take 5-10 minutes to complete."
```

#### Step 2: Delete GitHub Codespace (Codespaces Users Only)

🌟 **If you're using GitHub Codespaces**, make sure to delete the codespace to avoid ongoing storage charges:

1. **Navigate to GitHub Codespaces**: Go to [github.com/codespaces](https://github.com/codespaces)
2. **Find your workshop codespace**: Look for the `github-copilot-mcp-server-workshop` codespace
3. **Delete the codespace**:
   - Click the **"..."** menu next to your codespace
   - Select **"Delete"**
   - Confirm the deletion

> **💡 Important**: Codespaces are charged for storage even when stopped. Deleting the codespace ensures no ongoing charges.

### Selective Cleanup (Alternative)

If you want to keep some resources, delete them individually:

```bash
# Delete Azure Function App
az functionapp delete \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP

# Delete Azure AI Foundry resources
az cognitiveservices account delete \
  --name mcp-workshop-ai-hub \
  --resource-group $RESOURCE_GROUP

# Delete Storage Account
STORAGE_ACCOUNT=$(az storage account list \
  --resource-group $RESOURCE_GROUP \
  --query "[0].name" \
  --output tsv)

az storage account delete \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --yes

# Delete Application Insights
APP_INSIGHTS=$(az monitor app-insights component show \
  --resource-group $RESOURCE_GROUP \
  --query "[0].name" \
  --output tsv)

az monitor app-insights component delete \
  --app $APP_INSIGHTS \
  --resource-group $RESOURCE_GROUP

# Finally, delete the resource group (now empty)
az group delete --name $RESOURCE_GROUP --yes
```

---

## 💰 Cost Verification

### Check Final Costs

```bash
# Check if there are any remaining resources
az resource list --resource-group $RESOURCE_GROUP --output table

# View cost analysis (if you have billing access)
az consumption usage list \
  --start-date $(date -d '7 days ago' +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --output table
```

### Expected Workshop Costs

For the complete workshop, you should expect minimal costs:

- **Azure Functions (Consumption Plan)**: ~$0.01-0.05
- **Storage Account**: ~$0.01-0.02  
- **Application Insights**: ~$0.01-0.03
- **Azure AI Foundry (GPT-3.5-turbo)**: ~$0.10-0.50 (depending on testing)

**Total Expected Cost: $0.15-0.60 USD**

---

## 🎯 Local Cleanup

### Clean Local Development Environment

```bash
# Stop any running functions
# Press Ctrl+C in the terminal running func start

# Clean build artifacts
npm run clean
rm -rf dist/
rm -rf node_modules/

# Remove sensitive local settings (optional)
# rm local.settings.json

# Clean up test files (optional)
rm -f test-local-functions.sh
rm -f sample-code-for-review.js
```

### Reset VS Code Configuration

If you want to completely reset your MCP configuration:

1. **Open VS Code Settings** (Ctrl+,)
2. **Search for**: "MCP"
3. **Remove any MCP server configurations** you added in Part 4
4. **Restart VS Code**

---

## ✅ Cleanup Verification

### Confirm Resources are Deleted

```bash
# Verify resource group is deleted
az group show --name $RESOURCE_GROUP 2>/dev/null || echo "✅ Resource group successfully deleted"

# Check for any remaining resources with workshop tags
az resource list --tag workshop=mcp-server --output table

# Verify no function apps with your naming pattern
az functionapp list --query "[?contains(name, 'mcp-server')]" --output table
```

---

## 🚀 Next Steps & Extensions

Congratulations! You've successfully completed the workshop. Here are ways to extend your learning:

### 🔧 Technical Extensions

**Add More Tools:**
- **Database Query Tool**: Connect to Azure SQL/CosmosDB
- **API Testing Tool**: Test REST endpoints and validate responses  
- **Documentation Generator**: Auto-generate docs from code
- **Image Analysis Tool**: Use Azure Computer Vision
- **Translation Tool**: Multi-language support with Azure Translator

**Improve Architecture:**
- **Authentication**: Add Azure AD integration
- **Rate Limiting**: Implement request throttling
- **Caching**: Add Redis for performance
- **Monitoring**: Enhanced telemetry and alerts
- **CI/CD**: Automated deployment pipelines

### 📚 Learning Resources

**MCP Development:**
- [MCP Official Documentation](https://modelcontextprotocol.io/)
- [MCP Community Examples](https://github.com/modelcontextprotocol)
- [GitHub Copilot Extensions Guide](https://docs.github.com/en/copilot)

**Azure Development:**
- [Azure Functions Best Practices](https://docs.microsoft.com/azure/azure-functions/functions-best-practices)
- [Azure AI Services](https://docs.microsoft.com/azure/cognitive-services/)
- [Serverless Computing Patterns](https://docs.microsoft.com/azure/architecture/serverless/)

### 🤝 Community Contribution

**Share Your Work:**
- **Blog about your experience** with MCP and Azure Functions
- **Create custom tool templates** for common use cases
- **Contribute to open source** MCP projects
- **Present at conferences** or meetups

**Build for Your Organization:**
- **Team-specific tools** for your development workflow
- **Integration with internal APIs** and databases
- **Custom deployment templates** for consistent setups
- **Training materials** for team adoption

---

## 📝 Workshop Summary

### 🎉 What You Accomplished

- ✅ **Built a complete MCP server** with three custom tools
- ✅ **Deployed to Azure Functions** with Infrastructure as Code
- ✅ **Integrated with GitHub Copilot** for enhanced development
- ✅ **Connected to Azure AI** for intelligent code analysis
- ✅ **Implemented production patterns** with monitoring and error handling
- ✅ **Learned serverless architecture** with cost-effective scaling

### 🧠 Key Skills Gained

- **MCP Protocol Implementation**: JSON-RPC 2.0, tool patterns, error handling
- **Azure Functions Development**: TypeScript, serverless deployment, configuration
- **Infrastructure as Code**: Bicep templates, automated provisioning
- **AI Integration**: Azure OpenAI, prompt engineering, fallback strategies
- **DevOps Practices**: Automated testing, monitoring, cleanup procedures

### 🎯 Production-Ready Features

Your MCP server includes:
- **Robust error handling** with graceful fallbacks
- **Environment-based configuration** for different deployment stages
- **Comprehensive logging** with Azure Application Insights
- **Cost optimization** with consumption-based billing
- **Security best practices** with managed identity and proper authentication

---

## 🐛 Troubleshooting Cleanup

### Common Issues

**Resource group won't delete:**
```bash
# Check for locks on resources
az lock list --resource-group $RESOURCE_GROUP

# Remove any locks found
az lock delete --name <lock-name> --resource-group $RESOURCE_GROUP

# Try deletion again
az group delete --name $RESOURCE_GROUP --yes
```

**Function app still running:**
```bash
# Force stop the function app
az functionapp stop --name $FUNCTION_APP --resource-group $RESOURCE_GROUP

# Then delete
az functionapp delete --name $FUNCTION_APP --resource-group $RESOURCE_GROUP
```

**AI services billing concerns:**
```bash
# Check usage in the last 24 hours
az cognitiveservices account list-usage \
  --name mcp-workshop-ai-hub \
  --resource-group $RESOURCE_GROUP
```

---

## 📞 Support & Community

### Getting Help

- **Azure Support**: [Azure Support Portal](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade)
- **MCP Community**: [GitHub Discussions](https://github.com/modelcontextprotocol/specification/discussions)
- **VS Code Issues**: [VS Code GitHub Repository](https://github.com/microsoft/vscode)

### Stay Connected

- **Follow MCP updates**: [MCP Website](https://modelcontextprotocol.io/)
- **Azure Functions news**: [Azure Updates](https://azure.microsoft.com/updates/)
- **GitHub Copilot features**: [GitHub Blog](https://github.blog/)

---

## 🎊 Congratulations!

You've successfully completed the **Serverless MCP Server Workshop**! 

You now have the knowledge and experience to:
- **Build custom development tools** that integrate with GitHub Copilot
- **Deploy serverless applications** on Azure with best practices
- **Integrate AI services** for intelligent development assistance
- **Implement production-ready architectures** with proper monitoring and cleanup

**Thank you for participating!** 🚀

---

**🌟 Don't forget to share your success and help others learn by contributing back to the community!**