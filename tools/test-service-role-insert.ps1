# Teste de inserção com service role key

Write-Host "Testando inserção com service role key..." -ForegroundColor Green

$supabaseUrl = "https://aoktoecyoxzgdraszzjb.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFva3RvZWN5b3h6Z2RyYXN6empiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTk5NTgyMiwiZXhwIjoyMDc3NTcxODIyfQ.53Qp7btP3PWkXuIJYEX6noXBzTqHSnPhAO12XhNjObM"

$testMetric = @{
    user_id = "00000000-0000-0000-0000-000000000001"
    model_used = "gemini-1.5-flash"
    tokens_input = 50
    tokens_output = 25
    cost_input_usd = 0.00375
    cost_output_usd = 0.00750
    request_duration_ms = 1200
    files_processed = 0
    request_type = "test-service-role"
    error_occurred = $false
} | ConvertTo-Json

Write-Host "Dados de teste com service role:" -ForegroundColor Yellow
Write-Host $testMetric

try {
    $response = Invoke-WebRequest -Uri "$supabaseUrl/rest/v1/gemini_usage_metrics" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $serviceRoleKey"
            "apikey" = $serviceRoleKey
            "Content-Type" = "application/json"
            "Prefer" = "return=representation"
        } `
        -Body $testMetric `
        -UseBasicParsing

    Write-Host "✅ Inserção com service role bem-sucedida!" -ForegroundColor Green
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Resposta: $($response.Content)" -ForegroundColor White
    
    # Agora verificar se foi salvo
    Write-Host "`nVerificando se foi salvo..." -ForegroundColor Yellow
    $checkResponse = Invoke-WebRequest -Uri "$supabaseUrl/rest/v1/gemini_usage_metrics?select=*" `
        -Method GET `
        -Headers @{
            "Authorization" = "Bearer $serviceRoleKey"
            "apikey" = $serviceRoleKey
        } `
        -UseBasicParsing
        
    $savedMetrics = $checkResponse.Content | ConvertFrom-Json
    Write-Host "Métricas salvas: $($savedMetrics.Count)" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Erro na inserção com service role:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $errorContent = $reader.ReadToEnd()
        Write-Host "Detalhes: $errorContent" -ForegroundColor Red
    }
}