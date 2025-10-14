$body = @{
    jsonrpc = "2.0"
    id = 1
    method = "ping"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:7072/api/mcp-server" -Method POST -ContentType "application/json" -Body $body
    Write-Host "✅ Success! Response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "❌ Error:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response body: $responseBody"
    }
}
