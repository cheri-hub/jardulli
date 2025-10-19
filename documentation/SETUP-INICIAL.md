# 🚀 Setup Inicial - Jardulli Bot Buddy

## 📋 Pré-requisitos

Antes de começar, você precisa ter:

- ✅ **Node.js** (v18 ou superior)
- ✅ **Git** instalado
- ✅ **Conta no Supabase** (gratuita)
- ✅ **API Key do Google Gemini** (gratuita)
- ✅ **Editor de código** (VS Code recomendado)

---

## 🎯 O que vamos fazer?

1. Clonar e instalar dependências do projeto
2. Criar projeto no Supabase
3. Configurar Supabase CLI
4. Aplicar migrations (criar tabelas)
5. Fazer deploy das Edge Functions
6. Configurar variáveis de ambiente
7. Criar bucket de storage
8. Fazer primeiro teste

**Tempo estimado**: 15-20 minutos

---

## 📦 Passo 1: Clonar e Instalar Projeto

### 1.1. Clonar repositório

```powershell
# Clone o repositório
git clone https://github.com/rpmarciano/jardulli-bot-buddy.git
cd jardulli-bot-buddy
```

### 1.2. Instalar dependências

```powershell
# Instalar dependências do frontend
npm install

# Verificar instalação
npm list react typescript vite
```

**Resultado esperado**: Todas as dependências instaladas sem erros.

---

## 🌐 Passo 2: Criar Projeto no Supabase

### 2.1. Criar conta (se ainda não tem)

1. Acesse: https://supabase.com
2. Clique em **"Start your project"**
3. Faça login com GitHub ou email

### 2.2. Criar novo projeto

1. No Dashboard, clique em **"New Project"**
2. Preencha:
   - **Organization**: Selecione ou crie uma
   - **Name**: `jardulli-bot-buddy` (ou nome de sua preferência)
   - **Database Password**: Crie uma senha forte (anote!)
   - **Region**: `South America (São Paulo)` (recomendado)
   - **Pricing Plan**: `Free` (até 500MB)
3. Clique em **"Create new project"**
4. Aguarde ~2 minutos (provisioning)

### 2.3. Anotar informações do projeto

Quando o projeto estiver pronto:

1. Vá em **Settings** > **API**
2. Anote/copie:
   - ✅ **Project URL**: `https://xxxxx.supabase.co`
   - ✅ **Project ID** (reference ID): `xxxxx`
   - ✅ **anon public** key (API Key)
   - ✅ **service_role** key (Secret Key - não compartilhe!)

---

## 🔧 Passo 3: Configurar Supabase CLI

### 3.1. Instalar Supabase CLI

```powershell
# Via Scoop (recomendado para Windows)
# Primeiro, instalar Scoop se não tiver:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# Adicionar bucket do Supabase
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git

# Instalar Supabase CLI
scoop install supabase

# Verificar instalação
supabase --version
```

**Resultado esperado**: `2.51.0` (ou superior)

### 3.2. Fazer login no Supabase

#### Opção A: Access Token (mais estável)

1. Acesse: https://supabase.com/dashboard/account/tokens
2. Clique em **"Generate new token"**
3. Nome: `cli-jardulli`
4. Copie o token (aparece só uma vez!)
5. Configure no PowerShell:

```powershell
$env:SUPABASE_ACCESS_TOKEN = "sbp_seu-token-aqui"
```

#### Opção B: Login interativo

```powershell
supabase login
# Aperte Enter quando pedir
# Copie o código de 8 caracteres da página web
# Cole no terminal
```

### 3.3. Linkar projeto local com Supabase

```powershell
# Listar projetos disponíveis
supabase projects list

# Linkar com seu projeto (substitua PROJECT_ID)
supabase link --project-ref SEU_PROJECT_ID

# Exemplo:
# supabase link --project-ref gplumtfxxhgckjkgloni
```

**Resultado esperado**: `Finished supabase link.`

---

## 🗄️ Passo 4: Configurar Arquivo .env

### 4.1. Criar arquivo .env

Crie o arquivo `.env` na raiz do projeto:

```powershell
# Criar arquivo
New-Item -ItemType File -Path ".env" -Force

# Abrir no editor
notepad .env
```

### 4.2. Adicionar variáveis

Cole no arquivo `.env`:

```env
# Supabase Configuration
VITE_SUPABASE_PROJECT_ID="seu-project-id-aqui"
VITE_SUPABASE_URL="https://seu-project-id.supabase.co"
VITE_SUPABASE_PUBLISHABLE_KEY="sua-anon-public-key-aqui"

# Supabase CLI (para deploy)
SUPABASE_ACCESS_TOKEN="sbp_seu-access-token-aqui"

# Google Gemini API
GEMINI_API_KEY="AIza...sua-chave-gemini-aqui"
```

### 4.3. Como obter cada variável

| Variável | Onde encontrar |
|----------|----------------|
| `VITE_SUPABASE_PROJECT_ID` | Dashboard > Settings > General > Reference ID |
| `VITE_SUPABASE_URL` | Dashboard > Settings > API > Project URL |
| `VITE_SUPABASE_PUBLISHABLE_KEY` | Dashboard > Settings > API > anon public |
| `SUPABASE_ACCESS_TOKEN` | https://supabase.com/dashboard/account/tokens |
| `GEMINI_API_KEY` | https://makersuite.google.com/app/apikey |

⚠️ **IMPORTANTE**: Nunca commite o arquivo `.env`! Ele já está no `.gitignore`.

---

## 📊 Passo 5: Aplicar Migrations (Criar Tabelas)

```powershell
# Ver o que será aplicado
supabase db diff

# Aplicar no banco de dados
supabase db push
```

Digite `Y` quando perguntar: `Do you want to push these migrations?`

**O que será criado:**
- ✅ Tabela `profiles` (perfis de usuários)
- ✅ Tabela `conversations` (conversas)
- ✅ Tabela `messages` (mensagens)
- ✅ Tabela `message_feedback` (avaliações)
- ✅ Tabela `gemini_file_cache` (cache de arquivos)
- ✅ Tabela `user_rate_limit` (controle de taxa)
- ✅ Funções SQL (`check_rate_limit`, `increment_rate_limit`)
- ✅ Políticas RLS (Row Level Security)
- ✅ Índices otimizados

**Resultado esperado**: `Finished supabase db push.`

### Verificar no Dashboard

1. Acesse: Dashboard > **Database** > **Tables**
2. Confirme que as 6 tabelas foram criadas

---

## 🚀 Passo 6: Deploy das Edge Functions

### 6.1. Deploy ai-chat

```powershell
supabase functions deploy ai-chat
```

**Resultado esperado**: 
```
Deployed Functions on project xxxxx: ai-chat
```

### 6.2. Deploy upload-document

```powershell
supabase functions deploy upload-document
```

### 6.3. Verificar deploy

```powershell
supabase functions list
```

**Resultado esperado**:
```
NAME              | STATUS  | VERSION
ai-chat           | ACTIVE  | 1
upload-document   | ACTIVE  | 1
```

---

## 🔑 Passo 7: Configurar Secrets no Supabase

### 7.1. Acessar configuração de Functions

1. Acesse: Dashboard > **Project Settings** > **Edge Functions**
2. Vá na seção **"Secrets"**

### 7.2. Adicionar GEMINI_API_KEY

1. Clique em **"Add new secret"**
2. Preencha:
   - **Name**: `GEMINI_API_KEY`
   - **Value**: `AIza...` (sua chave do Gemini)
3. Clique em **"Add secret"**

### 7.3. Adicionar GEMINI_MODEL

1. Clique em **"Add new secret"** novamente
2. Preencha:
   - **Name**: `GEMINI_MODEL`
   - **Value**: `gemini-2.0-flash-exp`
3. Clique em **"Add secret"**

### 7.4. Verificar

Você deve ver as duas secrets listadas:
- ✅ `GEMINI_API_KEY` (valor oculto)
- ✅ `GEMINI_MODEL` (valor oculto)

---

## 📦 Passo 8: Criar Bucket de Storage

### 8.1. Via Dashboard (recomendado)

1. Acesse: Dashboard > **Storage**
2. Clique em **"New bucket"**
3. Preencha:
   - **Name**: `documentos`
   - **Public bucket**: ❌ Desmarque (privado)
   - **File size limit**: `10 MB`
   - **Allowed MIME types**: 
     - `application/pdf`
     - `text/plain`
     - `text/markdown`
4. Clique em **"Create bucket"**

### 8.2. Configurar Políticas RLS

No **SQL Editor**, execute:

```sql
-- Permitir service role fazer upload
CREATE POLICY "Service role can upload to documentos"
ON storage.objects FOR INSERT
TO service_role
WITH CHECK (bucket_id = 'documentos');

-- Permitir service role baixar
CREATE POLICY "Service role can download from documentos"
ON storage.objects FOR SELECT
TO service_role
USING (bucket_id = 'documentos');

-- Usuários autenticados podem ver lista
CREATE POLICY "Authenticated users can list documentos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'documentos');
```

---

## 📄 Passo 9: Upload de Documentos Iniciais

### 9.1. Via Dashboard

1. Vá em **Storage** > **documentos**
2. Clique em **"Upload file"**
3. Selecione PDFs ou TXTs com informações da empresa
4. Clique em **"Upload"**

### 9.2. Processar documentos no Gemini

Para cada documento enviado, você precisa processá-lo:

1. Anote o nome do arquivo (ex: `manual.pdf`)
2. Via terminal, teste a Edge Function:

```powershell
# Obter Service Role Key do Dashboard > Settings > API
$serviceKey = "eyJhbG...sua-service-role-key"

$headers = @{
    "Authorization" = "Bearer $serviceKey"
    "Content-Type" = "application/json"
}

$body = @{
    fileName = "manual.pdf"
    fileUrl = "manual.pdf"
} | ConvertTo-Json

Invoke-RestMethod `
    -Uri "https://seu-project-id.supabase.co/functions/v1/upload-document" `
    -Method POST `
    -Headers $headers `
    -Body $body
```

**Resultado esperado**:
```json
{
  "fileName": "manual.pdf",
  "geminiName": "files/xyz123...",
  "geminiUri": "https://generativelanguage.googleapis.com/...",
  "cached": false
}
```

---

## 🧪 Passo 10: Testar Localmente

### 10.1. Iniciar servidor de desenvolvimento

```powershell
npm run dev
```

**Resultado esperado**:
```
VITE v5.4.19  ready in 500 ms

➜  Local:   http://localhost:8080/
➜  Network: use --host to expose
```

### 10.2. Abrir no navegador

1. Acesse: http://localhost:8080
2. Clique em **"Criar conta"**
3. Preencha email e senha
4. Faça login

### 10.3. Fazer primeiro teste

1. Clique em **"Nova conversa"**
2. Digite: `Olá! Você pode me ajudar?`
3. Clique em **Enviar**

**Resultado esperado**:
- ✅ Mensagem enviada aparece
- ✅ "IA está digitando..." aparece
- ✅ Resposta da IA aparece em 3-5 segundos

### 10.4. Testar pergunta sobre documento

Digite uma pergunta sobre o conteúdo que você uploadou:

```
Qual o horário de atendimento?
```

**Resultado esperado**:
- ✅ IA responde baseada no documento
- ✅ Resposta coerente e relacionada ao conteúdo

---

## 🔍 Verificações Finais

### Checklist de Setup

Execute este checklist para confirmar que tudo está funcionando:

- [ ] Node.js instalado (`node --version`)
- [ ] Dependências instaladas (`npm list`)
- [ ] Projeto Supabase criado
- [ ] Supabase CLI instalado (`supabase --version`)
- [ ] Arquivo `.env` configurado com todas as variáveis
- [ ] Login no Supabase feito (`supabase projects list`)
- [ ] Projeto linkado (`supabase link`)
- [ ] Migrations aplicadas (6 tabelas criadas)
- [ ] Edge Functions deployadas (ai-chat + upload-document)
- [ ] Secrets configuradas (GEMINI_API_KEY + GEMINI_MODEL)
- [ ] Bucket `documentos` criado
- [ ] Pelo menos 1 documento uploadado e processado
- [ ] Frontend rodando localmente (`npm run dev`)
- [ ] Consegue criar conta e fazer login
- [ ] Consegue enviar mensagem e receber resposta
- [ ] IA responde baseada nos documentos

---

## 🐛 Troubleshooting

### Erro: "Cannot find module" ao rodar npm install

**Solução**:
```powershell
# Limpar cache e reinstalar
rm -r node_modules
rm package-lock.json
npm install
```

### Erro: "supabase: command not found"

**Solução**:
```powershell
# Fechar e reabrir terminal
# Ou adicionar ao PATH manualmente:
$env:PATH += ";$env:USERPROFILE\scoop\shims"
```

### Erro: "GEMINI_API_KEY não configurada"

**Solução**:
1. Verificar se adicionou no Dashboard > Edge Functions > Secrets
2. Aguardar 1-2 minutos (secrets levam um tempo para propagar)
3. Verificar se o nome está correto (case-sensitive)

### Erro: "Cannot find table gemini_file_cache"

**Solução**:
```powershell
# Migrations não foram aplicadas
supabase db push
```

### Erro: "File not found in storage"

**Solução**:
1. Verificar se arquivo foi uploadado no bucket `documentos`
2. Verificar se nome do arquivo está correto (case-sensitive)
3. Verificar políticas RLS do storage

### Edge Function não responde

**Solução**:
```powershell
# Ver logs
supabase functions logs ai-chat --tail

# Fazer redeploy
supabase functions deploy ai-chat
```

---

## 📚 Próximos Passos

Após setup completo:

1. **Adicionar mais documentos**: Populate sua base de conhecimento
2. **Ajustar prompts**: Customize o comportamento da IA
3. **Testar cenários**: Use o GUIA-TESTES.md
4. **Deploy frontend**: Lovable, Vercel ou Netlify
5. **Monitorar logs**: Acompanhe uso e erros
6. **Coletar feedback**: Teste com usuários reais

---

## 📖 Documentação Relacionada

- **DEPLOY-MVP.md**: Guia completo de deploy em produção
- **GUIA-TESTES.md**: Todos os cenários de teste
- **MVP-TODO.md**: Roadmap completo do projeto
- **QUICK-START.md**: Referência rápida de comandos

---

## 🆘 Precisa de Ajuda?

Se encontrar problemas:

1. **Verificar logs**: `supabase functions logs ai-chat`
2. **Documentação Supabase**: https://supabase.com/docs
3. **Documentação Gemini**: https://ai.google.dev/docs
4. **Issues do GitHub**: Abra uma issue no repositório

---

## 🎉 Parabéns!

Se chegou até aqui, seu projeto está funcionando! 🚀

Agora você tem:
- ✅ Backend completo com Supabase
- ✅ IA integrada com Google Gemini
- ✅ RAG (perguntas sobre documentos)
- ✅ Rate limiting (20 msg/hora)
- ✅ Sistema de feedback
- ✅ Autenticação de usuários

**Tempo total de setup**: ~20 minutos

---

**Data de criação**: Outubro 2025  
**Última atualização**: Outubro 2025  
**Versão**: 1.0.0
