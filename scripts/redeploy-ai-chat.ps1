# Script para fazer redeploy da Edge Function ai-chat

Write-Host "Fazendo redeploy da Edge Function ai-chat..." -ForegroundColor Cyan
Write-Host ""

# Adicionar scoop ao PATH
$env:PATH += ";C:\Users\luism\scoop\shims"
$env:SUPABASE_ACCESS_TOKEN = "sbp_36017abf392a8b5a02dac8b0f7c32d9c9abdaa86"

# Verificar se supabase esta disponivel
$supabasePath = Get-Command supabase -ErrorAction SilentlyContinue

if (-not $supabasePath) {
    Write-Host "Erro: Supabase CLI nao encontrado" -ForegroundColor Red
    Write-Host "Tentando usar caminho completo..." -ForegroundColor Yellow
    
    $supabaseExe = "C:\Users\luism\scoop\shims\supabase.exe"
    
    if (Test-Path $supabaseExe) {
        Write-Host "Encontrado em: $supabaseExe" -ForegroundColor Green
        & $supabaseExe functions deploy ai-chat
    } else {
        Write-Host "Supabase CLI nao instalado. Execute:" -ForegroundColor Red
        Write-Host "scoop install supabase" -ForegroundColor White
        exit 1
    }
} else {
    supabase functions deploy ai-chat
}

Write-Host ""
Write-Host "Deploy concluido com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "Aguarde 30 segundos e teste novamente no chat." -ForegroundColor Yellow
