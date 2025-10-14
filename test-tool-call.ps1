# Test markdown_review tool
Write-Host "Testing markdown_review tool..." -ForegroundColor Green

$toolCallBody = @{
    jsonrpc = "2.0"
    id = 3
    method = "tools/call"
    params = @{
        name = "markdown_review"
        arguments = @{
            content = "# Hello World

This is a test document. It has some issues:
- No proper structure
- Missing links
- Poor formatting

Let me know what you think!"
            analysis_type = "comprehensive"
        }
    }
} | ConvertTo-Json -Depth 10

Write-Host "Request body: $toolCallBody" -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri "http://localhost:7071/api/mcp-server" -Method POST -ContentType "application/json" -Body $toolCallBody -UseBasicParsing
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Content Type: $($response.Headers.'Content-Type')" -ForegroundColor Green
    
    if ($response.Content) {
        $jsonResponse = $response.Content | ConvertFrom-Json
        Write-Host "Tool Response:" -ForegroundColor Green
        $jsonResponse | ConvertTo-Json -Depth 10
    }
} catch {
    Write-Host "Request failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error response: $responseBody" -ForegroundColor Red
    }
}
