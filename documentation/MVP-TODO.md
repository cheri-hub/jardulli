# MVP ToDo List - Jardulli Bot Buddy

## 🎯 Objetivo do MVP
Criar uma versão funcional do assistente de IA que possa responder perguntas sobre produtos e serviços da Jardulli Máquinas usando uma base de conhecimento real.

---

## 🔴 CRÍTICO - Essencial para MVP

### 1. Integração com IA/LLM
**Prioridade**: ALTA | **Estimativa**: 8-16h | **LLM Escolhido**: ✅ **Google Gemini**

- [x] Escolher provedor de LLM: **Google Gemini**
- [ ] Obter API key do Google AI Studio (https://makersuite.google.com/app/apikey)
- [ ] Configurar API key no Supabase (variável de ambiente segura: `GEMINI_API_KEY`)
- [ ] Implementar chamada ao Gemini API em Edge Function
- [ ] Substituir resposta simulada por resposta real
- [ ] Adicionar tratamento de erros da API
- [ ] Implementar retry logic para falhas temporárias
- [ ] Configurar rate limiting para evitar abuso

**Arquivos a modificar**:
- `src/pages/Index.tsx` - remover setTimeout simulado
- Criar: `supabase/functions/chat-completion/index.ts`

**Exemplo de implementação com Google Gemini**:
```typescript
// supabase/functions/chat-completion/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')
const GEMINI_MODEL = 'gemini-1.5-flash' // Ou 'gemini-1.5-pro' para melhor qualidade

serve(async (req) => {
  const { message, conversationHistory } = await req.json()
  
  // Formatar histórico para Gemini
  const contents = [
    {
      role: 'user',
      parts: [{ text: 'Você é um assistente virtual da Jardulli Máquinas, especializado em café e máquinas de café. Seja prestativo, profissional e direto nas respostas.' }]
    },
    {
      role: 'model',
      parts: [{ text: 'Entendido! Estou pronto para ajudar com informações sobre a Jardulli Máquinas.' }]
    },
    ...conversationHistory.map(msg => ({
      role: msg.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: msg.content }]
    })),
    {
      role: 'user',
      parts: [{ text: message }]
    }
  ]
  
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents,
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        },
        safetySettings: [
          { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
          { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
          { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
          { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE" }
        ]
      })
    }
  )
  
  const data = await response.json()
  
  if (!response.ok) {
    throw new Error(data.error?.message || 'Erro ao chamar Gemini API')
  }
  
  const reply = data.candidates[0]?.content?.parts[0]?.text || 'Desculpe, não consegui gerar uma resposta.'
  
  return new Response(JSON.stringify({ reply }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

**Vantagens do Google Gemini**:
- ✅ Excelente custo-benefício (gratuito até 15 req/min)
- ✅ Suporte nativo a multimodal (texto + imagens futuras)
- ✅ Latência baixa
- ✅ Modelos: Gemini 1.5 Flash (rápido) e Pro (mais capaz)

---

### 2. Base de Conhecimento
**Prioridade**: ALTA | **Estimativa**: 12-24h

#### 2.1 Coleta de Conteúdo
- [ ] Reunir documentação de produtos da Jardulli
- [ ] Coletar manuais técnicos
- [ ] Compilar FAQs existentes
- [ ] Documentar especificações de máquinas
- [ ] Incluir informações de contato e suporte
- [ ] Adicionar políticas de garantia e assistência

#### 2.2 Estruturação da Base
- [ ] Criar tabela `knowledge_base` no Supabase
- [ ] Definir schema para documentos
- [ ] Implementar chunking de documentos grandes
- [ ] Adicionar metadata (categoria, produto, data)

**Schema sugerido**:
```sql
CREATE TABLE knowledge_base (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT, -- 'produto', 'servico', 'suporte', 'faq'
  product_name TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### 2.3 Vetorização (RAG - Retrieval Augmented Generation)
- [ ] Instalar extensão pgvector no Supabase
- [ ] Criar coluna de embeddings na tabela
- [ ] Implementar função de geração de embeddings
- [ ] Criar índice vetorial para busca eficiente
- [ ] Implementar busca semântica

**Implementação com Gemini Embeddings**:
```sql
-- Habilitar extensão
CREATE EXTENSION IF NOT EXISTS vector;

-- Adicionar coluna de embeddings
ALTER TABLE knowledge_base 
ADD COLUMN embedding VECTOR(768); -- Gemini text-embedding-004 usa 768 dimensões

-- Criar índice
CREATE INDEX ON knowledge_base 
USING ivfflat (embedding vector_cosine_ops);

-- Função de busca
CREATE FUNCTION search_knowledge(
  query_embedding VECTOR(768),
  match_threshold FLOAT,
  match_count INT
)
RETURNS TABLE (
  id UUID,
  content TEXT,
  similarity FLOAT
)
LANGUAGE SQL STABLE
AS $$
  SELECT id, content,
    1 - (embedding <=> query_embedding) AS similarity
  FROM knowledge_base
  WHERE 1 - (embedding <=> query_embedding) > match_threshold
  ORDER BY similarity DESC
  LIMIT match_count;
$$;
```

**Edge Function para gerar embeddings com Gemini**:
```typescript
// supabase/functions/generate-embeddings/index.ts
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')

async function generateEmbedding(text: string) {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: "models/text-embedding-004",
        content: { parts: [{ text }] }
      })
    }
  )
  
  const data = await response.json()
  return data.embedding.values // Array de 768 dimensões
}
```

#### 2.4 Pipeline de Ingestão
- [ ] Criar Edge Function para processar novos documentos
- [ ] Implementar chunking automático
- [ ] Gerar embeddings para cada chunk
- [ ] Salvar no banco de dados

---

### 3. Fluxo RAG Completo
**Prioridade**: ALTA | **Estimativa**: 8-12h

- [ ] Implementar busca semântica na pergunta do usuário
- [ ] Recuperar top 3-5 chunks mais relevantes
- [ ] Montar contexto para o LLM
- [ ] Enviar contexto + pergunta para LLM
- [ ] Processar e retornar resposta
- [ ] Adicionar citações/fontes na resposta

**Edge Function integrada com Gemini**:
```typescript
// supabase/functions/ai-chat/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_KEY!)

async function generateEmbedding(text: string) {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: "models/text-embedding-004",
        content: { parts: [{ text }] }
      })
    }
  )
  const data = await response.json()
  return data.embedding.values
}

serve(async (req) => {
  const { message, conversationId } = await req.json()
  
  // 1. Gerar embedding da pergunta
  const embedding = await generateEmbedding(message)
  
  // 2. Buscar contexto relevante na base de conhecimento
  const { data: results } = await supabase.rpc('search_knowledge', {
    query_embedding: embedding,
    match_threshold: 0.7,
    match_count: 5
  })
  
  // 3. Montar contexto
  const context = results?.map(r => r.content).join('\n\n---\n\n') || ''
  
  // 4. Buscar histórico da conversa
  const { data: messages } = await supabase
    .from('messages')
    .select('role, content')
    .eq('conversation_id', conversationId)
    .order('created_at', { ascending: true })
    .limit(10)
  
  // 5. Montar prompt com contexto
  const systemPrompt = `Você é o assistente virtual da Jardulli Máquinas, especializado em café e equipamentos.

BASE DE CONHECIMENTO:
${context}

INSTRUÇÕES:
- Use APENAS as informações da base de conhecimento acima
- Se não souber a resposta, diga claramente e sugira contato: (19) 98212-1616
- Seja profissional, prestativo e objetivo
- Responda em português brasileiro`

  // 6. Chamar Gemini
  const contents = [
    { role: 'user', parts: [{ text: systemPrompt }] },
    { role: 'model', parts: [{ text: 'Entendido! Vou usar apenas a base de conhecimento fornecida.' }] },
    ...messages.map(msg => ({
      role: msg.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: msg.content }]
    })),
    { role: 'user', parts: [{ text: message }] }
  ]
  
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents,
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        }
      })
    }
  )
  
  const data = await response.json()
  const reply = data.candidates[0]?.content?.parts[0]?.text || 
    'Desculpe, não consegui processar sua pergunta. Tente novamente.'
  
  return new Response(JSON.stringify({ 
    reply,
    sources: results?.length || 0 
  }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

---

### 4. Interface de Usuário - Melhorias Críticas
**Prioridade**: MÉDIA | **Estimativa**: 4-6h

- [ ] Adicionar indicador de "IA está pensando..."
- [ ] Mostrar fontes/referências usadas na resposta
- [ ] Implementar streaming de resposta (texto aparecendo progressivamente)
- [ ] Adicionar botão "Parar geração" durante streaming
- [ ] Melhorar feedback visual de erros
- [ ] Adicionar mensagem de boas-vindas explicativa

**Exemplo de mensagem inicial**:
```
👋 Olá! Sou o assistente virtual da Jardulli Máquinas.

Posso ajudá-lo com:
• Informações sobre nossos produtos
• Especificações técnicas
• Suporte e manutenção
• Perguntas frequentes
• Contato e localização

Como posso ajudar você hoje?
```

---

### 5. Tratamento de Erros
**Prioridade**: ALTA | **Estimativa**: 3-4h

- [ ] Implementar fallback quando IA não sabe responder
- [ ] Adicionar timeout para requisições longas (30s)
- [ ] Tratar erros de API (rate limit, quota, etc)
- [ ] Mostrar mensagem amigável ao usuário
- [ ] Log de erros para análise posterior
- [ ] Implementar retry automático (1-2 tentativas)

**Mensagens de fallback**:
```typescript
const FALLBACK_MESSAGES = {
  noContext: "Desculpe, não encontrei informações específicas sobre isso. Posso te direcionar para nosso suporte: (19) 98212-1616",
  apiError: "Ops! Tive um problema temporário. Por favor, tente novamente.",
  timeout: "A resposta está demorando mais que o esperado. Tente reformular sua pergunta.",
}
```

---

## 🟡 IMPORTANTE - Recomendado para MVP

### 6. Histórico de Conversas
**Prioridade**: MÉDIA | **Estimativa**: 4-6h

- [ ] Implementar contexto de conversa (últimas 5-10 mensagens)
- [ ] Enviar histórico para LLM para respostas contextualizadas
- [ ] Limitar tokens do histórico (max 4000 tokens)
- [ ] Adicionar botão "Limpar contexto" se conversa ficar confusa

---

### 7. Melhorias no Feedback
**Prioridade**: MÉDIA | **Estimativa**: 2-3h

- [ ] Adicionar campo "Por que este feedback?" (dropdown)
  - Resposta incorreta
  - Informação desatualizada
  - Não entendeu a pergunta
  - Resposta incompleta
  - Outro
- [ ] Salvar feedback para treinar/melhorar sistema
- [ ] Dashboard admin para revisar feedbacks (futuro)

---

### 8. Validação e Segurança
**Prioridade**: ALTA | **Estimativa**: 3-4h

- [ ] Implementar rate limiting por usuário (ex: 20 msgs/hora)
- [ ] Adicionar validação de tamanho da mensagem (max 1000 chars)
- [ ] Sanitizar inputs para evitar prompt injection
- [ ] Implementar moderação de conteúdo (palavrões, spam)
- [ ] Adicionar CAPTCHA ou similar se necessário

**Implementação de rate limiting**:
```sql
-- Tabela para rate limiting
CREATE TABLE user_rate_limit (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  message_count INT DEFAULT 0,
  window_start TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT check_limit CHECK (message_count <= 20)
);

-- Função para verificar limite
CREATE FUNCTION check_rate_limit(uid UUID)
RETURNS BOOLEAN AS $$
DECLARE
  current_count INT;
  window_start TIMESTAMPTZ;
BEGIN
  SELECT message_count, window_start 
  INTO current_count, window_start
  FROM user_rate_limit WHERE user_id = uid;
  
  -- Reset se passou 1 hora
  IF window_start < NOW() - INTERVAL '1 hour' THEN
    UPDATE user_rate_limit 
    SET message_count = 1, window_start = NOW()
    WHERE user_id = uid;
    RETURN TRUE;
  END IF;
  
  -- Incrementar contador
  IF current_count < 20 THEN
    UPDATE user_rate_limit 
    SET message_count = message_count + 1
    WHERE user_id = uid;
    RETURN TRUE;
  END IF;
  
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
```

---

### 9. Testes Básicos
**Prioridade**: MÉDIA | **Estimativa**: 6-8h

- [ ] Criar conjunto de perguntas de teste
- [ ] Testar com diferentes usuários
- [ ] Validar qualidade das respostas
- [ ] Testar edge cases (mensagens muito longas, caracteres especiais)
- [ ] Testar fluxo de feedback
- [ ] Testar compartilhamento

**Perguntas de teste sugeridas**:
```
1. "Quais máquinas vocês têm para café?"
2. "Qual a garantia dos produtos?"
3. "Como entrar em contato?"
4. "Preço da máquina X"
5. "Vocês fazem manutenção?"
6. "Horário de atendimento"
7. "Onde fica a loja?"
8. [pergunta fora do contexto] "Qual a capital da França?"
```

---

### 10. Otimizações de Performance
**Prioridade**: BAIXA | **Estimativa**: 3-4h

- [ ] Implementar cache de respostas frequentes
- [ ] Otimizar queries do banco de dados
- [ ] Adicionar índices necessários
- [ ] Implementar lazy loading de conversas antigas
- [ ] Comprimir payloads da API

---

## 🟢 NICE TO HAVE - Melhorias Futuras

### 11. Analytics Básico
**Prioridade**: BAIXA | **Estimativa**: 4-6h

- [ ] Criar tabela `analytics_events`
- [ ] Rastrear perguntas mais frequentes
- [ ] Medir tempo médio de resposta
- [ ] Calcular taxa de satisfação (feedbacks positivos/negativos)
- [ ] Dashboard simples de métricas

---

### 12. Recursos Adicionais
**Prioridade**: BAIXA | **Estimativa**: Variável

- [ ] Sugestões de perguntas relacionadas
- [ ] Botões de ação rápida (ex: "Falar com humano")
- [ ] Exportar conversa como PDF
- [ ] Busca em conversas antigas
- [ ] Notificações de novas funcionalidades
- [ ] Tutorial de primeiro uso

---

## 📋 Checklist de Deploy do MVP

### Pré-Deploy
- [ ] Obter API key do Google AI Studio (https://makersuite.google.com/app/apikey)
- [ ] Configurar variáveis de ambiente no Supabase:
  - `GEMINI_API_KEY`
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`
- [ ] Base de conhecimento populada e vetorizada
- [ ] Testes de integração passando
- [ ] Rate limiting configurado
- [ ] Tratamento de erros implementado

### Deploy
- [ ] Fazer backup do banco de dados
- [ ] Executar migrations no Supabase
- [ ] Deploy das Edge Functions
- [ ] Deploy do frontend (Lovable/Vercel/Netlify)
- [ ] Configurar domínio customizado (se aplicável)
- [ ] Configurar SSL/HTTPS

### Pós-Deploy
- [ ] Testar fluxo completo em produção
- [ ] Verificar logs de erro
- [ ] Monitorar uso de API (custos)
- [ ] Testar com usuários beta (2-3 pessoas)
- [ ] Coletar feedback inicial
- [ ] Ajustar prompts se necessário

---

## 💰 Estimativa de Custos (Mensal)

### Google Gemini API ✅
**Tier Gratuito (Free tier)**:
- **Gemini 1.5 Flash**: 15 requisições/minuto GRATUITO
- **Gemini 1.5 Pro**: 2 requisições/minuto GRATUITO
- **Text Embeddings**: 1500 requisições/dia GRATUITO
- Perfeito para MVP e pequena escala!

**Tier Pago** (se necessário expansão):
- **Gemini 1.5 Flash**: 
  - Input: $0.075 / 1M tokens
  - Output: $0.30 / 1M tokens
- **Gemini 1.5 Pro**:
  - Input: $1.25 / 1M tokens
  - Output: $5.00 / 1M tokens
- **Text Embeddings**: $0.00001 / 1K tokens

**Estimativa para 1000 conversas/mês**:
- **Tier Gratuito**: $0 (dentro dos limites!)
- **Se pago (Flash)**: ~$2-5/mês
- **Se pago (Pro)**: ~$10-20/mês

### Supabase
- **Free tier**: Suficiente para MVP (500MB database, 2GB bandwidth)
- **Pro** ($25/mês): Recomendado após 100+ usuários ativos

### Total Estimado
- **MVP inicial**: **$0/mês** 🎉 (usando tier gratuito Gemini + Supabase Free)
- **Pequena escala** (até ~500 usuários): $0-10/mês
- **Produção** (após crescimento): $25-50/mês (Supabase Pro + Gemini pago)

**Vantagem do Gemini**: Começar completamente GRATUITO!

---

## 🎯 Ordem de Implementação Sugerida

### Sprint 1 (Semana 1) - Fundação
1. Coletar e estruturar base de conhecimento
2. Criar schema de banco de dados
3. Configurar pgvector

### Sprint 2 (Semana 2) - IA Core
4. Implementar Edge Function de IA
5. Integrar com LLM escolhido
6. Implementar vetorização e RAG

### Sprint 3 (Semana 3) - Refinamentos
7. Melhorar UI/UX
8. Implementar tratamento de erros
9. Adicionar rate limiting

### Sprint 4 (Semana 4) - Testes e Deploy
10. Testes completos
11. Ajustes de prompts
12. Deploy para produção
13. Coleta de feedback

---

## 📝 Documentação Adicional Necessária

- [ ] README atualizado com setup completo
- [ ] Guia de contribuição
- [ ] Documentação de API das Edge Functions
- [ ] Guia de troubleshooting
- [ ] Processo de atualização da base de conhecimento
- [ ] Manual do administrador

---

## 🚨 Riscos e Mitigações

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| Custo de API muito alto | Alto | Média | Implementar cache, usar GPT-3.5, rate limiting |
| Respostas de baixa qualidade | Alto | Média | Melhorar prompts, aumentar base de conhecimento |
| Performance lenta | Médio | Baixa | Otimizar queries, adicionar índices, cache |
| Abuso do sistema | Médio | Média | Rate limiting, captcha, moderação |
| Base de conhecimento desatualizada | Médio | Alta | Processo de atualização periódica |

---

## 📞 Próximos Passos Imediatos

1. ✅ **Provedor de LLM definido**: **Google Gemini** (custo zero para começar!)
2. **Obter API key**: Acessar https://makersuite.google.com/app/apikey
3. **Reunir equipe da Jardulli** para coletar conteúdo da base de conhecimento
4. **Criar primeira versão da base de conhecimento** (mesmo que pequena - 10-20 documentos)
5. **Implementar integração básica** com Gemini API
6. **Testar primeira pergunta e resposta** real
7. **Vetorizar base de conhecimento** usando Gemini Embeddings

---

**Última atualização**: Outubro 2025  
**Status**: Planejamento  
**Responsável**: [Definir]  
**Prazo MVP**: [Definir - sugestão: 3-4 semanas]
