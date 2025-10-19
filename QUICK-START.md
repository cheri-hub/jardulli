# 🚀 Quick Start - Jardulli Bot Buddy

## ✅ Supabase CLI Instalado!

Versão: `2.51.0`

---

## 📝 Próximos Passos Rápidos

### 1. Login no Supabase

```powershell
supabase login
```

Isso abrirá o navegador para autenticação.

### 2. Inicializar projeto local (opcional - para testes locais)

```powershell
# Iniciar containers Docker locais
supabase start
```

⚠️ **Requer Docker Desktop instalado**

### 3. Linkar com projeto remoto (produção)

```powershell
# Listar seus projetos
supabase projects list

# Linkar (substitua PROJECT_ID)
supabase link --project-ref YOUR_PROJECT_ID
```

### 4. Aplicar migrations

```powershell
# Ver o que será aplicado
supabase db diff

# Aplicar no projeto remoto
supabase db push
```

### 5. Deploy das Edge Functions

```powershell
# Deploy ai-chat
supabase functions deploy ai-chat

# Deploy upload-document
supabase functions deploy upload-document

# Verificar deploy
supabase functions list
```

---

## 🧪 Testando Localmente (Opcional)

Se você tem Docker instalado:

```powershell
# 1. Iniciar Supabase local
supabase start

# 2. Criar .env.local
New-Item -ItemType File -Path "supabase\.env.local" -Force
notepad supabase\.env.local
```

Adicione ao `.env.local`:
```env
GEMINI_API_KEY=sua-chave-aqui
GEMINI_MODEL=gemini-2.0-flash-exp
```

```powershell
# 3. Iniciar Edge Functions localmente
supabase functions serve
```

Acesse: `http://localhost:54323` (Supabase Studio local)

---

## 📦 Se não tem Docker

Sem problemas! Você pode:

1. **Deploy direto em produção** (mais simples)
2. **Testar via Dashboard Supabase**
3. **Usar Postman/Insomnia** para testar APIs

---

## 🔑 Variáveis de Ambiente no Supabase

1. Acesse seu projeto no [Supabase Dashboard](https://supabase.com/dashboard)
2. Vá em **Project Settings** > **Edge Functions**
3. Adicione em **Secrets**:
   ```
   GEMINI_API_KEY=AIza...sua-chave
   GEMINI_MODEL=gemini-2.0-flash-exp
   ```

---

## 📚 Documentação Completa

- **DEPLOY-MVP.md**: Guia completo de deploy passo a passo
- **GUIA-TESTES.md**: Todos os cenários de teste detalhados
- **MVP-TODO.md**: Roadmap completo do projeto

---

## 🆘 Problemas Comuns

### Docker não instalado

Se `supabase start` falhar:

```
Error: Docker is not running
```

**Solução**: Instale [Docker Desktop](https://www.docker.com/products/docker-desktop/) ou pule testes locais e vá direto para produção.

### Não tem projeto Supabase

1. Acesse [supabase.com](https://supabase.com)
2. Crie conta (grátis)
3. Clique em **New Project**
4. Preencha:
   - Name: `jardulli-bot-buddy`
   - Database Password: (crie uma senha forte)
   - Region: `South America (São Paulo)`
5. Aguarde ~2 minutos para provisionar

### API Key do Gemini

1. Acesse [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Faça login com conta Google
3. Clique em **Get API Key**
4. Copie a chave (começa com `AIza...`)

---

## ✅ Checklist Rápido

- [x] Supabase CLI instalado
- [ ] Login no Supabase feito
- [ ] Projeto Supabase criado
- [ ] Projeto linkado localmente
- [ ] API Key do Gemini obtida
- [ ] Migrations aplicadas
- [ ] Edge Functions deployadas
- [ ] Variáveis configuradas
- [ ] Bucket Storage criado
- [ ] Primeiro teste realizado

---

**Próximo comando sugerido:**

```powershell
supabase login
```

Boa sorte! 🚀
