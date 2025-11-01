# Criar um usuário de teste no ambiente HML

Write-Host "Criando usuário de teste..." -ForegroundColor Green

$supabaseUrl = "https://aoktoecyoxzgdraszzjb.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFva3RvZWN5b3h6Z2RyYXN6empiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTk5NTgyMiwiZXhwIjoyMDc3NTcxODIyfQ.53Qp7btP3PWkXuIJYEX6noXBzTqHSnPhAO12XhNjObM"

$testUser = @{
    id = "00000000-0000-0000-0000-000000000001"
    email = "teste@jardulli.hml"
    email_confirmed_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    created_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    updated_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    raw_user_meta_data = @{
        role = "test_user"
        name = "Usuario Teste HML"
    }
} | ConvertTo-Json

Write-Host "Criando usuário teste:" -ForegroundColor Yellow
Write-Host $testUser

try {
    $response = Invoke-WebRequest -Uri "$supabaseUrl/rest/v1/auth.users" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $serviceRoleKey"
            "apikey" = $serviceRoleKey
            "Content-Type" = "application/json"
            "Prefer" = "return=representation"
        } `
        -Body $testUser `
        -UseBasicParsing

    Write-Host "✅ Usuário de teste criado!" -ForegroundColor Green
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Erro ao criar usuário (pode já existir):" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    
    # Verificar se o usuário já existe
    try {
        $checkResponse = Invoke-WebRequest -Uri "$supabaseUrl/rest/v1/auth.users?select=*&id=eq.00000000-0000-0000-0000-000000000001" `
            -Method GET `
            -Headers @{
                "Authorization" = "Bearer $serviceRoleKey"
                "apikey" = $serviceRoleKey
            } `
            -UseBasicParsing
            
        $existingUsers = $checkResponse.Content | ConvertFrom-Json
        if ($existingUsers.Count -gt 0) {
            Write-Host "✅ Usuário de teste já existe!" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Erro ao verificar usuário existente:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}