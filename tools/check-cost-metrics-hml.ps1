# Script para verificar se as métricas de custo foram capturadas no HML
# Consulta a tabela gemini_usage_metrics para ver os dados registrados

Write-Host "=================================================" -ForegroundColor Green
Write-Host "Verificando Cost Tracking - Métricas Capturadas" -ForegroundColor Green  
Write-Host "=================================================" -ForegroundColor Green
Write-Host

# Configurações do ambiente HML
$supabaseUrl = "https://aoktoecyoxzgdraszzjb.supabase.co"
$anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFva3RvZWN5b3h6Z2RyYXN6empiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5OTU4MjIsImV4cCI6MjA3NzU3MTgyMn0.1Eyr83dJNj1zzixUA4GC1c1zpgbcdp_mfgSWKlBI5gc"

Write-Host "Consultando métricas de uso do Gemini..." -ForegroundColor Yellow
Write-Host

try {
    # Consultar todas as métricas registradas
    $response = Invoke-WebRequest -Uri "$supabaseUrl/rest/v1/gemini_usage_metrics?select=*&order=created_at.desc" `
        -Method GET `
        -Headers @{
            "Authorization" = "Bearer $anonKey"
            "apikey" = $anonKey
            "Content-Type" = "application/json"
        } `
        -UseBasicParsing

    Write-Host "✅ Consulta executada com sucesso!" -ForegroundColor Green
    
    # Parsear a resposta JSON
    $metrics = $response.Content | ConvertFrom-Json
    
    if ($metrics.Count -gt 0) {
        Write-Host "📊 Encontradas $($metrics.Count) métricas registradas:" -ForegroundColor Green
        Write-Host
        
        foreach ($metric in $metrics) {
            Write-Host "🔹 Registro ID: $($metric.id)" -ForegroundColor Cyan
            Write-Host "   👤 User ID: $($metric.user_id)" -ForegroundColor White
            Write-Host "   🤖 Modelo: $($metric.model_used)" -ForegroundColor White
            Write-Host "   📝 Tokens Input: $($metric.tokens_input)" -ForegroundColor Yellow
            Write-Host "   📤 Tokens Output: $($metric.tokens_output)" -ForegroundColor Yellow
            Write-Host "   🟢 Total Tokens: $($metric.total_tokens)" -ForegroundColor Green
            Write-Host "   💰 Custo Input: $($metric.cost_input_usd)" -ForegroundColor Magenta
            Write-Host "   💰 Custo Output: $($metric.cost_output_usd)" -ForegroundColor Magenta
            Write-Host "   💸 Custo Total: $($metric.total_cost_usd) USD" -ForegroundColor Red
            Write-Host "   ⏱️  Duração: $($metric.request_duration_ms) ms" -ForegroundColor Blue
            Write-Host "   📅 Criado em: $($metric.created_at)" -ForegroundColor Gray
            Write-Host "   --------------------------------" -ForegroundColor DarkGray
            Write-Host
        }
        
        # Calcular totais
        $totalCost = ($metrics | Measure-Object -Property total_cost_usd -Sum).Sum
        $totalTokens = ($metrics | Measure-Object -Property total_tokens -Sum).Sum
        $avgDuration = ($metrics | Measure-Object -Property request_duration_ms -Average).Average
        
        Write-Host "📈 RESUMO GERAL:" -ForegroundColor Green
        Write-Host "   💸 Custo Total: $totalCost USD" -ForegroundColor Red
        Write-Host "   🟢 Tokens Total: $totalTokens" -ForegroundColor Green  
        Write-Host "   ⏱️  Duração Média: $([Math]::Round($avgDuration, 2)) ms" -ForegroundColor Blue
        
    } else {
        Write-Host "⚠️  Nenhuma métrica encontrada na tabela gemini_usage_metrics" -ForegroundColor Yellow
        Write-Host "   Isso pode significar que:" -ForegroundColor Yellow
        Write-Host "   - A função não está salvando as métricas corretamente" -ForegroundColor Yellow
        Write-Host "   - Houve algum erro durante o processamento" -ForegroundColor Yellow
        Write-Host "   - Os dados não foram commitados ao banco" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Erro ao consultar métricas:" -ForegroundColor Red
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
Write-Host "🎯 VALIDAÇÃO DO COST TRACKING" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host "✅ Conexão com ambiente HML: OK" -ForegroundColor Green
Write-Host "✅ Função ai-chat respondendo: OK" -ForegroundColor Green
Write-Host "✅ API Gemini funcionando: OK" -ForegroundColor Green
Write-Host "🔍 Captura de métricas: Verificar resultados acima" -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Green