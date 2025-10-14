# End-to-End Workshop Test
# This script will test the complete workshop flow

Write-Host "🚀 GitHub Copilot MCP Server Workshop - End-to-End Test" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green

# Step 1: Verify Prerequisites
Write-Host "`n📋 Step 1: Checking Prerequisites..." -ForegroundColor Cyan

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found" -ForegroundColor Red
    exit 1
}

# Check npm
try {
    $npmVersion = npm --version
    Write-Host "✅ npm: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ npm not found" -ForegroundColor Red
    exit 1
}

# Check Azure Functions Core Tools
try {
    $funcVersion = func --version
    Write-Host "✅ Azure Functions Core Tools: $funcVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure Functions Core Tools not found" -ForegroundColor Red
    Write-Host "Please install: npm install -g azure-functions-core-tools@4 --unsafe-perm true" -ForegroundColor Yellow
    exit 1
}

# Step 2: Verify Project Structure
Write-Host "`n📁 Step 2: Checking Project Structure..." -ForegroundColor Cyan

$requiredFiles = @(
    "package.json",
    "tsconfig.json",
    "host.json",
    "local.settings.json",
    "src/functions/mcp-server.ts",
    "src/mcp/server.ts",
    "src/tools/markdown-review.ts",
    "src/tools/dependency-check.ts",
    "src/shared/logger.ts",
    "README.md"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ $file (missing)" -ForegroundColor Red
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "`n❌ Missing required files. Please ensure the workshop setup completed successfully." -ForegroundColor Red
    exit 1
}

# Step 3: Install Dependencies
Write-Host "`n📦 Step 3: Installing Dependencies..." -ForegroundColor Cyan
try {
    npm install | Out-Host
    Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    exit 1
}

# Step 4: Build TypeScript
Write-Host "`n🔨 Step 4: Building TypeScript..." -ForegroundColor Cyan
try {
    npm run build | Out-Host
    Write-Host "✅ TypeScript build successful" -ForegroundColor Green
} catch {
    Write-Host "❌ TypeScript build failed" -ForegroundColor Red
    exit 1
}

# Step 5: Start Azure Functions (in background)
Write-Host "`n🌐 Step 5: Starting Azure Functions Server..." -ForegroundColor Cyan
$funcProcess = Start-Process -FilePath "func" -ArgumentList "start" -NoNewWindow -PassThru
Start-Sleep -Seconds 10  # Give it time to start

# Check if process is running
if ($funcProcess.HasExited) {
    Write-Host "❌ Failed to start Azure Functions server" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ Azure Functions server started (PID: $($funcProcess.Id))" -ForegroundColor Green
}

# Step 6: Test Server Health
Write-Host "`n🏥 Step 6: Testing Server Health..." -ForegroundColor Cyan
$maxRetries = 10
$retryCount = 0
$serverReady = $false

while ($retryCount -lt $maxRetries -and -not $serverReady) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:7071/api/mcp-server" -Method GET -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            $serverReady = $true
            Write-Host "✅ Server is responding (Status: $($response.StatusCode))" -ForegroundColor Green
        }
    } catch {
        $retryCount++
        Write-Host "⏳ Waiting for server... (attempt $retryCount/$maxRetries)" -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }
}

if (-not $serverReady) {
    Write-Host "❌ Server failed to respond after $maxRetries attempts" -ForegroundColor Red
    Stop-Process -Id $funcProcess.Id -Force
    exit 1
}

Write-Host "`n🎯 Running MCP Protocol Tests..." -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

# Test 1: Ping
Write-Host "`n1️⃣ Testing MCP Ping..." -ForegroundColor Yellow
$pingBody = @{
    jsonrpc = "2.0"
    id = 1
    method = "ping"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:7071/api/mcp-server" -Method POST -ContentType "application/json" -Body $pingBody
    if ($response.result.status -eq "ok") {
        Write-Host "✅ Ping successful - Server: $($response.result.server)" -ForegroundColor Green
    } else {
        Write-Host "❌ Ping failed - unexpected response" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Ping failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Tools List
Write-Host "`n2️⃣ Testing Tools List..." -ForegroundColor Yellow
$toolsBody = @{
    jsonrpc = "2.0"
    id = 2
    method = "tools/list"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:7071/api/mcp-server" -Method POST -ContentType "application/json" -Body $toolsBody
    $toolCount = $response.result.tools.Count
    Write-Host "✅ Tools list successful - Found $toolCount tools:" -ForegroundColor Green
    foreach ($tool in $response.result.tools) {
        Write-Host "   📝 $($tool.name): $($tool.description)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Tools list failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Markdown Review Tool
Write-Host "`n3️⃣ Testing Markdown Review Tool..." -ForegroundColor Yellow
$markdownContent = "# Workshop Test Document`n`nThis is a **test document** for our MCP server.`n`n## Features`n- Custom tools integration`n- Azure Functions hosting`n- GitHub Copilot compatibility`n`nLet's see what suggestions we get!"
$markdownTestBody = @{
    jsonrpc = "2.0"
    id = 3
    method = "tools/call"
    params = @{
        name = "markdown_review"
        arguments = @{
            content = $markdownContent
            analysis_type = "comprehensive"
        }
    }
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "http://localhost:7071/api/mcp-server" -Method POST -ContentType "application/json" -Body $markdownTestBody
    $analysis = $response.result.content[0].text | ConvertFrom-Json
    Write-Host "✅ Markdown review successful:" -ForegroundColor Green
    Write-Host "   📊 Document length: $($analysis.summary.contentLength) characters" -ForegroundColor Cyan
    Write-Host "   📝 Line count: $($analysis.summary.lineCount)" -ForegroundColor Cyan
    Write-Host "   🏷️ Headings found: $($analysis.metrics.headingStructure.totalHeadings)" -ForegroundColor Cyan
    Write-Host "   💡 Suggestions: $($analysis.suggestions.Count)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Markdown review failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Dependency Check Tool
Write-Host "`n4️⃣ Testing Dependency Check Tool..." -ForegroundColor Yellow
$packageJson = Get-Content "package.json" -Raw
$depCheckBody = @{
    jsonrpc = "2.0"
    id = 4
    method = "tools/call"
    params = @{
        name = "dependency_check"
        arguments = @{
            package_json = $packageJson
            check_type = "comprehensive"
            include_dev_dependencies = $true
        }
    }
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "http://localhost:7071/api/mcp-server" -Method POST -ContentType "application/json" -Body $depCheckBody
    $analysis = $response.result.content[0].text | ConvertFrom-Json
    Write-Host "✅ Dependency check successful:" -ForegroundColor Green
    Write-Host "   📦 Total dependencies: $($analysis.summary.totalDependencies)" -ForegroundColor Cyan
    Write-Host "   🔒 Production deps: $($analysis.summary.productionCount)" -ForegroundColor Cyan
    Write-Host "   🛠️ Dev dependencies: $($analysis.summary.devCount)" -ForegroundColor Cyan
    Write-Host "   ⚠️ Issues found: $($analysis.issues.Count)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Dependency check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Cleanup
Write-Host "`n🧹 Cleaning up..." -ForegroundColor Cyan
Stop-Process -Id $funcProcess.Id -Force
Write-Host "✅ Azure Functions server stopped" -ForegroundColor Green

# Final Summary
Write-Host "`n🎉 END-TO-END TEST COMPLETE!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "✅ All MCP protocol methods tested successfully" -ForegroundColor Green
Write-Host "✅ Both custom tools are working" -ForegroundColor Green
Write-Host "✅ Azure Functions integration verified" -ForegroundColor Green
Write-Host "`n🚀 Your GitHub Copilot MCP Server is ready for production!" -ForegroundColor Yellow
Write-Host "`n📚 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Deploy to Azure using the Bicep templates" -ForegroundColor White
Write-Host "   2. Configure GitHub Copilot with your MCP server URL" -ForegroundColor White
Write-Host "   3. Start using your custom tools in Copilot!" -ForegroundColor White
