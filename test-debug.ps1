# Debug test for MCP server
Write-Host "Debug testing MCP Server..." -ForegroundColor Yellow

$pingBody = @{
    jsonrpc = "2.0"
    id = 1
    method = "ping"
} | ConvertTo-Json

Write-Host "Request body: $pingBody" -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri "http://localhost:7071/api/mcp-server" -Method POST -ContentType "application/json" -Body $pingBody -UseBasicParsing
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Content Type: $($response.Headers.'Content-Type')" -ForegroundColor Green
    Write-Host "Content Length: $($response.Content.Length)" -ForegroundColor Green
    Write-Host "Raw Content: '$($response.Content)'" -ForegroundColor Green
    
    if ($response.Content) {
        $jsonResponse = $response.Content | ConvertFrom-Json
        Write-Host "Parsed JSON:" -ForegroundColor Green
        $jsonResponse | ConvertTo-Json -Depth 5
    }
} catch {
    Write-Host "Request failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error response body: $responseBody" -ForegroundColor Red
    }
}
