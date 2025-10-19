# 🚀 Guia de Deploy do MVP - Jardulli Bot Buddy

## ✅ O que foi implementado

### Sprint 1: Fundação ✅
- ✅ Migration SQL criada (`supabase/migrations/20251017164054_create_gemini_infrastructure.sql`)
  - Tabela `gemini_file_cache` para cache de arquivos
  - Tabela `user_rate_limit` para controle de mensagens
  - Funções SQL helper: `check_rate_limit`, `increment_rate_limit`
  - Políticas RLS configuradas

### Sprint 2: Edge Functions ✅
- ✅ Edge Function `upload-document` criada
  - Upload de documentos para Gemini File API
  - Sistema de cache por hash SHA256
  - Polling automático até arquivo estar processado
  
- ✅ Edge Function `ai-chat` criada
  - Integração completa com Gemini
  - RAG (Retrieval-Augmented Generation)
  - Rate limiting integrado
  - Histórico de conversa
  - System prompt otimizado para Jardulli

### Sprint 3: Frontend ✅
- ✅ `Index.tsx` atualizado
  - Removida simulação de resposta
  - Integração com Edge Function `ai-chat`
  - Tratamento de erros melhorado
  - Feedback de rate limit

---

## 📋 Pré-requisitos

Antes de fazer deploy, você precisa ter:

1. **Conta Supabase** (gratuita ou paga)
2. **Projeto Supabase** criado
3. **Supabase CLI** instalado
4. **API Key do Google Gemini** (gratuita em https://makersuite.google.com/app/apikey)
5. **Git** instalado

---

## 🔧 Passo 1: Configurar Supabase CLI

### Instalar Supabase CLI (Windows)

```powershell
# Via Scoop
scoop install supabase

# OU via npm
npm install -g supabase
```

### Login no Supabase

```powershell
supabase login
```

Isso abrirá o navegador para você autenticar.

### Linkar projeto local com projeto remoto

```powershell
# No diretório do projeto
cd c:\repo\jardulli-bot-buddy

# Listar projetos
supabase projects list

# Linkar (substitua PROJECT_ID pelo ID do seu projeto)
supabase link --project-ref <PROJECT_ID>
```

---

## 🗄️ Passo 2: Executar Migrations

```powershell
# Aplica a migration no banco de dados remoto
supabase db push

# Ou, se preferir revisar antes:
supabase db diff --schema public

# Depois aplica:
supabase db push
```

**O que será criado:**
- Tabela `gemini_file_cache`
- Tabela `user_rate_limit`
- Funções `check_rate_limit` e `increment_rate_limit`
- Políticas RLS
- Índices otimizados

---

## 📦 Passo 3: Criar Bucket de Storage

### Via Dashboard (mais fácil)

1. Acesse seu projeto no Supabase Dashboard
2. Vá em **Storage** no menu lateral
3. Clique em **New Bucket**
4. Configure:
   - **Name**: `documentos`
   - **Public**: ❌ Desmarque (bucket privado)
   - **File size limit**: `10 MB`
   - **Allowed MIME types**: `application/pdf, text/plain, text/markdown`
5. Clique em **Create bucket**

### Via SQL (alternativa)

Execute no SQL Editor do Supabase:

```sql
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documentos',
  'documentos',
  false,
  10485760, -- 10MB
  ARRAY['application/pdf', 'text/plain', 'text/markdown']
);
```

### Configurar Políticas de Storage

Execute no SQL Editor:

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

-- Usuários autenticados podem ver lista (opcional)
CREATE POLICY "Authenticated users can list documentos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'documentos');
```

---

## 🔑 Passo 4: Configurar Variáveis de Ambiente

### No Supabase Dashboard

1. Vá em **Project Settings** > **Edge Functions**
2. Na seção **Secrets**, adicione:

```
GEMINI_API_KEY=AIza...seu-api-key-aqui
GEMINI_MODEL=gemini-2.0-flash-exp
```

### Localmente (para testes)

Crie arquivo `supabase/.env.local`:

```env
GEMINI_API_KEY=AIza...seu-api-key-aqui
GEMINI_MODEL=gemini-2.0-flash-exp
```

⚠️ **NUNCA** commite este arquivo! Ele já está no `.gitignore`.

---

## 🚀 Passo 5: Deploy das Edge Functions

### Deploy de upload-document

```powershell
supabase functions deploy upload-document
```

### Deploy de ai-chat

```powershell
supabase functions deploy ai-chat
```

### Verificar Deploy

```powershell
# Listar functions
supabase functions list

# Ver logs (em tempo real)
supabase functions logs ai-chat --tail
```

---

## 📄 Passo 6: Upload de Documentos Iniciais

Você precisa fazer upload dos seus documentos (PDFs, TXTs, MDs) para o bucket `documentos`.

### Via Dashboard

1. Vá em **Storage** > **documentos**
2. Clique em **Upload file**
3. Selecione seus arquivos
4. Clique em **Upload**

### Via Script Node.js

Crie um arquivo `scripts/upload-docs.js`:

```javascript
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';

const supabaseUrl = 'https://seu-projeto.supabase.co';
const supabaseKey = 'seu-service-role-key-aqui';
const supabase = createClient(supabaseUrl, supabaseKey);

async function uploadDoc(filePath) {
  const fileName = path.basename(filePath);
  const fileBuffer = fs.readFileSync(filePath);

  const { data, error } = await supabase.storage
    .from('documentos')
    .upload(fileName, fileBuffer, {
      contentType: 'application/pdf',
      upsert: true
    });

  if (error) {
    console.error(`❌ Erro ao enviar ${fileName}:`, error.message);
  } else {
    console.log(`✅ ${fileName} enviado com sucesso`);
    
    // Chama Edge Function para processar no Gemini
    const { data: processData, error: processError } = await supabase.functions.invoke(
      'upload-document',
      {
        body: {
          fileName: fileName,
          fileUrl: fileName
        }
      }
    );
    
    if (processError) {
      console.error(`❌ Erro ao processar ${fileName} no Gemini:`, processError.message);
    } else {
      console.log(`✅ ${fileName} processado no Gemini`);
    }
  }
}

// Upload todos PDFs da pasta local
const docsDir = './docs-iniciais';
const files = fs.readdirSync(docsDir).filter(f => f.endsWith('.pdf'));

for (const file of files) {
  await uploadDoc(path.join(docsDir, file));
  // Aguarda 3 segundos entre uploads para não sobrecarregar
  await new Promise(r => setTimeout(r, 3000));
}

console.log('🎉 Todos os documentos foram processados!');
```

Execute:

```powershell
node scripts/upload-docs.js
```

---

## 🌐 Passo 7: Deploy do Frontend

O frontend já está configurado para Lovable.dev, mas você pode fazer deploy em outros lugares:

### Via Lovable (atual)

1. Commit suas mudanças no Git
2. Push para o repositório
3. Lovable detecta mudanças e faz deploy automático

### Via Vercel (alternativa)

```powershell
# Instalar Vercel CLI
npm i -g vercel

# Deploy
vercel

# Configurar variáveis de ambiente no dashboard Vercel:
# VITE_SUPABASE_URL
# VITE_SUPABASE_PUBLISHABLE_KEY
```

### Via Netlify (alternativa)

```powershell
# Instalar Netlify CLI
npm i -g netlify-cli

# Deploy
netlify deploy --prod

# Build command: npm run build
# Publish directory: dist
```

---

## ✅ Passo 8: Verificação Final

### Checklist de Testes

- [ ] **Migrations aplicadas?**
  ```powershell
  supabase db diff
  # Deve retornar "No schema changes detected"
  ```

- [ ] **Bucket criado?**
  - Acesse Storage no dashboard e veja se `documentos` existe

- [ ] **Edge Functions deployadas?**
  ```powershell
  supabase functions list
  # Deve listar: upload-document, ai-chat
  ```

- [ ] **Variáveis configuradas?**
  - Verifique em Project Settings > Edge Functions > Secrets

- [ ] **Documentos enviados e processados?**
  - Verifique na tabela `gemini_file_cache`:
  ```sql
  SELECT COUNT(*) FROM gemini_file_cache;
  ```

- [ ] **Frontend deployado?**
  - Acesse a URL do seu projeto e teste login

### Teste End-to-End

1. **Login** na aplicação
2. **Criar nova conversa**
3. **Enviar pergunta simples**: "Qual o horário de atendimento?"
4. **Verificar resposta** da IA
5. **Testar feedback**: Clicar em 👍 Bom
6. **Testar rate limit**: Enviar 21 mensagens seguidas (deve bloquear na 21ª)

### Monitorar Logs

```powershell
# Em tempo real
supabase functions logs ai-chat --tail

# Últimas 100 linhas
supabase functions logs ai-chat -n 100
```

---

## 🐛 Troubleshooting

### Erro: "GEMINI_API_KEY não configurada"

**Solução**: Configurar no dashboard Supabase:
1. Project Settings > Edge Functions > Secrets
2. Adicionar `GEMINI_API_KEY` com sua chave

### Erro: "Cannot find table gemini_file_cache"

**Solução**: Migration não foi aplicada
```powershell
supabase db push
```

### Erro: "Rate limit exceeded" nos primeiros testes

**Solução**: Resetar rate limit manualmente
```sql
DELETE FROM user_rate_limit WHERE user_id = 'seu-user-id';
```

### Erro: "File not found in storage"

**Solução**: Upload de documento
1. Verifique se arquivo está no bucket `documentos`
2. Verifique se nome do arquivo está correto

### Edge Function não responde

**Solução**: Ver logs
```powershell
supabase functions logs ai-chat --tail
```

Procure por erros de autenticação, API key inválida, etc.

---

## 💰 Custos Estimados (MVP)

### Tier Gratuito (início)

- **Supabase Free**:
  - 500MB database
  - 1GB bandwidth
  - 2GB storage
  - Edge Functions: 500k invocations/month

- **Gemini Free**:
  - 15 req/min (Flash)
  - 1500 embeddings/day
  - 20GB file storage

**Total: $0/mês** 🎉

### Quando escalar (100+ usuários ativos)

- **Supabase Pro**: $25/mês
- **Gemini Paid** (se necessário): $5-10/mês
- **Total**: $30-35/mês

---

## 📊 Próximos Passos

Após deploy bem-sucedido:

1. **Coletar feedback** de usuários beta
2. **Ajustar prompts** baseado em qualidade das respostas
3. **Adicionar mais documentos** à base de conhecimento
4. **Implementar analytics** (ver MVP-TODO.md - Sprint 4)
5. **Melhorias de UX** (streaming, sugestões, etc)

---

## 📞 Suporte

Problemas ou dúvidas?

1. **Logs**: Sempre comece pelos logs das Edge Functions
2. **Dashboard**: Verifique métricas no Supabase Dashboard
3. **Documentação**: 
   - [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
   - [Google Gemini API](https://ai.google.dev/docs)
4. **Issues**: Abra issue no repositório do projeto

---

**🎉 Parabéns! Seu MVP está pronto para uso!**

Data de criação: Outubro 2025  
Última atualização: Outubro 2025
