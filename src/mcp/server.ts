import { Logger } from '../shared/logger';
import { MarkdownReviewTool } from '../tools/markdown-review';
import { DependencyCheckTool } from '../tools/dependency-check';
import { AiCodeReviewTool } from '../tools/ai-code-review';

/**
 * Base interface for MCP tools
 */
export interface MCPTool {
    name: string;
    description: string;
    parameters: Record<string, any>;
    execute(args: Record<string, any>): Promise<any>;
}

/**
 * MCP Request/Response types based on the MCP specification
 */
export interface MCPRequest {
    jsonrpc: '2.0';
    id: string | number;
    method: string;
    params?: any;
}

export interface MCPResponse {
    jsonrpc: '2.0';
    id: string | number;
    result?: any;
    error?: {
        code: number;
        message: string;
        data?: any;
    };
}

export interface MCPServerConfig {
    name: string;
    version: string;
    logger: Logger;
}

/**
 * MCP Server implementation for Azure Functions
 * Handles the Model Context Protocol for GitHub Copilot integration
 */
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

    /**
     * Register a tool with the MCP server
     */
    registerTool(tool: MCPTool): void {
        this.tools.set(tool.name, tool);
        this.config.logger.info('Tool registered', {
            toolName: tool.name,
            description: tool.description
        });
    }

    /**
     * Handle incoming MCP requests
     */
    async handleRequest(request: MCPRequest): Promise<MCPResponse> {
        this.config.logger.info('Handling MCP request', {
            method: request.method,
            id: request.id
        });

        try {
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
                    return this.createErrorResponse(request.id, -32601, `Method '${request.method}' not found`);
            }
        } catch (error) {
            this.config.logger.error('Error handling MCP request', { error, request });
            return this.createErrorResponse(request.id, -32603, 'Internal error');
        }
    }

    /**
     * Handle initialization request
     */
    private handleInitialize(request: MCPRequest): MCPResponse {
        return {
            jsonrpc: '2.0',
            id: request.id,
            result: {
                protocolVersion: '2024-11-05',
                capabilities: {
                    tools: {
                        listChanged: false
                    }
                },
                serverInfo: {
                    name: this.config.name,
                    version: this.config.version
                }
            }
        };
    }

    /**
     * Handle tools list request
     */
    private handleToolsList(request: MCPRequest): MCPResponse {
        const tools = Array.from(this.tools.values()).map(tool => ({
            name: tool.name,
            description: tool.description,
            inputSchema: {
                type: 'object',
                properties: tool.parameters,
                required: Object.keys(tool.parameters)
            }
        }));

        return {
            jsonrpc: '2.0',
            id: request.id,
            result: {
                tools
            }
        };
    }

    /**
     * Handle tool call request
     */
    private async handleToolCall(request: MCPRequest): Promise<MCPResponse> {
        const { name, arguments: args } = request.params;

        if (!this.tools.has(name)) {
            return this.createErrorResponse(request.id, -32602, `Tool '${name}' not found`);
        }

        const tool = this.tools.get(name)!;

        try {
            this.config.logger.info('Executing tool', { toolName: name, arguments: args });
            const result = await tool.execute(args);
            
            return {
                jsonrpc: '2.0',
                id: request.id,
                result: {
                    content: [
                        {
                            type: 'text',
                            text: JSON.stringify(result, null, 2)
                        }
                    ]
                }
            };
        } catch (error) {
            this.config.logger.error('Tool execution failed', { toolName: name, error });
            return this.createErrorResponse(request.id, -32603, `Tool execution failed: ${error}`);
        }
    }

    /**
     * Handle ping request
     */
    private handlePing(request: MCPRequest): MCPResponse {
        return {
            jsonrpc: '2.0',
            id: request.id,
            result: {
                status: 'ok',
                timestamp: new Date().toISOString(),
                server: this.config.name,
                version: this.config.version
            }
        };
    }

    /**
     * Create error response
     */
    private createErrorResponse(id: string | number, code: number, message: string): MCPResponse {
        return {
            jsonrpc: '2.0',
            id,
            error: {
                code,
                message
            }
        };
    }
}
