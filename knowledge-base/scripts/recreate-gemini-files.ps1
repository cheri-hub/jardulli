# Script para recriar arquivos no Gemini File API
# Solução completa para o erro: Files not accessible (403 Forbidden)

Write-Host "Recriando arquivos no Gemini File API..." -ForegroundColor Cyan
Write-Host ""

# Gerar UUIDs para os novos uploads
$file1Id = [System.Guid]::NewGuid().ToString()
$file2Id = [System.Guid]::NewGuid().ToString() 
$file3Id = [System.Guid]::NewGuid().ToString()

Write-Host "UUIDs gerados:" -ForegroundColor Yellow
Write-Host "  01.pdf: $file1Id" -ForegroundColor White
Write-Host "  02.pdf: $file2Id" -ForegroundColor White  
Write-Host "  03.pdf: $file3Id" -ForegroundColor White
Write-Host ""

# Lista dos arquivos
$files = @(
    @{ id = $file1Id; path = "docs\01.pdf"; name = "Manual Jardulli - Parte 1" },
    @{ id = $file2Id; path = "docs\02.pdf"; name = "Manual Jardulli - Parte 2" },
    @{ id = $file3Id; path = "docs\03.pdf"; name = "Manual Jardulli - Parte 3" }
)

$supabaseUrl = "https://gplumtfxxhgckjkgloni.supabase.co"
$anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3ODU0MTYsImV4cCI6MjA3NjM2MTQxNn0.bGuIT3tLN5rNgvalJD9C8G6tN6FPqfuO2Zez64-ceqg"

foreach ($file in $files) {
    Write-Host "Processando: $($file.name)" -ForegroundColor Yellow
    
    if (Test-Path $file.path) {
        try {
            # Passo 1: Upload para Supabase Storage
            Write-Host "  Fazendo upload para Storage..." -ForegroundColor Gray
            
            $uploadUrl = "$supabaseUrl/storage/v1/object/documents/$($file.id).pdf"
            $fileContent = [System.IO.File]::ReadAllBytes($file.path)
            
            $uploadHeaders = @{
                "Authorization" = "Bearer $anonKey"
                "Content-Type" = "application/pdf"
            }
            
            $uploadResponse = Invoke-RestMethod -Uri $uploadUrl -Method POST -Headers $uploadHeaders -Body $fileContent
            Write-Host "  Upload para Storage OK!" -ForegroundColor Green
            
            # Passo 2: Inserir na tabela cache  
            Write-Host "  Inserindo na tabela cache..." -ForegroundColor Gray
            
            $cacheUrl = "$supabaseUrl/rest/v1/gemini_file_cache"
            $cacheData = @{
                id = $file.id
                file_name = $file.name
                file_path = "documents/$($file.id).pdf"
                processed = $false
            } | ConvertTo-Json
            
            $cacheHeaders = @{
                "Authorization" = "Bearer $anonKey"
                "Content-Type" = "application/json"
                "Prefer" = "return=minimal"
            }
            
            $cacheResponse = Invoke-RestMethod -Uri $cacheUrl -Method POST -Headers $cacheHeaders -Body $cacheData
            Write-Host "  Inserção na cache OK!" -ForegroundColor Green
            
            # Passo 3: Processar no Gemini via Edge Function
            Write-Host "  Processando no Gemini..." -ForegroundColor Gray
            
            $geminiUrl = "$supabaseUrl/functions/v1/upload-gemini-files"
            $geminiData = @{
                fileId = $file.id
            } | ConvertTo-Json
            
            $geminiHeaders = @{
                "Authorization" = "Bearer $anonKey"
                "Content-Type" = "application/json"
            }
            
            $geminiResponse = Invoke-RestMethod -Uri $geminiUrl -Method POST -Headers $geminiHeaders -Body $geminiData
            
            if ($geminiResponse.success) {
                Write-Host "  Gemini processamento OK!" -ForegroundColor Green
                Write-Host "  File ID Gemini: $($geminiResponse.geminiFileId)" -ForegroundColor White
            } else {
                Write-Host "  Erro no Gemini: $($geminiResponse.error)" -ForegroundColor Red
            }
            
        } catch {
            Write-Host "  ERRO: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  Arquivo não encontrado: $($file.path)" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "Processo de recriação concluído!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Novos IDs para atualizar na documentação:" -ForegroundColor Yellow
Write-Host "  files/[ID-DO-01.pdf]" -ForegroundColor White
Write-Host "  files/[ID-DO-02.pdf]" -ForegroundColor White
Write-Host "  files/[ID-DO-03.pdf]" -ForegroundColor White