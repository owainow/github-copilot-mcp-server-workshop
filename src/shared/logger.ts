import { InvocationContext } from '@azure/functions';

/**
 * Enhanced logger for MCP server operations
 * Provides structured logging with context and correlation
 */
export class Logger {
    private context: InvocationContext;
    private correlationId: string;

    constructor(context: InvocationContext) {
        this.context = context;
        this.correlationId = context.invocationId;
    }

    /**
     * Log information message
     */
    info(message: string, data?: Record<string, any>): void {
        this.log('info', message, data);
    }

    /**
     * Log warning message
     */
    warn(message: string, data?: Record<string, any>): void {
        this.log('warn', message, data);
    }

    /**
     * Log error message
     */
    error(message: string, data?: Record<string, any>): void {
        this.log('error', message, data);
    }

    /**
     * Log debug message
     */
    debug(message: string, data?: Record<string, any>): void {
        this.log('debug', message, data);
    }

    /**
     * Internal logging method
     */
    private log(level: string, message: string, data?: Record<string, any>): void {
        const logEntry = {
            timestamp: new Date().toISOString(),
            level,
            message,
            correlationId: this.correlationId,
            functionName: this.context.functionName || 'mcp-server',
            invocationId: this.context.invocationId || 'unknown',
            ...data
        };

        // Use console.log for Azure Functions v4 (context.log doesn't exist in v4)
        const logMessage = JSON.stringify(logEntry);
        
        switch (level) {
            case 'error':
                console.error(logMessage);
                break;
            case 'warn':
                console.warn(logMessage);
                break;
            case 'debug':
                console.debug(logMessage);
                break;
            default:
                console.log(logMessage);
        }
    }

    /**
     * Create a child logger with additional context
     */
    child(additionalContext: Record<string, any>): Logger {
        const childLogger = new Logger(this.context);
        // Store additional context for future log entries
        (childLogger as any).additionalContext = additionalContext;
        return childLogger;
    }

    /**
     * Log performance metrics
     */
    logPerformance(operation: string, startTime: number, success: boolean, additionalData?: Record<string, any>): void {
        const duration = Date.now() - startTime;
        this.info('Performance metric', {
            operation,
            duration,
            success,
            ...additionalData
        });
    }
}
