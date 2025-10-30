# Atualiza tabela gemini_file_cache com novos File IDs
# Solução para conectar arquivos recriados ao sistema

Write-Host "Atualizando tabela gemini_file_cache..." -ForegroundColor Cyan
Write-Host ""

$supabaseUrl = "https://gplumtfxxhgckjkgloni.supabase.co"
$headers = @{
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDc4NTQxNiwiZXhwIjoyMDc2MzYxNDE2fQ.KXPaXMxZWmJI9DYddQeCJlxK2AdHpMngkqejjyQ9r8U"
    "apikey" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDc4NTQxNiwiZXhwIjoyMDc2MzYxNDE2fQ.KXPaXMxZWmJI9DYddQeCJlxK2AdHpMngkqejjyQ9r8U"
    "Content-Type" = "application/json"
}

# Novos arquivos criados
$newFiles = @(
    @{
        id = [System.Guid]::NewGuid().ToString()
        display_name = "Manual Jardulli - Parte 1"
        gemini_name = "files/m6b9x13x6bsn"
        gemini_uri = "https://generativelanguage.googleapis.com/v1beta/files/m6b9x13x6bsn"
        mime_type = "application/pdf"
    },
    @{
        id = [System.Guid]::NewGuid().ToString()
        display_name = "Manual Jardulli - Parte 2"
        gemini_name = "files/03fnovqvndlr"
        gemini_uri = "https://generativelanguage.googleapis.com/v1beta/files/03fnovqvndlr"
        mime_type = "application/pdf"
    },
    @{
        id = [System.Guid]::NewGuid().ToString()
        display_name = "Manual Jardulli - Parte 3"
        gemini_name = "files/yymm0m09angx"
        gemini_uri = "https://generativelanguage.googleapis.com/v1beta/files/yymm0m09angx"
        mime_type = "application/pdf"
    }
)

Write-Host "Inserindo novos registros na tabela..." -ForegroundColor Yellow

foreach ($file in $newFiles) {
    Write-Host "  Processando: $($file.display_name)" -ForegroundColor White
    
    try {
        $record = @{
            id = $file.id
            display_name = $file.display_name
            gemini_name = $file.gemini_name
            gemini_uri = $file.gemini_uri
            mime_type = $file.mime_type
            gemini_file_state = "ACTIVE"
            processed_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            created_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            updated_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/gemini_file_cache" -Headers $headers -Method POST -Body $record
        
        Write-Host "    SUCESSO - ID: $($file.id)" -ForegroundColor Green
        
    } catch {
        Write-Host "    ERRO: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Verificando registros atualizados..." -ForegroundColor Yellow

try {
    $activeFiles = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/gemini_file_cache?gemini_file_state=eq.ACTIVE&select=*" -Headers $headers -Method GET
    
    if ($activeFiles -and $activeFiles.Count -gt 0) {
        Write-Host "Arquivos ATIVOS na tabela:" -ForegroundColor Green
        
        foreach ($activeFile in $activeFiles) {
            Write-Host "  - $($activeFile.display_name)" -ForegroundColor White
            Write-Host "    ID: $($activeFile.gemini_name)" -ForegroundColor Gray
            Write-Host "    Estado: $($activeFile.gemini_file_state)" -ForegroundColor Gray
        }
    } else {
        Write-Host "Nenhum arquivo ativo encontrado!" -ForegroundColor Red
    }
} catch {
    Write-Host "Erro ao verificar registros: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Agora teste o chat para verificar se funciona!" -ForegroundColor Cyan
Write-Host "Comando: .\scripts\test-ai-chat.ps1" -ForegroundColor Gray