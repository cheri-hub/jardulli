# Teste da Edge Function ai-chat
# Verifica se esta funcionando corretamente

Write-Host "Testando Edge Function ai-chat..." -ForegroundColor Cyan
Write-Host ""

$projectUrl = "https://gplumtfxxhgckjkgloni.supabase.co"
$anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3ODU0MTYsImV4cCI6MjA3NjM2MTQxNn0.bGuIT3tLN5rNgvalJD9C8G6tN6FPqfuO2Zez64-ceqg"

# Primeiro, fazer login para obter userId
Write-Host "1. Fazendo login..." -ForegroundColor Yellow

$loginHeaders = @{
    "apikey" = $anonKey
    "Authorization" = "Bearer $anonKey"
    "Content-Type" = "application/json"
}

$loginBody = @{
    email = "teste@jardulli.com"
    password = "teste123456"
} | ConvertTo-Json

try {
    $loginUrl = "$projectUrl/auth/v1/token?grant_type=password"
    $authResponse = Invoke-RestMethod -Uri $loginUrl -Method POST -Headers $loginHeaders -Body $loginBody
    
    $accessToken = $authResponse.access_token
    $userId = $authResponse.user.id
    
    Write-Host "   Login OK - User ID: $userId" -ForegroundColor Green
    Write-Host ""
    
    # Agora testar ai-chat
    Write-Host "2. Testando Edge Function ai-chat..." -ForegroundColor Yellow
    
    $chatHeaders = @{
        "Authorization" = "Bearer $accessToken"
        "apikey" = $anonKey
        "Content-Type" = "application/json"
    }
    
    $chatBody = @{
        message = "Qual o horario de atendimento?"
        userId = $userId
        conversationId = $null
    } | ConvertTo-Json
    
    $chatUrl = "$projectUrl/functions/v1/ai-chat"
    
    Write-Host "   Enviando pergunta..." -ForegroundColor Gray
    Write-Host "   URL: $chatUrl" -ForegroundColor DarkGray
    
    $chatResponse = Invoke-RestMethod -Uri $chatUrl -Method POST -Headers $chatHeaders -Body $chatBody
    
    Write-Host ""
    Write-Host "Sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Resposta da IA:" -ForegroundColor Cyan
    Write-Host $chatResponse.response -ForegroundColor White
    Write-Host ""
    Write-Host "Conversation ID: $($chatResponse.conversationId)" -ForegroundColor Gray
    Write-Host "Sources Count: $($chatResponse.sourcesCount)" -ForegroundColor Gray
    
} catch {
    Write-Host ""
    Write-Host "Erro!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.ErrorDetails.Message) {
        Write-Host ""
        Write-Host "Detalhes do erro:" -ForegroundColor Yellow
        Write-Host $_.ErrorDetails.Message -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Possiveis causas:" -ForegroundColor Cyan
    Write-Host "  1. GEMINI_API_KEY nao configurada nas Edge Function Secrets" -ForegroundColor White
    Write-Host "  2. GEMINI_MODEL nao configurada" -ForegroundColor White
    Write-Host "  3. Erro no codigo da Edge Function" -ForegroundColor White
    Write-Host ""
    Write-Host "Verifique:" -ForegroundColor Yellow
    Write-Host "  https://supabase.com/dashboard/project/gplumtfxxhgckjkgloni/settings/functions" -ForegroundColor Gray
    Write-Host ""
    Write-Host "As secrets devem ter:" -ForegroundColor Yellow
    Write-Host "  GEMINI_API_KEY = AIzaSyACfNvh_gwmIgpddUS-A3Wb2UTarR4myQw" -ForegroundColor White
    Write-Host "  GEMINI_MODEL = gemini-2.0-flash-exp" -ForegroundColor White
}
