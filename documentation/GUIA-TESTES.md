# 🧪 Guia de Testes - Passo a Passo

## 📋 Pré-requisitos

Antes de iniciar os testes, confirme que:

- ✅ Migrations aplicadas no Supabase
- ✅ Edge Functions deployadas (`upload-document` e `ai-chat`)
- ✅ Variáveis de ambiente configuradas (GEMINI_API_KEY)
- ✅ Bucket `documentos` criado no Storage
- ✅ Pelo menos 1 documento enviado e processado
- ✅ Frontend deployado e acessível

---

## 🚀 Fase 1: Testes Locais (Desenvolvimento)

### 1.1. Testar Migration Localmente

```powershell
# No diretório do projeto
cd c:\repo\jardulli-bot-buddy

# Resetar banco local (se já tiver um)
supabase db reset

# Aplicar migrations
supabase migration up

# Verificar tabelas criadas
supabase db diff
```

**Resultado esperado**: 
- `gemini_file_cache` criada
- `user_rate_limit` criada
- Funções SQL criadas
- "No schema changes detected" no diff

### 1.2. Testar Edge Functions Localmente

```powershell
# Criar arquivo de environment local
New-Item -ItemType File -Path "supabase\.env.local" -Force

# Editar e adicionar:
# GEMINI_API_KEY=sua-chave-aqui
# GEMINI_MODEL=gemini-2.0-flash-exp
notepad supabase\.env.local

# Iniciar Supabase local
supabase start

# Em outro terminal, iniciar Edge Functions
supabase functions serve
```

**Resultado esperado**:
```
Edge Functions serving on http://localhost:54321/functions/v1
- upload-document
- ai-chat
```

### 1.3. Testar upload-document Local

```powershell
# Criar arquivo de teste
"Horário de atendimento: Segunda a Sexta, 8h às 18h" | Out-File -FilePath "test-doc.txt" -Encoding UTF8

# Fazer upload para storage local (via dashboard Supabase Studio)
# http://localhost:54323 > Storage > documentos > Upload

# Testar Edge Function (substitua ANON_KEY)
$headers = @{
    "Authorization" = "Bearer YOUR_ANON_KEY"
    "Content-Type" = "application/json"
}

$body = @{
    fileName = "test-doc.txt"
    fileUrl = "test-doc.txt"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:54321/functions/v1/upload-document" `
    -Method POST `
    -Headers $headers `
    -Body $body
```

**Resultado esperado**:
```json
{
  "fileName": "test-doc.txt",
  "geminiName": "files/xyz...",
  "geminiUri": "https://generativelanguage.googleapis.com/...",
  "cached": false
}
```

### 1.4. Testar ai-chat Local

```powershell
# Fazer login na aplicação local (obter userId e conversationId)

$body = @{
    message = "Qual o horário de atendimento?"
    conversationId = "uuid-da-conversa"
    userId = "uuid-do-usuario"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:54321/functions/v1/ai-chat" `
    -Method POST `
    -Headers $headers `
    -Body $body
```

**Resultado esperado**:
```json
{
  "response": "O horário de atendimento é de segunda a sexta, das 8h às 18h.",
  "conversationId": "uuid-da-conversa",
  "sourcesCount": 1
}
```

---

## 🌐 Fase 2: Testes em Produção (Após Deploy)

### 2.1. Verificar Infraestrutura

#### A. Verificar Migrations

1. Acesse o Supabase Dashboard
2. Vá em **Database** > **Tables**
3. Confirme que existem:
   - ✅ `gemini_file_cache`
   - ✅ `user_rate_limit`

```sql
-- No SQL Editor, execute:
SELECT COUNT(*) as total_cache FROM gemini_file_cache;
SELECT COUNT(*) as total_rate_limits FROM user_rate_limit;
```

#### B. Verificar Edge Functions

```powershell
# Listar functions deployadas
supabase functions list
```

**Resultado esperado**:
```
upload-document (deployed)
ai-chat (deployed)
send-whatsapp-feedback (deployed)
```

#### C. Verificar Variáveis de Ambiente

1. Acesse **Project Settings** > **Edge Functions**
2. Vá em **Secrets**
3. Confirme:
   - ✅ `GEMINI_API_KEY` (configurada)
   - ✅ `GEMINI_MODEL` (configurada)

#### D. Verificar Storage

1. Acesse **Storage**
2. Confirme bucket `documentos` existe
3. Verifique se tem pelo menos 1 arquivo

### 2.2. Upload de Documento de Teste

#### Via Dashboard

1. Storage > `documentos` > **Upload file**
2. Selecione arquivo PDF ou TXT
3. Clique em **Upload**

#### Via Script PowerShell

```powershell
# Script: test-upload.ps1
$supabaseUrl = "https://seu-projeto.supabase.co"
$serviceRoleKey = "sua-service-role-key"

# 1. Upload para Storage
$file = Get-Content "test-doc.txt" -Raw
$bytes = [System.Text.Encoding]::UTF8.GetBytes($file)

$headers = @{
    "Authorization" = "Bearer $serviceRoleKey"
    "Content-Type" = "text/plain"
}

$uploadResponse = Invoke-RestMethod `
    -Uri "$supabaseUrl/storage/v1/object/documentos/test-doc.txt" `
    -Method POST `
    -Headers $headers `
    -Body $bytes

Write-Host "✅ Arquivo enviado para Storage"

# 2. Processar no Gemini
$processHeaders = @{
    "Authorization" = "Bearer $serviceRoleKey"
    "Content-Type" = "application/json"
}

$processBody = @{
    fileName = "test-doc.txt"
    fileUrl = "test-doc.txt"
} | ConvertTo-Json

$processResponse = Invoke-RestMethod `
    -Uri "$supabaseUrl/functions/v1/upload-document" `
    -Method POST `
    -Headers $processHeaders `
    -Body $processBody

Write-Host "✅ Arquivo processado no Gemini"
Write-Host "Gemini Name: $($processResponse.geminiName)"
```

Execute:
```powershell
.\test-upload.ps1
```

### 2.3. Teste End-to-End Completo

#### Passo 1: Criar Conta

1. Acesse seu frontend deployado
2. Clique em **Criar conta**
3. Preencha email e senha
4. Confirme email (se configurado)
5. Faça login

**✅ Checkpoint**: Você está logado e vê a tela de chat

#### Passo 2: Criar Primeira Conversa

1. Clique em **Nova conversa** (botão +)
2. Digite: "Olá!"
3. Clique em **Enviar**

**✅ Checkpoint**: 
- Mensagem enviada aparece no chat
- Loading "IA está digitando..." aparece
- Resposta da IA aparece em ~3-5 segundos

#### Passo 3: Testar Pergunta Sobre Documento

Digite uma pergunta que está nos seus documentos, por exemplo:

```
Qual o horário de atendimento da empresa?
```

**✅ Checkpoint**:
- IA responde baseada no documento
- Resposta coerente com o conteúdo
- Sem erros no console

#### Passo 4: Testar Pergunta Fora de Contexto

```
Quem ganhou a Copa do Mundo de 2022?
```

**✅ Checkpoint**:
- IA responde: "Não encontrei essa informação na base de conhecimento"
- Ou sugere: "Posso ajudar com informações sobre [temas dos documentos]"

#### Passo 5: Testar Feedback

1. Clique no ícone 👍 em uma resposta boa
2. Clique no ícone 👎 em uma resposta ruim

**✅ Checkpoint**:
- Toast aparece: "Feedback enviado"
- No banco, verifica se foi salvo:

```sql
SELECT * FROM message_feedback 
ORDER BY created_at DESC 
LIMIT 5;
```

#### Passo 6: Testar Histórico de Conversa

1. Faça 3-4 perguntas seguidas sobre o mesmo tema
2. Observe se a IA mantém contexto
3. Por exemplo:
   - "Qual o horário de atendimento?"
   - "E no sábado?"
   - "Vocês abrem em feriados?"

**✅ Checkpoint**:
- IA usa contexto das mensagens anteriores
- Respostas coerentes e contextualizadas

#### Passo 7: Testar Múltiplas Conversas

1. Clique em **Nova conversa**
2. Faça perguntas diferentes
3. Volte para conversa anterior no sidebar
4. Verifique se mensagens persistem

**✅ Checkpoint**:
- Sidebar lista todas conversas
- Cada conversa mantém suas mensagens
- Títulos das conversas são gerados automaticamente

#### Passo 8: Testar Rate Limiting

Envie 21 mensagens seguidas rapidamente (pode copiar/colar).

**✅ Checkpoint na mensagem 21**:
```
⚠️ Você atingiu o limite de 20 mensagens por hora. 
Aguarde alguns minutos e tente novamente.
```

Verificar no banco:
```sql
SELECT * FROM user_rate_limit 
WHERE user_id = 'seu-user-id';
```

Deve mostrar `message_count = 20` e `last_reset` recente.

### 2.4. Testar Cache de Arquivos

#### Upload do mesmo arquivo 2x

1. Faça upload de `doc1.pdf`
2. Aguarde processar
3. Faça upload de `doc1.pdf` novamente (mesmo arquivo)

**✅ Checkpoint**:
- Segunda vez é instantânea (cache hit)
- Logs da Edge Function mostram: `"Using cached file"`

Verificar no banco:
```sql
SELECT file_name, sha256_hash, gemini_name, created_at 
FROM gemini_file_cache;
```

Deve ter apenas 1 registro para o mesmo arquivo.

---

## 🐛 Fase 3: Testes de Erro

### 3.1. Testar sem API Key

1. Remova `GEMINI_API_KEY` do Secrets
2. Tente fazer pergunta

**✅ Checkpoint**:
- Toast de erro aparece
- Logs mostram: `"GEMINI_API_KEY não configurada"`

### 3.2. Testar com Documento Inexistente

Force um erro tentando processar arquivo que não existe:

```powershell
$body = @{
    fileName = "arquivo-que-nao-existe.pdf"
    fileUrl = "arquivo-que-nao-existe.pdf"
} | ConvertTo-Json

Invoke-RestMethod -Uri "$supabaseUrl/functions/v1/upload-document" `
    -Method POST `
    -Headers $headers `
    -Body $body
```

**✅ Checkpoint**:
- Erro 404 retornado
- Mensagem clara: "Arquivo não encontrado no storage"

### 3.3. Testar Rate Limit Reset

Após atingir rate limit, aguarde 1 hora e teste novamente.

Ou force reset manual:
```sql
DELETE FROM user_rate_limit 
WHERE user_id = 'seu-user-id';
```

**✅ Checkpoint**:
- Consegue enviar mensagens novamente

---

## 📊 Fase 4: Testes de Performance

### 4.1. Tempo de Resposta

Meça tempo de resposta da IA:

```powershell
$start = Get-Date

# Fazer pergunta via API
$response = Invoke-RestMethod ...

$end = Get-Date
$duration = ($end - $start).TotalSeconds

Write-Host "Tempo de resposta: $duration segundos"
```

**✅ Meta**: < 5 segundos para perguntas simples

### 4.2. Teste de Carga (Light)

Simule 10 usuários fazendo perguntas simultaneamente:

```powershell
# Script: load-test.ps1
1..10 | ForEach-Object -Parallel {
    $body = @{
        message = "Pergunta teste $($_)"
        conversationId = "conv-$($_)"
        userId = "user-$($_)"
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri "$env:SUPABASE_URL/functions/v1/ai-chat" `
        -Method POST `
        -Headers $env:HEADERS `
        -Body $body
} -ThrottleLimit 10
```

**✅ Checkpoint**:
- Todas as requisições completam
- Sem timeouts
- Logs não mostram erros

### 4.3. Teste de Documento Grande

Faça upload de PDF de 5-10MB:

**✅ Checkpoint**:
- Upload completa em < 30 segundos
- Processamento no Gemini completa
- Cache criado corretamente

---

## 🔍 Fase 5: Verificação de Logs

### 5.1. Monitorar Logs em Tempo Real

```powershell
# Terminal 1: Logs do ai-chat
supabase functions logs ai-chat --tail

# Terminal 2: Logs do upload-document
supabase functions logs upload-document --tail
```

Faça perguntas e observe logs em tempo real.

**✅ O que observar**:
- Requisições chegando
- Tempo de processamento
- Erros (se houver)
- Cache hits/misses

### 5.2. Verificar Erros Recentes

```powershell
# Últimos 100 logs com filtro de erro
supabase functions logs ai-chat -n 100 | Select-String "error|Error|ERROR"
```

**✅ Checkpoint**: Nenhum erro crítico

---

## 📋 Checklist Final de Testes

### Infraestrutura
- [ ] Migrations aplicadas corretamente
- [ ] Tabelas criadas com RLS ativo
- [ ] Bucket Storage criado e acessível
- [ ] Edge Functions deployadas e respondendo
- [ ] Variáveis de ambiente configuradas

### Funcionalidades Core
- [ ] Criar conta e fazer login
- [ ] Criar nova conversa
- [ ] Enviar mensagem e receber resposta
- [ ] Pergunta sobre documento retorna resposta baseada no conteúdo
- [ ] Pergunta fora de contexto retorna resposta apropriada
- [ ] Histórico de conversa funciona (contexto mantido)
- [ ] Múltiplas conversas independentes funcionam

### Upload e Cache
- [ ] Upload de documento via Storage funciona
- [ ] Edge Function `upload-document` processa corretamente
- [ ] Cache funciona (segundo upload é instantâneo)
- [ ] Diferentes tipos de arquivo (PDF, TXT, MD) funcionam

### Rate Limiting
- [ ] 20 mensagens permitidas por hora
- [ ] 21ª mensagem bloqueia com mensagem clara
- [ ] Reset após 1 hora funciona

### Feedback e UX
- [ ] Feedback 👍👎 salva corretamente
- [ ] Loading states aparecem
- [ ] Erros mostram toasts informativos
- [ ] Sidebar atualiza em tempo real

### Performance
- [ ] Resposta da IA em < 5 segundos
- [ ] Upload de documento em < 30 segundos
- [ ] Sem crashes ou timeouts
- [ ] Cache reduz tempo de processamento

### Logs e Monitoramento
- [ ] Logs das Edge Functions acessíveis
- [ ] Nenhum erro crítico nos logs
- [ ] Métricas no dashboard Supabase visíveis

---

## 🎯 Cenários de Teste Sugeridos

### Cenário 1: Primeiro Acesso de Usuário

1. Usuário novo cria conta
2. Recebe email de confirmação
3. Confirma email
4. Faz login
5. Cria primeira conversa
6. Faz pergunta simples
7. Avalia resposta com 👍

### Cenário 2: Usuário Recorrente

1. Usuário existente faz login
2. Vê conversas anteriores no sidebar
3. Continua conversa antiga
4. Cria nova conversa sobre tema diferente
5. Alterna entre conversas
6. Faz logout

### Cenário 3: Upload de Base de Conhecimento

1. Admin faz upload de 10 PDFs
2. Aguarda processamento
3. Verifica cache no banco
4. Testa perguntas sobre cada documento
5. Verifica qualidade das respostas
6. Ajusta prompts se necessário

### Cenário 4: Limite de Uso

1. Usuário envia 19 mensagens
2. Consegue enviar todas
3. Tenta enviar 20ª
4. Consegue
5. Tenta enviar 21ª
6. Recebe bloqueio
7. Aguarda reset (ou admin força)
8. Consegue enviar novamente

---

## 🔧 Ferramentas Úteis

### Postman Collection

Crie coleção no Postman com:
- POST `upload-document`
- POST `ai-chat`
- Variáveis de ambiente (URL, keys)

### Script de Teste Automatizado

```powershell
# test-all.ps1
Write-Host "🧪 Iniciando testes automatizados..."

# 1. Testar health
$health = Invoke-RestMethod "$supabaseUrl/functions/v1/ai-chat" -Method GET
if ($health) { Write-Host "✅ ai-chat respondendo" }

# 2. Testar upload
# ... (código anterior)

# 3. Testar chat
# ... (código anterior)

# 4. Verificar banco
# ... (queries SQL)

Write-Host "🎉 Todos os testes passaram!"
```

---

## 🆘 Quando Algo Falha

### Passo a Passo de Debug

1. **Verificar logs** da Edge Function
2. **Verificar Network tab** no DevTools
3. **Verificar SQL** (queries no banco)
4. **Verificar RLS** (políticas de segurança)
5. **Verificar variáveis** de ambiente
6. **Testar localmente** primeiro

### Comandos Úteis de Debug

```powershell
# Ver status completo do Supabase
supabase status

# Resetar banco local
supabase db reset

# Ver logs filtrados
supabase functions logs ai-chat | Select-String "error"

# Testar query SQL
supabase db execute "SELECT * FROM gemini_file_cache LIMIT 5"
```

---

## 🎉 Sucesso!

Se todos os checkpoints passaram, seu MVP está funcionando! 🚀

**Próximos passos**:
1. Monitorar logs por 1 semana
2. Coletar feedback de usuários
3. Ajustar prompts baseado nas respostas
4. Adicionar mais documentos
5. Implementar melhorias (Sprint 4 do MVP-TODO.md)

---

**Data de criação**: Outubro 2025  
**Última atualização**: Outubro 2025
