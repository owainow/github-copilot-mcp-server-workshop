# Example Usage Scenarios

This directory contains practical examples of how to use the MCP server with GitHub Copilot.

## Scenario 1: Markdown Documentation Review

### What you'll learn:
- How to use the markdown review tool
- Interpreting analysis results
- Implementing suggested improvements

### Example conversation with Copilot:

**You:** "Can you review the markdown in my README.md file and suggest improvements?"

**Copilot (using MCP):** "I'll analyze your README.md file using the markdown review tool."

```json
{
  "analysis": {
    "summary": {
      "contentLength": 2450,
      "lineCount": 98,
      "analysisType": "comprehensive"
    },
    "issues": [
      {
        "type": "missing_alt_text",
        "severity": "medium",
        "message": "Found 2 image(s) without alt text",
        "count": 2
      }
    ],
    "suggestions": [
      {
        "type": "table_of_contents",
        "priority": "medium",
        "message": "Consider adding a table of contents for better navigation"
      }
    ]
  }
}
```

**Copilot:** "I found a couple of issues with your README:

1. **Missing Alt Text**: You have 2 images without alt text, which affects accessibility
2. **Navigation**: Consider adding a table of contents since you have multiple sections

Would you like me to help fix these issues?"

## Scenario 2: Dependency Security Audit

### What you'll learn:
- Security vulnerability detection
- Dependency update recommendations
- Risk assessment interpretation

### Example conversation:

**You:** "Please check my project dependencies for security issues."

**Copilot (using MCP):** "I'll run a comprehensive dependency check on your package.json."

```json
{
  "security": {
    "vulnerabilities": [
      {
        "package": "lodash",
        "currentVersion": "4.17.15",
        "severity": "high",
        "cve": "CVE-2020-8203",
        "fixedVersion": "4.17.19"
      }
    ],
    "riskScore": 7
  },
  "updates": {
    "outdated": [
      {
        "package": "express",
        "currentVersion": "4.17.1",
        "latestVersion": "4.18.2",
        "updateType": "minor"
      }
    ]
  }
}
```

**Copilot:** "⚠️ **Security Alert**: I found 1 high-severity vulnerability:

- **lodash** (v4.17.15): Prototype pollution vulnerability (CVE-2020-8203)
  - Fix: Update to v4.17.19 or later

I also found 1 outdated package:
- **express**: Update from 4.17.1 to 4.18.2 (minor update, safe)

Would you like me to help update these dependencies?"

## Scenario 3: Combined Analysis Workflow

### Advanced usage combining multiple tools:

**You:** "Can you do a complete project health check?"

**Copilot:** "I'll run both dependency and documentation analysis for a comprehensive health check."

*[Copilot automatically uses both tools and provides a consolidated report]*

## Interactive Examples

Try these commands with your deployed MCP server:

### 1. Basic Tool Discovery

```bash
curl -X POST https://your-function-app.azurewebsites.net/api/mcp-server \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
  }'
```

### 2. Markdown Review Test

```bash
curl -X POST https://your-function-app.azurewebsites.net/api/mcp-server \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "markdown_review",
      "arguments": {
        "content": "# Test\n\n![Image](image.jpg)\n\nSome content here.",
        "analysis_type": "comprehensive"
      }
    }
  }'
```

### 3. Dependency Check Test

```bash
curl -X POST https://your-function-app.azurewebsites.net/api/mcp-server \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "dependency_check",
      "arguments": {
        "package_json": "{\"dependencies\": {\"lodash\": \"^4.17.15\", \"express\": \"^4.17.1\"}}",
        "check_type": "comprehensive"
      }
    }
  }'
```

## Advanced Integration Patterns

### Pattern 1: Conditional Tool Usage

Copilot can intelligently choose which tools to use based on context:

- **Files changed**: Uses appropriate analysis tools
- **User intent**: Selects relevant capabilities
- **Project type**: Adapts to different tech stacks

### Pattern 2: Chained Operations

Multiple tools can be used in sequence:

1. Dependency check identifies issues
2. Markdown review finds documentation problems
3. Combined report with prioritized recommendations

### Pattern 3: Context-Aware Analysis

Tools consider project context:

- **File types**: Different analysis for different file types
- **Project size**: Scaled recommendations
- **Development stage**: Appropriate suggestions for project maturity

## Best Practices

### For Users

1. **Be Specific**: "Check my dependencies for security issues" is better than "check my project"
2. **Provide Context**: Mention if you're looking for specific types of issues
3. **Follow Up**: Ask for explanations if results aren't clear

### For Tool Development

1. **Clear Descriptions**: Tools should have descriptive names and parameters
2. **Actionable Results**: Always provide specific, actionable recommendations
3. **Error Handling**: Gracefully handle edge cases and invalid inputs

## Troubleshooting Examples

### Common Issues and Solutions

#### Issue: Tool not found
```json
{
  "error": {
    "code": -32602,
    "message": "Tool 'markdown_review' not found"
  }
}
```

**Solution**: Check that tools are properly registered and environment variables are set.

#### Issue: Invalid parameters
```json
{
  "error": {
    "code": -32603,
    "message": "Tool execution failed: Content parameter is required"
  }
}
```

**Solution**: Verify that required parameters are provided in the correct format.

## Next Steps

Ready to try these examples? 

1. Deploy your MCP server following [Part 4: Azure Deployment](../docs/part-4-azure-deployment.md)
2. Configure GitHub Copilot following [Part 5: Copilot Integration](../docs/part-5-copilot-integration.md)
3. Try the examples above in your own projects!

---

*These examples demonstrate the power of custom MCP servers in enhancing GitHub Copilot's capabilities. The serverless architecture ensures these tools are always available when you need them.*
