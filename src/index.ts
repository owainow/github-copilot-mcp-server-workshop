// Main entry point for the MCP Server package
// This allows the package to be used as both an Azure Function and a standalone library

// Export the main MCP server handler for library usage
export * from './functions/mcp-server';

// Also export other useful modules for advanced usage
export * from './mcp/server';
export * from './tools/markdown-review';
export * from './tools/dependency-check';
export * from './tools/ai-code-review';
export * from './shared/logger';