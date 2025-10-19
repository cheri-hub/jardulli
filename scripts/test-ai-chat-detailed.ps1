# Script para testar a Edge Function ai-chat com detalhes

Write-Host "Testando Edge Function ai-chat..." -ForegroundColor Cyan
Write-Host ""

# Configuração
$projectRef = "gplumtfxxhgckjkgloni"
$anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3ODU0MTYsImV4cCI6MjA3NjM2MTQxNn0.bGuIT3tLN5rNgvalJD9C8G6tN6FPqfuO2Zez64-ceqg"

# Pegar JWT token de um usuário autenticado
Write-Host "Cole o Access Token JWT do usuario (pode pegar do DevTools > Application > Local Storage):" -ForegroundColor Yellow
$accessToken = Read-Host

$url = "https://$projectRef.supabase.co/functions/v1/ai-chat"

$headers = @{
    "Authorization" = "Bearer $accessToken"
    "apikey" = $anonKey
    "Content-Type" = "application/json"
}

$body = @{
    message = "Qual o horário de atendimento?"
    conversationId = "test-conv-id"
    userId = "test-user-id"
} | ConvertTo-Json

Write-Host "Enviando requisição..." -ForegroundColor Cyan
Write-Host "URL: $url" -ForegroundColor Gray
Write-Host "Body: $body" -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri $url -Method POST -Headers $headers -Body $body -UseBasicParsing
    
    Write-Host "✅ Sucesso!" -ForegroundColor Green
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Green
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
    
} catch {
    Write-Host "❌ Erro!" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body:" -ForegroundColor Yellow
        Write-Host $responseBody -ForegroundColor Yellow
    }
}
