# Salvar arquivo no cache do banco
# Depois de fazer upload manual

Write-Host "Salvando no cache do banco..." -ForegroundColor Cyan

$projectUrl = "https://gplumtfxxhgckjkgloni.supabase.co"
$serviceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDc4NTQxNiwiZXhwIjoyMDc2MzYxNDE2fQ.KXPaXMxZWmJI9DYddQeCJlxK2AdHpMngkqejjyQ9r8U"

# Calcular hash do arquivo
$filePath = "docs\jardulli-info.md"
$fileContent = Get-Content $filePath -Raw -Encoding UTF8
$bytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)

$sha256 = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $sha256.ComputeHash($bytes)
$hash = [System.BitConverter]::ToString($hashBytes).Replace("-","").ToLower()

Write-Host "Hash SHA256: $hash" -ForegroundColor Yellow

# Dados do Gemini (do upload mais recente)
$geminiName = "files/czlnr7yti9jy"
$geminiUri = "https://generativelanguage.googleapis.com/v1beta/files/czlnr7yti9jy"

$headers = @{
    "Authorization" = "Bearer $serviceKey"
    "Content-Type" = "application/json"
    "apikey" = $serviceKey
}

$body = @{
    file_hash = $hash
    gemini_name = $geminiName
    gemini_uri = $geminiUri
    mime_type = "text/markdown"
    display_name = "jardulli-info.md"
    original_path = "docs/jardulli-info.md"
} | ConvertTo-Json

try {
    $url = "$projectUrl/rest/v1/gemini_file_cache"
    
    $response = Invoke-RestMethod `
        -Uri $url `
        -Method POST `
        -Headers $headers `
        -Body $body
    
    Write-Host ""
    Write-Host "Sucesso! Arquivo salvo no cache." -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "Erro ao salvar no cache:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    
    if ($_.ErrorDetails.Message) {
        Write-Host "Detalhes:" -ForegroundColor Yellow
        Write-Host $_.ErrorDetails.Message
    }
}
