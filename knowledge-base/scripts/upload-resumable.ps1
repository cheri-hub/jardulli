# Upload resumavel para Gemini File API - Versão 2
# Solução para arquivos expirados

Write-Host "Upload resumavel para Gemini File API..." -ForegroundColor Cyan
Write-Host ""

$apiKey = "AIzaSyACfNvh_gwmIgpddUS-A3Wb2UTarR4myQw"

function New-GeminiUpload {
    param(
        [string]$filePath,
        [string]$displayName
    )
    
    Write-Host "Processando: $displayName" -ForegroundColor Yellow
    
    if (!(Test-Path $filePath)) {
        Write-Host "  ERRO: Arquivo não encontrado" -ForegroundColor Red
        return $null
    }
    
    try {
        $fileInfo = Get-Item $filePath
        $fileSize = $fileInfo.Length
        
        Write-Host "  Tamanho: $([math]::Round($fileSize/1024/1024, 2)) MB" -ForegroundColor Gray
        
        # Passo 1: Inicializar upload resumable
        $initUrl = "https://generativelanguage.googleapis.com/upload/v1beta/files?key=$apiKey"
        
        $metadata = @{
            file = @{
                displayName = $displayName
            }
        } | ConvertTo-Json -Depth 3
        
        $initHeaders = @{
            "X-Goog-Upload-Protocol" = "resumable"
            "X-Goog-Upload-Command" = "start"
            "X-Goog-Upload-Header-Content-Length" = $fileSize.ToString()
            "X-Goog-Upload-Header-Content-Type" = "application/pdf"
            "Content-Type" = "application/json"
        }
        
        Write-Host "  Iniciando sessao resumable..." -ForegroundColor Gray
        $initResponse = Invoke-WebRequest -Uri $initUrl -Method POST -Headers $initHeaders -Body $metadata -UseBasicParsing
        
        if ($initResponse.StatusCode -ne 200) {
            Write-Host "  ERRO no inicio: Status $($initResponse.StatusCode)" -ForegroundColor Red
            return $null
        }
        
        $uploadUrl = $initResponse.Headers["X-Goog-Upload-URL"]
        if (!$uploadUrl) {
            Write-Host "  ERRO: URL de upload nao retornada" -ForegroundColor Red
            return $null
        }
        
        Write-Host "  Enviando arquivo..." -ForegroundColor Gray
        
        # Passo 2: Upload dos dados
        $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
        
        $uploadHeaders = @{
            "X-Goog-Upload-Offset" = "0"
            "X-Goog-Upload-Command" = "upload, finalize"
            "Content-Length" = $fileSize.ToString()
        }
        
        $uploadResponse = Invoke-WebRequest -Uri $uploadUrl -Method POST -Headers $uploadHeaders -Body $fileBytes -UseBasicParsing -ContentType "application/pdf"
        
        if ($uploadResponse.StatusCode -eq 200) {
            $result = $uploadResponse.Content | ConvertFrom-Json
            
            if ($result.file -and $result.file.name) {
                Write-Host "  SUCESSO!" -ForegroundColor Green  
                Write-Host "    File ID: $($result.file.name)" -ForegroundColor White
                Write-Host "    Estado: $($result.file.state)" -ForegroundColor Gray
                
                return $result.file.name
            } else {
                Write-Host "  ERRO: Resposta invalida do Gemini" -ForegroundColor Red
                return $null
            }
        } else {
            Write-Host "  ERRO no upload: Status $($uploadResponse.StatusCode)" -ForegroundColor Red
            return $null
        }
        
    } catch {
        Write-Host "  ERRO: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Lista de arquivos
$files = @(
    @{ path = "docs\01.pdf"; name = "Manual Jardulli - Parte 1" },
    @{ path = "docs\02.pdf"; name = "Manual Jardulli - Parte 2" },  
    @{ path = "docs\03.pdf"; name = "Manual Jardulli - Parte 3" }
)

$uploadedFiles = @()

Write-Host "Iniciando uploads..." -ForegroundColor Cyan
Write-Host ""

foreach ($file in $files) {
    $fileId = New-GeminiUpload -filePath $file.path -displayName $file.name
    
    if ($fileId) {
        $uploadedFiles += @{ name = $file.name; id = $fileId }
    }
    
    Write-Host ""
    Start-Sleep -Seconds 2  # Pausa entre uploads
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESULTADOS FINAIS" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan

if ($uploadedFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "ARQUIVOS CARREGADOS COM SUCESSO:" -ForegroundColor Green
    
    foreach ($uploaded in $uploadedFiles) {
        Write-Host ""
        Write-Host "  Arquivo: $($uploaded.name)" -ForegroundColor White
        Write-Host "  File ID: $($uploaded.id)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "NOVOS IDs PARA ATUALIZAR NO CODIGO:" -ForegroundColor Yellow
    Write-Host "====================================" -ForegroundColor Yellow
    
    foreach ($uploaded in $uploadedFiles) {
        Write-Host "$($uploaded.id)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "COPIE os IDs acima para atualizar:" -ForegroundColor Cyan
    Write-Host "- Função ai-chat (arquivo index.ts)" -ForegroundColor Gray
    Write-Host "- Documentação do projeto" -ForegroundColor Gray
    
} else {
    Write-Host ""
    Write-Host "NENHUM ARQUIVO FOI CARREGADO!" -ForegroundColor Red
    Write-Host "Verifique a conectividade e tente novamente." -ForegroundColor Red
}

Write-Host ""
Write-Host "Processo finalizado!" -ForegroundColor Cyan