# Aplicar Migrations no Ambiente HML
Write-Host "📊 Aplicando migrations no HML..." -ForegroundColor Green

# Verificar se está na pasta correta
if (-not (Test-Path "backend/supabase/migrations")) {
    Write-Host "❌ Execute este script na raiz do projeto" -ForegroundColor Red
    exit 1
}

cd backend/supabase

# Link para o projeto HML
Write-Host "🔗 Conectando ao projeto HML..." -ForegroundColor Blue
supabase link --project-ref aoktoecyoxzgdraszzjb

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao conectar projeto HML" -ForegroundColor Red
    Write-Host "💡 Certifique-se que o Supabase CLI está instalado: npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

# Aplicar migrations
Write-Host "📝 Aplicando todas as migrations..." -ForegroundColor Blue
supabase db push

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Migrations aplicadas com sucesso!" -ForegroundColor Green
    Write-Host "📊 Verificando tabelas criadas..." -ForegroundColor Blue
    
    # Lista tabelas criadas
    Write-Host "🔍 Tabelas esperadas:" -ForegroundColor Blue
    Write-Host "   - conversations" -ForegroundColor Gray
    Write-Host "   - messages" -ForegroundColor Gray
    Write-Host "   - message_feedback" -ForegroundColor Gray
    Write-Host "   - gemini_file_cache" -ForegroundColor Gray
    Write-Host "   - gemini_usage_metrics ⭐ (NOVA)" -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "🎯 Próximo passo: configurar variáveis de ambiente no dashboard Supabase" -ForegroundColor Yellow
    Write-Host "📝 Variáveis necessárias:" -ForegroundColor Blue
    Write-Host "   - GEMINI_API_KEY" -ForegroundColor Gray
    Write-Host "   - GEMINI_MODEL=gemini-2.0-flash-exp" -ForegroundColor Gray
} else {
    Write-Host "❌ Erro ao aplicar migrations" -ForegroundColor Red
    Write-Host "💡 Verifique se o projeto HML existe e você tem permissão" -ForegroundColor Yellow
}

cd ..\..