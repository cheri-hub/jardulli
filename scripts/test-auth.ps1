# Teste de autenticacao do Supabase
# Verifica se signup e login estao funcionando

Write-Host "Testando autenticacao do Supabase..." -ForegroundColor Cyan
Write-Host ""

$projectUrl = "https://gplumtfxxhgckjkgloni.supabase.co"
$anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3ODU0MTYsImV4cCI6MjA3NjM2MTQxNn0.bGuIT3tLN5rNgvalJD9C8G6tN6FPqfuO2Zez64-ceqg"

$headers = @{
    "apikey" = $anonKey
    "Authorization" = "Bearer $anonKey"
    "Content-Type" = "application/json"
}

# Tentar fazer login com credenciais de teste
$email = "teste@jardulli.com"
$password = "teste123456"

Write-Host "Tentando fazer login com:" -ForegroundColor Yellow
Write-Host "  Email: $email" -ForegroundColor White
Write-Host "  Password: ******" -ForegroundColor White
Write-Host ""

$loginBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $loginUrl = "$projectUrl/auth/v1/token?grant_type=password"
    
    $response = Invoke-RestMethod `
        -Uri $loginUrl `
        -Method POST `
        -Headers $headers `
        -Body $loginBody
    
    Write-Host "Login bem-sucedido!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access Token: $($response.access_token.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host "User ID: $($response.user.id)" -ForegroundColor White
    Write-Host "Email: $($response.user.email)" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "Erro ao fazer login:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.ErrorDetails.Message) {
        $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host ""
        Write-Host "Detalhes do erro:" -ForegroundColor Yellow
        Write-Host "  Mensagem: $($errorJson.msg)" -ForegroundColor White
        Write-Host "  Erro: $($errorJson.error_description)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Solucoes:" -ForegroundColor Cyan
    Write-Host "  1. Verifique se o email esta confirmado no dashboard" -ForegroundColor White
    Write-Host "  2. Desabilite confirmacao de email em Auth Settings" -ForegroundColor White
    Write-Host "  3. Tente criar uma nova conta" -ForegroundColor White
    Write-Host ""
    Write-Host "Dashboard: https://supabase.com/dashboard/project/gplumtfxxhgckjkgloni/auth/users" -ForegroundColor Gray
}
