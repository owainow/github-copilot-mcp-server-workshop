# Part 5: AI Integration

> **Navigation**: [Workshop Home](../README.md) | [Linux Path](README.md) | [← Part 4](part-4-copilot-integration.md)

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

```bash
# Set up variables
AI_RESOURCE_GROUP="rg-ai-mcp-workshop"
AI_WORKSPACE="ai-mcp-workspace"
LOCATION="eastus"

# Create resource group for AI resources
az group create --name $AI_RESOURCE_GROUP --location $LOCATION

# Create AI Foundry workspace
az ml workspace create --resource-group $AI_RESOURCE_GROUP --name $AI_WORKSPACE --location $LOCATION
```

### 2. Create Cognitive Services Multi-Service Account

```bash
COGNITIVE_SERVICES="cog-mcp-workshop"

az cognitiveservices account create \
  --name $COGNITIVE_SERVICES \
  --resource-group $AI_RESOURCE_GROUP \
  --kind CognitiveServices \
  --sku S0 \
  --location $LOCATION \
  --custom-domain $COGNITIVE_SERVICES
```

### 3. Get API Keys and Endpoints

```bash
# Get Cognitive Services key and endpoint
COGNITIVE_KEY=$(az cognitiveservices account keys list --name $COGNITIVE_SERVICES --resource-group $AI_RESOURCE_GROUP --query "key1" --output tsv)
COGNITIVE_ENDPOINT=$(az cognitiveservices account show --name $COGNITIVE_SERVICES --resource-group $AI_RESOURCE_GROUP --query "properties.endpoint" --output tsv)

echo "Cognitive Services Key: $COGNITIVE_KEY"
echo "Cognitive Services Endpoint: $COGNITIVE_ENDPOINT"

# Save for reuse
echo "export COGNITIVE_KEY='$COGNITIVE_KEY'" >> ~/.bashrc
echo "export COGNITIVE_ENDPOINT='$COGNITIVE_ENDPOINT'" >> ~/.bashrc
source ~/.bashrc
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

```bash
# Add AI service configuration to Function App
az functionapp config appsettings set --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --settings \
  "COGNITIVE_SERVICES_KEY=$COGNITIVE_KEY" \
  "COGNITIVE_SERVICES_ENDPOINT=$COGNITIVE_ENDPOINT" \
  "AZURE_OPENAI_ENDPOINT=your-openai-endpoint" \
  "AZURE_OPENAI_KEY=your-openai-key" \
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

```bash
# Create test-ai-integration.sh
cat > test-ai-integration.sh << 'EOF'
#!/bin/bash

# Test AI-Enhanced MCP Tools
FUNCTION_URL="$FUNCTION_URL"

echo "Testing AI-Enhanced MCP Tools"
echo "=============================="

# Test 1: Enhanced Markdown Review
echo ""
echo "Testing enhanced markdown review..."

MARKDOWN_CONTENT="# Project Documentation
This document provides overview of the project.
## Features
- Feature 1
- Feature 2
## Installation
Run npm install to install dependencies"

REVIEW_RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"id\": 1,
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"markdown_review\",
      \"arguments\": {
        \"content\": $(echo "$MARKDOWN_CONTENT" | jq -Rs .)
      }
    }
  }")

if echo "$REVIEW_RESPONSE" | jq -e '.result.content[0].text' > /dev/null 2>&1; then
    ANALYSIS=$(echo "$REVIEW_RESPONSE" | jq -r '.result.content[0].text' | jq .)
    echo "✅ Enhanced markdown review successful"
    
    AI_INSIGHTS=$(echo "$ANALYSIS" | jq -r '.aiInsights // "none"')
    CONFIDENCE=$(echo "$ANALYSIS" | jq -r '.confidence // "unknown"')
    SUGGESTIONS_COUNT=$(echo "$ANALYSIS" | jq -r '.enhancedSuggestions | length // 0')
    
    echo "   AI Insights Available: $([ "$AI_INSIGHTS" != "none" ] && echo "Yes" || echo "No")"
    echo "   Confidence Score: $CONFIDENCE"
    echo "   Enhanced Suggestions: $SUGGESTIONS_COUNT"
else
    echo "❌ Enhanced markdown review failed"
    echo "   Response: $REVIEW_RESPONSE"
fi

# Test 2: Advanced Code Review
echo ""
echo "Testing advanced AI code review..."

CODE_CONTENT="function processData(data) {
    var result = [];
    for (var i = 0; i < data.length; i++) {
        if (data[i].active) {
            result.push(data[i].name.toUpperCase());
        }
    }
    return result;
}"

CODE_REVIEW_RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"id\": 2,
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"ai_code_review\",
      \"arguments\": {
        \"code\": $(echo "$CODE_CONTENT" | jq -Rs .),
        \"language\": \"javascript\"
      }
    }
  }")

if echo "$CODE_REVIEW_RESPONSE" | jq -e '.result.content[0].text' > /dev/null 2>&1; then
    ANALYSIS=$(echo "$CODE_REVIEW_RESPONSE" | jq -r '.result.content[0].text' | jq .)
    echo "✅ Advanced code review successful"
    
    ENHANCED_BY_AI=$(echo "$ANALYSIS" | jq -r '.enhancedByAI // false')
    CODE_SCORE=$(echo "$ANALYSIS" | jq -r '.score // "unknown"')
    SUGGESTIONS_COUNT=$(echo "$ANALYSIS" | jq -r '.suggestions | length // 0')
    
    echo "   Enhanced by AI: $ENHANCED_BY_AI"
    echo "   Code Score: $CODE_SCORE/100"
    echo "   AI Suggestions: $SUGGESTIONS_COUNT"
else
    echo "❌ Advanced code review failed"
    echo "   Response: $CODE_REVIEW_RESPONSE"
fi

# Test 3: Intelligent Pipeline
echo ""
echo "Testing intelligent pipeline..."

PROJECT_FILES='{
  "src/app.ts": "class UserService {\n    private users: any[] = [];\n    \n    getUser(id: string) {\n        return this.users.find(u => u.id == id);\n    }\n}",
  "README.md": "# My Project\\nThis is my project"
}'

PIPELINE_RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"id\": 3,
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"intelligent_pipeline\",
      \"arguments\": {
        \"projectFiles\": $PROJECT_FILES,
        \"analysisDepth\": \"standard\"
      }
    }
  }")

if echo "$PIPELINE_RESPONSE" | jq -e '.result.content[0].text' > /dev/null 2>&1; then
    ANALYSIS=$(echo "$PIPELINE_RESPONSE" | jq -r '.result.content[0].text' | jq .)
    echo "✅ Intelligent pipeline successful"
    
    PROJECT_HEALTH=$(echo "$ANALYSIS" | jq -r '.analysis.projectInsights.projectHealth // "unknown"')
    RISK_LEVEL=$(echo "$ANALYSIS" | jq -r '.analysis.projectInsights.riskAssessment // "unknown"')
    RECOMMENDATIONS_COUNT=$(echo "$ANALYSIS" | jq -r '.analysis.recommendations | length // 0')
    
    echo "   Project Health: $PROJECT_HEALTH"
    echo "   Risk Level: $RISK_LEVEL"
    echo "   Recommendations: $RECOMMENDATIONS_COUNT"
else
    echo "❌ Intelligent pipeline failed"
    echo "   Response: $PIPELINE_RESPONSE"
fi

echo ""
echo "AI Integration Testing Complete!"
EOF

chmod +x test-ai-integration.sh
./test-ai-integration.sh
```

### 2. Performance Monitoring

Monitor AI service usage and costs:

```bash
# Monitor Cognitive Services usage
az cognitiveservices account list-usage --name $COGNITIVE_SERVICES --resource-group $AI_RESOURCE_GROUP

# Monitor costs
az consumption usage list --start-date "2024-01-01" --end-date "2024-12-31" | jq '.[] | select(.meterName | contains("Cognitive"))'

# Set up cost alerts
az consumption budget create --resource-group $AI_RESOURCE_GROUP --budget-name "ai-services-budget" --amount 50 --time-grain Monthly
```

## Production Considerations

### 1. Cost Optimization

```bash
# Create cost monitoring script
cat > monitor-ai-costs.sh << 'EOF'
#!/bin/bash

echo "AI Services Cost Analysis"
echo "========================"

# Get current month usage
CURRENT_MONTH=$(date +%Y-%m)
USAGE=$(az consumption usage list --start-date "${CURRENT_MONTH}-01" --output json)

# Filter AI-related costs
AI_COSTS=$(echo "$USAGE" | jq '.[] | select(.meterName | test("Cognitive|OpenAI|Form"; "i"))')

if [ -n "$AI_COSTS" ]; then
    TOTAL_COST=$(echo "$AI_COSTS" | jq '[.pretaxCost] | add')
    echo "Total AI Services Cost This Month: \$$TOTAL_COST"
    
    echo "$AI_COSTS" | jq -r '"- " + .meterName + ": $" + (.pretaxCost | tostring)'
else
    echo "No AI services costs found for current month"
fi

# Check quotas
echo ""
echo "AI Services Quotas:"
az cognitiveservices account list-usage --name $COGNITIVE_SERVICES --resource-group $AI_RESOURCE_GROUP --output table
EOF

chmod +x monitor-ai-costs.sh
```

### 2. Security and Compliance

```bash
# Set up secure key management
az keyvault create --name "kv-mcp-workshop" --resource-group $AI_RESOURCE_GROUP --location $LOCATION

# Store AI service keys in Key Vault
az keyvault secret set --vault-name "kv-mcp-workshop" --name "cognitive-services-key" --value "$COGNITIVE_KEY"
az keyvault secret set --vault-name "kv-mcp-workshop" --name "openai-key" --value "your-openai-key"

# Grant Function App access to Key Vault
FUNCTION_PRINCIPAL_ID=$(az functionapp identity assign --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --query "principalId" --output tsv)
az keyvault set-policy --name "kv-mcp-workshop" --object-id $FUNCTION_PRINCIPAL_ID --secret-permissions get list

# Update Function App to use Key Vault references
az functionapp config appsettings set --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --settings \
  "COGNITIVE_SERVICES_KEY=@Microsoft.KeyVault(SecretUri=https://kv-mcp-workshop.vault.azure.net/secrets/cognitive-services-key/)" \
  "AZURE_OPENAI_KEY=@Microsoft.KeyVault(SecretUri=https://kv-mcp-workshop.vault.azure.net/secrets/openai-key/)"
```

### 3. Scaling and Performance

```bash
# Configure auto-scaling for Function App
az functionapp config set --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --always-on true

# Set up Application Insights for monitoring
APP_INSIGHTS="ai-mcp-monitor"
az monitor app-insights component create --app $APP_INSIGHTS --location $LOCATION --resource-group $RESOURCE_GROUP

INSTRUMENTATION_KEY=$(az monitor app-insights component show --app $APP_INSIGHTS --resource-group $RESOURCE_GROUP --query "instrumentationKey" --output tsv)

az functionapp config appsettings set --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$INSTRUMENTATION_KEY"
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

```bash
# Create analytics query for Application Insights
ANALYTICS_QUERY='
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
'

echo "Application Insights Analytics Query:"
echo "$ANALYTICS_QUERY"
echo ""
echo "Use this query in Application Insights to monitor AI-enhanced tool usage"
```

### 2. Cost Analysis

```bash
# Create cost analysis script
cat > ai-cost-analysis.sh << 'EOF'
#!/bin/bash

echo "Detailed AI Services Cost Analysis"
echo "================================="

# Get detailed usage metrics
COGNITIVE_USAGE=$(az cognitiveservices account list-usage --name $COGNITIVE_SERVICES --resource-group $AI_RESOURCE_GROUP --output json)

echo "Cognitive Services Usage:"
echo "$COGNITIVE_USAGE" | jq -r '.[] | "- " + .name.value + ": " + (.currentValue | tostring) + "/" + (.limit | tostring) + " (" + ((.currentValue/.limit)*100 | tostring) + "%)"'

# Calculate cost per tool usage
echo ""
echo "Cost Per Tool Analysis:"
echo "- Document Intelligence: ~\$0.001 per page"
echo "- GPT-4 Turbo: ~\$0.01 per 1K tokens"
echo "- Text Analytics: ~\$0.0005 per record"

echo ""
echo "Optimization Recommendations:"
echo "1. Cache frequent analysis results"
echo "2. Use batch processing for multiple files"
echo "3. Implement rate limiting for cost control"
echo "4. Consider using smaller models for simple tasks"
EOF

chmod +x ai-cost-analysis.sh
```

## Automation and Workflow Scripts

### 1. AI Services Management

```bash
# Create comprehensive AI services management script
cat > ai-services-manager.sh << 'EOF'
#!/bin/bash

function deploy_ai_enhancements() {
    echo "Deploying AI enhancements to Function App..."
    
    # Build and deploy
    npm run build
    func azure functionapp publish $FUNCTION_APP --typescript
    
    echo "✅ AI enhancements deployed"
}

function test_ai_services() {
    echo "Testing AI services integration..."
    ./test-ai-integration.sh
}

function monitor_costs() {
    echo "Monitoring AI services costs..."
    ./monitor-ai-costs.sh
}

function check_quotas() {
    echo "Checking AI services quotas..."
    az cognitiveservices account list-usage --name $COGNITIVE_SERVICES --resource-group $AI_RESOURCE_GROUP --output table
}

function show_endpoints() {
    echo "AI Services Endpoints"
    echo "===================="
    echo "Cognitive Services: $COGNITIVE_ENDPOINT"
    echo "Function App: https://$(az functionapp show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --query 'defaultHostName' --output tsv)"
    echo "Key Vault: https://kv-mcp-workshop.vault.azure.net/"
}

case "$1" in
    deploy)
        deploy_ai_enhancements
        ;;
    test)
        test_ai_services
        ;;
    monitor)
        monitor_costs
        ;;
    quotas)
        check_quotas
        ;;
    endpoints)
        show_endpoints
        ;;
    *)
        echo "Usage: $0 {deploy|test|monitor|quotas|endpoints}"
        exit 1
        ;;
esac
EOF

chmod +x ai-services-manager.sh

# Usage examples:
# ./ai-services-manager.sh deploy
# ./ai-services-manager.sh test
# ./ai-services-manager.sh monitor
```

### 2. Environment Management for Codespaces

```bash
# Create Codespaces-specific setup
cat > setup-ai-services-codespaces.sh << 'EOF'
#!/bin/bash

echo "Setting up AI Services for GitHub Codespaces"
echo "============================================"

# Check if we're in Codespaces
if [ "$CODESPACES" = "true" ]; then
    echo "✅ Running in GitHub Codespaces"
    
    # Install additional dependencies if needed
    npm install @azure/ai-form-recognizer @azure/openai
    
    # Set up environment variables for Codespaces
    echo "export AI_RESOURCE_GROUP='$AI_RESOURCE_GROUP'" >> ~/.bashrc
    echo "export COGNITIVE_SERVICES='$COGNITIVE_SERVICES'" >> ~/.bashrc
    echo "export COGNITIVE_KEY='$COGNITIVE_KEY'" >> ~/.bashrc
    echo "export COGNITIVE_ENDPOINT='$COGNITIVE_ENDPOINT'" >> ~/.bashrc
    
    # Create VS Code workspace settings for AI features
    mkdir -p .vscode
    cat > .vscode/settings.json << 'EOJ'
{
    "github.copilot.chat.mcpServers": {
        "azure-mcp-ai-workshop": {
            "url": "YOUR_FUNCTION_URL_WITH_AI_FEATURES",
            "description": "AI-Enhanced Azure Functions MCP Server"
        }
    },
    "typescript.preferences.includePackageJsonAutoImports": "on"
}
EOJ
    
    echo "✅ Codespaces AI services setup complete"
    echo "ℹ️  Don't forget to update the MCP server URL in .vscode/settings.json"
else
    echo "❌ This script is designed for GitHub Codespaces"
    echo "ℹ️  For local setup, use the regular installation process"
fi
EOF

chmod +x setup-ai-services-codespaces.sh
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
- ✅ Optimized for both local Linux and GitHub Codespaces environments

### Key Takeaways

1. **AI Enhancement**: Azure AI services significantly improve tool capabilities
2. **Cost Management**: Proper monitoring is essential for production use
3. **Pipeline Automation**: AI-powered workflows can automate complex tasks
4. **Scalability**: Azure services provide enterprise-grade scaling
5. **Security**: Key Vault integration ensures secure credential management
6. **Cross-Platform**: Works seamlessly in local, VM, and Codespaces environments

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
- Cross-platform support for local development and GitHub Codespaces

Your MCP server is now a powerful AI-enhanced tool that can significantly improve your development workflow and code quality!

---

> **Navigation**: [Workshop Home](../README.md) | [Linux Path](README.md) | [← Part 4](part-4-copilot-integration.md)

## Resources and Further Learning

- [Azure AI Foundry Documentation](https://docs.microsoft.com/azure/ai-services/)
- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)
- [Azure Functions Best Practices](https://docs.microsoft.com/azure/azure-functions/functions-best-practices)
- [GitHub Copilot Extensions](https://docs.github.com/copilot/building-copilot-extensions)
- [Azure OpenAI Service](https://docs.microsoft.com/azure/cognitive-services/openai/)
- [GitHub Codespaces Documentation](https://docs.github.com/codespaces)