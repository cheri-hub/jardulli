# Testar Ambiente HML
Write-Host "🧪 Testando ambiente HML..." -ForegroundColor Green

$ProjectUrl = "https://aoktoecyoxzgdraszzjb.supabase.co"
$AnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFva3RvZWN5b3h6Z2RyYXN6empiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5OTU4MjIsImV4cCI6MjA3NzU3MTgyMn0.1Eyr83dJNj1zzixUA4GC1c1zpgbcdp_mfgSWKlBI5gc"

Write-Host "🔗 Projeto HML: $ProjectUrl" -ForegroundColor Blue

# Testar conectividade básica
Write-Host "📡 Testando conectividade com Supabase..." -ForegroundColor Blue
try {
    $headers = @{
        "apikey" = $AnonKey
        "Authorization" = "Bearer $AnonKey"
    }
    
    $response = Invoke-RestMethod -Uri "$ProjectUrl/rest/v1/" -Headers $headers -TimeoutSec 10
    Write-Host "✅ Conectividade com database OK" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro de conectividade: $_" -ForegroundColor Red
    Write-Host "💡 Verifique se o projeto HML está ativo" -ForegroundColor Yellow
}

# Testar tabelas
Write-Host "📊 Testando acesso às tabelas..." -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "$ProjectUrl/rest/v1/gemini_usage_metrics?select=count" -Headers $headers -TimeoutSec 10
    Write-Host "✅ Tabela gemini_usage_metrics acessível" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao acessar tabela gemini_usage_metrics: $_" -ForegroundColor Red
    Write-Host "💡 Execute .\tools\apply-migrations-hml.ps1 primeiro" -ForegroundColor Yellow
}

# Testar Edge Function
Write-Host "🤖 Testando Edge Function ai-chat..." -ForegroundColor Blue
$testPayload = @{
    message = "Teste do ambiente HML"
    userId = "test-user-hml-123"
} | ConvertTo-Json

try {
    $headers = @{
        "apikey" = $AnonKey
        "Authorization" = "Bearer $AnonKey"
        "Content-Type" = "application/json"
    }
    
    $response = Invoke-RestMethod -Uri "$ProjectUrl/functions/v1/ai-chat" -Method Post -Body $testPayload -Headers $headers -TimeoutSec 30
    
    if ($response.success) {
        Write-Host "✅ Edge Function ai-chat respondeu com sucesso!" -ForegroundColor Green
        if ($response.reply) {
            Write-Host "💬 Resposta: $($response.reply.Substring(0, [Math]::Min(100, $response.reply.Length)))..." -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️ Edge Function respondeu mas com erro: $($response.error)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erro na Edge Function: $_" -ForegroundColor Red
    Write-Host "💡 Verifique se as Edge Functions foram deployadas e variáveis configuradas" -ForegroundColor Yellow
}

# Verificar métricas de custo (se disponível)
Write-Host "💰 Testando captura de métricas de custo..." -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "$ProjectUrl/rest/v1/gemini_usage_metrics?select=*&limit=5" -Headers $headers -TimeoutSec 10
    $count = $response.Count
    Write-Host "📊 Métricas capturadas: $count registros" -ForegroundColor Green
    
    if ($count -gt 0) {
        $latestMetric = $response[0]
        Write-Host "🔍 Última métrica:" -ForegroundColor Blue
        Write-Host "   - Modelo: $($latestMetric.model_used)" -ForegroundColor Gray
        Write-Host "   - Tokens: $($latestMetric.total_tokens)" -ForegroundColor Gray
        Write-Host "   - Custo: `$$($latestMetric.total_cost_usd)" -ForegroundColor Gray
    }
} catch {
    Write-Host "⚠️ Ainda não há métricas capturadas (normal se é a primeira vez)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 Próximos passos para teste completo:" -ForegroundColor Yellow
Write-Host "1. Configure GEMINI_API_KEY no dashboard Supabase" -ForegroundColor White
Write-Host "2. Execute .\tools\build-hml.ps1 para build do frontend" -ForegroundColor White
Write-Host "3. Acesse o frontend e teste o chat completo" -ForegroundColor White
Write-Host "4. Monitore a tabela gemini_usage_metrics para validar custos" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Dashboard HML: https://supabase.com/dashboard/project/aoktoecyoxzgdraszzjb" -ForegroundColor Blue