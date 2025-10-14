# Part 5: AI Integration

> **Navigation**: [Workshop Home](../README.md) | [Windows Path](README.md) | [← Part 4](part-4-copilot-integration.md)

## Overview

In this final part, we'll explore advanced AI integration scenarios using Azure AI Foundry (formerly Azure AI Studio) with your MCP server. You'll learn how to enhance your tools with Azure AI services, implement more sophisticated AI workflows, and create intelligent automation pipelines that work seamlessly with GitHub Copilot.

## Learning Objectives

- Set up Azure AI Foundry for advanced AI scenarios
- Integrate Azure Cognitive Services with your MCP tools
- Implement intelligent document processing workflows
- Create AI-powered code analysis pipelines
- Build custom AI models for specific use cases
- Monitor and optimize AI service usage

## Prerequisites

- Completed [Part 4: Copilot Integration](part-4-copilot-integration.md)
- Azure subscription with AI services permissions
- Understanding of Azure Cognitive Services
- Basic knowledge of machine learning concepts

## Azure AI Foundry Setup

### 1. Create AI Foundry Workspace

Azure AI Foundry provides a unified platform for building, training, and deploying AI models.

```powershell
# Set up variables
$aiResourceGroup = "rg-ai-mcp-workshop"
$aiWorkspace = "ai-mcp-workspace"
$location = "East US"

# Create resource group for AI resources
az group create --name $aiResourceGroup --location $location

# Create AI Foundry workspace
az ml workspace create --resource-group $aiResourceGroup --name $aiWorkspace --location $location
```

### 2. Create Cognitive Services Multi-Service Account

```powershell
$cognitiveServices = "cog-mcp-workshop"

az cognitiveservices account create `
  --name $cognitiveServices `
  --resource-group $aiResourceGroup `
  --kind CognitiveServices `
  --sku S0 `
  --location $location `
  --custom-domain $cognitiveServices
```

### 3. Get API Keys and Endpoints

```powershell
# Get Cognitive Services key and endpoint
$cognitiveKey = az cognitiveservices account keys list --name $cognitiveServices --resource-group $aiResourceGroup --query "key1" --output tsv
$cognitiveEndpoint = az cognitiveservices account show --name $cognitiveServices --resource-group $aiResourceGroup --query "properties.endpoint" --output tsv

Write-Host "Cognitive Services Key: $cognitiveKey"
Write-Host "Cognitive Services Endpoint: $cognitiveEndpoint"
```

## Enhanced MCP Tools with AI Services

### 1. AI-Powered Document Intelligence

Let's enhance our `markdown_review` tool with Azure AI Document Intelligence:

Create `src/ai-services/document-intelligence.ts`:

```typescript
import { DocumentAnalysisClient, AzureKeyCredential } from "@azure/ai-form-recognizer";

export interface DocumentIntelligenceConfig {
    endpoint: string;
    key: string;
}

export class DocumentIntelligenceService {
    private client: DocumentAnalysisClient;

    constructor(config: DocumentIntelligenceConfig) {
        this.client = new DocumentAnalysisClient(
            config.endpoint,
            new AzureKeyCredential(config.key)
        );
    }

    async analyzeDocument(content: string): Promise<any> {
        try {
            // Convert markdown to analyze its structure
            const poller = await this.client.beginAnalyzeDocument(
                "prebuilt-document",
                Buffer.from(content, 'utf-8'),
                {
                    contentType: "text/plain"
                }
            );

            const result = await poller.pollUntilDone();
            
            return {
                structure: this.extractStructureInsights(result),
                suggestions: this.generateStructuralSuggestions(result),
                readability: this.analyzeReadability(result)
            };
        } catch (error) {
            console.error('Document Intelligence analysis failed:', error);
            return {
                error: 'Document analysis unavailable',
                suggestions: []
            };
        }
    }

    private extractStructureInsights(result: any): any {
        // Extract document structure insights
        return {
            headingHierarchy: result.paragraphs?.filter((p: any) => p.role === 'title'),
            lists: result.paragraphs?.filter((p: any) => p.role === 'listItem'),
            tables: result.tables?.length || 0,
            keyValuePairs: result.keyValuePairs?.length || 0
        };
    }

    private generateStructuralSuggestions(result: any): string[] {
        const suggestions: string[] = [];
        
        // Analyze heading structure
        const headings = result.paragraphs?.filter((p: any) => p.role === 'title') || [];
        if (headings.length === 0) {
            suggestions.push("Consider adding headings to improve document structure");
        }
        
        // Analyze content organization
        if (result.paragraphs && result.paragraphs.length > 10) {
            const sections = headings.length;
            if (sections < 3) {
                suggestions.push("Long document would benefit from more section headings");
            }
        }

        return suggestions;
    }

    private analyzeReadability(result: any): any {
        const paragraphs = result.paragraphs || [];
        const totalWords = paragraphs.reduce((sum: number, p: any) => {
            return sum + (p.content?.split(' ').length || 0);
        }, 0);

        const avgWordsPerParagraph = paragraphs.length > 0 ? totalWords / paragraphs.length : 0;

        return {
            totalWords,
            paragraphCount: paragraphs.length,
            avgWordsPerParagraph,
            readabilityScore: this.calculateReadabilityScore(avgWordsPerParagraph)
        };
    }

    private calculateReadabilityScore(avgWords: number): string {
        if (avgWords < 20) return "Very Easy";
        if (avgWords < 50) return "Easy";
        if (avgWords < 100) return "Moderate";
        if (avgWords < 150) return "Difficult";
        return "Very Difficult";
    }
}
```

### 2. Advanced Code Analysis with Azure OpenAI

Enhance the `ai_code_review` tool with Azure OpenAI:

Create `src/ai-services/openai-service.ts`:

```typescript
import { OpenAIClient, AzureKeyCredential } from "@azure/openai";

export interface OpenAIConfig {
    endpoint: string;
    key: string;
    deploymentId: string;
}

export class OpenAIService {
    private client: OpenAIClient;
    private deploymentId: string;

    constructor(config: OpenAIConfig) {
        this.client = new OpenAIClient(
            config.endpoint,
            new AzureKeyCredential(config.key)
        );
        this.deploymentId = config.deploymentId;
    }

    async performAdvancedCodeReview(code: string, language: string): Promise<any> {
        const prompt = this.buildCodeReviewPrompt(code, language);
        
        try {
            const response = await this.client.getChatCompletions(
                this.deploymentId,
                {
                    messages: [
                        {
                            role: "system",
                            content: "You are an expert code reviewer with deep knowledge of software engineering best practices, security, and performance optimization."
                        },
                        {
                            role: "user",
                            content: prompt
                        }
                    ],
                    maxTokens: 1500,
                    temperature: 0.3
                }
            );

            const analysis = response.choices[0]?.message?.content || "";
            return this.parseCodeReviewResponse(analysis);
        } catch (error) {
            console.error('OpenAI code review failed:', error);
            return {
                error: 'Advanced code review unavailable',
                suggestions: [],
                score: 70
            };
        }
    }

    private buildCodeReviewPrompt(code: string, language: string): string {
        return `
Please perform a comprehensive code review of the following ${language} code:

\`\`\`${language}
${code}
\`\`\`

Analyze the code for:
1. **Security Issues**: Identify potential security vulnerabilities
2. **Performance**: Suggest performance optimizations
3. **Best Practices**: Check adherence to ${language} best practices
4. **Maintainability**: Assess code readability and maintainability
5. **Error Handling**: Evaluate error handling patterns
6. **Testing**: Suggest testing strategies

Please provide:
- A numerical score (0-100)
- Specific suggestions with line references where applicable
- Priority levels (Critical, High, Medium, Low)
- Code examples for improvements where helpful

Format your response as structured analysis with clear sections.
        `;
    }

    private parseCodeReviewResponse(response: string): any {
        // Parse the OpenAI response into structured format
        const lines = response.split('\n');
        const suggestions: any[] = [];
        let score = 75; // Default score
        
        // Extract score
        const scoreMatch = response.match(/score[:\s]*(\d+)/i);
        if (scoreMatch) {
            score = parseInt(scoreMatch[1]);
        }

        // Extract suggestions (simplified parsing)
        let currentSuggestion: any = null;
        
        for (const line of lines) {
            const trimmed = line.trim();
            
            // Look for priority indicators
            if (trimmed.match(/^(Critical|High|Medium|Low):/i)) {
                if (currentSuggestion) {
                    suggestions.push(currentSuggestion);
                }
                currentSuggestion = {
                    priority: trimmed.split(':')[0].toLowerCase(),
                    message: trimmed.split(':')[1]?.trim() || '',
                    category: 'general'
                };
            } else if (currentSuggestion && trimmed.length > 0) {
                currentSuggestion.message += ' ' + trimmed;
            }
        }
        
        if (currentSuggestion) {
            suggestions.push(currentSuggestion);
        }

        // If no structured suggestions found, create general ones
        if (suggestions.length === 0) {
            suggestions.push({
                priority: 'medium',
                message: response.substring(0, 500) + '...',
                category: 'general'
            });
        }

        return {
            score,
            suggestions,
            analysis: response,
            enhancedByAI: true
        };
    }
}
```

### 3. Update Azure Function Configuration

Update your Azure Function to use AI services:

```powershell
# Add AI service configuration to Function App
az functionapp config appsettings set --name $functionApp --resource-group $resourceGroup --settings `
  "COGNITIVE_SERVICES_KEY=$cognitiveKey" `
  "COGNITIVE_SERVICES_ENDPOINT=$cognitiveEndpoint" `
  "AZURE_OPENAI_ENDPOINT=your-openai-endpoint" `
  "AZURE_OPENAI_KEY=your-openai-key" `
  "AZURE_OPENAI_DEPLOYMENT=your-deployment-name"
```

### 4. Enhanced Tool Implementation

Update `src/tools/markdown-review.ts`:

```typescript
import { DocumentIntelligenceService } from '../ai-services/document-intelligence';

export async function enhancedMarkdownReview(content: string): Promise<any> {
    const config = {
        endpoint: process.env.COGNITIVE_SERVICES_ENDPOINT!,
        key: process.env.COGNITIVE_SERVICES_KEY!
    };

    const documentService = new DocumentIntelligenceService(config);
    
    // Combine traditional analysis with AI insights
    const [traditionalAnalysis, aiAnalysis] = await Promise.all([
        performTraditionalMarkdownAnalysis(content),
        documentService.analyzeDocument(content)
    ]);

    return {
        ...traditionalAnalysis,
        aiInsights: aiAnalysis,
        enhancedSuggestions: combineAnalysisResults(traditionalAnalysis, aiAnalysis),
        confidence: calculateConfidenceScore(traditionalAnalysis, aiAnalysis)
    };
}

function performTraditionalMarkdownAnalysis(content: string): any {
    // Your existing markdown analysis logic
    const suggestions: string[] = [];
    let score = 85;

    // Existing analysis logic...
    
    return { suggestions, score, method: 'traditional' };
}

function combineAnalysisResults(traditional: any, ai: any): any[] {
    const combined = [...traditional.suggestions];
    
    if (ai.suggestions) {
        combined.push(...ai.suggestions.map((s: string) => ({
            type: 'ai-insight',
            message: s,
            confidence: 'high'
        })));
    }

    if (ai.structure) {
        combined.push({
            type: 'structure',
            message: `Document has ${ai.structure.headingHierarchy?.length || 0} headings and ${ai.structure.lists?.length || 0} lists`,
            confidence: 'high'
        });
    }

    return combined;
}

function calculateConfidenceScore(traditional: any, ai: any): number {
    // Calculate confidence based on agreement between analyses
    const baseConfidence = 0.8;
    const aiAvailable = ai && !ai.error ? 0.2 : 0;
    return baseConfidence + aiAvailable;
}
```

## Advanced AI Workflows

### 1. Intelligent Pipeline Automation

Create an AI-powered workflow that automatically:

Create `src/workflows/intelligent-pipeline.ts`:

```typescript
import { OpenAIService } from '../ai-services/openai-service';
import { DocumentIntelligenceService } from '../ai-services/document-intelligence';

export class IntelligentPipeline {
    private openaiService: OpenAIService;
    private documentService: DocumentIntelligenceService;

    constructor() {
        this.openaiService = new OpenAIService({
            endpoint: process.env.AZURE_OPENAI_ENDPOINT!,
            key: process.env.AZURE_OPENAI_KEY!,
            deploymentId: process.env.AZURE_OPENAI_DEPLOYMENT!
        });

        this.documentService = new DocumentIntelligenceService({
            endpoint: process.env.COGNITIVE_SERVICES_ENDPOINT!,
            key: process.env.COGNITIVE_SERVICES_KEY!
        });
    }

    async processProject(projectFiles: { [key: string]: string }): Promise<any> {
        const results = {
            codeReviews: {},
            documentAnalysis: {},
            projectInsights: {},
            recommendations: []
        };

        // Analyze code files
        for (const [filename, content] of Object.entries(projectFiles)) {
            if (this.isCodeFile(filename)) {
                const language = this.detectLanguage(filename);
                results.codeReviews[filename] = await this.openaiService.performAdvancedCodeReview(content, language);
            } else if (this.isDocumentFile(filename)) {
                results.documentAnalysis[filename] = await this.documentService.analyzeDocument(content);
            }
        }

        // Generate project-level insights
        results.projectInsights = await this.generateProjectInsights(results);
        results.recommendations = await this.generateActionableRecommendations(results);

        return results;
    }

    private isCodeFile(filename: string): boolean {
        const codeExtensions = ['.ts', '.js', '.py', '.cs', '.java', '.cpp', '.c', '.go', '.rs'];
        return codeExtensions.some(ext => filename.endsWith(ext));
    }

    private isDocumentFile(filename: string): boolean {
        const docExtensions = ['.md', '.txt', '.rst'];
        return docExtensions.some(ext => filename.endsWith(ext));
    }

    private detectLanguage(filename: string): string {
        const ext = filename.split('.').pop()?.toLowerCase();
        const langMap: { [key: string]: string } = {
            'ts': 'typescript',
            'js': 'javascript',
            'py': 'python',
            'cs': 'csharp',
            'java': 'java',
            'cpp': 'cpp',
            'c': 'c',
            'go': 'go',
            'rs': 'rust'
        };
        return langMap[ext || ''] || 'unknown';
    }

    private async generateProjectInsights(results: any): Promise<any> {
        const codeFiles = Object.keys(results.codeReviews);
        const docFiles = Object.keys(results.documentAnalysis);
        
        const avgCodeScore = this.calculateAverageScore(results.codeReviews);
        const totalSuggestions = this.countTotalSuggestions(results.codeReviews);

        return {
            projectHealth: this.assessProjectHealth(avgCodeScore),
            fileCount: { code: codeFiles.length, docs: docFiles.length },
            averageCodeQuality: avgCodeScore,
            totalIssues: totalSuggestions,
            riskAssessment: this.assessRisk(avgCodeScore, totalSuggestions)
        };
    }

    private calculateAverageScore(codeReviews: any): number {
        const scores = Object.values(codeReviews).map((review: any) => review.score || 70);
        return scores.length > 0 ? scores.reduce((a: number, b: number) => a + b) / scores.length : 70;
    }

    private countTotalSuggestions(codeReviews: any): number {
        return Object.values(codeReviews).reduce((total: number, review: any) => {
            return total + (review.suggestions?.length || 0);
        }, 0);
    }

    private assessProjectHealth(avgScore: number): string {
        if (avgScore >= 90) return 'Excellent';
        if (avgScore >= 80) return 'Good';
        if (avgScore >= 70) return 'Fair';
        if (avgScore >= 60) return 'Poor';
        return 'Critical';
    }

    private assessRisk(avgScore: number, totalIssues: number): string {
        if (avgScore < 60 || totalIssues > 20) return 'High';
        if (avgScore < 75 || totalIssues > 10) return 'Medium';
        return 'Low';
    }

    private async generateActionableRecommendations(results: any): Promise<string[]> {
        const recommendations: string[] = [];
        
        const insights = results.projectInsights;
        
        if (insights.averageCodeQuality < 70) {
            recommendations.push("Priority: Improve code quality through refactoring and code reviews");
        }
        
        if (insights.totalIssues > 15) {
            recommendations.push("Address high-priority code issues identified in the analysis");
        }
        
        if (insights.riskAssessment === 'High') {
            recommendations.push("Critical: Project requires immediate attention to reduce risk");
        }

        // Add specific recommendations based on code reviews
        const criticalIssues = this.extractCriticalIssues(results.codeReviews);
        criticalIssues.forEach(issue => {
            recommendations.push(`Critical Issue: ${issue}`);
        });

        return recommendations;
    }

    private extractCriticalIssues(codeReviews: any): string[] {
        const critical: string[] = [];
        
        Object.values(codeReviews).forEach((review: any) => {
            if (review.suggestions) {
                review.suggestions.forEach((suggestion: any) => {
                    if (suggestion.priority === 'critical') {
                        critical.push(suggestion.message);
                    }
                });
            }
        });

        return critical;
    }
}
```

### 2. Add Intelligent Pipeline Tool

Add new MCP tool for the intelligent pipeline:

```typescript
// In src/tools/intelligent-pipeline.ts
import { IntelligentPipeline } from '../workflows/intelligent-pipeline';

export const intelligentPipelineTool = {
    name: "intelligent_pipeline",
    description: "Run AI-powered analysis pipeline on entire project",
    inputSchema: {
        type: "object",
        properties: {
            projectFiles: {
                type: "object",
                description: "Object with filename as key and file content as value"
            },
            analysisDepth: {
                type: "string",
                enum: ["quick", "standard", "comprehensive"],
                description: "Depth of analysis to perform"
            }
        },
        required: ["projectFiles"]
    }
};

export async function executeIntelligentPipeline(args: any): Promise<any> {
    const pipeline = new IntelligentPipeline();
    
    try {
        const results = await pipeline.processProject(args.projectFiles);
        
        return {
            success: true,
            analysis: results,
            summary: generateAnalysisSummary(results),
            timestamp: new Date().toISOString()
        };
    } catch (error) {
        console.error('Intelligent pipeline failed:', error);
        return {
            success: false,
            error: error instanceof Error ? error.message : 'Unknown error',
            fallback: "Basic analysis tools are still available"
        };
    }
}

function generateAnalysisSummary(results: any): string {
    const insights = results.projectInsights;
    const recommendations = results.recommendations;
    
    return `
Project Health: ${insights.projectHealth}
Average Code Quality: ${insights.averageCodeQuality}/100
Total Issues Found: ${insights.totalIssues}
Risk Level: ${insights.riskAssessment}

Top Recommendations:
${recommendations.slice(0, 3).map((r: string, i: number) => `${i + 1}. ${r}`).join('\n')}
    `.trim();
}
```

## Testing AI-Enhanced Tools

### 1. Test AI Services Integration

Create comprehensive test script:

```powershell
# Create test-ai-integration.ps1
@"
# Test AI-Enhanced MCP Tools
`$functionUrl = "YOUR_FUNCTION_URL_HERE"

Write-Host "Testing AI-Enhanced MCP Tools"
Write-Host "=============================="

# Test 1: Enhanced Markdown Review
Write-Host "`nTesting enhanced markdown review..."
`$markdownContent = @"
# Project Documentation
This document provides overview of the project.
## Features
- Feature 1
- Feature 2
## Installation
Run npm install to install dependencies
"@

`$reviewBody = @{
    jsonrpc = "2.0"
    id = 1
    method = "tools/call"
    params = @{
        name = "markdown_review"
        arguments = @{
            content = `$markdownContent
        }
    }
} | ConvertTo-Json -Depth 10

try {
    `$response = Invoke-RestMethod -Uri `$functionUrl -Method POST -Body `$reviewBody -ContentType "application/json"
    if (`$response.result.content[0].text) {
        `$analysis = `$response.result.content[0].text | ConvertFrom-Json
        Write-Host "✅ Enhanced markdown review successful"
        Write-Host "   AI Insights Available: `$(`$analysis.aiInsights -ne `$null)"
        Write-Host "   Confidence Score: `$(`$analysis.confidence)"
        Write-Host "   Enhanced Suggestions: `$(`$analysis.enhancedSuggestions.Count)"
    }
} catch {
    Write-Host "❌ Enhanced markdown review failed: `$(`$_.Exception.Message)"
}

# Test 2: Advanced Code Review
Write-Host "`nTesting advanced AI code review..."
`$codeContent = @"
function processData(data) {
    var result = [];
    for (var i = 0; i < data.length; i++) {
        if (data[i].active) {
            result.push(data[i].name.toUpperCase());
        }
    }
    return result;
}
"@

`$codeReviewBody = @{
    jsonrpc = "2.0"
    id = 2
    method = "tools/call"
    params = @{
        name = "ai_code_review"
        arguments = @{
            code = `$codeContent
            language = "javascript"
        }
    }
} | ConvertTo-Json -Depth 10

try {
    `$response = Invoke-RestMethod -Uri `$functionUrl -Method POST -Body `$codeReviewBody -ContentType "application/json"
    if (`$response.result.content[0].text) {
        `$analysis = `$response.result.content[0].text | ConvertFrom-Json
        Write-Host "✅ Advanced code review successful"
        Write-Host "   Enhanced by AI: `$(`$analysis.enhancedByAI)"
        Write-Host "   Code Score: `$(`$analysis.score)/100"
        Write-Host "   AI Suggestions: `$(`$analysis.suggestions.Count)"
    }
} catch {
    Write-Host "❌ Advanced code review failed: `$(`$_.Exception.Message)"
}

# Test 3: Intelligent Pipeline
Write-Host "`nTesting intelligent pipeline..."
`$projectFiles = @{
    "src/app.ts" = @"
class UserService {
    private users: any[] = [];
    
    getUser(id: string) {
        return this.users.find(u => u.id == id);
    }
}
"@
    "README.md" = @"
# My Project
This is my project
"@
}

`$pipelineBody = @{
    jsonrpc = "2.0"
    id = 3
    method = "tools/call"
    params = @{
        name = "intelligent_pipeline"
        arguments = @{
            projectFiles = `$projectFiles
            analysisDepth = "standard"
        }
    }
} | ConvertTo-Json -Depth 10

try {
    `$response = Invoke-RestMethod -Uri `$functionUrl -Method POST -Body `$pipelineBody -ContentType "application/json"
    if (`$response.result.content[0].text) {
        `$analysis = `$response.result.content[0].text | ConvertFrom-Json
        Write-Host "✅ Intelligent pipeline successful"
        Write-Host "   Project Health: `$(`$analysis.analysis.projectInsights.projectHealth)"
        Write-Host "   Risk Level: `$(`$analysis.analysis.projectInsights.riskAssessment)"
        Write-Host "   Recommendations: `$(`$analysis.analysis.recommendations.Count)"
    }
} catch {
    Write-Host "❌ Intelligent pipeline failed: `$(`$_.Exception.Message)"
}

Write-Host "`nAI Integration Testing Complete!"
"@ | Out-File -FilePath "test-ai-integration.ps1" -Encoding UTF8

# Run the test
.\test-ai-integration.ps1
```

### 2. Performance Monitoring

Monitor AI service usage and costs:

```powershell
# Monitor Cognitive Services usage
az cognitiveservices account list-usage --name $cognitiveServices --resource-group $aiResourceGroup

# Monitor costs
az consumption usage list --start-date "2024-01-01" --end-date "2024-12-31" | Where-Object { $_.meterName -like "*Cognitive*" }

# Set up cost alerts
az consumption budget create --resource-group $aiResourceGroup --budget-name "ai-services-budget" --amount 50 --time-grain Monthly
```

## Production Considerations

### 1. Cost Optimization

```powershell
# Create cost monitoring script
@"
# AI Services Cost Monitor
Write-Host "AI Services Cost Analysis"
Write-Host "========================"

# Get current month usage
`$currentMonth = Get-Date -Format "yyyy-MM"
`$usage = az consumption usage list --start-date "`$currentMonth-01" | ConvertFrom-Json

# Filter AI-related costs
`$aiCosts = `$usage | Where-Object { 
    `$_.meterName -like "*Cognitive*" -or 
    `$_.meterName -like "*OpenAI*" -or 
    `$_.meterName -like "*Form*" 
}

if (`$aiCosts) {
    `$totalCost = (`$aiCosts | Measure-Object -Property pretaxCost -Sum).Sum
    Write-Host "Total AI Services Cost This Month: `$$totalCost"
    
    `$aiCosts | ForEach-Object {
        Write-Host "- `$(`$_.meterName): `$$(`$_.pretaxCost)"
    }
} else {
    Write-Host "No AI services costs found for current month"
}

# Check quotas
Write-Host "`nAI Services Quotas:"
az cognitiveservices account list-usage --name $cognitiveServices --resource-group $aiResourceGroup
"@ | Out-File -FilePath "monitor-ai-costs.ps1" -Encoding UTF8
```

### 2. Security and Compliance

```powershell
# Set up secure key management
az keyvault create --name "kv-mcp-workshop" --resource-group $aiResourceGroup --location $location

# Store AI service keys in Key Vault
az keyvault secret set --vault-name "kv-mcp-workshop" --name "cognitive-services-key" --value $cognitiveKey
az keyvault secret set --vault-name "kv-mcp-workshop" --name "openai-key" --value "your-openai-key"

# Grant Function App access to Key Vault
$functionPrincipalId = az functionapp identity assign --name $functionApp --resource-group $resourceGroup --query "principalId" --output tsv
az keyvault set-policy --name "kv-mcp-workshop" --object-id $functionPrincipalId --secret-permissions get list

# Update Function App to use Key Vault references
az functionapp config appsettings set --name $functionApp --resource-group $resourceGroup --settings `
  "COGNITIVE_SERVICES_KEY=@Microsoft.KeyVault(SecretUri=https://kv-mcp-workshop.vault.azure.net/secrets/cognitive-services-key/)" `
  "AZURE_OPENAI_KEY=@Microsoft.KeyVault(SecretUri=https://kv-mcp-workshop.vault.azure.net/secrets/openai-key/)"
```

### 3. Scaling and Performance

```powershell
# Configure auto-scaling for Function App
az functionapp config set --name $functionApp --resource-group $resourceGroup --always-on true

# Set up Application Insights for monitoring
$appInsights = "ai-mcp-monitor"
az monitor app-insights component create --app $appInsights --location $location --resource-group $resourceGroup

$instrumentationKey = az monitor app-insights component show --app $appInsights --resource-group $resourceGroup --query "instrumentationKey" --output tsv

az functionapp config appsettings set --name $functionApp --resource-group $resourceGroup --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$instrumentationKey"
```

## Advanced Use Cases

### 1. Continuous Code Quality Monitoring

Set up automated code quality monitoring:

```typescript
// Create webhook endpoint for GitHub integration
export const codeQualityWebhook = {
    name: "code_quality_webhook",
    description: "Webhook for continuous code quality monitoring",
    inputSchema: {
        type: "object",
        properties: {
            repository: { type: "string" },
            commit: { type: "string" },
            files: {
                type: "array",
                items: {
                    type: "object",
                    properties: {
                        filename: { type: "string" },
                        content: { type: "string" },
                        status: { type: "string" }
                    }
                }
            }
        },
        required: ["repository", "commit", "files"]
    }
};

export async function executeCodeQualityWebhook(args: any): Promise<any> {
    const pipeline = new IntelligentPipeline();
    
    // Analyze only changed files
    const changedFiles: { [key: string]: string } = {};
    args.files
        .filter((f: any) => f.status === 'modified' || f.status === 'added')
        .forEach((f: any) => {
            changedFiles[f.filename] = f.content;
        });

    const results = await pipeline.processProject(changedFiles);
    
    // Generate quality report
    const report = {
        repository: args.repository,
        commit: args.commit,
        qualityScore: results.projectInsights.averageCodeQuality,
        riskLevel: results.projectInsights.riskAssessment,
        criticalIssues: results.recommendations.filter((r: string) => r.includes('Critical')),
        summary: generateQualityReport(results)
    };

    // Could integrate with GitHub status API here
    
    return report;
}
```

### 2. Documentation Generation

Auto-generate documentation from code:

```typescript
export const documentationGenerator = {
    name: "generate_documentation",
    description: "AI-powered documentation generation from code",
    inputSchema: {
        type: "object",
        properties: {
            codeFiles: { type: "object" },
            format: { 
                type: "string", 
                enum: ["markdown", "html", "pdf"],
                default: "markdown"
            },
            includeExamples: { type: "boolean", default: true }
        },
        required: ["codeFiles"]
    }
};

export async function executeDocumentationGenerator(args: any): Promise<any> {
    const openaiService = new OpenAIService({
        endpoint: process.env.AZURE_OPENAI_ENDPOINT!,
        key: process.env.AZURE_OPENAI_KEY!,
        deploymentId: process.env.AZURE_OPENAI_DEPLOYMENT!
    });

    const documentation: { [key: string]: string } = {};
    
    for (const [filename, content] of Object.entries(args.codeFiles)) {
        const language = detectLanguage(filename);
        const prompt = buildDocumentationPrompt(content as string, language, args.includeExamples);
        
        try {
            const response = await openaiService.client.getChatCompletions(
                openaiService.deploymentId,
                {
                    messages: [
                        {
                            role: "system",
                            content: "You are a technical documentation expert. Generate clear, comprehensive documentation for code."
                        },
                        {
                            role: "user",
                            content: prompt
                        }
                    ],
                    maxTokens: 2000,
                    temperature: 0.3
                }
            );

            documentation[filename] = response.choices[0]?.message?.content || "Documentation generation failed";
        } catch (error) {
            documentation[filename] = `Error generating documentation: ${error}`;
        }
    }

    return {
        documentation,
        format: args.format,
        generatedAt: new Date().toISOString(),
        summary: `Generated documentation for ${Object.keys(documentation).length} files`
    };
}

function buildDocumentationPrompt(code: string, language: string, includeExamples: boolean): string {
    return `
Generate comprehensive documentation for this ${language} code:

\`\`\`${language}
${code}
\`\`\`

Please include:
- Overview and purpose
- Function/class descriptions
- Parameter documentation
- Return value descriptions
- Usage notes
${includeExamples ? '- Code examples' : ''}
- Best practices

Format the output as clean markdown.
    `;
}
```

## Monitoring and Analytics Dashboard

### 1. Create Analytics Dashboard

```powershell
# Create analytics query for Application Insights
$analyticsQuery = @"
let timeRange = ago(7d);
requests
| where timestamp > timeRange
| where name == "mcp"
| extend toolName = tostring(customDimensions.tool_name)
| extend aiEnhanced = tostring(customDimensions.ai_enhanced) == "true"
| summarize 
    TotalCalls = count(),
    AIEnhancedCalls = countif(aiEnhanced),
    AvgDuration = avg(duration),
    SuccessRate = avg(toint(resultCode < 400)) * 100
    by toolName, bin(timestamp, 1h)
| order by timestamp desc
"@

Write-Host "Application Insights Analytics Query:"
Write-Host $analyticsQuery
Write-Host ""
Write-Host "Use this query in Application Insights to monitor AI-enhanced tool usage"
```

### 2. Cost Analysis

```powershell
# Create cost analysis script
@"
# AI Services Cost Analysis
Write-Host "Detailed AI Services Cost Analysis"
Write-Host "================================="

# Get detailed usage metrics
`$cognitiveUsage = az cognitiveservices account list-usage --name $cognitiveServices --resource-group $aiResourceGroup | ConvertFrom-Json

Write-Host "Cognitive Services Usage:"
`$cognitiveUsage | ForEach-Object {
    Write-Host "- `$(`$_.name.value): `$(`$_.currentValue)/`$(`$_.limit) (`$((`$_.currentValue/`$_.limit)*100)%)"
}

# Calculate cost per tool usage
Write-Host "`nCost Per Tool Analysis:"
Write-Host "- Document Intelligence: ~`$0.001 per page"
Write-Host "- GPT-4 Turbo: ~`$0.01 per 1K tokens"
Write-Host "- Text Analytics: ~`$0.0005 per record"

Write-Host "`nOptimization Recommendations:"
Write-Host "1. Cache frequent analysis results"
Write-Host "2. Use batch processing for multiple files"
Write-Host "3. Implement rate limiting for cost control"
Write-Host "4. Consider using smaller models for simple tasks"
"@ | Out-File -FilePath "ai-cost-analysis.ps1" -Encoding UTF8
```

## Next Steps and Future Enhancements

### What We Accomplished

- ✅ Set up Azure AI Foundry workspace for advanced AI scenarios
- ✅ Integrated Azure Cognitive Services with MCP tools
- ✅ Enhanced tools with Azure OpenAI for intelligent analysis
- ✅ Created intelligent automation pipelines
- ✅ Implemented cost monitoring and optimization
- ✅ Built advanced use cases for continuous quality monitoring
- ✅ Created documentation generation capabilities

### Key Takeaways

1. **AI Enhancement**: Azure AI services significantly improve tool capabilities
2. **Cost Management**: Proper monitoring is essential for production use
3. **Pipeline Automation**: AI-powered workflows can automate complex tasks
4. **Scalability**: Azure services provide enterprise-grade scaling
5. **Security**: Key Vault integration ensures secure credential management

### Future Enhancement Ideas

1. **Custom Model Training**: Train specialized models for your domain
2. **Multi-Modal Analysis**: Integrate vision and speech services
3. **Real-Time Collaboration**: Build live collaboration features
4. **Advanced Analytics**: Implement predictive analytics for code quality
5. **Integration Hub**: Connect with more development tools and services

### Workshop Completion

Congratulations! You have successfully completed the comprehensive MCP workshop. You now have:

- A fully functional MCP server deployed to Azure Functions
- Integration with GitHub Copilot for enhanced AI assistance  
- Advanced AI capabilities through Azure AI services
- Production-ready monitoring and cost management
- Automation pipelines for continuous quality improvement

Your MCP server is now a powerful AI-enhanced tool that can significantly improve your development workflow and code quality!

---

> **Navigation**: [Workshop Home](../README.md) | [Windows Path](README.md) | [← Part 4](part-4-copilot-integration.md)

## Resources and Further Learning

- [Azure AI Foundry Documentation](https://docs.microsoft.com/azure/ai-services/)
- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)
- [Azure Functions Best Practices](https://docs.microsoft.com/azure/azure-functions/functions-best-practices)
- [GitHub Copilot Extensions](https://docs.github.com/copilot/building-copilot-extensions)
- [Azure OpenAI Service](https://docs.microsoft.com/azure/cognitive-services/openai/)