@echo off
REM Script para testar o cost tracking no ambiente HML
REM Executa uma chamada para a função ai-chat e verifica se os custos são capturados

echo =================================================
echo Testando Cost Tracking no Ambiente HML
echo =================================================
echo.

REM URL da função ai-chat no HML
set "FUNCTION_URL=https://aoktoecyoxzgdraszzjb.supabase.co/functions/v1/ai-chat"
set "ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFva3RvZWN5b3h6Z2RyYXN6empiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ0NDI4ODQsImV4cCI6MjA1MDAxODg4NH0.k3d6JCNStMhHrf8P3Mi-a4-xohfaWY_ovs4mIkZsUhc"

echo Fazendo uma requisição de teste para capturar métricas...
echo.

REM Fazer uma chamada POST para a função
curl -X POST "%FUNCTION_URL%" ^
  -H "Authorization: Bearer %ANON_KEY%" ^
  -H "Content-Type: application/json" ^
  -d "{\"message\": \"Olá, esta é uma mensagem de teste para verificar o cost tracking. Quanto custa usar o Gemini API?\", \"user_id\": \"test-user-hml-001\"}"

echo.
echo.
echo =================================================
echo Teste concluído!
echo =================================================
echo Verifique o dashboard do Supabase HML para ver se as métricas foram capturadas:
echo https://supabase.com/dashboard/project/aoktoecyoxzgdraszzjb/editor
echo.
echo Tabela: gemini_usage_metrics
echo =================================================