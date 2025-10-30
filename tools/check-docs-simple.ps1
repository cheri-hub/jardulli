# Diagnóstico simples da base de conhecimento
$projectUrl = "https://gplumtfxxhgckjkgloni.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDc4NTQxNiwiZXhwIjoyMDc2MzYxNDE2fQ.KXPaXMxZWmJI9DYddQeCJlxK2AdHpMngkqejjyQ9r8U"

Write-Host "Verificando arquivos..." -ForegroundColor Cyan

$headers = @{
    "Authorization" = "Bearer $serviceRoleKey"
    "apikey" = $serviceRoleKey
}

$body = @{ prefix = "" } | ConvertTo-Json
$response = Invoke-RestMethod -Uri "$projectUrl/storage/v1/object/list/documentos" -Headers $headers -Method POST -ContentType "application/json" -Body $body

Write-Host "Arquivos encontrados: $($response.Count)" -ForegroundColor Green

if ($response) {
    foreach ($file in $response) {
        Write-Host "- $($file.name)" -ForegroundColor White
    }
}

Write-Host "Concluido!" -ForegroundColor Cyan