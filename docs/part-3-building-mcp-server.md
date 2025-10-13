# Part 3: Building the MCP Server

Now that your development environment is set up, let's dive deep into building and customizing our MCP server. This section will walk you through the architecture, implementation details, and customization options.

## Understanding the MCP Server Architecture

### Core Components Overview

Our MCP server consists of several key components working together:

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Function App                      │
├─────────────────────────────────────────────────────────────┤
│  ┌───────────────┐  ┌─────────────────────────────────┐   │
│  │   HTTP        │  │        MCP Server Core          │   │
│  │   Handler     │──┤                                 │   │
│  │ (mcp-server.ts)│  │  • Request routing             │   │
│  └───────────────┘  │  • Tool management             │   │
│                     │  • Error handling              │   │
│                     │  • Logging                     │   │
│                     └─────────────────────────────────┘   │
│                                     │                      │
│                     ┌───────────────▼───────────────┐      │
│                     │           Tools               │      │
│                     │                               │      │
│                     │  ┌─────────────────────────┐  │      │
│                     │  │   Markdown Review       │  │      │
│                     │  │   • Structure analysis │  │      │
│                     │  │   • Link validation    │  │      │
│                     │  │   • Accessibility      │  │      │
│                     │  └─────────────────────────┘  │      │
│                     │                               │      │
│                     │  ┌─────────────────────────┐  │      │
│                     │  │   Dependency Check      │  │      │
│                     │  │   • Security scanning  │  │      │
│                     │  │   • Update analysis    │  │      │
│                     │  │   • Compatibility      │  │      │
│                     │  └─────────────────────────┘  │      │
│                     └───────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### MCP Protocol Flow

1. **GitHub Copilot** sends MCP request to Azure Function
2. **HTTP Handler** validates request and extracts MCP payload
3. **MCP Server** routes request to appropriate handler
4. **Tools** execute business logic and return results
5. **Response** is formatted and sent back to Copilot

## Deep Dive: MCP Server Core

Let's examine the core MCP server implementation in detail:

### Server Initialization

```typescript
// src/mcp/server.ts
export class MCPServer {
    private tools: Map<string, MCPTool> = new Map();
    private config: MCPServerConfig;

    constructor(config: MCPServerConfig) {
        this.config = config;
        this.config.logger.info('MCP Server initialized', {
            name: config.name,
            version: config.version
        });
    }
```

**Key Features:**
- **Tool Registry**: Maintains a map of available tools
- **Configuration**: Stores server metadata and dependencies
- **Logging**: Comprehensive operation tracking

### Request Handling

The `handleRequest` method is the heart of the MCP server:

```typescript
async handleRequest(request: MCPRequest): Promise<MCPResponse> {
    switch (request.method) {
        case 'initialize':
            return this.handleInitialize(request);
        
        case 'tools/list':
            return this.handleToolsList(request);
        
        case 'tools/call':
            return this.handleToolCall(request);
        
        case 'ping':
            return this.handlePing(request);
        
        default:
            return this.createErrorResponse(request.id, -32601, 
                `Method '${request.method}' not found`);
    }
}
```

**Supported Methods:**
- **initialize**: Handshake and capability negotiation
- **tools/list**: Discovery of available tools
- **tools/call**: Execution of specific tools
- **ping**: Health check and connectivity test

### Tool Registration

Tools are registered using a simple but powerful pattern:

```typescript
registerTool(tool: MCPTool): void {
    this.tools.set(tool.name, tool);
    this.config.logger.info('Tool registered', {
        toolName: tool.name,
        description: tool.description
    });
}
```

This design allows for:
- **Dynamic registration**: Tools can be added at runtime
- **Type safety**: TypeScript interfaces ensure tool compliance
- **Observability**: All registrations are logged

## Deep Dive: Markdown Review Tool

Let's explore the markdown review tool implementation:

### Tool Structure

```typescript
export class MarkdownReviewTool implements MCPTool {
    name = 'markdown_review';
    description = 'Analyze and provide improvement suggestions for markdown content';
    
    parameters = {
        content: {
            type: 'string',
            description: 'The markdown content to review'
        },
        analysis_type: {
            type: 'string',
            enum: ['basic', 'comprehensive', 'accessibility'],
            default: 'comprehensive'
        }
    };
```

### Analysis Engine

The tool performs multi-layered analysis:

#### 1. Structural Analysis
```typescript
private analyzeHeadingStructure(content: string): any {
    const headings = content.match(/^#{1,6}\s+.+$/gm) || [];
    const structure = headings.map(heading => {
        const level = heading.match(/^#+/)?.[0].length || 0;
        const text = heading.replace(/^#+\s+/, '');
        return { level, text };
    });

    return {
        totalHeadings: headings.length,
        structure,
        hasH1: structure.some(h => h.level === 1),
        hasSkippedLevels: this.hasSkippedHeadingLevels(structure)
    };
}
```

#### 2. Link Analysis
```typescript
private analyzeLinks(content: string): any {
    const links = content.match(/\[([^\]]+)\]\(([^)]+)\)/g) || [];
    
    return {
        totalLinks: links.length,
        links: links.map(link => {
            const match = link.match(/\[([^\]]+)\]\(([^)]+)\)/);
            return {
                text: match?.[1],
                url: match?.[2],
                isExternal: match?.[2]?.startsWith('http')
            };
        })
    };
}
```

#### 3. Accessibility Checks
```typescript
private findAccessibilityIssues(content: string): any[] {
    const issues = [];

    // Check for images without alt text
    const imagesWithoutAlt = content.match(/!\[\s*\]\([^)]+\)/g);
    if (imagesWithoutAlt) {
        issues.push({
            type: 'accessibility_alt_text',
            severity: 'high',
            message: 'Images without alt text are not accessible to screen readers',
            wcagGuideline: 'WCAG 2.1 Level A - 1.1.1 Non-text Content'
        });
    }

    return issues;
}
```

## Deep Dive: Dependency Check Tool

The dependency check tool provides comprehensive security and maintenance analysis:

### Security Analysis

```typescript
private async performSecurityAnalysis(dependencies: Record<string, string>): Promise<any> {
    const vulnerabilities = [];
    const knownVulnerabilities = this.getKnownVulnerabilities();

    for (const [packageName, version] of Object.entries(dependencies)) {
        const cleanVersion = this.cleanVersion(version);
        
        const vulns = knownVulnerabilities.filter(v => 
            v.package === packageName && 
            this.isVersionAffected(cleanVersion, v.affectedVersions)
        );

        vulnerabilities.push(...vulns.map(v => ({
            ...v,
            currentVersion: cleanVersion,
            severity: v.severity
        })));
    }

    return { vulnerabilities, riskScore: this.calculateRiskScore(vulnerabilities) };
}
```

### Update Analysis

```typescript
private async performUpdateAnalysis(dependencies: Record<string, string>): Promise<any> {
    const outdated = [];

    for (const [packageName, version] of Object.entries(dependencies)) {
        const cleanVersion = this.cleanVersion(version);
        const latestVersion = await this.getLatestVersion(packageName);

        if (latestVersion && semver.lt(cleanVersion, latestVersion)) {
            outdated.push({
                package: packageName,
                currentVersion: cleanVersion,
                latestVersion,
                updateType: this.getUpdateType(cleanVersion, latestVersion)
            });
        }
    }

    return { outdated };
}
```

## Azure Functions Integration

### HTTP Handler Implementation

The Azure Function serves as the bridge between HTTP requests and our MCP server:

```typescript
export async function mcpServerHandler(
    request: HttpRequest, 
    context: InvocationContext
): Promise<HttpResponseInit> {
    const logger = new Logger(context);
    
    try {
        // Handle CORS preflight
        if (request.method === 'OPTIONS') {
            return createCorsResponse();
        }

        // Initialize MCP server with tools
        const mcpServer = new MCPServer({
            name: process.env.MCP_SERVER_NAME || 'GitHub Copilot MCP Server',
            version: process.env.MCP_SERVER_VERSION || '1.0.0',
            logger
        });

        // Register tools based on configuration
        if (process.env.ENABLE_MARKDOWN_TOOL === 'true') {
            mcpServer.registerTool(new MarkdownReviewTool(logger));
        }

        if (process.env.ENABLE_DEPENDENCY_TOOL === 'true') {
            mcpServer.registerTool(new DependencyCheckTool(logger));
        }

        // Process MCP request
        const requestBody = await request.text();
        const mcpRequest = JSON.parse(requestBody);
        const mcpResponse = await mcpServer.handleRequest(mcpRequest);

        return {
            status: 200,
            headers: { 
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify(mcpResponse)
        };

    } catch (error) {
        logger.error('Error processing MCP request', { error });
        return createErrorResponse(error);
    }
}
```

### Configuration Management

Environment variables control tool availability:

```typescript
// Tool registration is dynamic based on environment
const toolConfig = {
    markdownTool: process.env.ENABLE_MARKDOWN_TOOL === 'true',
    dependencyTool: process.env.ENABLE_DEPENDENCY_TOOL === 'true',
    customTools: process.env.ENABLE_CUSTOM_TOOLS === 'true'
};
```

## Testing Your Implementation

### Local Testing

1. **Start the development server:**
```bash
npm run start:dev
```

2. **Test tool discovery:**
```bash
curl -X POST http://localhost:7071/api/mcp-server \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
  }'
```

3. **Test markdown review:**
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
        "content": "# Test\n\nSome content with ![](image.jpg) image.",
        "analysis_type": "comprehensive"
      }
    }
  }'
```

### Understanding Test Responses

#### Successful Tool List Response:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [
      {
        "name": "markdown_review",
        "description": "Analyze and provide improvement suggestions for markdown content",
        "inputSchema": {
          "type": "object",
          "properties": {
            "content": { "type": "string" },
            "analysis_type": { "type": "string", "enum": ["basic", "comprehensive", "accessibility"] }
          }
        }
      }
    ]
  }
}
```

#### Successful Tool Execution Response:
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"summary\": {\n    \"contentLength\": 45,\n    \"lineCount\": 3\n  },\n  \"issues\": [\n    {\n      \"type\": \"missing_alt_text\",\n      \"severity\": \"medium\",\n      \"message\": \"Found 1 image(s) without alt text\"\n    }\n  ]\n}"
      }
    ]
  }
}
```

## Customization and Extension

### Adding New Tools

To add a new tool to your MCP server:

1. **Create the tool class:**
```typescript
// src/tools/my-custom-tool.ts
export class MyCustomTool implements MCPTool {
    name = 'my_custom_tool';
    description = 'Description of what your tool does';
    
    parameters = {
        input: {
            type: 'string',
            description: 'Input parameter description'
        }
    };

    constructor(private logger: Logger) {}

    async execute(args: Record<string, any>): Promise<any> {
        // Tool implementation
        return { result: 'success' };
    }
}
```

2. **Register the tool:**
```typescript
// src/functions/mcp-server.ts
import { MyCustomTool } from '../tools/my-custom-tool';

// Add to tool registration section
if (process.env.ENABLE_MY_CUSTOM_TOOL === 'true') {
    mcpServer.registerTool(new MyCustomTool(logger));
}
```

3. **Update environment configuration:**
```env
ENABLE_MY_CUSTOM_TOOL=true
```

### Tool Best Practices

1. **Error Handling**: Always wrap tool logic in try-catch blocks
2. **Logging**: Use the provided logger for observability
3. **Input Validation**: Validate all input parameters
4. **Performance**: Consider timeout limits for long-running operations
5. **Security**: Never expose sensitive data in responses

### Advanced Customization

#### Custom Authentication
```typescript
private validateApiKey(request: HttpRequest): boolean {
    const apiKey = request.headers.get('X-MCP-API-KEY');
    return apiKey === process.env.MCP_API_KEY;
}
```

#### Rate Limiting
```typescript
private rateLimiter = new Map<string, number>();

private checkRateLimit(clientId: string): boolean {
    const now = Date.now();
    const lastRequest = this.rateLimiter.get(clientId) || 0;
    
    if (now - lastRequest < 1000) { // 1 second cooldown
        return false;
    }
    
    this.rateLimiter.set(clientId, now);
    return true;
}
```

## Performance Optimization

### Caching Strategies

For tools that make external API calls:

```typescript
private cache = new Map<string, { data: any, expiry: number }>();

private async getCachedResult(key: string, fetcher: () => Promise<any>): Promise<any> {
    const cached = this.cache.get(key);
    
    if (cached && cached.expiry > Date.now()) {
        return cached.data;
    }
    
    const data = await fetcher();
    this.cache.set(key, { data, expiry: Date.now() + 300000 }); // 5 minutes
    
    return data;
}
```

### Memory Management

```typescript
// Clean up resources when function execution completes
process.on('beforeExit', () => {
    // Clear caches, close connections, etc.
    this.cache.clear();
});
```

## Next Steps

Now that you understand the MCP server implementation, you're ready to:

1. **Deploy to Azure**: [Part 4: Azure Deployment](./part-4-azure-deployment.md)
2. **Integrate with Copilot**: [Part 5: GitHub Copilot Integration](./part-5-copilot-integration.md)
3. **Build Custom Tools**: Extend the server with your own tools

## Key Takeaways

✅ **MCP server follows a modular, extensible architecture**
✅ **Tools implement a simple interface for easy development**
✅ **Azure Functions provide seamless HTTP-to-MCP translation**
✅ **Comprehensive logging and error handling ensure reliability**
✅ **Configuration-driven tool registration enables flexible deployments**

Ready to deploy your MCP server to Azure? Let's continue to the next section!
