# Verifica status dos arquivos no Gemini File API
# Para diagnosticar o erro: File ojsr3jnxjs3s not accessible

Write-Host "Verificando arquivos no Gemini File API..." -ForegroundColor Cyan
Write-Host ""

$apiKey = "AIzaSyACfNvh_gwmIgpddUS-A3Wb2UTarR4myQw"

# Lista todos os arquivos
Write-Host "Listando todos os arquivos..." -ForegroundColor Yellow
$listUrl = "https://generativelanguage.googleapis.com/v1beta/files?key=$apiKey"

try {
    $files = Invoke-RestMethod -Uri $listUrl -Method Get
    
    if ($files.files -and $files.files.Count -gt 0) {
        Write-Host "Arquivos encontrados:" -ForegroundColor Green
        foreach ($file in $files.files) {
            $status = "ATIVO"
            if ($file.state -eq "FAILED" -or $file.state -eq "INACTIVE") {
                $status = "INATIVO"
            } elseif ($file.state -eq "PROCESSING") {
                $status = "PROCESSANDO"
            }
            
            Write-Host "  Nome: $($file.displayName)" -ForegroundColor White
            Write-Host "  ID: $($file.name)" -ForegroundColor Gray
            Write-Host "  Status: $status ($($file.state))" -ForegroundColor White
            Write-Host "  Criado: $($file.createTime)" -ForegroundColor Gray
            Write-Host "  Tamanho: $($file.sizeBytes) bytes" -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host "Nenhum arquivo encontrado!" -ForegroundColor Red
    }
} catch {
    Write-Host "Erro ao listar arquivos:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
}

# Testa especificamente os arquivos conhecidos
$knownFiles = @(
    "files/2fq17czmwe32",
    "files/ojsr3jnxjs3s", 
    "files/fpfmb430cayi"
)

Write-Host "Testando arquivos específicos..." -ForegroundColor Yellow
foreach ($fileId in $knownFiles) {
    Write-Host "Testando: $fileId" -ForegroundColor White
    
    $detailUrl = "https://generativelanguage.googleapis.com/v1beta/$fileId" + "?key=$apiKey"
    
    try {
        $fileDetail = Invoke-RestMethod -Uri $detailUrl -Method Get
        Write-Host "  ACESSIVEL - $($fileDetail.displayName)" -ForegroundColor Green
        Write-Host "  Estado: $($fileDetail.state)" -ForegroundColor Gray
    } catch {
        Write-Host "  INACESSIVEL - $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "Diagnostico concluido!" -ForegroundColor Cyan