# Script para upload de documento e processamento no Gemini
# Jardulli Bot Buddy

Write-Host "Jardulli Bot Buddy - Upload de Documento" -ForegroundColor Cyan
Write-Host ""

# Configuracoes
$projectUrl = "https://gplumtfxxhgckjkgloni.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDc4NTQxNiwiZXhwIjoyMDc2MzYxNDE2fQ.KXPaXMxZWmJI9DYddQeCJlxK2AdHpMngkqejjyQ9r8U"

# Verificar se arquivo existe
$filePath = "docs\jardulli-info.md"
if (-not (Test-Path $filePath)) {
    Write-Host "Erro: Arquivo nao encontrado: $filePath" -ForegroundColor Red
    exit 1
}

Write-Host "Arquivo encontrado: $filePath" -ForegroundColor Green

# Ler conteudo do arquivo
$fileContent = Get-Content $filePath -Raw -Encoding UTF8
$fileName = Split-Path $filePath -Leaf
$bytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)

Write-Host "Tamanho: $($bytes.Length) bytes" -ForegroundColor Yellow
Write-Host ""

# Passo 1: Upload para Supabase Storage
Write-Host "Passo 1/2: Enviando para Supabase Storage..." -ForegroundColor Cyan

$headers = @{
    "Authorization" = "Bearer $serviceRoleKey"
    "Content-Type" = "text/markdown"
}

# Tentar fazer upload (POST)
try {
    $uploadUrl = "$projectUrl/storage/v1/object/documentos/$fileName"
    
    $uploadResponse = Invoke-RestMethod `
        -Uri $uploadUrl `
        -Method POST `
        -Headers $headers `
        -Body $bytes
    
    Write-Host "Arquivo enviado para Storage com sucesso!" -ForegroundColor Green
    Write-Host ""
} catch {
    # Se erro 400 (arquivo ja existe), tentar atualizar (PUT)
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "Arquivo ja existe, atualizando..." -ForegroundColor Yellow
        
        try {
            $uploadResponse = Invoke-RestMethod `
                -Uri $uploadUrl `
                -Method PUT `
                -Headers $headers `
                -Body $bytes
            
            Write-Host "Arquivo atualizado no Storage com sucesso!" -ForegroundColor Green
            Write-Host ""
        } catch {
            Write-Host "Erro ao atualizar arquivo:" -ForegroundColor Red
            Write-Host $_.Exception.Message
            exit 1
        }
    } else {
        Write-Host "Erro ao enviar para Storage:" -ForegroundColor Red
        Write-Host $_.Exception.Message
        exit 1
    }
}

# Passo 2: Processar no Gemini
Write-Host "Passo 2/2: Processando no Google Gemini..." -ForegroundColor Cyan

$processHeaders = @{
    "Authorization" = "Bearer $serviceRoleKey"
    "Content-Type" = "application/json"
}

$processBody = @{
    fileName = $fileName
    fileUrl = $fileName
} | ConvertTo-Json

try {
    $processUrl = "$projectUrl/functions/v1/upload-document"
    
    Write-Host "Aguarde, o Gemini esta processando o documento..." -ForegroundColor Yellow
    
    $processResponse = Invoke-RestMethod `
        -Uri $processUrl `
        -Method POST `
        -Headers $processHeaders `
        -Body $processBody
    
    Write-Host ""
    Write-Host "Documento processado com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Detalhes:" -ForegroundColor Cyan
    Write-Host "  Nome: $($processResponse.fileName)" -ForegroundColor White
    Write-Host "  Gemini Name: $($processResponse.geminiName)" -ForegroundColor White
    Write-Host "  URI: $($processResponse.geminiUri)" -ForegroundColor Gray
    Write-Host "  Cached: $($processResponse.cached)" -ForegroundColor White
    Write-Host ""
    Write-Host "Pronto! O documento ja pode ser usado no chat." -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "Erro ao processar no Gemini:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    
    if ($_.ErrorDetails.Message) {
        $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "Detalhes: $($errorJson.error)" -ForegroundColor Red
    }
    
    exit 1
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Proximos passos:" -ForegroundColor Yellow
Write-Host "  1. Acesse: http://localhost:8080" -ForegroundColor White
Write-Host "  2. Crie uma conta ou faca login" -ForegroundColor White
Write-Host "  3. Faca uma pergunta sobre o documento" -ForegroundColor White
Write-Host "     Ex: Qual o horario de atendimento?" -ForegroundColor Gray
Write-Host ""
