# Script para testar o cost tracking no ambiente HML
# Executa uma chamada para a função ai-chat e verifica se os custos são capturados

Write-Host "=================================================" -ForegroundColor Green
Write-Host "Testando Cost Tracking no Ambiente HML" -ForegroundColor Green  
Write-Host "=================================================" -ForegroundColor Green
Write-Host

# Configurações do ambiente HML
$functionUrl = "https://aoktoecyoxzgdraszzjb.supabase.co/functions/v1/ai-chat"
$anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFva3RvZWN5b3h6Z2RyYXN6empiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5OTU4MjIsImV4cCI6MjA3NzU3MTgyMn0.1Eyr83dJNj1zzixUA4GC1c1zpgbcdp_mfgSWKlBI5gc"

# Corpo da requisição
$body = @{
    message = "Olá! Esta é uma mensagem de teste para verificar se o cost tracking está funcionando. Pode me falar sobre os custos do Gemini API?"
    userId = "00000000-0000-0000-0000-000000000001"  # UUID válido para teste
    conversationId = $null
} | ConvertTo-Json

Write-Host "Fazendo uma requisição de teste para capturar métricas..." -ForegroundColor Yellow
Write-Host "User ID: $($body | ConvertFrom-Json | Select-Object -ExpandProperty userId)" -ForegroundColor Cyan
Write-Host

try {
    # Fazer a chamada para a função
    $response = Invoke-WebRequest -Uri $functionUrl `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $anonKey"
            "Content-Type" = "application/json"
            "apikey" = $anonKey
        } `
        -Body $body `
        -UseBasicParsing

    Write-Host "✅ Resposta recebida com sucesso!" -ForegroundColor Green
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    
    # Tentar parsear a resposta JSON
    try {
        $responseJson = $response.Content | ConvertFrom-Json
        Write-Host "Resposta da AI: $($responseJson.message -replace '\n', ' ')" -ForegroundColor White
    }
    catch {
        Write-Host "Resposta (texto): $($response.Content)" -ForegroundColor White
    }
    
} catch {
    Write-Host "❌ Erro na requisição:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $errorContent = $reader.ReadToEnd()
        Write-Host "Detalhes do erro: $errorContent" -ForegroundColor Red
    }
}

Write-Host
Write-Host "=================================================" -ForegroundColor Green
Write-Host "Próximos passos:" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host "1. Acesse o dashboard do Supabase HML:" -ForegroundColor Yellow
Write-Host "   https://supabase.com/dashboard/project/aoktoecyoxzgdraszzjb/editor" -ForegroundColor Blue
Write-Host
Write-Host "2. Verifique a tabela 'gemini_usage_metrics' para ver se houve captura de dados" -ForegroundColor Yellow
Write-Host
Write-Host "3. Consulte os logs das Edge Functions:" -ForegroundColor Yellow  
Write-Host "   https://supabase.com/dashboard/project/aoktoecyoxzgdraszzjb/functions" -ForegroundColor Blue
Write-Host "=================================================" -ForegroundColor Green