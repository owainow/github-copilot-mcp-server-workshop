/**
 * Jest setup file for MCP Server tests
 */

// Mock Azure Functions context
global.mockContext = {
    invocationId: 'test-invocation-id',
    functionName: 'mcp-server',
    log: {
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
        verbose: jest.fn()
    }
};

// Mock environment variables
process.env.MCP_SERVER_NAME = 'Test MCP Server';
process.env.MCP_SERVER_VERSION = '1.0.0-test';
process.env.ENABLE_MARKDOWN_TOOL = 'true';
process.env.ENABLE_DEPENDENCY_TOOL = 'true';

// Global test timeout
jest.setTimeout(30000);
