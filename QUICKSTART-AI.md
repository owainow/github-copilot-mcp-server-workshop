# Quick Start: AI Integration

## 🚀 5-Minute Setup for Azure AI Integration

Want to see the difference between educational and production MCP tools? Follow this quick guide!

### Prerequisites
- Azure account (free tier works!)
- Azure CLI installed
- Workshop project already set up

### Step 1: Run Setup Script
```powershell
# This script creates Azure AI resources and configures everything
.\setup-azure-ai.ps1
```

### Step 2: Restart Your Function
```powershell
# Stop current function (Ctrl+C if running)
# Then restart
func start
```

### Step 3: Test the Integration
```powershell
# This will show you the difference!
.\test-ai-integration.ps1
```

## 🎯 What You'll See

### Before (Mock Analysis)
```json
{
  "status": "mock_analysis",
  "message": "Azure AI not configured - showing mock analysis for demonstration"
}
```

### After (Real AI Analysis)
```json
{
  "status": "ai_analysis",
  "analysis": "The code shows good structure but has potential type safety issues..."
}
```

## 💰 Cost Information

- **Free Tier**: F0 SKU with monthly quotas
- **Workshop Usage**: Minimal cost (usually $0 for testing)
- **Production**: Upgrade to S0 when ready

## 🔧 Troubleshooting

### "Resource creation failed"
- Try a different region: `.\setup-azure-ai.ps1 -Location "westus"`
- Check your Azure subscription limits

### "Still showing mock analysis"
- Verify `local.settings.json` has your credentials
- Restart the Azure Function
- Check Azure portal for model deployment status

### "API quota exceeded"
- You've hit the free tier limits
- Wait for quota reset (monthly)
- Or upgrade to paid tier

## 🎓 Learning Value

This demonstrates the **core MCP principle**:
- **Educational tools**: Do analysis locally (good for learning)
- **Production tools**: Provide context to AI (true MCP pattern)

The AI tool shows how MCP tools should work in production - they gather and structure data for LLMs to analyze, rather than doing the analysis themselves.

## 📚 Next Steps

After setup:
1. Test different code examples with the AI tool
2. Compare quality of analysis with educational tools
3. Understand the architecture differences
4. Deploy to Azure for production testing

## 🤝 Workshop Support

Having issues? The workshop is designed to work with or without Azure AI:
- ✅ Educational tools work offline
- ✅ AI tool falls back gracefully
- ✅ Full learning experience guaranteed

The AI integration enhances the workshop but isn't required for core MCP learning!
