import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import { MCPServer } from '../mcp/server';
import { MarkdownReviewTool } from '../tools/markdown-review';
import { DependencyCheckTool } from '../tools/dependency-check';
import { AiCodeReviewTool } from '../tools/ai-code-review';
import { Logger } from '../shared/logger';

/**
 * Azure Function handler for the MCP server
 * This is the main entry point for GitHub Copilot to interact with our custom tools
 */
export async function mcpServerHandler(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    const logger = new Logger(context);
    
    try {
        logger.info('MCP Server request received', {
            method: request.method,
            url: request.url,
            headers: Object.fromEntries(request.headers.entries())
        });

        // Handle CORS preflight requests
        if (request.method === 'OPTIONS') {
            return {
                status: 200,
                headers: {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-MCP-API-KEY',
                    'Access-Control-Max-Age': '86400'
                }
            };
        }

        // Validate HTTP method
        if (request.method !== 'POST') {
            return {
                status: 405,
                headers: {
                    'Access-Control-Allow-Origin': '*',
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    error: 'Method not allowed',
                    message: 'Only POST requests are supported'
                })
            };
        }

        // Initialize MCP server with tools
        const mcpServer = new MCPServer({
            name: process.env.MCP_SERVER_NAME || 'GitHub Copilot MCP Server',
            version: process.env.MCP_SERVER_VERSION || '1.0.0',
            logger
        });

        // Register tools based on environment configuration
        if (process.env.ENABLE_MARKDOWN_TOOL === 'true') {
            mcpServer.registerTool(new MarkdownReviewTool(logger));
        }

        if (process.env.ENABLE_DEPENDENCY_TOOL === 'true') {
            mcpServer.registerTool(new DependencyCheckTool(logger));
        }

        if (process.env.ENABLE_AI_TOOL === 'true') {
            mcpServer.registerTool(new AiCodeReviewTool(logger));
        }

        // Parse request body
        const requestBody = await request.text();
        let mcpRequest;
        
        try {
            mcpRequest = JSON.parse(requestBody);
        } catch (parseError) {
            logger.error('Invalid JSON in request body', { error: parseError, body: requestBody });
            return {
                status: 400,
                headers: {
                    'Access-Control-Allow-Origin': '*',
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    error: 'Invalid JSON',
                    message: 'Request body must be valid JSON'
                })
            };
        }

        // Process MCP request
        const mcpResponse = await mcpServer.handleRequest(mcpRequest);

        logger.info('MCP request processed successfully', {
            requestId: mcpRequest.id,
            method: mcpRequest.method
        });

        return {
            status: 200,
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(mcpResponse)
        };

    } catch (error) {
        logger.error('Error processing MCP request', { error });

        return {
            status: 500,
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                error: 'Internal server error',
                message: 'An error occurred while processing the MCP request'
            })
        };
    }
}

// Register the function using the v4 programming model
app.http('mcp-server', {
    methods: ['GET', 'POST', 'OPTIONS'],
    authLevel: 'anonymous',
    handler: mcpServerHandler
});
