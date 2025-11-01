# Deploy Edge Functions para HML
Write-Host "🔧 Deployando Edge Functions para HML..." -ForegroundColor Green

# Verificar se Supabase CLI está instalado
try {
    $version = supabase --version 2>$null
    if (-not $version) {
        throw "Supabase CLI não encontrado"
    }
    Write-Host "✅ Supabase CLI encontrado: $version" -ForegroundColor Green
} catch {
    Write-Host "❌ Supabase CLI não encontrado. Instale com:" -ForegroundColor Red
    Write-Host "npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

Set-Location backend/supabase

Write-Host "📡 Deployando ai-chat..." -ForegroundColor Blue
supabase functions deploy ai-chat --project-ref aoktoecyoxzgdraszzjb

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ ai-chat deployado" -ForegroundColor Green
} else {
    Write-Host "❌ Erro no deploy ai-chat" -ForegroundColor Red
}

Write-Host "📡 Deployando send-whatsapp-feedback..." -ForegroundColor Blue  
supabase functions deploy send-whatsapp-feedback --project-ref aoktoecyoxzgdraszzjb

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ send-whatsapp-feedback deployado" -ForegroundColor Green
} else {
    Write-Host "❌ Erro no deploy send-whatsapp-feedback" -ForegroundColor Red
}

Write-Host "📡 Deployando upload-gemini-files..." -ForegroundColor Blue
supabase functions deploy upload-gemini-files --project-ref aoktoecyoxzgdraszzjb

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ upload-gemini-files deployado" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎉 Todas as Edge Functions deployadas com sucesso!" -ForegroundColor Green
    Write-Host "🔗 URL base: https://aoktoecyoxzgdraszzjb.supabase.co/functions/v1/" -ForegroundColor Blue
} else {
    Write-Host "❌ Erro no deploy upload-gemini-files" -ForegroundColor Red
}

Set-Location ..\..