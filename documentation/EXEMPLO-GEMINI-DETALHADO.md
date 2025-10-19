# Como Funciona a Integração Gemini - Análise do Backend de Exemplo

## 📚 Visão Geral

Este documento explica **detalhadamente** como o backend de exemplo (`agrosinergia_responde_backend`) implementa a integração com **Google Gemini** para criar um sistema de **RAG (Retrieval-Augmented Generation)** - perguntas e respostas baseadas em documentos.

---

## 🎯 O Que o Sistema Faz

### Objetivo Principal
Permitir que usuários façam perguntas e obtenham respostas **baseadas exclusivamente** em documentos (PDFs, TXTs, MDs) armazenados no servidor, usando o Google Gemini para processar e gerar as respostas.

### Fluxo Simplificado
```
1. Documentos ficam na pasta docs/
2. Sistema faz upload dos documentos para Gemini File API
3. Usuário faz pergunta via POST /perguntar-gemini
4. Sistema envia documentos + pergunta para Gemini
5. Gemini analisa documentos e responde
6. Resposta formatada retorna para o usuário
```

---

## 🏗️ Arquitetura da Solução Gemini

### Estrutura de Arquivos

```
agrosinergia_responde_backend/
│
├── src/
│   ├── routes/
│   │   └── perguntar-gemini.ts    ← Rota que recebe perguntas
│   │
│   ├── services/
│   │   └── gemini.ts              ← Lógica de integração com Gemini
│   │
│   ├── stores/
│   │   └── threadsStore.ts        ← Gerencia histórico de conversas
│   │
│   └── config.ts                  ← Configurações e paths
│
├── docs/                          ← Documentos (PDF, TXT, MD)
├── file_cache.json                ← Cache de arquivos já enviados
├── threads.json                   ← Histórico de threads locais
└── .env                           ← Variáveis de ambiente
```

---

## 🔧 Componente 1: Configuração (`config.ts`)

### Variáveis de Ambiente

```typescript
export const GEMINI_API_KEY = process.env.GEMINI_API_KEY || "";
export const GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-2.5-pro";
```

**O que configurar no `.env`**:
```env
GEMINI_API_KEY=AIza...                    # API key do Google AI Studio
GEMINI_MODEL=gemini-2.5-flash             # Ou gemini-2.5-pro
```

### Paths Importantes

```typescript
export const DOCS_DIR = path.join(ROOT_DIR, "docs");
export const GEMINI_CACHE_FILE = path.join(ROOT_DIR, ".gemini_cache.json");
export const THREADS_FILE = path.join(ROOT_DIR, "threads.json");
```

- **`docs/`**: Onde você coloca seus PDFs, TXTs, MDs
- **`file_cache.json`**: Evita reenviar arquivos já carregados
- **`threads.json`**: Histórico de conversas (opcional para Gemini)

---

## 🚀 Componente 2: Service Gemini (`services/gemini.ts`)

Este é o **coração** da integração. Vamos analisar passo a passo.

### 2.1 Inicialização do Cliente

```typescript
import { createPartFromUri, GoogleGenAI } from "@google/genai";

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || "";
const ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY });
```

**O que acontece**:
- Importa SDK oficial do Gemini (`@google/genai` versão 1.13.0)
- Cria instância do cliente com a API key
- Este cliente será usado para upload e geração de conteúdo

---

### 2.2 Sistema de Cache de Arquivos

#### Por que Cache?
Evitar **reupload** de arquivos que já foram enviados ao Gemini. Uploads são lentos e consomem quota.

#### Estrutura do Cache (`file_cache.json`)

```json
{
  "a3f5e9b2c1d4...": {
    "name": "files/abc123xyz",
    "uri": "https://generativelanguage.googleapis.com/v1beta/files/abc123xyz",
    "mimeType": "application/pdf",
    "displayName": "manual.pdf",
    "uploadedAt": "2025-10-17T10:30:00.000Z"
  },
  "d7c2b8a4f6e1...": {
    "name": "files/def456uvw",
    "uri": "https://generativelanguage.googleapis.com/v1beta/files/def456uvw",
    "mimeType": "text/plain",
    "displayName": "regras.txt",
    "uploadedAt": "2025-10-17T11:45:00.000Z"
  }
}
```

**Chave**: Hash SHA256 do conteúdo do arquivo  
**Valor**: Metadados do arquivo no Gemini (name, uri, mimeType, etc)

#### Funções de Cache

```typescript
function loadFileCache(): FileCache {
  try {
    return JSON.parse(fs.readFileSync(FILE_CACHE_PATH, "utf8"));
  } catch {
    return {}; // Arquivo não existe ou JSON inválido
  }
}

function saveFileCache(c: FileCache) {
  fs.writeFileSync(FILE_CACHE_PATH, JSON.stringify(c, null, 2), "utf8");
}
```

#### Função de Hash

```typescript
function sha256File(absPath: string): string {
  const buf = fs.readFileSync(absPath);
  return crypto.createHash("sha256").update(buf).digest("hex");
}
```

**Por que SHA256?**  
Se você modificar 1 byte no arquivo, o hash muda completamente → sistema detecta que precisa fazer novo upload.

---

### 2.3 Upload de Arquivos com Cache

Esta é a **função mais importante**:

```typescript
async function uploadLocalFileWithCache(absPath: string) {
  // 1. Calcula hash do arquivo
  const hash = sha256File(absPath);
  const cache = loadFileCache();

  // 2. Verifica se já existe no cache
  if (cache[hash]) {
    console.log(`✅ Cache HIT: ${path.basename(absPath)}`);
    return cache[hash]; // Retorna dados salvos (não reenvia!)
  }

  console.log(`📤 Uploading: ${path.basename(absPath)}`);

  // 3. Determina MIME type
  const ext = path.extname(absPath);
  const mimeType = mimeFromExt(ext); // .pdf → application/pdf
  const displayName = path.basename(absPath);

  // 4. Lê arquivo como buffer e cria Blob
  const buf = fs.readFileSync(absPath);
  const blob = new Blob([buf], { type: mimeType });

  // 5. FAZ UPLOAD para Gemini File API
  const uploaded = await ai.files.upload({
    file: blob,
    config: { displayName },
  });

  // 6. Validação: garante que recebeu 'name'
  if (!uploaded?.name || typeof uploaded.name !== "string") {
    throw new Error(`Upload não retornou 'name' válido para "${displayName}".`);
  }

  // 7. POLLING: aguarda processamento do arquivo
  let getFile = await ai.files.get({ name: uploaded.name });
  while (getFile.state === "PROCESSING") {
    console.log(`⏳ Processing: ${displayName}...`);
    await new Promise((r) => setTimeout(r, 2000)); // Aguarda 2 segundos
    getFile = await ai.files.get({ name: uploaded.name });
  }

  // 8. Verifica se processamento foi bem-sucedido
  if (getFile.state === "FAILED") {
    throw new Error(`Processamento de arquivo falhou: ${displayName}`);
  }

  // 9. Validação final
  if (!getFile?.name || !getFile?.uri) {
    throw new Error(
      `Arquivo "${displayName}" processado, mas sem 'name' ou 'uri' retornados.`
    );
  }

  // 10. Salva no cache para reutilizar depois
  const entry = {
    name: getFile.name,
    uri: getFile.uri,
    mimeType,
    displayName,
    uploadedAt: new Date().toISOString(),
  };

  cache[hash] = entry;
  saveFileCache(cache);

  console.log(`✅ Cached: ${displayName}`);
  return entry;
}
```

#### Estados do Arquivo no Gemini

```
PROCESSING → Gemini está processando (pode levar segundos/minutos)
ACTIVE     → Pronto para uso
FAILED     → Erro no processamento
```

#### Por que Polling?

Gemini File API é **assíncrona**. Quando você faz upload, o arquivo não está imediatamente disponível. Você precisa **verificar o estado** até ficar `ACTIVE`.

---

### 2.4 Coleta de Documentos

```typescript
function listDocs(exts = [".pdf", ".txt", ".md"]) {
  if (!fs.existsSync(DOCS_DIR)) return [];
  return fs
    .readdirSync(DOCS_DIR)
    .map((f) => path.join(DOCS_DIR, f))
    .filter(
      (full) =>
        fs.statSync(full).isFile() &&
        exts.includes(path.extname(full).toLowerCase())
    );
}
```

**O que faz**: Lista todos os arquivos `.pdf`, `.txt`, `.md` da pasta `docs/`.

```typescript
async function collectDocParts() {
  const files = listDocs();
  const parts: any[] = [];

  for (const abs of files) {
    const meta = await uploadLocalFileWithCache(abs);

    // Cria "part" que o Gemini entende
    if (typeof meta.uri === "string" && typeof meta.mimeType === "string") {
      parts.push(createPartFromUri(meta.uri, meta.mimeType));
    }
  }
  return parts;
}
```

**O que é `createPartFromUri`?**  
É uma função helper do SDK que cria um objeto no formato que o Gemini espera:

```typescript
// Internamente cria algo assim:
{
  fileData: {
    fileUri: "https://generativelanguage.googleapis.com/.../files/abc123",
    mimeType: "application/pdf"
  }
}
```

---

### 2.5 Função Principal: `askGeminiFromDocs`

Esta função **orquestra tudo**:

```typescript
export async function askGeminiFromDocs(pergunta: string): Promise<string> {
  // 1. Define qual modelo usar
  const model = process.env.GEMINI_MODEL || "gemini-2.5-flash";

  // 2. Monta prompt do sistema (instruções para a IA)
  const systemPrompt = `
Você é uma Consultora Especialista.
Responda exclusivamente com base nos documentos fornecidos.

FORMATO OBRIGATÓRIO DA RESPOSTA:
- Sempre use títulos, subtítulos e listas numeradas ou com marcadores.
- Separe os tópicos com quebras de linha.
- Use **negrito** para destacar termos importantes.
- Organize a resposta para fácil leitura e compreensão.
- Caso a resposta seja um conjunto de etapas, utilize passo a passo numerado.
- Caso a resposta seja conceitual ou descritiva, utilize tópicos ou seções.
- Nunca escreva tudo em um único parágrafo.
- Caso não haja informação clara nos documentos, responda exatamente:
  "Não encontrei essa informação em nossa base de dados."
`;

  // 3. Coleta e faz upload de todos os documentos (com cache!)
  const fileParts = await collectDocParts();

  // 4. Monta o array de contents (prompt + pergunta + arquivos)
  const contents: any[] = [
    systemPrompt,
    `Pergunta: ${pergunta}`,
    ...fileParts
  ];

  // 5. CHAMA GEMINI API
  const response = await ai.models.generateContent({
    model,
    contents,
  });

  // 6. Extrai texto da resposta
  const text = (response as any)?.text ?? "";

  return text || "";
}
```

#### Estrutura do `contents`

```typescript
[
  "Você é uma Consultora...",           // System prompt (instruções)
  "Pergunta: Como cadastrar usuário?",  // Pergunta do usuário
  { fileData: { fileUri: "...", mimeType: "..." } }, // Arquivo 1
  { fileData: { fileUri: "...", mimeType: "..." } }, // Arquivo 2
  { fileData: { fileUri: "...", mimeType: "..." } }, // Arquivo 3
  // ... outros arquivos
]
```

**Gemini processa tudo junto**: Ele lê os arquivos + a pergunta + as instruções e gera uma resposta.

---

## 🌐 Componente 3: Rota (`routes/perguntar-gemini.ts`)

Esta é a **API endpoint** que o frontend chama.

```typescript
import express from "express";
import { ensureThreadForAsk, loadThreads, saveThreads } from "../stores/threadsStore";
import { askGeminiFromDocs } from "../services/gemini";

const router = express.Router();

router.post("/perguntar-gemini", async (req, res) => {
  try {
    // 1. Extrai dados da requisição
    const pergunta = String(req.body.pergunta || "").trim();
    const wantedThreadId = (req.body.threadId as string) || null;

    // 2. Validação básica
    if (!pergunta) {
      return res.status(400).json({ erro: "Pergunta vazia." });
    }

    // 3. Gerencia thread local (histórico de conversa)
    const t = await ensureThreadForAsk(wantedThreadId, "gemini");

    // 4. CHAMA GEMINI
    const texto = await askGeminiFromDocs(pergunta);

    // 5. Atualiza metadados da thread
    const threads = loadThreads();
    const i = threads.findIndex((x) => x.id === t.id);
    if (i >= 0) {
      // Atualiza título com primeira pergunta
      if (threads[i].title === "Novo chat") {
        threads[i].title = pergunta.slice(0, 60);
      }
      threads[i].updatedAt = Date.now();
      saveThreads(threads);
    }

    // 6. Retorna resposta
    res.json({ texto, threadId: t.id });

  } catch (e: any) {
    console.error("Erro /perguntar-gemini:", e);
    res.status(500).json({ erro: e?.message ?? "Erro inesperado." });
  }
});

export default router;
```

### Como o Frontend Chama

```typescript
// No React/Frontend
const response = await fetch('http://localhost:3000/perguntar-gemini', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    pergunta: "Como cadastrar usuário?",
    threadId: "thread-abc-123" // Opcional, para continuar conversa
  })
});

const data = await response.json();
console.log(data.texto); // Resposta do Gemini
console.log(data.threadId); // ID da thread (para próxima pergunta)
```

---

## 🗂️ Componente 4: Thread Store (`stores/threadsStore.ts`)

### O que são Threads?

**Thread** = Conversa completa (histórico de perguntas e respostas).

No exemplo, threads são armazenadas **localmente** em `threads.json`:

```json
[
  {
    "id": "abc-123-def",
    "provider": "gemini",
    "assistant_id": "gemini",
    "thread_id": null,
    "title": "Como cadastrar usuário?",
    "createdAt": 1697532000000,
    "updatedAt": 1697532180000
  },
  {
    "id": "xyz-789-uvw",
    "provider": "gemini",
    "assistant_id": "gemini",
    "thread_id": null,
    "title": "Preço das máquinas",
    "createdAt": 1697531000000,
    "updatedAt": 1697531300000
  }
]
```

### Função `ensureThreadForAsk`

```typescript
export async function ensureThreadForAsk(
  wantedLocalThreadId: string | null,
  assistant_id: string
): Promise<ThreadRecord> {
  let threads = loadThreads();

  // 1. Se thread específica foi pedida, retorna ela
  if (wantedLocalThreadId) {
    const existing = threads.find((t) => t.id === wantedLocalThreadId);
    if (existing) return existing;
  }

  // 2. Reutiliza thread mais recente do mesmo assistant
  const recent = threads.find((t) => t.assistant_id === assistant_id);
  if (recent) return recent;

  // 3. Cria nova thread
  const provider: Provider = "gemini";
  const thread_id = null; // Gemini não usa thread_id remoto

  const newThread: ThreadRecord = {
    id: uuid(),
    provider,
    assistant_id,
    thread_id,
    title: "Novo chat",
    createdAt: Date.now(),
    updatedAt: Date.now(),
  };

  // 4. Salva no início da lista (mais recente primeiro)
  threads.unshift(newThread);
  saveThreads(threads);

  return newThread;
}
```

**Lógica de Reuso**:
1. Se você passar `threadId` existente → continua aquela conversa
2. Se não passar → reutiliza a mais recente do Gemini
3. Se não houver nenhuma → cria nova

---

## 📦 Dependências (`package.json`)

### Principais Pacotes

```json
{
  "dependencies": {
    "@google/genai": "^1.13.0",    // ← SDK oficial do Gemini
    "express": "^5.1.0",            // Web server
    "cors": "^2.8.5",               // CORS para frontend
    "dotenv": "^17.2.1",            // Variáveis de ambiente
    "multer": "^2.0.2",             // Upload de arquivos
    "uuid": "^11.1.0"               // Geração de IDs únicos
  }
}
```

### Script de Dev

```bash
npm run dev  # Usa tsx watch (hot reload)
```

---

## 🔄 Fluxo Completo: Da Pergunta à Resposta

### Diagrama de Sequência

```
┌─────────┐         ┌──────────┐         ┌──────────────┐         ┌─────────┐
│Frontend │         │  Express │         │ gemini.ts    │         │ Gemini  │
│ (React) │         │  (Route) │         │ (Service)    │         │   API   │
└────┬────┘         └────┬─────┘         └──────┬───────┘         └────┬────┘
     │                   │                       │                      │
     │ 1. POST           │                       │                      │
     │ /perguntar-gemini │                       │                      │
     │──────────────────>│                       │                      │
     │ { pergunta }      │                       │                      │
     │                   │                       │                      │
     │                   │ 2. askGeminiFromDocs()│                      │
     │                   │──────────────────────>│                      │
     │                   │                       │                      │
     │                   │                       │ 3. Lista docs/       │
     │                   │                       │─┐                    │
     │                   │                       │ │                    │
     │                   │                       │<┘                    │
     │                   │                       │                      │
     │                   │                       │ 4. Para cada arquivo:│
     │                   │                       │    - Calcula hash    │
     │                   │                       │    - Verifica cache  │
     │                   │                       │    - Upload (se novo)│
     │                   │                       │─────────────────────>│
     │                   │                       │                      │
     │                   │                       │<─────────────────────│
     │                   │                       │ file.name, file.uri  │
     │                   │                       │                      │
     │                   │                       │ 5. Monta contents:   │
     │                   │                       │    [prompt, pergunta,│
     │                   │                       │     file1, file2...] │
     │                   │                       │                      │
     │                   │                       │ 6. generateContent() │
     │                   │                       │─────────────────────>│
     │                   │                       │                      │
     │                   │                       │                      │
     │                   │                       │    [IA PROCESSA]     │
     │                   │                       │                      │
     │                   │                       │<─────────────────────│
     │                   │                       │ response.text        │
     │                   │                       │                      │
     │                   │<──────────────────────│                      │
     │                   │ texto da resposta     │                      │
     │                   │                       │                      │
     │<──────────────────│                       │                      │
     │ { texto, threadId}│                       │                      │
     │                   │                       │                      │
```

### Tempo Estimado

1. **Primeira execução** (sem cache):
   - Upload de 3 PDFs: ~10-30 segundos (depende do tamanho)
   - Processamento Gemini: ~2-5 segundos
   - **Total**: ~15-35 segundos

2. **Execuções seguintes** (com cache):
   - Cache hit: 0 segundos (não reenvia)
   - Processamento Gemini: ~2-5 segundos
   - **Total**: ~2-5 segundos ⚡

---

## 💡 Conceitos-Chave

### 1. Cache de Arquivos

**Problema**: Reenviar arquivos grandes é lento e consome quota.  
**Solução**: Hash SHA256 + arquivo `.json` para mapear arquivos já enviados.

**Quando o cache é invalidado?**
- Você modifica o conteúdo do arquivo (hash muda)
- Você deleta `file_cache.json`
- O arquivo expira no Gemini (eles podem deletar após X dias)

### 2. File API vs Embeddings

**Gemini File API** (usado aqui):
- ✅ Você só faz upload
- ✅ Gemini cuida da indexação/busca internamente
- ✅ Mais simples de implementar
- ❌ Menos controle sobre a busca

**Embeddings + Vector Store** (alternativa):
- ✅ Você tem controle total (pode usar pgvector, Pinecone, etc)
- ✅ Busca semântica customizável
- ❌ Mais complexo (precisa gerar embeddings, criar índice, etc)

### 3. System Prompt Engineering

```typescript
const systemPrompt = `
Você é uma Consultora Especialista.
Responda exclusivamente com base nos documentos fornecidos.
...
`;
```

**Por que importante?**
- Instrui o modelo a **não inventar** informações
- Define o **formato** da resposta (markdown, listas, etc)
- Estabelece o **tom** (formal, amigável, técnico)

**Dica**: Teste diferentes prompts para melhorar qualidade!

### 4. Gemini 2.5 Flash vs Pro

| Característica | Flash | Pro |
|----------------|-------|-----|
| **Velocidade** | ⚡ Muito rápido (1-2s) | 🐢 Mais lento (3-5s) |
| **Qualidade** | ⭐⭐⭐ Boa | ⭐⭐⭐⭐⭐ Excelente |
| **Custo** | $ Mais barato | $$ Mais caro |
| **Uso ideal** | Respostas rápidas, FAQs | Análises complexas |

**Recomendação para MVP**: Comece com **Flash**, depois teste Pro se precisar.

---

## 🚨 Problemas Comuns e Soluções

### Erro: `INVALID_ARGUMENT`

```
Error: 400 INVALID_ARGUMENT: Request contains an invalid argument.
```

**Causas**:
1. API key inválida ou expirada
2. Formato do `contents` incorreto
3. Arquivo não foi processado (ainda em `PROCESSING`)

**Solução**:
```typescript
// Sempre aguarde processamento
while (getFile.state === "PROCESSING") {
  await new Promise((r) => setTimeout(r, 2000));
  getFile = await ai.files.get({ name: uploaded.name });
}
```

### Erro: `ValidationError`

```
ValidationError: File must be an object returned from upload
```

**Causa**: Você tentou passar um objeto manualmente construído em vez do retornado pelo upload.

**Solução**:
```typescript
// ✅ CERTO
const uploaded = await ai.files.upload({ file: blob });
parts.push(createPartFromUri(uploaded.uri, uploaded.mimeType));

// ❌ ERRADO
parts.push({ name: "files/abc123" }); // Falta estrutura completa
```

### Erro: `Rate limit exceeded`

```
Error: 429 Resource has been exhausted
```

**Causa**: Ultrapassou limite gratuito (15 req/min para Flash).

**Solução**:
1. Adicionar retry com exponential backoff
2. Implementar fila de requisições
3. Fazer upgrade para tier pago

### Cache não está funcionando

**Sintomas**: Arquivos sendo reenviados sempre.

**Checklist**:
- [ ] `file_cache.json` existe e tem permissão de escrita?
- [ ] Hash está sendo calculado corretamente?
- [ ] Você está modificando o arquivo entre uploads?

---

## 🎯 Adaptando para Seu Projeto Supabase

### Principais Diferenças

| Característica | Backend Node.js | Supabase Edge Function |
|----------------|-----------------|------------------------|
| **Runtime** | Node.js | Deno |
| **File System** | ✅ Acesso direto | ❌ Sem file system |
| **Cache** | Arquivo `.json` | Supabase Database |
| **Documentos** | Pasta `docs/` | Supabase Storage |

### Adaptação 1: Armazenar Documentos

```typescript
// ❌ Backend Node.js
const files = fs.readdirSync('docs/');

// ✅ Supabase Edge Function
const { data: files } = await supabase.storage
  .from('documentos')
  .list();
```

### Adaptação 2: Cache de Arquivos

```typescript
// ❌ Backend Node.js
fs.writeFileSync('file_cache.json', JSON.stringify(cache));

// ✅ Supabase Edge Function
await supabase
  .from('file_cache')
  .upsert({ hash, name, uri, mime_type });
```

### Adaptação 3: Threads/Histórico

```typescript
// ❌ Backend Node.js
fs.writeFileSync('threads.json', JSON.stringify(threads));

// ✅ Supabase Edge Function
// Já está implementado! Tabela 'conversations' + 'messages'
```

---

## 📚 Referências e Recursos

### Documentação Oficial
- [Google Gemini API Docs](https://ai.google.dev/docs)
- [Gemini File API](https://ai.google.dev/docs/file_api)
- [SDK @google/genai](https://github.com/google/generative-ai-js)

### Modelos Disponíveis
- `gemini-2.5-flash` - Rápido e eficiente
- `gemini-2.5-pro` - Máxima qualidade
- `gemini-1.5-flash` - Versão anterior (ainda boa)
- `gemini-1.5-pro` - Versão anterior Pro

### Limites Gratuitos (Free Tier)
- **Gemini Flash**: 15 requisições/minuto
- **Gemini Pro**: 2 requisições/minuto
- **File API**: 20GB storage, 1500 uploads/dia
- **Tamanho máx arquivo**: 2GB

---

## ✅ Checklist de Implementação

Para implementar no seu projeto:

- [ ] Instalar SDK: `npm install @google/genai`
- [ ] Obter API key em https://makersuite.google.com/app/apikey
- [ ] Configurar `.env` com `GEMINI_API_KEY`
- [ ] Criar pasta `docs/` ou usar Supabase Storage
- [ ] Implementar função de upload com cache
- [ ] Implementar função de hash SHA256
- [ ] Criar sistema de cache (arquivo ou banco)
- [ ] Implementar `askGeminiFromDocs()` ou similar
- [ ] Criar rota/Edge Function para perguntas
- [ ] Testar com arquivo pequeno (TXT)
- [ ] Testar com PDF grande
- [ ] Implementar tratamento de erros
- [ ] Adicionar retry logic para rate limits
- [ ] Documentar prompts do sistema
- [ ] Testar qualidade das respostas

---

**Última atualização**: Outubro 2025  
**Baseado em**: `agrosinergia_responde_backend` v1.0.0  
**SDK Gemini**: `@google/genai` v1.13.0
