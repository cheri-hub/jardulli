# Script para visualizar logs da Edge Function ai-chat

Write-Host "Visualizando logs da Edge Function ai-chat..." -ForegroundColor Cyan
Write-Host ""

$env:SUPABASE_ACCESS_TOKEN = "sbp_36017abf392a8b5a02dac8b0f7c32d9c9abdaa86"

C:\Users\luism\scoop\shims\supabase.exe functions logs ai-chat --project-ref gplumtfxxhgckjkgloni
