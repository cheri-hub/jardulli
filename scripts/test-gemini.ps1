# Teste simples do Gemini API
# Para verificar se a API Key esta funcionando

Write-Host "Testando Google Gemini API..." -ForegroundColor Cyan
Write-Host ""

$apiKey = "AIzaSyACfNvh_gwmIgpddUS-A3Wb2UTarR4myQw"
$model = "gemini-2.0-flash-exp"

$url = "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=$apiKey"

$body = @{
    contents = @(
        @{
            parts = @(
                @{
                    text = "Oi! Responda apenas: OK"
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

$headers = @{
    "Content-Type" = "application/json"
}

try {
    Write-Host "Enviando requisicao para Gemini..." -ForegroundColor Yellow
    
    $response = Invoke-RestMethod `
        -Uri $url `
        -Method POST `
        -Headers $headers `
        -Body $body
    
    Write-Host ""
    Write-Host "Sucesso! Gemini respondeu:" -ForegroundColor Green
    Write-Host $response.candidates[0].content.parts[0].text -ForegroundColor White
    Write-Host ""
    Write-Host "API Key esta funcionando!" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "Erro ao testar Gemini API:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.ErrorDetails.Message) {
        Write-Host ""
        Write-Host "Detalhes:" -ForegroundColor Yellow
        Write-Host $_.ErrorDetails.Message -ForegroundColor Gray
    }
    
    exit 1
}
