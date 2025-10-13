# Part 2: Setting Up the Development Environment

Welcome to the hands-on portion of our workshop! In this section, we'll prepare your development environment and get familiar with the project structure.

## Prerequisites Verification

Before we begin, let's verify that you have all the required tools installed:

### 1. Node.js Version Check

```bash
node --version
# Should show v18.x.x or later
```

If you need to install or update Node.js:
- Visit [nodejs.org](https://nodejs.org/)
- Download the LTS version (18.x or later)
- Follow the installation instructions for your platform

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

## Project Setup

### 1. Initialize the Project

You should already have the project files from cloning this repository. Let's set up the development environment:

```bash
# Navigate to the project directory
cd serverless-mcp-on-functions

# Install dependencies
npm install

# Copy environment configuration
cp .env.example .env
```

### 2. Configure Environment Variables

Open the `.env` file and update the following values:

```env
# Get your subscription ID
AZURE_SUBSCRIPTION_ID=your-subscription-id-here

# Choose a unique name for your function app
AZURE_FUNCTION_APP_NAME=mcp-server-functions-your-name

# Choose your preferred Azure region
AZURE_REGION=eastus

# Tool configuration (leave as-is for workshop)
ENABLE_MARKDOWN_TOOL=true
ENABLE_DEPENDENCY_TOOL=true
```

**How to get your subscription ID:**
```bash
az account show --query id --output tsv
```

### 3. Verify Project Structure

Your project should now have this structure:

```
serverless-mcp-on-functions/
├── .env                          # Environment configuration
├── .env.example                  # Example environment file
├── README.md                     # Main workshop documentation
├── package.json                  # Node.js dependencies and scripts
├── tsconfig.json                 # TypeScript configuration
├── host.json                     # Azure Functions host configuration
├── docs/                         # Workshop documentation
│   ├── part-1-understanding-mcp.md
│   ├── part-2-setup.md
│   └── ...
├── src/                          # Source code
│   ├── functions/               # Azure Functions
│   │   └── mcp-server.ts        # Main MCP server function
│   ├── mcp/                     # MCP server implementation
│   │   └── server.ts            # Core MCP server logic
│   ├── tools/                   # MCP tools
│   │   ├── markdown-review.ts   # Markdown analysis tool
│   │   └── dependency-check.ts  # Dependency security tool
│   └── shared/                  # Shared utilities
│       └── logger.ts            # Enhanced logging
├── infra/                       # Azure infrastructure
│   ├── main.bicep              # Azure resources definition
│   └── main.parameters.json    # Deployment parameters
└── dist/                        # Compiled TypeScript (created after build)
```

## Understanding the Codebase

Let's explore the key components:

### 1. MCP Server Core (`src/mcp/server.ts`)

This is the heart of our MCP implementation. It handles:
- **Tool Registration**: Managing available tools
- **Request Processing**: Handling MCP protocol messages
- **Error Handling**: Graceful error responses
- **Logging**: Comprehensive operation tracking

Key methods:
- `registerTool()`: Add new tools to the server
- `handleRequest()`: Process incoming MCP requests
- `handleToolCall()`: Execute specific tools

### 2. Azure Functions Integration (`src/functions/mcp-server.ts`)

This Azure Function serves as the HTTP endpoint for our MCP server:
- **HTTP Handling**: Processes POST requests from GitHub Copilot
- **CORS Support**: Enables cross-origin requests
- **Authentication**: (Extensible for API keys)
- **Error Handling**: Robust error responses

### 3. Tools Implementation

#### Markdown Review Tool (`src/tools/markdown-review.ts`)
- Analyzes markdown content for issues
- Checks structure, links, and accessibility
- Provides actionable improvement suggestions

#### Dependency Check Tool (`src/tools/dependency-check.ts`)
- Scans package.json for security vulnerabilities
- Identifies outdated dependencies
- Provides update recommendations

### 4. Infrastructure as Code (`infra/main.bicep`)

Our Azure infrastructure includes:
- **Function App**: Serverless compute for MCP server
- **Storage Account**: Required for Azure Functions
- **Application Insights**: Monitoring and logging
- **App Service Plan**: Consumption-based hosting

## Local Development Setup

### 1. Build the Project

```bash
# Compile TypeScript to JavaScript
npm run build

# Watch for changes during development
npm run build -- --watch
```

### 2. Start Local Development Server

```bash
# Start Azure Functions locally
npm start

# Alternative: Start with TypeScript watching
npm run start:dev
```

You should see output similar to:
```
Azure Functions Core Tools
Core Tools Version:       4.0.5455
Function Runtime Version: 4.25.2.20230

[2024-01-26T10:30:00.000Z] Worker process started and initialized.

Functions:
        mcp-server: [POST,GET,OPTIONS] http://localhost:7071/api/mcp-server
```

### 3. Test the Local Server

Open a new terminal and test the server:

```bash
# Test ping endpoint
curl -X POST http://localhost:7071/api/mcp-server \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "ping"
  }'
```

Expected response:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "status": "ok",
    "timestamp": "2024-01-26T10:30:00.000Z",
    "server": "GitHub Copilot MCP Server",
    "version": "1.0.0"
  }
}
```

### 4. Test Tool Discovery

```bash
# List available tools
curl -X POST http://localhost:7071/api/mcp-server \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/list"
  }'
```

This should return a list of available tools (markdown_review and dependency_check).

## Development Workflow

### 1. Making Changes

1. **Edit source code** in the `src/` directory
2. **Rebuild** using `npm run build` or use watch mode
3. **Restart** the local server if needed
4. **Test** your changes using curl or Postman

### 2. Adding New Tools

To add a new tool:

1. Create a new file in `src/tools/` (e.g., `my-tool.ts`)
2. Implement the `MCPTool` interface
3. Register the tool in `src/functions/mcp-server.ts`
4. Test locally before deployment

### 3. Debugging

Enable debug logging by setting:
```env
MCP_LOG_LEVEL=debug
```

View logs in:
- **Local development**: Terminal output
- **Azure**: Application Insights or Function App logs

## Workshop Environment Validation

Let's verify everything is working correctly:

### 1. Check Dependencies

```bash
# Verify all packages are installed
npm list --depth=0
```

### 2. Validate TypeScript Compilation

```bash
# Check for TypeScript errors
npm run build

# Run linting
npm run lint
```

### 3. Test Local Server

```bash
# Start the server
npm start

# In another terminal, test the ping endpoint
curl -X POST http://localhost:7071/api/mcp-server \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "ping"}'
```

## Troubleshooting Common Issues

### Issue: "Cannot find module '@azure/functions'"

**Solution:**
```bash
npm install
npm run build
```

### Issue: "Port 7071 is already in use"

**Solution:**
```bash
# Kill existing process
npx kill-port 7071

# Or use a different port
func start --port 7072
```

### Issue: "Azure CLI not authenticated"

**Solution:**
```bash
az login
az account set --subscription "your-subscription-id"
```

### Issue: TypeScript compilation errors

**Solution:**
1. Check `tsconfig.json` configuration
2. Ensure all dependencies are installed
3. Verify Node.js version is 18.x or later

## Next Steps

Congratulations! You now have a fully configured development environment. In the next section, we'll dive deep into building and customizing our MCP tools.

**Continue to:** [Part 3: Building the MCP Server](./part-3-building-mcp-server.md)

## Quick Reference

### Useful Commands

```bash
# Development
npm run build          # Compile TypeScript
npm start             # Start local server
npm run lint          # Check code quality
npm test             # Run tests

# Azure
az login                    # Authenticate with Azure
func start                  # Start Functions locally
func azure functionapp publish # Deploy to Azure

# Debugging
npm run start:dev          # Start with TypeScript watching
curl -X POST ...          # Test HTTP endpoints
```

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription | `12345678-1234-...` |
| `AZURE_FUNCTION_APP_NAME` | Unique function app name | `mcp-server-functions-john` |
| `ENABLE_MARKDOWN_TOOL` | Enable markdown analysis | `true` |
| `ENABLE_DEPENDENCY_TOOL` | Enable dependency check | `true` |

Ready to build something amazing? Let's continue to the implementation phase!
