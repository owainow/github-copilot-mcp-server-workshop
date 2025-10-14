# Test tools/list endpoint
Write-Host "Testing tools/list endpoint..." -ForegroundColor Green

$toolsBody = @{
    jsonrpc = "2.0"
    id = 2
    method = "tools/list"
} | ConvertTo-Json

Write-Host "Request body: $toolsBody" -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri "http://localhost:7071/api/mcp-server" -Method POST -ContentType "application/json" -Body $toolsBody -UseBasicParsing
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Content Type: $($response.Headers.'Content-Type')" -ForegroundColor Green
    Write-Host "Raw Content: '$($response.Content)'" -ForegroundColor Green
    
    if ($response.Content) {
        $jsonResponse = $response.Content | ConvertFrom-Json
        Write-Host "Parsed JSON:" -ForegroundColor Green
        $jsonResponse | ConvertTo-Json -Depth 10
    }
} catch {
    Write-Host "Request failed: $($_.Exception.Message)" -ForegroundColor Red
}
