# Guia de Implementação: Do Exemplo Gemini para o MVP Jardulli

## 📋 Objetivo deste Documento

Este guia conecta a análise técnica do **backend de exemplo** (`EXEMPLO-GEMINI-DETALHADO.md`) com as tarefas do **MVP Jardulli Bot Buddy** (`MVP-TODO.md`), mostrando:

- ✅ O que pode ser **reutilizado** do exemplo
- 🔄 O que precisa ser **adaptado**
- ⚠️ O que **NÃO** deve ser usado (diferenças de arquitetura)
- 📝 Código pronto para copiar e ajustar

---

## 🏗️ Diferenças de Arquitetura

### Backend de Exemplo (Node.js + Express)

```
┌─────────────────────────────────────┐
│   Express Server (Node.js)          │
│   - File System (docs/ folder)      │
│   - JSON files (cache, threads)     │
│   - Multer (file uploads)           │
│   - Direct API calls                │
└─────────────────────────────────────┘
```

### Jardulli MVP (Supabase + React)

```
┌──────────────────┐
│  React Frontend  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Supabase Client  │
│  - Auth          │
│  - Database      │
│  - Storage       │
│  - Edge Functions│ ← Aqui vive a lógica Gemini
└──────────────────┘
```

**Principais Diferenças**:
- ❌ Sem file system → Use **Supabase Storage**
- ❌ Sem JSON files → Use **Supabase Database**
- ❌ Sem Express routes → Use **Edge Functions**
- ✅ Runtime: Deno (Edge Functions) vs Node.js

---

## 🎯 Mapeamento: Exemplo → MVP

### 1. Upload e Cache de Arquivos

#### 📂 No Exemplo (Node.js)

```typescript
// services/gemini.ts
function sha256File(absPath: string): string {
  const buf = fs.readFileSync(absPath);
  return crypto.createHash("sha256").update(buf).digest("hex");
}

async function uploadLocalFileWithCache(absPath: string) {
  const hash = sha256File(absPath);
  const cache = loadFileCache(); // Lê file_cache.json
  
  if (cache[hash]) {
    return cache[hash]; // Cache hit
  }
  
  // Upload para Gemini...
  const uploaded = await ai.files.upload({ file: blob });
  
  cache[hash] = { name: uploaded.name, uri: uploaded.uri, ... };
  saveFileCache(cache); // Salva em file_cache.json
}
```

#### ✅ Para o MVP (Supabase)

**MVP TODO**: Sprint 1 - Task 2.4 "Pipeline de Ingestão"

```typescript
// supabase/functions/upload-document/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { GoogleGenAI } from "https://esm.sh/@google/genai@1"

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )
  
  const { fileName, fileUrl } = await req.json()
  
  // 1. Baixa arquivo do Supabase Storage
  const { data: fileData } = await supabase.storage
    .from('documentos')
    .download(fileUrl)
  
  // 2. Calcula hash (usando Web Crypto API do Deno)
  const arrayBuffer = await fileData.arrayBuffer()
  const hashBuffer = await crypto.subtle.digest('SHA-256', arrayBuffer)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  const hash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
  
  // 3. Verifica cache no banco de dados
  const { data: cached } = await supabase
    .from('gemini_file_cache')
    .select('*')
    .eq('file_hash', hash)
    .single()
  
  if (cached) {
    return new Response(JSON.stringify({ 
      cached: true,
      geminiFile: cached 
    }))
  }
  
  // 4. Upload para Gemini
  const ai = new GoogleGenAI({ apiKey: Deno.env.get('GEMINI_API_KEY')! })
  const blob = new Blob([arrayBuffer], { type: fileData.type })
  
  const uploaded = await ai.files.upload({
    file: blob,
    config: { displayName: fileName }
  })
  
  // 5. Aguarda processamento
  let geminiFile = await ai.files.get({ name: uploaded.name })
  while (geminiFile.state === 'PROCESSING') {
    await new Promise(r => setTimeout(r, 2000))
    geminiFile = await ai.files.get({ name: uploaded.name })
  }
  
  // 6. Salva no cache (banco de dados)
  await supabase.from('gemini_file_cache').insert({
    file_hash: hash,
    gemini_name: geminiFile.name,
    gemini_uri: geminiFile.uri,
    mime_type: fileData.type,
    display_name: fileName,
    original_path: fileUrl
  })
  
  return new Response(JSON.stringify({ 
    cached: false,
    geminiFile 
  }))
})
```

**Schema SQL necessário**:

```sql
-- Tabela para cache de arquivos do Gemini
CREATE TABLE gemini_file_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_hash TEXT NOT NULL UNIQUE,
  gemini_name TEXT NOT NULL,
  gemini_uri TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  display_name TEXT NOT NULL,
  original_path TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_gemini_cache_hash ON gemini_file_cache(file_hash);
```

**O que mudou**:
- ✅ `fs.readFileSync()` → `supabase.storage.download()`
- ✅ `JSON file cache` → `gemini_file_cache` table
- ✅ `crypto.createHash()` (Node) → `crypto.subtle.digest()` (Web API)

---

### 2. Função Principal de Perguntas

#### 📂 No Exemplo (Node.js)

```typescript
// services/gemini.ts
export async function askGeminiFromDocs(pergunta: string): Promise<string> {
  const model = process.env.GEMINI_MODEL || "gemini-2.5-flash";
  
  const systemPrompt = `Você é uma Consultora...`;
  
  const fileParts = await collectDocParts(); // Coleta da pasta docs/
  
  const contents: any[] = [
    systemPrompt,
    `Pergunta: ${pergunta}`,
    ...fileParts
  ];
  
  const response = await ai.models.generateContent({
    model,
    contents,
  });
  
  return response.text || "";
}
```

#### ✅ Para o MVP (Supabase)

**MVP TODO**: Sprint 2 - Task 3 "Fluxo RAG Completo"

```typescript
// supabase/functions/ai-chat/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { GoogleGenAI, createPartFromUri } from "https://esm.sh/@google/genai@1"

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )
  
  const { message, conversationId, userId } = await req.json()
  
  // 1. Valida rate limiting
  const canProceed = await checkRateLimit(supabase, userId)
  if (!canProceed) {
    return new Response(
      JSON.stringify({ error: 'Rate limit excedido' }),
      { status: 429 }
    )
  }
  
  // 2. Busca arquivos em cache
  const { data: cachedFiles } = await supabase
    .from('gemini_file_cache')
    .select('gemini_uri, mime_type')
  
  // 3. Monta file parts para Gemini
  const fileParts = cachedFiles?.map(f => 
    createPartFromUri(f.gemini_uri, f.mime_type)
  ) || []
  
  // 4. Busca histórico da conversa (últimas 10 mensagens)
  const { data: messages } = await supabase
    .from('messages')
    .select('role, content')
    .eq('conversation_id', conversationId)
    .order('created_at', { ascending: true })
    .limit(10)
  
  // 5. Monta prompt do sistema
  const systemPrompt = `Você é o assistente virtual da Jardulli Máquinas.

INSTRUÇÕES IMPORTANTES:
- Responda APENAS com base nos documentos fornecidos
- Se não souber, diga: "Não encontrei essa informação em nossa base"
- Sugira contato: (19) 98212-1616
- Use formatação markdown (listas, negrito, títulos)
- Seja profissional e prestativo

SOBRE A JARDULLI:
- Especializada em máquinas de café
- Vendas, assistência técnica e suporte
`
  
  // 6. Monta contents (histórico + nova pergunta + arquivos)
  const ai = new GoogleGenAI({ apiKey: Deno.env.get('GEMINI_API_KEY')! })
  
  const contents = [
    { role: 'user', parts: [{ text: systemPrompt }] },
    { role: 'model', parts: [{ text: 'Entendido! Vou seguir as instruções.' }] },
    // Histórico
    ...messages.map(msg => ({
      role: msg.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: msg.content }]
    })),
    // Nova pergunta + arquivos
    { 
      role: 'user', 
      parts: [
        { text: `Pergunta: ${message}` },
        ...fileParts
      ]
    }
  ]
  
  // 7. Chama Gemini
  const model = Deno.env.get('GEMINI_MODEL') || 'gemini-2.5-flash'
  const response = await ai.models.generateContent({
    model,
    contents,
    generationConfig: {
      temperature: 0.7,
      topK: 40,
      topP: 0.95,
      maxOutputTokens: 1024,
    }
  })
  
  const aiResponse = response.text || 'Desculpe, não consegui processar sua pergunta.'
  
  // 8. Salva mensagens no banco
  await supabase.from('messages').insert([
    {
      conversation_id: conversationId,
      role: 'user',
      content: message
    },
    {
      conversation_id: conversationId,
      role: 'assistant',
      content: aiResponse
    }
  ])
  
  // 9. Atualiza rate limiting
  await updateRateLimit(supabase, userId)
  
  return new Response(JSON.stringify({ 
    reply: aiResponse,
    conversationId 
  }), {
    headers: { 'Content-Type': 'application/json' }
  })
})

// Helper: Rate limiting
async function checkRateLimit(supabase: any, userId: string): Promise<boolean> {
  const { data } = await supabase
    .from('user_rate_limit')
    .select('message_count, window_start')
    .eq('user_id', userId)
    .single()
  
  if (!data) {
    // Primeira mensagem do usuário
    await supabase.from('user_rate_limit').insert({
      user_id: userId,
      message_count: 1,
      window_start: new Date().toISOString()
    })
    return true
  }
  
  const windowStart = new Date(data.window_start)
  const now = new Date()
  const hoursPassed = (now.getTime() - windowStart.getTime()) / (1000 * 60 * 60)
  
  if (hoursPassed >= 1) {
    // Reset janela
    await supabase.from('user_rate_limit')
      .update({ message_count: 1, window_start: now.toISOString() })
      .eq('user_id', userId)
    return true
  }
  
  return data.message_count < 20 // Limite: 20 mensagens/hora
}

async function updateRateLimit(supabase: any, userId: string) {
  await supabase.rpc('increment_rate_limit', { uid: userId })
}
```

**SQL adicional**:

```sql
-- Rate limiting
CREATE TABLE user_rate_limit (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  message_count INT DEFAULT 0,
  window_start TIMESTAMPTZ DEFAULT NOW()
);

-- Função para incrementar
CREATE FUNCTION increment_rate_limit(uid UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE user_rate_limit 
  SET message_count = message_count + 1
  WHERE user_id = uid;
END;
$$ LANGUAGE plpgsql;
```

**O que mudou**:
- ✅ `collectDocParts()` → Query em `gemini_file_cache`
- ✅ Histórico local → Query em `messages` table
- ✅ Rate limiting integrado
- ✅ Mensagens salvas automaticamente no banco

---

### 3. Sistema de Threads (Histórico)

#### 📂 No Exemplo (Node.js)

```typescript
// stores/threadsStore.ts
export function loadThreads(): ThreadRecord[] {
  try {
    return JSON.parse(fs.readFileSync(THREADS_FILE, "utf8"));
  } catch {
    return [];
  }
}

export function saveThreads(list: ThreadRecord[]) {
  fs.writeFileSync(THREADS_FILE, JSON.stringify(list, null, 2));
}
```

#### ✅ Para o MVP (Supabase)

**MVP TODO**: Já implementado! ✅

O MVP Jardulli já tem sistema de threads melhor que o exemplo:

```typescript
// Tabela conversations (já existe!)
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  title TEXT DEFAULT 'Nova Conversa',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

// Tabela messages (já existe!)
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id),
  role TEXT CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**O que usar**:
- ✅ **NÃO** precisa adaptar do exemplo
- ✅ Seu sistema atual é **superior** (RLS, real-time, etc)
- ✅ Apenas integre com Edge Function (já mostrado acima)

---

## 📊 Tabela de Aproveitamento

| Componente | Exemplo | MVP | Ação |
|-----------|---------|-----|------|
| **Upload de arquivos** | `fs.readFileSync` | Supabase Storage | 🔄 Adaptar |
| **Cache de arquivos** | `file_cache.json` | Tabela `gemini_file_cache` | 🔄 Adaptar |
| **Hash SHA256** | `crypto.createHash` | `crypto.subtle.digest` | 🔄 Adaptar (API diferente) |
| **Gemini API call** | `ai.models.generateContent` | Mesmo! | ✅ Reutilizar |
| **Polling de arquivo** | `while (state === PROCESSING)` | Mesmo! | ✅ Reutilizar |
| **System prompt** | Template string | Copiar e ajustar | ✅ Reutilizar 90% |
| **File parts** | `createPartFromUri` | Mesmo! | ✅ Reutilizar |
| **Threads/Histórico** | `threads.json` | Tabelas existentes | ❌ Não usar (já tem melhor) |
| **Rate limiting** | Não tem | Implementar novo | ➕ Adicionar |
| **Autenticação** | Não tem | Supabase Auth | ➕ Já existe |

---

## 🚀 Plano de Implementação Passo a Passo

### Sprint 1: Fundação (Semana 1)

#### Task 1.1: Criar Tabela de Cache
```sql
-- Execute no Supabase SQL Editor
CREATE TABLE gemini_file_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_hash TEXT NOT NULL UNIQUE,
  gemini_name TEXT NOT NULL,
  gemini_uri TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  display_name TEXT NOT NULL,
  original_path TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_gemini_cache_hash ON gemini_file_cache(file_hash);

-- RLS
ALTER TABLE gemini_file_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role pode tudo"
  ON gemini_file_cache FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');
```

#### Task 1.2: Criar Bucket no Supabase Storage
```typescript
// Execute no Supabase Dashboard > Storage
// Ou via API:
await supabase.storage.createBucket('documentos', {
  public: false,
  fileSizeLimit: 10485760, // 10MB
  allowedMimeTypes: ['application/pdf', 'text/plain', 'text/markdown']
})
```

#### Task 1.3: Upload de Documentos Iniciais
```typescript
// Script para popular base inicial
// scripts/upload-initial-docs.ts
import { createClient } from '@supabase/supabase-js'
import fs from 'fs'
import path from 'path'

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!
)

async function uploadDoc(filePath: string) {
  const fileName = path.basename(filePath)
  const fileBuffer = fs.readFileSync(filePath)
  
  const { data, error } = await supabase.storage
    .from('documentos')
    .upload(fileName, fileBuffer, {
      contentType: 'application/pdf',
      upsert: true
    })
  
  if (error) {
    console.error(`Erro ao enviar ${fileName}:`, error)
  } else {
    console.log(`✅ ${fileName} enviado com sucesso`)
  }
}

// Upload todos PDFs da pasta local
const docsDir = './docs-iniciais'
const files = fs.readdirSync(docsDir).filter(f => f.endsWith('.pdf'))

for (const file of files) {
  await uploadDoc(path.join(docsDir, file))
}
```

---

### Sprint 2: Edge Functions (Semana 2)

#### Task 2.1: Edge Function de Upload com Cache

Copie o código da seção "1. Upload e Cache de Arquivos" acima.

```bash
# Criar Edge Function
supabase functions new upload-document

# Copiar código para supabase/functions/upload-document/index.ts

# Deploy
supabase functions deploy upload-document
```

#### Task 2.2: Edge Function de Chat

Copie o código da seção "2. Função Principal de Perguntas" acima.

```bash
# Criar Edge Function
supabase functions new ai-chat

# Copiar código para supabase/functions/ai-chat/index.ts

# Deploy
supabase functions deploy ai-chat
```

#### Task 2.3: Configurar Variáveis de Ambiente

```bash
# No Supabase Dashboard > Project Settings > Edge Functions

GEMINI_API_KEY=AIza...
GEMINI_MODEL=gemini-2.5-flash
SUPABASE_URL=https://...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

---

### Sprint 3: Integração Frontend (Semana 3)

#### Task 3.1: Atualizar `src/pages/Index.tsx`

```typescript
// Remover simulação
const handleSendMessage = async () => {
  if (!inputMessage.trim() || !currentConversationId || sending) return;

  const userMessage = inputMessage;
  setInputMessage("");
  setSending(true);

  // ❌ REMOVER ISTO:
  // setTimeout(async () => {
  //   const aiResponse = `Esta é uma resposta simulada...`;
  // }, 1500);

  // ✅ ADICIONAR ISTO:
  try {
    // 1. Insere mensagem do usuário
    const { data: userMsg, error: userError } = await supabase
      .from("messages")
      .insert({
        conversation_id: currentConversationId,
        role: "user",
        content: userMessage,
      })
      .select()
      .single();

    if (userError) throw userError;

    // 2. Chama Edge Function
    const { data: { session } } = await supabase.auth.getSession();
    
    const { data: aiData, error: aiError } = await supabase.functions.invoke(
      'ai-chat',
      {
        body: {
          message: userMessage,
          conversationId: currentConversationId,
          userId: session?.user?.id
        }
      }
    );

    if (aiError) throw aiError;

    // 3. Edge Function já salvou a resposta no banco
    // Realtime vai atualizar a UI automaticamente!

    // 4. Atualiza título da conversa (primeira mensagem)
    if (messages.length === 0) {
      await supabase
        .from("conversations")
        .update({ title: userMessage.slice(0, 50) })
        .eq("id", currentConversationId);
    }

  } catch (error) {
    console.error("Erro ao enviar mensagem:", error);
    toast({
      title: "Erro",
      description: error.message || "Não foi possível enviar a mensagem",
      variant: "destructive",
    });
  } finally {
    setSending(false);
  }
};
```

#### Task 3.2: Adicionar Indicador de "IA Pensando"

```typescript
// Já existe! Só garantir que está funcionando
{sending && (
  <div className="flex justify-start">
    <div className="bg-card border border-border rounded-lg p-4">
      <div className="flex items-center gap-2">
        <Loader2 className="h-5 w-5 animate-spin text-primary" />
        <span className="text-sm text-muted-foreground">
          Consultando base de conhecimento...
        </span>
      </div>
    </div>
  </div>
)}
```

---

### Sprint 4: Testes e Ajustes (Semana 4)

#### Task 4.1: Testar Fluxo Completo

```typescript
// Checklist de testes:
// 1. Upload de documentos
const testUpload = async () => {
  const { data, error } = await supabase.functions.invoke('upload-document', {
    body: {
      fileName: 'manual-teste.pdf',
      fileUrl: 'documentos/manual-teste.pdf'
    }
  })
  console.log('Upload result:', data)
}

// 2. Pergunta simples
const testSimpleQuestion = async () => {
  const { data, error } = await supabase.functions.invoke('ai-chat', {
    body: {
      message: 'Qual o horário de atendimento?',
      conversationId: 'test-conv-id',
      userId: 'test-user-id'
    }
  })
  console.log('AI response:', data)
}

// 3. Pergunta complexa
// 4. Pergunta fora do contexto (deve responder que não sabe)
// 5. Rate limiting (enviar 21 mensagens seguidas)
```

#### Task 4.2: Ajustar System Prompt

Baseado nos testes, refine o prompt:

```typescript
const systemPrompt = `Você é o assistente virtual da Jardulli Máquinas.

CONTEXTO DA EMPRESA:
- Especializada em máquinas de café profissionais
- Atua em vendas, locação, assistência técnica e suporte
- Atende diversos segmentos: escritórios, cafeterias, eventos

INSTRUÇÕES DE RESPOSTA:
1. Base APENAS nos documentos fornecidos
2. Se não souber, seja honesto: "Não encontrei essa informação"
3. Sugira sempre contato humano: (19) 98212-1616
4. Use formatação clara:
   - Listas para múltiplos itens
   - **Negrito** para informações importantes
   - Parágrafos curtos e objetivos

ESTILO:
- Profissional mas acessível
- Evite jargões técnicos desnecessários
- Seja proativo: ofereça informações relacionadas
- Finalize sugerindo outras dúvidas

NUNCA:
- Invente preços ou condições comerciais
- Garanta coisas que não estão nos documentos
- Dê informações médicas ou legais
- Responda perguntas não relacionadas à Jardulli
`
```

---

## 🎨 Melhorias Visuais no Frontend

### Mostrar Fontes Usadas

```typescript
// src/components/MessageActions.tsx
// Adicionar indicador de fontes

interface MessageActionsProps {
  messageId: string;
  messageContent: string;
  userQuestion: string;
  sourcesCount?: number; // ← NOVO
}

export const MessageActions = ({ 
  messageId, 
  messageContent, 
  userQuestion,
  sourcesCount = 0 
}: MessageActionsProps) => {
  return (
    <>
      {/* Indicador de fontes */}
      {sourcesCount > 0 && (
        <div className="flex items-center gap-1 text-xs text-muted-foreground mt-2">
          <FileText className="h-3 w-3" />
          <span>Baseado em {sourcesCount} documento(s)</span>
        </div>
      )}
      
      {/* Ações existentes */}
      <div className="flex items-center gap-2 mt-3 pt-3 border-t border-border">
        {/* ... botões existentes ... */}
      </div>
    </>
  );
};
```

### Melhorar Feedback Visual

```typescript
// src/pages/Index.tsx
// Adicionar estado de erro

const [error, setError] = useState<string | null>(null);

// No handleSendMessage:
catch (error) {
  setError(error.message);
  toast({
    title: "Erro",
    description: error.message,
    variant: "destructive",
  });
}

// No JSX:
{error && (
  <div className="max-w-3xl mx-auto mb-4">
    <Alert variant="destructive">
      <AlertCircle className="h-4 w-4" />
      <AlertTitle>Erro</AlertTitle>
      <AlertDescription>{error}</AlertDescription>
    </Alert>
  </div>
)}
```

---

## 🔍 Código que Pode Copiar DIRETO do Exemplo

### 1. Lógica de Polling do Gemini

```typescript
// ✅ COPIAR EXATAMENTE
let geminiFile = await ai.files.get({ name: uploaded.name });
while (geminiFile.state === 'PROCESSING') {
  await new Promise(r => setTimeout(r, 2000));
  geminiFile = await ai.files.get({ name: uploaded.name });
}

if (geminiFile.state === 'FAILED') {
  throw new Error(`Processamento falhou: ${displayName}`);
}
```

### 2. Função de MIME Type

```typescript
// ✅ COPIAR EXATAMENTE
function mimeFromExt(ext: string): string {
  switch (ext.toLowerCase()) {
    case '.pdf':
      return 'application/pdf';
    case '.md':
      return 'text/markdown';
    case '.txt':
      return 'text/plain';
    default:
      return 'application/octet-stream';
  }
}
```

### 3. Estrutura do `generateContent`

```typescript
// ✅ COPIAR EXATAMENTE (ajustar contents)
const response = await ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: [...], // Seu array aqui
  generationConfig: {
    temperature: 0.7,
    topK: 40,
    topP: 0.95,
    maxOutputTokens: 1024,
  },
  safetySettings: [
    { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
    { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_MEDIUM_AND_ABOVE" }
  ]
});
```

---

## ⚠️ Código que NÃO Deve Copiar

### ❌ File System Operations

```typescript
// ❌ NÃO FUNCIONA em Edge Functions
fs.readFileSync(path)
fs.writeFileSync(path, data)
fs.existsSync(path)
fs.mkdirSync(path)

// ✅ Use Supabase Storage
supabase.storage.from('bucket').download(path)
supabase.storage.from('bucket').upload(path, file)
```

### ❌ Threads Store Local

```typescript
// ❌ NÃO usar threads.json
loadThreads() // Lê arquivo local
saveThreads() // Grava arquivo local

// ✅ Use tabelas existentes
supabase.from('conversations').select()
supabase.from('messages').select()
```

### ❌ Express Routes

```typescript
// ❌ NÃO é Express
router.post('/perguntar-gemini', async (req, res) => {
  res.json({ texto })
})

// ✅ Edge Functions
serve(async (req) => {
  return new Response(JSON.stringify({ texto }))
})
```

---

## 📈 Métricas de Sucesso

Após implementação, monitore:

1. **Performance**
   - Tempo de resposta: < 5 segundos
   - Cache hit rate: > 80%
   - Uptime: > 99%

2. **Qualidade**
   - Taxa de feedback positivo: > 70%
   - Perguntas sem resposta: < 5%
   - Respostas "não sei": 10-15% (bom!)

3. **Uso**
   - Mensagens/dia
   - Usuários ativos
   - Conversas por usuário
   - Documentos mais consultados

---

## 🎯 Resumo: O Que Fazer Agora

1. ✅ **Ler este documento completo**
2. ✅ **Implementar Sprint 1** (tabelas + storage)
3. ✅ **Testar upload de 1 documento** simples
4. ✅ **Implementar Sprint 2** (Edge Functions)
5. ✅ **Testar pergunta simples** localmente
6. ✅ **Deploy das Edge Functions**
7. ✅ **Integrar com frontend** (Sprint 3)
8. ✅ **Testar fluxo completo**
9. ✅ **Ajustar prompts** baseado em feedback
10. ✅ **Documentar aprendizados**

---

**Próximo passo recomendado**: Comece pela Sprint 1, Task 1.1 (criar tabela de cache). É rápido e dá base para tudo!

---

**Última atualização**: Outubro 2025  
**Mantido por**: Time Jardulli Bot Buddy
