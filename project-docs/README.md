# 🤖 Jardulli Bot Buddy

> Assistente de IA inteligente com RAG (Retrieval-Augmented Generation) integrado ao Google Gemini

[![React](https://img.shields.io/badge/React-18.3.1-blue.svg)](https://reactjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.6.2-blue.svg)](https://www.typescriptlang.org/)
[![Supabase](https://img.shields.io/badge/Supabase-Latest-green.svg)](https://supabase.com/)
[![Google Gemini](https://img.shields.io/badge/Gemini-2.0--flash-orange.svg)](https://ai.google.dev/)

## 🎯 O que é?

Um chatbot inteligente que responde perguntas baseadas em documentos da sua empresa usando:
- **Google Gemini AI** para respostas contextualizadas
- **Gemini File API** para processamento otimizado de documentos (90% economia de tokens)
- **RAG (Retrieval-Augmented Generation)** avançado sem limitações de tamanho
- **Supabase** para backend, autenticação e storage
- **React + TypeScript** para interface moderna

## ✨ Principais Funcionalidades

- 💬 **Chat em tempo real** com IA
- 📄 **Upload de documentos** via **Gemini File API** (sem limite de tamanho)
- 🧠 **RAG Avançado**: IA responde com **file references** diretas no Gemini
- 🔐 **Autenticação** de usuários via Supabase
- 💾 **Histórico** de conversas persistente
- 👍👎 **Feedback** nas respostas
- 🚦 **Rate limiting** (20 mensagens/hora por usuário)
- ⚡ **Cache inteligente** SHA256 + Gemini File API
- 🌙 **Tema escuro/claro**
- 🚀 **90% economia de tokens** comparado ao sistema anterior

## 🚀 Quick Start

### Primeira vez rodando o projeto?

Siga o guia completo: **[📋 DOCUMENTAÇÃO COMPLETA](DOCUMENTACAO-COMPLETA.md)**

**Resumo rápido:**

```powershell
# 1. Clonar e instalar
git clone https://github.com/rpmarciano/jardulli-bot-buddy.git
cd jardulli-bot-buddy
npm install

# 2. Configurar Supabase CLI
scoop install supabase
supabase login
supabase link --project-ref SEU_PROJECT_ID

# 3. Aplicar migrations
supabase db push

# 4. Deploy Edge Functions
supabase functions deploy ai-chat
supabase functions deploy upload-document

# 5. Configurar .env (veja exemplo abaixo)
cp .env.example .env

# 6. Rodar localmente
npm run dev
```

### Configurar arquivo .env

```env
VITE_SUPABASE_PROJECT_ID="seu-project-id"
VITE_SUPABASE_URL="https://seu-project-id.supabase.co"
VITE_SUPABASE_PUBLISHABLE_KEY="sua-anon-key"
SUPABASE_ACCESS_TOKEN="sbp_seu-token"
```

### Configurar Secrets no Supabase

1. Acesse: Dashboard > Project Settings > Edge Functions > Secrets
2. Adicione:
   - `GEMINI_API_KEY`: Sua chave do Google AI Studio
   - `GEMINI_MODEL`: `gemini-2.0-flash-exp`

## 📚 Documentação

### 📖 **Documentação Principal**
**[📋 DOCUMENTAÇÃO COMPLETA](DOCUMENTACAO-COMPLETA.md)** - Guia completo do projeto com tudo que você precisa:

- 🚀 **Setup inicial** completo (zero to hero)
- 🏗️ **Arquitetura** detalhada do sistema
- 🌐 **Deploy e produção** (Vercel, Apache, IIS)
- 📄 **Gerenciamento de documentos** e File API
- 🔧 **Manutenção e monitoramento**
- 🐛 **Troubleshooting** completo
- 📊 **Métricas e performance**

### 🔧 **Documentos Específicos**
| Documento | Descrição |
|-----------|-----------|
| **[COMO-ATUALIZAR-BASE-CONHECIMENTO.md](COMO-ATUALIZAR-BASE-CONHECIMENTO.md)** | � Como adicionar/atualizar documentos |

## 🏗️ Arquitetura

```
┌─────────────┐
│   Frontend  │  React + TypeScript + Vite
│  (Lovable)  │  shadcn/ui + Tailwind CSS
└──────┬──────┘
       │
       ↓ (Supabase Client)
┌──────────────────────────────────────────┐
│           Supabase Backend               │
├──────────────┬───────────────┬───────────┤
│  Auth        │  Database     │  Storage  │
│  (RLS)       │  (PostgreSQL) │  (Files)  │
└──────────────┴───────────────┴───────────┘
       │
       ↓ (Edge Functions - Deno)
┌──────────────────────────────────────────┐
│         Edge Functions (Serverless)       │
├──────────────┬───────────────────────────┤
│  ai-chat     │  upload-document          │
│  (RAG+Chat)  │  (File Cache)             │
└──────┬───────┴────────┬──────────────────┘
       │                │
       ↓                ↓
┌──────────────┐  ┌─────────────┐
│ Google Gemini│  │   Gemini    │
│   Chat API   │  │   File API  │
└──────────────┘  └─────────────┘
```

## 🛠️ Stack Tecnológica

### Frontend
- **React** 18.3.1 - UI Library
- **TypeScript** 5.6.2 - Type Safety
- **Vite** 5.4.19 - Build Tool
- **shadcn/ui** - Component Library
- **Tailwind CSS** - Styling
- **React Router** v6.30.1 - Routing
- **TanStack Query** - Data Fetching

### Backend
- **Supabase** - BaaS Platform
  - Auth (JWT + RLS)
  - PostgreSQL Database
  - Realtime Subscriptions
  - Edge Functions (Deno)
  - Storage (S3-compatible)
- **Google Gemini** - LLM API
  - gemini-2.0-flash-exp
  - **File API** (RAG otimizado) ✅ **IMPLEMENTADO**
  - @google/generative-ai SDK v0.21.0
  - Multipart upload via HTTP API direta

## 📊 Estrutura do Banco de Dados

### Tabelas Principais

```sql
-- Perfis de usuários
profiles (id, email, full_name, avatar_url, created_at)

-- Conversas
conversations (id, user_id, title, created_at, updated_at)

-- Mensagens
messages (id, conversation_id, user_id, content, role, sources_count, created_at)

-- Feedback
message_feedback (id, message_id, user_id, feedback_type, created_at)

-- Cache de arquivos Gemini
gemini_file_cache (id, file_name, sha256_hash, gemini_name, gemini_uri, mime_type, created_at)

-- Rate limiting
user_rate_limit (id, user_id, message_count, last_reset, created_at)
```

## 🔒 Segurança

- ✅ **RLS (Row Level Security)** em todas as tabelas
- ✅ **JWT Authentication** via Supabase Auth
- ✅ **API Keys** nunca expostas no frontend
- ✅ **Service Role** apenas nas Edge Functions
- ✅ **Rate Limiting** (20 mensagens/hora)
- ✅ **CORS** configurado
- ✅ **HTTPS** obrigatório

## 📈 Performance

- ⚡ **Cache de arquivos** (SHA256) - evita re-uploads
- ⚡ **Realtime subscriptions** - atualizações instantâneas
- ⚡ **Lazy loading** de componentes
- ⚡ **Optimistic updates** no frontend
- ⚡ **Connection pooling** no PostgreSQL
- ⚡ **CDN** para assets estáticos (Lovable)

## 🧪 Testes

```powershell
# Rodar localmente
npm run dev

# Build para produção
npm run build

# Preview do build
npm run preview

# Testes Edge Functions
supabase functions logs ai-chat --tail
```

## 📝 Scripts Disponíveis

```json
{
  "dev": "vite",
  "build": "tsc && vite build",
  "preview": "vite preview",
  "lint": "eslint .",
  "db:push": "supabase db push",
  "functions:deploy": "supabase functions deploy"
}
```

## 🌐 Deploy

### Frontend (Lovable)

Automatic deployment on git push to main branch.

**URL**: https://lovable.dev/projects/ca8c2aaa-2c45-430c-b4f2-f067214bd038

### Backend (Supabase)

```powershell
# Deploy Edge Functions (File API)
supabase functions deploy ai-chat                # ✅ Atualizada para File API
supabase functions deploy upload-gemini-files    # ✅ Nova - Upload File API

# Aplicar migrations
supabase db push
```

Guia completo: **[DEPLOY-MVP.md](documentation/DEPLOY-MVP.md)**

## 💰 Custos

### Tier Gratuito (início)
- **Supabase Free**: 500MB DB, 1GB bandwidth, 2GB storage
- **Gemini Free**: 15 req/min, 20GB file storage
- **Lovable**: Deploy automático
- **Total**: $0/mês 🎉

### Produção (100+ usuários)
- **Supabase Pro**: $25/mês
- **Gemini Pay-as-you-go**: ~$2-5/mês (90% economia com File API)
- **Total**: ~$27-30/mês (redução significativa)

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/nova-funcionalidade`
3. Commit: `git commit -m 'Add: nova funcionalidade'`
4. Push: `git push origin feature/nova-funcionalidade`
5. Abra um Pull Request

## 📄 Licença

Este projeto é privado. Todos os direitos reservados.

## 🆘 Suporte

Problemas ou dúvidas?

1. Consulte a [Documentação](documentation/)
2. Verifique os [Logs](https://supabase.com/dashboard)
3. Abra uma [Issue](https://github.com/rpmarciano/jardulli-bot-buddy/issues)

## 🎯 Roadmap

- [x] Sprint 1: Infraestrutura (Migrations + Tables)
- [x] Sprint 2: Edge Functions (RAG + Upload)
- [x] Sprint 3: Frontend Integration
- [ ] Sprint 4: Testes e Ajustes
- [ ] v1.1: Streaming de respostas
- [ ] v1.2: Sugestões de perguntas
- [ ] v1.3: Multi-idioma
- [ ] v2.0: WhatsApp Integration

## 👥 Autores

- **Rafael Marciano** - [@rpmarciano](https://github.com/rpmarciano)

## 🙏 Agradecimentos

- [Lovable.dev](https://lovable.dev) - Frontend platform
- [Supabase](https://supabase.com) - Backend platform
- [Google AI](https://ai.google.dev) - Gemini API
- [shadcn/ui](https://ui.shadcn.com) - Component library

---

**Data de criação**: Outubro 2025  
**Última atualização**: Outubro 2025  
**Versão**: 1.0.0

---

Made with ❤️ and ☕ by Jardulli Team
- Edit files directly within the Codespace and commit and push your changes once you're done.

## What technologies are used for this project?

This project is built with:

- Vite
- TypeScript
- React
- shadcn-ui
- Tailwind CSS

## How can I deploy this project?

Simply open [Lovable](https://lovable.dev/projects/ca8c2aaa-2c45-430c-b4f2-f067214bd038) and click on Share -> Publish.

## Can I connect a custom domain to my Lovable project?

Yes, you can!

To connect a domain, navigate to Project > Settings > Domains and click Connect Domain.

Read more here: [Setting up a custom domain](https://docs.lovable.dev/features/custom-domain#custom-domain)
