# Setup do Ambiente HML - Scripts Automatizados

Write-Host "🏗️  Configurando ambiente HML para Jardulli..." -ForegroundColor Green

# Verificar se está na pasta correta
if (-not (Test-Path "backend/supabase/migrations")) {
    Write-Host "❌ Execute este script na raiz do projeto jardulli-bot-buddy" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Checklist - Informações Necessárias:" -ForegroundColor Yellow
Write-Host "1. Projeto HML criado no Supabase?" -ForegroundColor White
Write-Host "2. Project ID do HML anotado?" -ForegroundColor White
Write-Host "3. API Keys do HML coletadas?" -ForegroundColor White
Write-Host ""

# Solicitar informações do projeto HML
$ProjectId = Read-Host "Digite o Project ID do ambiente HML"
$ProjectUrl = Read-Host "Digite a URL do projeto HML (ex: https://abc123.supabase.co)"
$AnonKey = Read-Host "Digite a Anon Key do HML"
$ServiceKey = Read-Host "Digite a Service Role Key do HML"

Write-Host ""
Write-Host "🔧 Configurando ambiente local..." -ForegroundColor Blue

# Criar arquivo .env.hml
$EnvHmlContent = @"
# Jardulli HML Environment Configuration
# Created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Frontend Configuration
VITE_SUPABASE_URL=$ProjectUrl
VITE_SUPABASE_ANON_KEY=$AnonKey

# Backend Configuration (para testes locais)
SUPABASE_URL=$ProjectUrl
SUPABASE_ANON_KEY=$AnonKey
SUPABASE_SERVICE_ROLE_KEY=$ServiceKey

# Edge Functions Environment
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-2.0-flash-exp
ENVIRONMENT=hml
"@

$EnvHmlContent | Out-File -FilePath ".env.hml" -Encoding UTF8
Write-Host "✅ Arquivo .env.hml criado" -ForegroundColor Green

# Criar script de build HML
$BuildHmlScript = @"
# Build para Homologação - Jardulli
Write-Host "🚀 Building frontend para HML..." -ForegroundColor Green

cd frontend

# Configurar variáveis de ambiente HML
`$env:VITE_SUPABASE_URL="$ProjectUrl"
`$env:VITE_SUPABASE_ANON_KEY="$AnonKey"

# Build
npm run build

if (`$LASTEXITCODE -eq 0) {
    Write-Host "✅ Build HML concluído com sucesso!" -ForegroundColor Green
    Write-Host "📁 Arquivos em: frontend/dist/" -ForegroundColor Blue
    Write-Host "🌐 Para testar localmente: npm run preview" -ForegroundColor Blue
} else {
    Write-Host "❌ Erro no build" -ForegroundColor Red
}

cd ..
"@

$BuildHmlScript | Out-File -FilePath "tools/build-hml.ps1" -Encoding UTF8
Write-Host "✅ Script tools/build-hml.ps1 criado" -ForegroundColor Green

# Criar script de deploy de Edge Functions
$DeployFunctionsScript = @"
# Deploy Edge Functions para HML
Write-Host "🔧 Deployando Edge Functions para HML..." -ForegroundColor Green

# Verificar se Supabase CLI está instalado
try {
    supabase --version | Out-Null
} catch {
    Write-Host "❌ Supabase CLI não encontrado. Instale com: npm install -g supabase" -ForegroundColor Red
    exit 1
}

cd backend/supabase

Write-Host "📡 Deployando ai-chat..." -ForegroundColor Blue
supabase functions deploy ai-chat --project-ref $ProjectId

Write-Host "📡 Deployando send-whatsapp-feedback..." -ForegroundColor Blue  
supabase functions deploy send-whatsapp-feedback --project-ref $ProjectId

Write-Host "📡 Deployando upload-gemini-files..." -ForegroundColor Blue
supabase functions deploy upload-gemini-files --project-ref $ProjectId

if (`$LASTEXITCODE -eq 0) {
    Write-Host "✅ Edge Functions deployadas com sucesso!" -ForegroundColor Green
} else {
    Write-Host "❌ Erro no deploy das functions" -ForegroundColor Red
}

cd ../..
"@

$DeployFunctionsScript | Out-File -FilePath "tools/deploy-functions-hml.ps1" -Encoding UTF8
Write-Host "✅ Script tools/deploy-functions-hml.ps1 criado" -ForegroundColor Green

# Criar script de aplicação de migrations
$MigrationsScript = @"
# Aplicar Migrations no Ambiente HML
Write-Host "📊 Aplicando migrations no HML..." -ForegroundColor Green

cd backend/supabase

# Link para o projeto HML
Write-Host "🔗 Conectando ao projeto HML..." -ForegroundColor Blue
supabase link --project-ref $ProjectId

# Aplicar migrations
Write-Host "📝 Aplicando todas as migrations..." -ForegroundColor Blue
supabase db push

if (`$LASTEXITCODE -eq 0) {
    Write-Host "✅ Migrations aplicadas com sucesso!" -ForegroundColor Green
    Write-Host "🎯 Próximo passo: configurar variáveis de ambiente no dashboard Supabase" -ForegroundColor Yellow
} else {
    Write-Host "❌ Erro ao aplicar migrations" -ForegroundColor Red
}

cd ../..
"@

$MigrationsScript | Out-File -FilePath "tools/apply-migrations-hml.ps1" -Encoding UTF8
Write-Host "✅ Script tools/apply-migrations-hml.ps1 criado" -ForegroundColor Green

# Criar script de teste
$TestScript = @"
# Testar Ambiente HML
Write-Host "🧪 Testando ambiente HML..." -ForegroundColor Green

# Testar conectividade básica
Write-Host "📡 Testando conectividade com Supabase..." -ForegroundColor Blue
try {
    `$response = Invoke-RestMethod -Uri "$ProjectUrl/rest/v1/" -Headers @{
        "apikey" = "$AnonKey"
        "Authorization" = "Bearer $AnonKey"
    }
    Write-Host "✅ Conectividade OK" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro de conectividade: `$_" -ForegroundColor Red
}

# Testar Edge Function
Write-Host "🤖 Testando Edge Function ai-chat..." -ForegroundColor Blue
`$testPayload = @{
    message = "Teste do ambiente HML"
    userId = "test-user-hml-123"
} | ConvertTo-Json

try {
    `$response = Invoke-RestMethod -Uri "$ProjectUrl/functions/v1/ai-chat" -Method Post -Body `$testPayload -Headers @{
        "apikey" = "$AnonKey"
        "Authorization" = "Bearer $AnonKey"
        "Content-Type" = "application/json"
    }
    Write-Host "✅ Edge Function respondeu: `$(`$response.success)" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro na Edge Function: `$_" -ForegroundColor Red
}

Write-Host "🎯 Teste manual: Acesse o frontend e faça login/chat" -ForegroundColor Yellow
"@

$TestScript | Out-File -FilePath "tools/test-hml.ps1" -Encoding UTF8
Write-Host "✅ Script tools/test-hml.ps1 criado" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 Setup automatizado concluído!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Próximos passos:" -ForegroundColor Yellow
Write-Host "1. Execute: .\tools\apply-migrations-hml.ps1" -ForegroundColor White
Write-Host "2. Configure variáveis de ambiente no dashboard Supabase HML" -ForegroundColor White
Write-Host "3. Execute: .\tools\deploy-functions-hml.ps1" -ForegroundColor White
Write-Host "4. Execute: .\tools\build-hml.ps1" -ForegroundColor White
Write-Host "5. Execute: .\tools\test-hml.ps1" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Variáveis para configurar no Supabase Dashboard:" -ForegroundColor Blue
Write-Host "   - GEMINI_API_KEY" -ForegroundColor Gray
Write-Host "   - GEMINI_MODEL=gemini-2.0-flash-exp" -ForegroundColor Gray
Write-Host ""
Write-Host "📁 Arquivos criados:" -ForegroundColor Blue
Write-Host "   - .env.hml" -ForegroundColor Gray
Write-Host "   - tools/build-hml.ps1" -ForegroundColor Gray  
Write-Host "   - tools/deploy-functions-hml.ps1" -ForegroundColor Gray
Write-Host "   - tools/apply-migrations-hml.ps1" -ForegroundColor Gray
Write-Host "   - tools/test-hml.ps1" -ForegroundColor Gray