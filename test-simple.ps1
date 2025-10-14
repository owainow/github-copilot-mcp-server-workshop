# Simple test for MCP server functionality
Write-Host "Testing MCP Server functionality..." -ForegroundColor Green

# Test ping
$pingBody = @{
    jsonrpc = "2.0"
    id = 1
    method = "ping"
} | ConvertTo-Json

Write-Host "`nTesting ping..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:7071/api/mcp-server" -Method POST -ContentType "application/json" -Body $pingBody
    Write-Host "Ping Response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 5
} catch {
    Write-Host "Ping failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test tools/list
$toolsBody = @{
    jsonrpc = "2.0"
    id = 2
    method = "tools/list"
} | ConvertTo-Json

Write-Host "`nTesting tools/list..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:7071/api/mcp-server" -Method POST -ContentType "application/json" -Body $toolsBody
    Write-Host "Tools List Response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 5
} catch {
    Write-Host "Tools list failed: $($_.Exception.Message)" -ForegroundColor Red
}
