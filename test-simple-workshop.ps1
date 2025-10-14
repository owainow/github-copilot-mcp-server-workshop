# MCP Workshop Test Script - Clean Version
param(
    [string]$TestLevel = "local",
    [string]$FunctionUrl = "http://localhost:7071/api/mcp-server"
)

Write-Host "🧪 MCP Workshop Test Suite" -ForegroundColor Green
Write-Host "Test Level: $TestLevel" -ForegroundColor Cyan

function Invoke-MCPRequest {
    param([string]$Method, [hashtable]$Params = @{})
    
    $body = @{
        jsonrpc = "2.0"
        id = Get-Random
        method = $Method
        params = $Params
    } | ConvertTo-Json -Depth 10
    
    try {
        return Invoke-RestMethod -Uri $FunctionUrl -Method POST -ContentType "application/json" -Body $body
    } catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Test 1: Ping
Write-Host "`n1️⃣ Testing MCP Protocol" -ForegroundColor Cyan
$pingResult = Invoke-MCPRequest -Method "ping"
if ($pingResult) {
    Write-Host "✅ Ping successful" -ForegroundColor Green
} else {
    Write-Host "❌ Ping failed" -ForegroundColor Red
    exit 1
}

# Test 2: List Tools
$toolsResult = Invoke-MCPRequest -Method "tools/list"
if ($toolsResult -and $toolsResult.result.tools) {
    Write-Host "✅ Found $($toolsResult.result.tools.Count) tools" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to list tools" -ForegroundColor Red
    exit 1
}

# Test 3: Markdown Review
Write-Host "`n2️⃣ Testing Markdown Review" -ForegroundColor Cyan
$markdownParams = @{
    name = "markdown_review"
    arguments = @{
        content = "# Test README`n`nThis is test content."
        analysis_type = "comprehensive"
    }
}

$markdownResult = Invoke-MCPRequest -Method "tools/call" -Params $markdownParams
if ($markdownResult) {
    Write-Host "✅ Markdown review completed" -ForegroundColor Green
} else {
    Write-Host "❌ Markdown review failed" -ForegroundColor Red
}

# Test 4: AI Code Review
Write-Host "`n3️⃣ Testing AI Code Review" -ForegroundColor Cyan
$aiParams = @{
    name = "ai_code_review"
    arguments = @{
        code = "function test() { console.log('hello'); }"
        language = "javascript"
        review_type = "comprehensive"
    }
}

$aiResult = Invoke-MCPRequest -Method "tools/call" -Params $aiParams
if ($aiResult) {
    $analysis = $aiResult.result.content[0].text | ConvertFrom-Json
    Write-Host "✅ AI code review completed - Status: $($analysis.status)" -ForegroundColor Green
} else {
    Write-Host "❌ AI code review failed" -ForegroundColor Red
}

Write-Host "`n🎉 Test Complete!" -ForegroundColor Green
