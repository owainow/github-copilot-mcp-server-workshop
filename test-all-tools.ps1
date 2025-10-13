# Complete MCP Tools Test Script
# This script demonstrates all three tools in the MCP server

Write-Host "🚀 Testing Complete MCP Server with All Tools" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

$baseUrl = "http://localhost:7071/api/mcp-server"

# Function to make MCP requests
function Invoke-MCPRequest {
    param(
        [string]$Method,
        [hashtable]$Params = @{}
    )
    
    $body = @{
        jsonrpc = "2.0"
        id = Get-Random
        method = $Method
        params = $Params
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri $baseUrl -Method POST -ContentType "application/json" -Body $body
        return $response
    } catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

Write-Host "`n1️⃣ Testing MCP Protocol - Ping" -ForegroundColor Cyan
$pingResult = Invoke-MCPRequest -Method "ping"
if ($pingResult) {
    Write-Host "✅ Ping successful: $($pingResult.result.message)" -ForegroundColor Green
} else {
    Write-Host "❌ Ping failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n2️⃣ Testing MCP Protocol - List Tools" -ForegroundColor Cyan
$toolsResult = Invoke-MCPRequest -Method "tools/list"
if ($toolsResult -and $toolsResult.result.tools) {
    Write-Host "✅ Found $($toolsResult.result.tools.Count) tools:" -ForegroundColor Green
    foreach ($tool in $toolsResult.result.tools) {
        Write-Host "   📦 $($tool.name): $($tool.description)" -ForegroundColor White
    }
} else {
    Write-Host "❌ Failed to list tools" -ForegroundColor Red
    exit 1
}

Write-Host "`n3️⃣ Testing Tool 1: Markdown Review (Educational)" -ForegroundColor Cyan
$markdownContent = @'
# Sample Project README

This is a sample project demonstrating markdown analysis.

## Features
- Feature 1
- Feature 2

## Installation
```bash
npm install
```

## Usage
Run the application with npm start.

TODO: Add more documentation
'@

$markdownParams = @{
    name = "markdown_review"
    arguments = @{
        content = $markdownContent
        analysis_type = "comprehensive"
    }
}

$markdownResult = Invoke-MCPRequest -Method "tools/call" -Params $markdownParams
if ($markdownResult -and $markdownResult.result) {
    Write-Host "✅ Markdown Review completed:" -ForegroundColor Green
    $analysis = $markdownResult.result.content[0].text | ConvertFrom-Json
    Write-Host "   📊 Quality Score: $($analysis.quality_score)/100" -ForegroundColor Yellow
    Write-Host "   📝 Issues found: $($analysis.issues.Count)" -ForegroundColor Yellow
    Write-Host "   💡 Recommendations: $($analysis.recommendations.Count)" -ForegroundColor Yellow
} else {
    Write-Host "❌ Markdown review failed" -ForegroundColor Red
}

Write-Host "`n4️⃣ Testing Tool 2: Dependency Check (Educational)" -ForegroundColor Cyan
$packageJson = @'
{
  "name": "test-project",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0",
    "lodash": "^4.17.21",
    "moment": "^2.29.4"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "@types/node": "^18.0.0"
  }
}
'@

$depParams = @{
    name = "dependency_check"
    arguments = @{
        package_json = $packageJson
        check_type = "security_and_updates"
    }
}

$depResult = Invoke-MCPRequest -Method "tools/call" -Params $depParams
if ($depResult -and $depResult.result) {
    Write-Host "✅ Dependency Check completed:" -ForegroundColor Green
    $depAnalysis = $depResult.result.content[0].text | ConvertFrom-Json
    Write-Host "   📦 Total packages: $($depAnalysis.total_packages)" -ForegroundColor Yellow
    Write-Host "   ⚠️  Security issues: $($depAnalysis.security_issues.Count)" -ForegroundColor Yellow
    Write-Host "   📅 Update recommendations: $($depAnalysis.update_recommendations.Count)" -ForegroundColor Yellow
} else {
    Write-Host "❌ Dependency check failed" -ForegroundColor Red
}

Write-Host "`n5️⃣ Testing Tool 3: AI Code Review (Production-Style)" -ForegroundColor Cyan
$sampleCode = @'
function calculateSum(a, b) {
    return a + b;
}

function processData(data) {
    // TODO: Add validation
    let results = [];
    for (let i = 0; i < data.length; i++) {
        results.push(calculateSum(data[i], 10));
    }
    return results;
}

// Usage with potential type issues
let testData = ["5", "10", 15];
let result = processData(testData);
console.log(result);
'@

$aiParams = @{
    name = "ai_code_review"
    arguments = @{
        code = $sampleCode
        language = "javascript"
        review_type = "comprehensive"
    }
}

$aiResult = Invoke-MCPRequest -Method "tools/call" -Params $aiParams
if ($aiResult -and $aiResult.result) {
    Write-Host "✅ AI Code Review completed:" -ForegroundColor Green
    $aiAnalysis = $aiResult.result.content[0].text | ConvertFrom-Json
    Write-Host "   🤖 Analysis Type: $($aiAnalysis.status)" -ForegroundColor Yellow
    if ($aiAnalysis.status -eq "ai_analysis") {
        Write-Host "   🌟 Real AI analysis provided" -ForegroundColor Green
    } else {
        Write-Host "   📚 Mock analysis provided (no Azure AI configured)" -ForegroundColor Yellow
    }
    Write-Host "   🔍 Issues identified: $($aiAnalysis.analysis.issues.Count)" -ForegroundColor Yellow
} else {
    Write-Host "❌ AI code review failed" -ForegroundColor Red
}

Write-Host "`n🎉 MCP Server Testing Complete!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host "✨ Summary:" -ForegroundColor Cyan
Write-Host "   • MCP Protocol: Working" -ForegroundColor White
Write-Host "   • Educational Tools: markdown_review, dependency_check" -ForegroundColor White
Write-Host "   • Production-Style Tool: ai_code_review" -ForegroundColor White
Write-Host "   • AI Integration: $($aiAnalysis.status)" -ForegroundColor White
Write-Host "`n🔗 This demonstrates both educational MCP patterns and true LLM integration!" -ForegroundColor Yellow
