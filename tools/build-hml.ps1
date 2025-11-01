# Build para Homologação - Jardulli
Write-Host "🚀 Building frontend para HML..." -ForegroundColor Green

Set-Location frontend

# Verificar se package.json existe
if (-not (Test-Path "package.json")) {
    Write-Host "❌ package.json não encontrado na pasta frontend" -ForegroundColor Red
    Set-Location ..
    exit 1
}

# Configurar variáveis de ambiente HML
$env:VITE_SUPABASE_URL="https://aoktoecyoxzgdraszzjb.supabase.co"
$env:VITE_SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFva3RvZWN5b3h6Z2RyYXN6empiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5OTU4MjIsImV4cCI6MjA3NzU3MTgyMn0.1Eyr83dJNj1zzixUA4GC1c1zpgbcdp_mfgSWKlBI5gc"

Write-Host "🔧 Variáveis de ambiente configuradas para HML" -ForegroundColor Blue
Write-Host "📍 URL: https://aoktoecyoxzgdraszzjb.supabase.co" -ForegroundColor Gray

# Build
Write-Host "📦 Executando npm run build..." -ForegroundColor Blue
npm run build

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build HML concluído com sucesso!" -ForegroundColor Green
    Write-Host "📁 Arquivos gerados em: frontend/dist/" -ForegroundColor Blue
    Write-Host "🌐 Para testar localmente: npm run preview" -ForegroundColor Blue
    Write-Host "🔗 Ou publique os arquivos de frontend/dist/ em seu provedor de hosting" -ForegroundColor Yellow
} else {
    Write-Host "❌ Erro no build" -ForegroundColor Red
    Write-Host "💡 Verifique se todas as dependências estão instaladas: npm install" -ForegroundColor Yellow
}

Set-Location ..