# Cadastrar PDFs na tabela gemini_file_cache
$projectUrl = "https://gplumtfxxhgckjkgloni.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDc4NTQxNiwiZXhwIjoyMDc2MzYxNDE2fQ.KXPaXMxZWmJI9DYddQeCJlxK2AdHpMngkqejjyQ9r8U"

Write-Host "Cadastrando PDFs na tabela cache..." -ForegroundColor Cyan

$headers = @{
    "Authorization" = "Bearer $serviceRoleKey"
    "apikey" = $serviceRoleKey
    "Content-Type" = "application/json"
}

# Lista dos PDFs para cadastrar
$pdfs = @(
    @{ 
        original_path = "01.pdf"; 
        display_name = "Documento 01"; 
        mime_type = "application/pdf";
        file_hash = "hash_01_pdf";
        gemini_name = "doc_01";
        gemini_uri = "gs://generativelanguage-download/doc_01";
        file_size_bytes = 1000
    },
    @{ 
        original_path = "02.pdf"; 
        display_name = "Documento 02"; 
        mime_type = "application/pdf";
        file_hash = "hash_02_pdf";
        gemini_name = "doc_02";
        gemini_uri = "gs://generativelanguage-download/doc_02";
        file_size_bytes = 1000
    },
    @{ 
        original_path = "03.pdf"; 
        display_name = "Documento 03"; 
        mime_type = "application/pdf";
        file_hash = "hash_03_pdf";
        gemini_name = "doc_03";
        gemini_uri = "gs://generativelanguage-download/doc_03";
        file_size_bytes = 1000
    }
)

foreach ($pdf in $pdfs) {
    try {
        $body = $pdf | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "$projectUrl/rest/v1/gemini_file_cache" -Headers $headers -Method POST -Body $body
        Write-Host "✅ Cadastrado: $($pdf.display_name)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erro ao cadastrar $($pdf.display_name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Concluido!" -ForegroundColor Cyan