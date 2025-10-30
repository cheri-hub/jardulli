# Re-upload dos PDFs para Gemini File API
# Solução para o erro: Files not accessible (403 Forbidden)

Write-Host "Re-upload de PDFs para Gemini File API..." -ForegroundColor Cyan
Write-Host ""

$apiKey = "AIzaSyACfNvh_gwmIgpddUS-A3Wb2UTarR4myQw"

# Lista dos arquivos para upload
$pdfs = @(
    @{ path = "docs\01.pdf"; name = "Manual Jardulli - Parte 1" },
    @{ path = "docs\02.pdf"; name = "Manual Jardulli - Parte 2" },
    @{ path = "docs\03.pdf"; name = "Manual Jardulli - Parte 3" }
)

foreach ($pdf in $pdfs) {
    Write-Host "Processando: $($pdf.name)" -ForegroundColor Yellow
    
    if (Test-Path $pdf.path) {
        try {
            # Passo 1: Inicializar upload
            $startUrl = "https://generativelanguage.googleapis.com/upload/v1beta/files?key=$apiKey"
            
            $metadata = @{
                file = @{
                    displayName = $pdf.name
                }
            } | ConvertTo-Json -Depth 3
            
            $headers = @{
                "X-Goog-Upload-Protocol" = "resumable"
                "X-Goog-Upload-Command" = "start"
                "X-Goog-Upload-Header-Content-Length" = (Get-Item $pdf.path).Length
                "X-Goog-Upload-Header-Content-Type" = "application/pdf"
                "Content-Type" = "application/json"
            }
            
            Write-Host "  Iniciando upload..." -ForegroundColor Gray
            $startResponse = Invoke-RestMethod -Uri $startUrl -Method POST -Headers $headers -Body $metadata
            
            if ($startResponse.file -and $startResponse.file.uri) {
                Write-Host "  Upload iniciado com sucesso!" -ForegroundColor Green
                Write-Host "  File ID: $($startResponse.file.name)" -ForegroundColor White
                Write-Host "  URI: $($startResponse.file.uri)" -ForegroundColor Gray
                Write-Host ""
            } else {
                Write-Host "  Erro: Resposta inesperada do servidor" -ForegroundColor Red
                Write-Host ""
            }
            
        } catch {
            Write-Host "  Erro no upload: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host ""
        }
    } else {
        Write-Host "  Arquivo não encontrado: $($pdf.path)" -ForegroundColor Red
        Write-Host ""
    }
}

Write-Host "Re-upload concluído!" -ForegroundColor Cyan