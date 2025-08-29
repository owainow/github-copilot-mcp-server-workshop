import { MCPTool } from '../mcp/server';
import { Logger } from '../shared/logger';
import { marked } from 'marked';

/**
 * Markdown Review Tool for GitHub Copilot
 * Provides comprehensive analysis and suggestions for markdown content
 */
export class MarkdownReviewTool implements MCPTool {
    name = 'markdown_review';
    description = 'Analyze and provide improvement suggestions for markdown content including grammar, structure, links, and accessibility';
    
    parameters = {
        content: {
            type: 'string',
            description: 'The markdown content to review'
        },
        analysis_type: {
            type: 'string',
            description: 'Type of analysis to perform: basic, comprehensive, or accessibility',
            enum: ['basic', 'comprehensive', 'accessibility'],
            default: 'comprehensive'
        }
    };

    private logger: Logger;

    constructor(logger: Logger) {
        this.logger = logger;
    }

    async execute(args: Record<string, any>): Promise<any> {
        const startTime = Date.now();
        
        try {
            const { content, analysis_type = 'comprehensive' } = args;

            if (!content || typeof content !== 'string') {
                throw new Error('Content parameter is required and must be a string');
            }

            this.logger.info('Starting markdown review', {
                contentLength: content.length,
                analysisType: analysis_type
            });

            const analysis = await this.analyzeMarkdown(content, analysis_type);
            
            this.logger.logPerformance('markdown_review', startTime, true, {
                issuesFound: analysis.issues.length,
                analysisType: analysis_type
            });

            return analysis;

        } catch (error) {
            this.logger.error('Markdown review failed', { error, args });
            this.logger.logPerformance('markdown_review', startTime, false);
            throw error;
        }
    }

    private async analyzeMarkdown(content: string, analysisType: string): Promise<any> {
        const analysis = {
            summary: {
                contentLength: content.length,
                lineCount: content.split('\n').length,
                analysisType,
                timestamp: new Date().toISOString()
            },
            issues: [] as any[],
            suggestions: [] as any[],
            metrics: {
                headingStructure: this.analyzeHeadingStructure(content),
                linkAnalysis: this.analyzeLinks(content),
                codeBlockAnalysis: this.analyzeCodeBlocks(content)
            }
        };

        // Basic analysis
        analysis.issues.push(...this.findBasicIssues(content));
        analysis.suggestions.push(...this.getBasicSuggestions(content));

        // Comprehensive analysis
        if (analysisType === 'comprehensive' || analysisType === 'accessibility') {
            analysis.issues.push(...this.findStructuralIssues(content));
            analysis.suggestions.push(...this.getStructuralSuggestions(content));
        }

        // Accessibility analysis
        if (analysisType === 'accessibility') {
            analysis.issues.push(...this.findAccessibilityIssues(content));
            analysis.suggestions.push(...this.getAccessibilitySuggestions(content));
        }

        // Calculate quality score based on analysis results
        const qualityScore = this.calculateQualityScore(analysis, content);
        (analysis as any).qualityScore = qualityScore;

        return analysis;
    }

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

    private hasSkippedHeadingLevels(structure: any[]): boolean {
        for (let i = 1; i < structure.length; i++) {
            if (structure[i].level > structure[i - 1].level + 1) {
                return true;
            }
        }
        return false;
    }

    private analyzeLinks(content: string): any {
        const links = content.match(/\[([^\]]+)\]\(([^)]+)\)/g) || [];
        const imageLinks = content.match(/!\[([^\]]*)\]\(([^)]+)\)/g) || [];
        
        return {
            totalLinks: links.length,
            totalImages: imageLinks.length,
            links: links.map(link => {
                const match = link.match(/\[([^\]]+)\]\(([^)]+)\)/);
                return {
                    text: match?.[1],
                    url: match?.[2],
                    isExternal: match?.[2]?.startsWith('http'),
                    hasAltText: (match?.[1]?.length ?? 0) > 0
                };
            })
        };
    }

    private analyzeCodeBlocks(content: string): any {
        const codeBlocks = content.match(/```[\s\S]*?```/g) || [];
        const inlineCode = content.match(/`[^`]+`/g) || [];

        return {
            totalCodeBlocks: codeBlocks.length,
            totalInlineCode: inlineCode.length,
            codeBlocks: codeBlocks.map(block => {
                const language = block.match(/```(\w+)/)?.[1] || 'none';
                return { language, hasLanguage: language !== 'none' };
            })
        };
    }

    private findBasicIssues(content: string): any[] {
        const issues = [];

        // Check for common markdown issues
        if (content.includes('](')) {
            const brokenLinks = content.match(/\]\(\s*\)/g);
            if (brokenLinks) {
                issues.push({
                    type: 'broken_link',
                    severity: 'high',
                    message: `Found ${brokenLinks.length} empty link(s)`,
                    count: brokenLinks.length
                });
            }
        }

        // Check for missing alt text in images
        const imagesWithoutAlt = content.match(/!\[\s*\]\([^)]+\)/g);
        if (imagesWithoutAlt) {
            issues.push({
                type: 'missing_alt_text',
                severity: 'medium',
                message: `Found ${imagesWithoutAlt.length} image(s) without alt text`,
                count: imagesWithoutAlt.length
            });
        }

        // Check for consecutive blank lines
        if (content.includes('\n\n\n')) {
            issues.push({
                type: 'excessive_blank_lines',
                severity: 'low',
                message: 'Found multiple consecutive blank lines',
                suggestion: 'Use single blank lines for better readability'
            });
        }

        return issues;
    }

    private getBasicSuggestions(content: string): any[] {
        const suggestions = [];

        // Table of contents suggestion
        const headingMatches = content.match(/^#{1,6}\s+.+$/gm);
        if (headingMatches && headingMatches.length > 3) {
            suggestions.push({
                type: 'table_of_contents',
                priority: 'medium',
                message: 'Consider adding a table of contents for better navigation',
                implementation: 'Add <!-- TOC --> comment where you want the table of contents'
            });
        }

        // Code language suggestion
        const codeBlocksWithoutLanguage = content.match(/```\n/g);
        if (codeBlocksWithoutLanguage) {
            suggestions.push({
                type: 'code_language',
                priority: 'medium',
                message: 'Specify language for code blocks to enable syntax highlighting',
                example: '```javascript\ncode here\n```'
            });
        }

        return suggestions;
    }

    private findStructuralIssues(content: string): any[] {
        const issues = [];
        const headingStructure = this.analyzeHeadingStructure(content);

        // Check heading structure
        if (!headingStructure.hasH1) {
            issues.push({
                type: 'missing_h1',
                severity: 'medium',
                message: 'Document should have at least one H1 heading',
                suggestion: 'Add a main title using # at the beginning of your document'
            });
        }

        if (headingStructure.hasSkippedLevels) {
            issues.push({
                type: 'skipped_heading_levels',
                severity: 'medium',
                message: 'Heading levels are not sequential',
                suggestion: 'Use consecutive heading levels (H1, H2, H3) for better structure'
            });
        }

        return issues;
    }

    private getStructuralSuggestions(content: string): any[] {
        const suggestions = [];

        // Document structure suggestions
        if (!content.includes('## ') && content.includes('# ')) {
            suggestions.push({
                type: 'document_structure',
                priority: 'low',
                message: 'Consider breaking long content into sections with H2 headings',
                benefit: 'Improves readability and navigation'
            });
        }

        return suggestions;
    }

    private findAccessibilityIssues(content: string): any[] {
        const issues = [];

        // Check for images without alt text (accessibility critical)
        const imagesWithoutAlt = content.match(/!\[\s*\]\([^)]+\)/g);
        if (imagesWithoutAlt) {
            issues.push({
                type: 'accessibility_alt_text',
                severity: 'high',
                message: 'Images without alt text are not accessible to screen readers',
                count: imagesWithoutAlt.length,
                wcagGuideline: 'WCAG 2.1 Level A - 1.1.1 Non-text Content'
            });
        }

        // Check for poor link text
        const genericLinkText = content.match(/\[(click here|here|link|read more)\]\(/gi);
        if (genericLinkText) {
            issues.push({
                type: 'accessibility_link_text',
                severity: 'medium',
                message: 'Generic link text is not descriptive for screen readers',
                count: genericLinkText.length,
                wcagGuideline: 'WCAG 2.1 Level AA - 2.4.4 Link Purpose'
            });
        }

        return issues;
    }

    private getAccessibilitySuggestions(content: string): any[] {
        const suggestions = [];

        suggestions.push({
            type: 'accessibility_best_practices',
            priority: 'high',
            message: 'Follow accessibility best practices',
            practices: [
                'Use descriptive alt text for images',
                'Write descriptive link text',
                'Use proper heading hierarchy',
                'Ensure sufficient color contrast in images',
                'Provide context for code examples'
            ]
        });

        return suggestions;
    }

    private calculateQualityScore(analysis: any, content: string): number {
        let score = 100;
        
        // Deduct points for issues by severity
        for (const issue of analysis.issues) {
            switch (issue.severity) {
                case 'high':
                    score -= 15;
                    break;
                case 'medium':
                    score -= 8;
                    break;
                case 'low':
                    score -= 3;
                    break;
                default:
                    score -= 5;
            }
        }

        // Deduct points for content quality issues
        const contentLength = content.length;
        if (contentLength < 50) {
            score -= 10; // Very short content
        }

        // Deduct points for poor structure
        if (!analysis.metrics.headingStructure.hasH1) {
            score -= 10; // Missing H1
        }
        
        if (analysis.metrics.headingStructure.hasSkippedLevels) {
            score -= 5; // Poor heading hierarchy
        }

        // Bonus points for good structure
        if (analysis.metrics.headingStructure.totalHeadings > 1 && !analysis.metrics.headingStructure.hasSkippedLevels) {
            score += 5; // Good heading structure
        }

        // Ensure score is between 0 and 100
        return Math.max(0, Math.min(100, score));
    }
}
