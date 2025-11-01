# Script para verificar métricas de custo no HML

Write-Host "Verificando métricas de custo..." -ForegroundColor Green

$supabaseUrl = "https://aoktoecyoxzgdraszzjb.supabase.co"
$anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFva3RvZWN5b3h6Z2RyYXN6empiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5OTU4MjIsImV4cCI6MjA3NzU3MTgyMn0.1Eyr83dJNj1zzixUA4GC1c1zpgbcdp_mfgSWKlBI5gc"

try {
    $response = Invoke-WebRequest -Uri "$supabaseUrl/rest/v1/gemini_usage_metrics?select=*&order=created_at.desc" `
        -Method GET `
        -Headers @{
            "Authorization" = "Bearer $anonKey"
            "apikey" = $anonKey
            "Content-Type" = "application/json"
        } `
        -UseBasicParsing

    $metrics = $response.Content | ConvertFrom-Json
    
    Write-Host "Encontradas $($metrics.Count) métricas:" -ForegroundColor Yellow
    
    if ($metrics.Count -gt 0) {
        foreach ($metric in $metrics) {
            Write-Host "ID: $($metric.id)"
            Write-Host "User: $($metric.user_id)"  
            Write-Host "Modelo: $($metric.model_used)"
            Write-Host "Tokens: $($metric.total_tokens)"
            Write-Host "Custo: $($metric.total_cost_usd) USD"
            Write-Host "Duração: $($metric.request_duration_ms) ms"
            Write-Host "Data: $($metric.created_at)"
            Write-Host "-------------------"
        }
        
        $totalCost = ($metrics | Measure-Object -Property total_cost_usd -Sum).Sum
        Write-Host "CUSTO TOTAL: $totalCost USD" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
}