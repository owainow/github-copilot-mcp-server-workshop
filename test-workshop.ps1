# MCP Workshop Test Script - Clean Version
param(
    [string]$TestLevel = "local",
    [string]$FunctionUrl = "http://localhost:7071/api/mcp-server"
)

Write-Host "MCP Workshop Test Suite" -ForegroundColor Green
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
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Test 1: Ping
Write-Host "`n1. Testing MCP Protocol" -ForegroundColor Cyan
$pingResult = Invoke-MCPRequest -Method "ping"
if ($pingResult) {
    Write-Host "[OK] Ping successful" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Ping failed" -ForegroundColor Red
    exit 1
}

# Test 2: List Tools
$toolsResult = Invoke-MCPRequest -Method "tools/list"
if ($toolsResult -and $toolsResult.result.tools) {
    Write-Host "[OK] Found $($toolsResult.result.tools.Count) tools" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Failed to list tools" -ForegroundColor Red
    exit 1
}

# Test 3: Markdown Review
Write-Host "`n2. Testing Markdown Review" -ForegroundColor Cyan
$markdownParams = @{
    name = "markdown_review"
    arguments = @{
        content = "# Test README`n`nThis is test content."
        analysis_type = "comprehensive"
    }
}

$markdownResult = Invoke-MCPRequest -Method "tools/call" -Params $markdownParams
if ($markdownResult) {
    Write-Host "[OK] Markdown review completed" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Markdown review failed" -ForegroundColor Red
}

# Test 4: Dependency Check
Write-Host "`n3. Testing Dependency Check" -ForegroundColor Cyan
$depParams = @{
    name = "dependency_check"
    arguments = @{
        package_file = @{
            filename = "package.json"
            content = '{"dependencies": {"express": "^4.18.0", "lodash": "^4.17.20"}}'
        }
    }
}

$depResult = Invoke-MCPRequest -Method "tools/call" -Params $depParams
if ($depResult) {
    Write-Host "[OK] Dependency check completed" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Dependency check failed" -ForegroundColor Red
}

# Test 5: AI Code Review
Write-Host "`n4. Testing AI Code Review" -ForegroundColor Cyan
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
    try {
        # The response has double-nested JSON structure:
        # result.content[0].text -> JSON -> text -> actual analysis JSON
        $outerText = $aiResult.result.content[0].text
        $outerJson = $outerText | ConvertFrom-Json
        $innerText = $outerJson.text
        $analysis = $innerText | ConvertFrom-Json
        $status = if ($analysis.status) { $analysis.status } else { "unknown" }
        Write-Host "[OK] AI code review completed - Status: $status" -ForegroundColor Green
        
        if ($status -eq "ai_analysis") {
            Write-Host "  > Real AI analysis active!" -ForegroundColor Green
        } elseif ($status -eq "mock_analysis") {
            Write-Host "  > Mock analysis (Azure AI not configured)" -ForegroundColor Yellow
        } else {
            Write-Host "  > Response received" -ForegroundColor White
        }
    } catch {
        Write-Host "[OK] AI code review completed - Response received" -ForegroundColor Green
        Write-Host "  > Could not parse status from response" -ForegroundColor Yellow
    }
} else {
    Write-Host "[FAIL] AI code review failed" -ForegroundColor Red
}

Write-Host "`nTest Complete!" -ForegroundColor Green
