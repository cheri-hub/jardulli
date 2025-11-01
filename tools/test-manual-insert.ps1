# Teste de inserção manual na tabela gemini_usage_metrics

Write-Host "Testando inserção manual de métricas..." -ForegroundColor Green

$supabaseUrl = "https://aoktoecyoxzgdraszzjb.supabase.co"
$anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFva3RvZWN5b3h6Z2RyYXN6empiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5OTU4MjIsImV4cCI6MjA3NzU3MTgyMn0.1Eyr83dJNj1zzixUA4GC1c1zpgbcdp_mfgSWKlBI5gc"

$testMetric = @{
    user_id = "00000000-0000-0000-0000-000000000001"
    model_used = "gemini-1.5-flash"
    tokens_input = 50
    tokens_output = 25
    cost_input_usd = 0.00375
    cost_output_usd = 0.00750
    request_duration_ms = 1200
    files_processed = 0
    request_type = "test"
    error_occurred = $false
    error_message = $null
    conversation_id = $null
    message_id = $null
} | ConvertTo-Json

Write-Host "Dados de teste:" -ForegroundColor Yellow
Write-Host $testMetric

try {
    $response = Invoke-WebRequest -Uri "$supabaseUrl/rest/v1/gemini_usage_metrics" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $anonKey"
            "apikey" = $anonKey
            "Content-Type" = "application/json"
            "Prefer" = "return=representation"
        } `
        -Body $testMetric `
        -UseBasicParsing

    Write-Host "✅ Inserção manual bem-sucedida!" -ForegroundColor Green
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Resposta: $($response.Content)" -ForegroundColor White
    
} catch {
    Write-Host "❌ Erro na inserção manual:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $errorContent = $reader.ReadToEnd()
        Write-Host "Detalhes: $errorContent" -ForegroundColor Red
    }
}