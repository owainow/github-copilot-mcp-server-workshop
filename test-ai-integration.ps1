# Test AI Integration Script
# This script specifically tests the AI code review functionality

Write-Host "🤖 Testing AI Integration for MCP Workshop" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green

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
        Write-Host "💡 Make sure your Azure Function is running (func start)" -ForegroundColor Yellow
        return $null
    }
}

# Test 1: Check if server is running
Write-Host "`n1️⃣ Testing Server Connection..." -ForegroundColor Cyan
$pingResult = Invoke-MCPRequest -Method "ping"
if (-not $pingResult) {
    Write-Host "❌ Cannot connect to MCP server. Please start it with 'func start'" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Server is running" -ForegroundColor Green

# Test 2: Verify AI tool is available
Write-Host "`n2️⃣ Checking AI Tool Availability..." -ForegroundColor Cyan
$toolsResult = Invoke-MCPRequest -Method "tools/list"
$aiTool = $toolsResult.result.tools | Where-Object { $_.name -eq "ai_code_review" }

if (-not $aiTool) {
    Write-Host "❌ AI code review tool not found" -ForegroundColor Red
    exit 1
}
Write-Host "✅ AI code review tool is available" -ForegroundColor Green

# Test 3: Simple code analysis
Write-Host "`n3️⃣ Testing with Simple Code..." -ForegroundColor Cyan
$simpleCode = "function greet(name) { return 'Hello ' + name; }"

$simpleParams = @{
    name = "ai_code_review"
    arguments = @{
        code = $simpleCode
        language = "javascript"
        review_type = "comprehensive"
    }
}

$simpleResult = Invoke-MCPRequest -Method "tools/call" -Params $simpleParams
if ($simpleResult -and $simpleResult.result) {
    $analysis = $simpleResult.result.content[0].text | ConvertFrom-Json
    Write-Host "✅ Analysis completed" -ForegroundColor Green
    Write-Host "   Status: $($analysis.status)" -ForegroundColor Yellow
    
    if ($analysis.status -eq "ai_analysis") {
        Write-Host "   🌟 Using REAL AI analysis!" -ForegroundColor Green
    } else {
        Write-Host "   📚 Using mock analysis (Azure AI not configured)" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Simple code analysis failed" -ForegroundColor Red
}

# Test 4: Problematic code with security issues
Write-Host "`n4️⃣ Testing with Problematic Code..." -ForegroundColor Cyan
$problematicCode = @"
function processUserInput(userInput) {
    // Dangerous: eval usage
    var result = eval(userInput);
    
    // Dangerous: DOM manipulation without sanitization
    document.getElementById('output').innerHTML = result;
    
    // Dangerous: no input validation
    return result;
}

// Usage with string concatenation vulnerability
processUserInput("alert('XSS')" + userInput);
"@

$problematicParams = @{
    name = "ai_code_review"
    arguments = @{
        code = $problematicCode
        language = "javascript"
        review_type = "security"
    }
}

$problematicResult = Invoke-MCPRequest -Method "tools/call" -Params $problematicParams
if ($problematicResult -and $problematicResult.result) {
    $analysis = $problematicResult.result.content[0].text | ConvertFrom-Json
    Write-Host "✅ Security analysis completed" -ForegroundColor Green
    Write-Host "   Issues found: $($analysis.analysis.issues.Count)" -ForegroundColor Yellow
    
    if ($analysis.analysis.issues.Count -gt 0) {
        Write-Host "   🔍 Security Issues:" -ForegroundColor Red
        $analysis.analysis.issues | ForEach-Object { 
            Write-Host "     • $_" -ForegroundColor White
        }
    }
} else {
    Write-Host "❌ Security analysis failed" -ForegroundColor Red
}

# Test 5: TypeScript code with type issues
Write-Host "`n5️⃣ Testing TypeScript Analysis..." -ForegroundColor Cyan
$typescriptCode = @"
interface User {
    id: number;
    name: string;
    email?: string;
}

function processUser(user: any): User {
    // Type issues here
    return {
        id: user.id.toString(),  // Should be number
        name: user.firstName + user.lastName,  // Missing space
        email: user.contact.email  // Unsafe property access
    };
}

// Usage with wrong types
const result = processUser({ id: "123", name: "John" });
"@

$typescriptParams = @{
    name = "ai_code_review"
    arguments = @{
        code = $typescriptCode
        language = "typescript"
        review_type = "comprehensive"
    }
}

$typescriptResult = Invoke-MCPRequest -Method "tools/call" -Params $typescriptParams
if ($typescriptResult -and $typescriptResult.result) {
    $analysis = $typescriptResult.result.content[0].text | ConvertFrom-Json
    Write-Host "✅ TypeScript analysis completed" -ForegroundColor Green
    Write-Host "   Recommendations: $($analysis.analysis.recommendations.Count)" -ForegroundColor Yellow
} else {
    Write-Host "❌ TypeScript analysis failed" -ForegroundColor Red
}

# Summary
Write-Host "`n📊 Test Summary" -ForegroundColor Green
Write-Host "===============" -ForegroundColor Green

if ($analysis.status -eq "ai_analysis") {
    Write-Host "🎉 SUCCESS: Real AI analysis is working!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your MCP server is now using Azure AI Foundry to provide:" -ForegroundColor White
    Write-Host "• Intelligent code analysis" -ForegroundColor White
    Write-Host "• Security vulnerability detection" -ForegroundColor White
    Write-Host "• Best practice recommendations" -ForegroundColor White
    Write-Host "• Language-specific insights" -ForegroundColor White
    Write-Host ""
    Write-Host "🌟 This demonstrates the true power of MCP:" -ForegroundColor Yellow
    Write-Host "Tools provide context, AI provides intelligence!" -ForegroundColor Yellow
} else {
    Write-Host "📚 INFO: Using mock analysis" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To enable real AI analysis:" -ForegroundColor White
    Write-Host "1. Run: .\setup-azure-ai.ps1" -ForegroundColor White
    Write-Host "2. Restart your function (func start)" -ForegroundColor White
    Write-Host "3. Re-run this test" -ForegroundColor White
    Write-Host ""
    Write-Host "💰 The setup uses Azure AI Foundry FREE tier" -ForegroundColor Green
}

Write-Host "`n🎓 Workshop Learning:" -ForegroundColor Cyan
Write-Host "This demonstrates the difference between:" -ForegroundColor White
Write-Host "• Educational MCP tools (local analysis)" -ForegroundColor White
Write-Host "• Production MCP tools (AI-powered analysis)" -ForegroundColor White
