import { MCPTool } from '../mcp/server';
import { Logger } from '../shared/logger';

interface AzureAIResponse {
    choices: Array<{
        message: {
            content: string;
        };
    }>;
}

export class AiCodeReviewTool implements MCPTool {
    name = 'ai_code_review';
    description = 'Analyze code using Azure AI to provide intelligent feedback on quality, security, and best practices';
    
    parameters = {
        code: {
            type: 'string',
            description: 'The code content to review'
        },
        language: {
            type: 'string',
            description: 'Programming language (javascript, typescript, python, etc.)',
            default: 'typescript'
        },
        review_type: {
            type: 'string',
            description: 'Type of review: security, performance, best_practices, or comprehensive',
            enum: ['security', 'performance', 'best_practices', 'comprehensive'],
            default: 'comprehensive'
        }
    };

    private logger: Logger;
    private readonly AZURE_AI_ENDPOINT: string;
    private readonly AZURE_AI_KEY: string;

    constructor(logger: Logger) {
        this.logger = logger;
        // Azure AI Foundry free tier endpoint (would be configured via environment variables)
        this.AZURE_AI_ENDPOINT = process.env.AZURE_AI_ENDPOINT || '';
        this.AZURE_AI_KEY = process.env.AZURE_AI_KEY || '';
    }

    async execute(args: Record<string, any>): Promise<any> {
        const startTime = Date.now();
        
        try {
            const { code, language = 'typescript', review_type = 'comprehensive' } = args;

            if (!code || typeof code !== 'string') {
                throw new Error('Code parameter is required and must be a string');
            }

            this.logger.info('Starting AI code review', {
                codeLength: code.length,
                language,
                reviewType: review_type
            });

            // Check if Azure AI is configured
            if (!this.AZURE_AI_ENDPOINT || !this.AZURE_AI_KEY) {
                this.logger.warn('Azure AI not configured, falling back to mock analysis');
                return this.generateMockAnalysis(code, language, review_type);
            }

            // Call Azure AI for real analysis
            const aiAnalysis = await this.callAzureAI(code, language, review_type);
            
            this.logger.logPerformance('ai_code_review', startTime, true, {
                reviewType: review_type,
                language,
                responseLength: aiAnalysis.length
            });

            return {
                type: 'text',
                text: aiAnalysis
            };

        } catch (error) {
            this.logger.error('AI code review failed', { error, args });
            this.logger.logPerformance('ai_code_review', startTime, false);
            
            // Graceful fallback to mock analysis
            this.logger.info('Falling back to mock analysis due to error');
            return this.generateMockAnalysis(args.code || '', args.language || 'typescript', args.review_type || 'comprehensive');
        }
    }

    private async callAzureAI(code: string, language: string, reviewType: string): Promise<string> {
        const prompt = this.buildReviewPrompt(code, language, reviewType);
        
        const requestBody = {
            messages: [
                {
                    role: "system",
                    content: "You are an expert code reviewer. Provide detailed, actionable feedback on code quality, security, and best practices. Format your response as structured analysis with specific recommendations."
                },
                {
                    role: "user", 
                    content: prompt
                }
            ],
            max_tokens: 1000,
            temperature: 0.3,
            top_p: 0.9
        };

        const response = await fetch(`${this.AZURE_AI_ENDPOINT}/openai/deployments/gpt-35-turbo/chat/completions?api-version=2024-02-15-preview`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'api-key': this.AZURE_AI_KEY
            },
            body: JSON.stringify(requestBody)
        });

        if (!response.ok) {
            throw new Error(`Azure AI API error: ${response.status} ${response.statusText}`);
        }

        const result = await response.json() as AzureAIResponse;
        return result.choices[0]?.message?.content || 'No analysis generated';
    }

    private buildReviewPrompt(code: string, language: string, reviewType: string): string {
        const reviewFocus = {
            security: "Focus on security vulnerabilities, input validation, authentication, and potential exploits.",
            performance: "Focus on performance optimizations, algorithmic efficiency, and resource usage.",
            best_practices: "Focus on code style, maintainability, readability, and language-specific best practices.",
            comprehensive: "Provide a comprehensive review covering security, performance, maintainability, and best practices."
        };

        return `Please review this ${language} code with ${reviewFocus[reviewType as keyof typeof reviewFocus]}

## Code to Review:
\`\`\`${language}
${code}
\`\`\`

## Please provide:
1. **Overall Assessment**: Brief summary of code quality
2. **Specific Issues**: List any problems found with line references where possible
3. **Recommendations**: Actionable suggestions for improvement
4. **Best Practices**: Language-specific recommendations
5. **Security Considerations**: Any security concerns (if applicable)

Format your response clearly with sections and bullet points for easy reading.`;
    }

    private generateMockAnalysis(code: string, language: string, reviewType: string): any {
        // Provide a realistic mock analysis when Azure AI isn't available
        const analysis = {
            status: "mock_analysis",
            message: "Azure AI not configured - showing mock analysis for demonstration",
            analysis: {
                overall_assessment: `This ${language} code appears to be ${code.length > 100 ? 'well-structured' : 'concise'} with ${this.countFunctions(code)} functions detected.`,
                issues: this.generateMockIssues(code, language),
                recommendations: this.generateMockRecommendations(reviewType),
                best_practices: [
                    `Follow ${language} naming conventions`,
                    "Add comprehensive error handling",
                    "Include unit tests for all functions",
                    "Document complex logic with comments"
                ],
                security_notes: reviewType === 'security' || reviewType === 'comprehensive' ? [
                    "Validate all user inputs",
                    "Use parameterized queries for database operations",
                    "Implement proper authentication and authorization"
                ] : []
            },
            note: "This is a mock analysis. Configure Azure AI credentials for real LLM-powered analysis."
        };

        return {
            type: 'text',
            text: JSON.stringify(analysis, null, 2)
        };
    }

    private countFunctions(code: string): number {
        // Simple function detection
        const functionPatterns = [
            /function\s+\w+/g,
            /const\s+\w+\s*=\s*\(/g,
            /\w+\s*:\s*\(/g,
            /def\s+\w+/g  // Python
        ];
        
        let count = 0;
        functionPatterns.forEach(pattern => {
            const matches = code.match(pattern);
            if (matches) count += matches.length;
        });
        
        return count;
    }

    private generateMockIssues(code: string, language: string): string[] {
        const issues = [];
        
        if (code.includes('console.log')) {
            issues.push("Remove console.log statements before production");
        }
        
        if (code.includes('TODO') || code.includes('FIXME')) {
            issues.push("Address TODO/FIXME comments");
        }
        
        if (!code.includes('try') && !code.includes('catch') && code.length > 200) {
            issues.push("Consider adding error handling for robustness");
        }
        
        if (language === 'javascript' || language === 'typescript') {
            if (code.includes('var ')) {
                issues.push("Use 'const' or 'let' instead of 'var'");
            }
        }
        
        return issues.length > 0 ? issues : ["No obvious issues detected in this code sample"];
    }

    private generateMockRecommendations(reviewType: string): string[] {
        const baseRecommendations = [
            "Add comprehensive documentation",
            "Implement unit tests",
            "Consider edge cases and error scenarios"
        ];

        const typeSpecific = {
            security: [
                "Implement input validation",
                "Use secure coding practices",
                "Review for injection vulnerabilities"
            ],
            performance: [
                "Profile for bottlenecks",
                "Optimize algorithm complexity",
                "Consider caching strategies"
            ],
            best_practices: [
                "Follow SOLID principles",
                "Use meaningful variable names",
                "Refactor large functions"
            ],
            comprehensive: [
                "Apply security best practices",
                "Optimize for performance",
                "Follow coding standards"
            ]
        };

        return [...baseRecommendations, ...(typeSpecific[reviewType as keyof typeof typeSpecific] || [])];
    }
}
