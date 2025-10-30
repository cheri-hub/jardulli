# Script para obter as keys do Supabase via API

Write-Host "Obtendo configuracoes do Supabase..." -ForegroundColor Cyan
Write-Host ""

$projectRef = "gplumtfxxhgckjkgloni"
$accessToken = "sbp_36017abf392a8b5a02dac8b0f7c32d9c9abdaa86"

$headers = @{
    "Authorization" = "Bearer $accessToken"
}

try {
    # Buscar configuracoes do projeto
    $url = "https://api.supabase.com/v1/projects/$projectRef/api-keys"
    
    $response = Invoke-RestMethod `
        -Uri $url `
        -Method GET `
        -Headers $headers
    
    Write-Host "Keys encontradas:" -ForegroundColor Green
    Write-Host ""
    
    foreach ($key in $response) {
        Write-Host "Nome: $($key.name)" -ForegroundColor Yellow
        Write-Host "Chave: $($key.api_key)" -ForegroundColor White
        Write-Host ""
    }
    
} catch {
    Write-Host "Erro ao obter keys:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Por favor, acesse manualmente:" -ForegroundColor Yellow
    Write-Host "https://supabase.com/dashboard/project/$projectRef/settings/api" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "E copie a chave 'anon public'" -ForegroundColor White
}
