# Upload direto para Gemini File API
# Bypass da Edge Function

Write-Host "Upload direto para Gemini File API" -ForegroundColor Cyan
Write-Host ""

$apiKey = "AIzaSyACfNvh_gwmIgpddUS-A3Wb2UTarR4myQw"
$filePath = "docs\jardulli-info.md"

if (-not (Test-Path $filePath)) {
    Write-Host "Erro: Arquivo nao encontrado" -ForegroundColor Red
    exit 1
}

# Ler arquivo
$fileContent = Get-Content $filePath -Raw -Encoding UTF8
$fileName = Split-Path $filePath -Leaf

Write-Host "Arquivo: $fileName" -ForegroundColor Green
Write-Host "Tamanho: $($fileContent.Length) bytes" -ForegroundColor Yellow
Write-Host ""

# Upload para Gemini
Write-Host "Enviando para Gemini File API..." -ForegroundColor Cyan

$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

$bodyLines = (
    "--$boundary",
    "Content-Disposition: form-data; name=`"metadata`"",
    "Content-Type: application/json; charset=UTF-8",
    "",
    "{`"file`": {`"displayName`": `"$fileName`"}}",
    "--$boundary",
    "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
    "Content-Type: text/markdown",
    "",
    $fileContent,
    "--$boundary--"
) -join $LF

$headers = @{
    "X-Goog-Upload-Protocol" = "multipart"
}

try {
    $url = "https://generativelanguage.googleapis.com/upload/v1beta/files?key=$apiKey"
    
    $response = Invoke-RestMethod `
        -Uri $url `
        -Method POST `
        -Headers $headers `
        -ContentType "multipart/related; boundary=$boundary" `
        -Body $bodyLines
    
    Write-Host ""
    Write-Host "Sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Detalhes do arquivo no Gemini:" -ForegroundColor Cyan
    Write-Host "  Name: $($response.file.name)" -ForegroundColor White
    Write-Host "  URI: $($response.file.uri)" -ForegroundColor Gray
    Write-Host "  Display Name: $($response.file.displayName)" -ForegroundColor White
    Write-Host "  MIME Type: $($response.file.mimeType)" -ForegroundColor White
    Write-Host "  State: $($response.file.state)" -ForegroundColor Yellow
    Write-Host ""
    
    if ($response.file.state -eq "PROCESSING") {
        Write-Host "Aguardando processamento..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        
        # Verificar status
        $statusUrl = "https://generativelanguage.googleapis.com/v1beta/$($response.file.name)?key=$apiKey"
        $status = Invoke-RestMethod -Uri $statusUrl -Method GET
        
        Write-Host "Status atualizado: $($status.state)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Arquivo pronto para uso no chat!" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "Erro:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    
    if ($_.ErrorDetails.Message) {
        Write-Host ""
        Write-Host "Detalhes:" -ForegroundColor Yellow
        Write-Host $_.ErrorDetails.Message
    }
    
    exit 1
}
