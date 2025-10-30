# Verificar tabela de documentos
$projectUrl = "https://gplumtfxxhgckjkgloni.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDc4NTQxNiwiZXhwIjoyMDc2MzYxNDE2fQ.KXPaXMxZWmJI9DYddQeCJlxK2AdHpMngkqejjyQ9r8U"

Write-Host "Verificando tabela document_cache..." -ForegroundColor Cyan

$headers = @{
    "Authorization" = "Bearer $serviceRoleKey"
    "apikey" = $serviceRoleKey
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri "$projectUrl/rest/v1/gemini_file_cache?select=*" -Headers $headers -Method GET
    
    Write-Host "Documentos na tabela: $($response.Count)" -ForegroundColor Green
    
    if ($response) {
        foreach ($doc in $response) {
            Write-Host "- $($doc.display_name) ($($doc.original_path))" -ForegroundColor White
        }
    } else {
        Write-Host "Nenhum documento na tabela cache!" -ForegroundColor Red
    }
} catch {
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Concluido!" -ForegroundColor Cyan