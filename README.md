# 🤖 Jardulli Bot Buddy

> Assistente de IA inteligente com RAG (Retrieval-Augmented Generation) integrado ao Google Gemini

[![React](https://img.shields.io/badge/React-18.3.1-blue.svg)](https://reactjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.6.2-blue.svg)](https://www.typescriptlang.org/)
[![Supabase](https://img.shields.io/badge/Supabase-Latest-green.svg)](https://supabase.com/)
[![Google Gemini](https://img.shields.io/badge/Gemini-2.0--flash-orange.svg)](https://ai.google.dev/)

## 🎯 O que é?

Um chatbot inteligente que responde perguntas baseadas em documentos da sua empresa usando:
- **Google Gemini AI** para respostas contextualizadas
- **RAG (Retrieval-Augmented Generation)** para consultar base de conhecimento
- **Supabase** para backend, autenticação e storage
- **React + TypeScript** para interface moderna

## ✨ Principais Funcionalidades

- 💬 **Chat em tempo real** com IA
- 📄 **Upload de documentos** (PDF, TXT, MD) para base de conhecimento
- 🧠 **RAG**: IA responde baseada nos seus documentos
- 🔐 **Autenticação** de usuários via Supabase
- 💾 **Histórico** de conversas persistente
- 👍👎 **Feedback** nas respostas
- 🚦 **Rate limiting** (20 mensagens/hora por usuário)
- ⚡ **Cache inteligente** de arquivos (SHA256)
- 🌙 **Tema escuro/claro**

## 🚀 Quick Start

### Primeira vez rodando o projeto?

Siga o guia completo: **[SETUP-INICIAL.md](documentation/SETUP-INICIAL.md)**

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

| Documento | Descrição |
|-----------|-----------|
| **[SETUP-INICIAL.md](documentation/SETUP-INICIAL.md)** | 🚀 Guia completo de instalação (primeira vez) |
| **[QUICK-START.md](QUICK-START.md)** | ⚡ Comandos rápidos e checklist |
| **[DEPLOY-MVP.md](documentation/DEPLOY-MVP.md)** | 🌐 Deploy em produção passo a passo |
| **[GUIA-TESTES.md](documentation/GUIA-TESTES.md)** | 🧪 Testes completos (5 fases) |
| **[MVP-TODO.md](documentation/MVP-TODO.md)** | 📋 Roadmap do projeto (4 sprints) |
| **[FUNCIONALIDADES.md](documentation/FUNCIONALIDADES.md)** | 📖 Detalhes de todas as funcionalidades |
| **[GUIA-IMPLEMENTACAO.md](documentation/GUIA-IMPLEMENTACAO.md)** | 💻 Guia técnico de implementação |

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
  - File API (RAG)
  - @google/generative-ai SDK v1.13.0

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
# Deploy Edge Functions
supabase functions deploy ai-chat
supabase functions deploy upload-document

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
- **Gemini Pay-as-you-go**: ~$5-10/mês
- **Total**: ~$30-35/mês

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
