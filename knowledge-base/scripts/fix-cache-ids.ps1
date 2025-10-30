# Atualiza registros existentes com novos File IDs
# Corrige os IDs antigos que expiraram

Write-Host "Atualizando registros existentes..." -ForegroundColor Cyan
Write-Host ""

$supabaseUrl = "https://gplumtfxxhgckjkgloni.supabase.co"
$headers = @{
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDc4NTQxNiwiZXhwIjoyMDc2MzYxNDE2fQ.KXPaXMxZWmJI9DYddQeCJlxK2AdHpMngkqejjyQ9r8U"
    "apikey" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDc4NTQxNiwiZXhwIjoyMDc2MzYxNDE2fQ.KXPaXMxZWmJI9DYddQeCJlxK2AdHpMngkqejjyQ9r8U"
    "Content-Type" = "application/json"
    "Prefer" = "return=minimal"
}

# Mapeamento dos IDs antigos para novos
$updates = @(
    @{
        oldId = "files/2fq17czmwe32"
        newId = "files/m6b9x13x6bsn" 
        newUri = "https://generativelanguage.googleapis.com/v1beta/files/m6b9x13x6bsn"
        name = "Manual Jardulli - Parte 1"
    },
    @{
        oldId = "files/ojsr3jnxjs3s"
        newId = "files/03fnovqvndlr"
        newUri = "https://generativelanguage.googleapis.com/v1beta/files/03fnovqvndlr" 
        name = "Manual Jardulli - Parte 2"
    },
    @{
        oldId = "files/fpfmb430cayi"
        newId = "files/yymm0m09angx"
        newUri = "https://generativelanguage.googleapis.com/v1beta/files/yymm0m09angx"
        name = "Manual Jardulli - Parte 3"
    }
)

foreach ($update in $updates) {
    Write-Host "Atualizando $($update.name)..." -ForegroundColor Yellow
    Write-Host "  De: $($update.oldId)" -ForegroundColor Gray
    Write-Host "  Para: $($update.newId)" -ForegroundColor Gray
    
    try {
        $updateData = @{
            gemini_name = $update.newId
            gemini_uri = $update.newUri
            gemini_file_state = "ACTIVE"
            updated_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        } | ConvertTo-Json
        
        $updateUrl = "$supabaseUrl/rest/v1/gemini_file_cache?gemini_name=eq.$($update.oldId)"
        
        $result = Invoke-RestMethod -Uri $updateUrl -Headers $headers -Method PATCH -Body $updateData
        
        Write-Host "  SUCESSO!" -ForegroundColor Green
        
    } catch {
        Write-Host "  ERRO: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "Verificando resultado final..." -ForegroundColor Cyan

try {
    $activeFiles = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/gemini_file_cache?gemini_file_state=eq.ACTIVE&select=display_name,gemini_name,gemini_file_state" -Headers $headers -Method GET
    
    if ($activeFiles -and $activeFiles.Count -gt 0) {
        Write-Host "Arquivos ATIVOS atualizados:" -ForegroundColor Green
        
        foreach ($file in $activeFiles) {
            Write-Host "  - $($file.display_name)" -ForegroundColor White
            Write-Host "    ID: $($file.gemini_name)" -ForegroundColor Yellow
            Write-Host "    Estado: $($file.gemini_file_state)" -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host "Nenhum arquivo ativo!" -ForegroundColor Red
    }
} catch {
    Write-Host "Erro ao verificar: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Atualizacao concluida!" -ForegroundColor Cyan
Write-Host ""
Write-Host "PROXIMO PASSO: Teste o chat" -ForegroundColor Yellow
Write-Host "Comando: .\scripts\test-ai-chat.ps1" -ForegroundColor Gray