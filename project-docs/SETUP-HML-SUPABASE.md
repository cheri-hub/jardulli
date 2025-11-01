# 🏗️ Setup do Ambiente HML - Projeto Supabase Separado

## 🎯 Objetivo
Criar um ambiente de homologação completo com projeto Supabase dedicado para testar o sistema de tracking de custos com segurança.

---

## 📋 Passo a Passo

### 1. 🆕 Criar Novo Projeto Supabase

#### No Dashboard Supabase:
1. Acesse [supabase.com/dashboard](https://supabase.com/dashboard)
2. Clique em **"New Project"**
3. **Nome**: `jardulli-hml` ou `jardulli-homologacao`
4. **Organization**: Sua organização atual
5. **Database Password**: Anote a senha gerada
6. **Region**: Escolha a mesma região da produção
7. Clique **"Create new project"**

⏳ Aguarde ~2 minutos para o projeto ser criado.

### 2. 📝 Coletar Informações do Novo Projeto

Após criação, vá em **Settings > API**:

```bash
# Anote estas informações:
HML_PROJECT_URL=https://SEU-PROJETO-HML.supabase.co
HML_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
HML_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3. 🗂️ Aplicar Migrations Existentes

#### Opção A: Via Supabase CLI (Recomendada)
```powershell
# Instalar Supabase CLI se não tiver
npm install -g supabase

# Conectar ao projeto HML
supabase login
supabase link --project-ref SEU-PROJETO-HML-ID

# Aplicar todas as migrations
cd backend/supabase
supabase db push
```

#### Opção B: Via SQL Editor Manual
Executar no **SQL Editor** do dashboard HML, **nesta ordem**:

1. `20251005150233_15709953-45e7-4ba4-9c4d-60067fd1aebc.sql`
2. `20251017164054_create_gemini_infrastructure.sql` 
3. `20251018174500_create_storage_bucket.sql`
4. `20241022120000_add_gemini_file_api_fields.sql`
5. `20251031100000_create_gemini_usage_metrics.sql` ⭐ **NOVA**

### 4. 🔧 Deploy Edge Functions para HML

```powershell
# Deploy todas as Edge Functions para HML
cd backend/supabase

# Deploy ai-chat (com novo logging de custos)
supabase functions deploy ai-chat --project-ref SEU-PROJETO-HML-ID

# Deploy outras functions
supabase functions deploy send-whatsapp-feedback --project-ref SEU-PROJETO-HML-ID
supabase functions deploy upload-gemini-files --project-ref SEU-PROJETO-HML-ID
```

### 5. ⚙️ Configurar Variáveis de Ambiente HML

#### No Dashboard Supabase HML:
**Settings > Edge Functions > Environment Variables**

Adicionar:
```bash
GEMINI_API_KEY=sua_gemini_api_key_aqui
GEMINI_MODEL=gemini-2.0-flash-exp
SUPABASE_URL=https://SEU-PROJETO-HML.supabase.co
SUPABASE_SERVICE_ROLE_KEY=sua_service_role_key_hml
```

### 6. 📁 Criar Configuração Local HML

#### Criar arquivo `.env.hml`:
```bash
# Frontend HML Configuration
VITE_SUPABASE_URL=https://SEU-PROJETO-HML.supabase.co
VITE_SUPABASE_ANON_KEY=sua_anon_key_hml

# Para testes locais apontando para HML
SUPABASE_URL=https://SEU-PROJETO-HML.supabase.co
SUPABASE_ANON_KEY=sua_anon_key_hml
SUPABASE_SERVICE_ROLE_KEY=sua_service_role_key_hml
```

### 7. 🚀 Deploy Frontend HML

#### Script de Build para HML:
```powershell
# build-hml.ps1
cd frontend

# Usar variáveis HML
$env:VITE_SUPABASE_URL="https://SEU-PROJETO-HML.supabase.co"
$env:VITE_SUPABASE_ANON_KEY="sua_anon_key_hml"

# Build
npm run build

# Deploy para Vercel/Netlify com configuração HML
# Ou servir localmente para testes
npm run preview
```

---

## 🧪 Validação do Setup

### 1. Verificar Database
```sql
-- No SQL Editor do projeto HML, executar:

-- Verificar tabelas criadas
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- Deve incluir:
-- conversations, messages, message_feedback, gemini_file_cache, gemini_usage_metrics

-- Verificar nova tabela de custos
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'gemini_usage_metrics';
```

### 2. Verificar Edge Functions
```bash
# Testar Edge Functions no ambiente HML
curl -X POST 'https://SEU-PROJETO-HML.supabase.co/functions/v1/ai-chat' \
  -H 'Authorization: Bearer SUA_ANON_KEY_HML' \
  -H 'apikey: SUA_ANON_KEY_HML' \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "Teste do ambiente HML",
    "userId": "test-user-123"
  }'
```

### 3. Verificar Tracking de Custos
```sql
-- Após fazer alguns testes, verificar métricas:
SELECT COUNT(*) as total_requests,
       SUM(total_cost_usd) as total_cost,
       AVG(request_duration_ms) as avg_duration
FROM gemini_usage_metrics;
```

---

## 📊 Dados de Teste para HML

### Criar usuários de teste:
```sql
-- Inserir usuário admin para testes
INSERT INTO auth.users (
  id, email, encrypted_password, 
  raw_user_meta_data, created_at, updated_at
) VALUES (
  gen_random_uuid(),
  'admin@jardulli-hml.com',
  crypt('senha123', gen_salt('bf')),
  '{"role": "admin", "full_name": "Admin HML"}',
  NOW(), NOW()
);
```

### Conversa de exemplo:
```sql
-- Inserir conversa de teste
INSERT INTO conversations (id, user_id, title) VALUES 
(gen_random_uuid(), 'SEU_USER_ID_TESTE', 'Teste de Custos HML');
```

---

## 🔄 Workflow de Testes

### Para testar novas funcionalidades:

1. **🔧 Desenvolver** localmente apontando para HML
2. **🧪 Testar** todas as funcionalidades no ambiente HML
3. **📊 Validar** métricas de custos e performance
4. **✅ Aprovar** para deploy em produção

### Comandos úteis:
```powershell
# Rodar frontend local apontando para HML
cd frontend
Copy-Item .env.hml .env.local
npm run dev

# Monitorar logs das Edge Functions HML
supabase functions logs --project-ref SEU-PROJETO-HML-ID

# Reset dados de teste se necessário
# (cuidado - vai apagar tudo!)
supabase db reset --project-ref SEU-PROJETO-HML-ID
```

---

## ✅ Checklist de Validação

- [ ] Projeto Supabase HML criado
- [ ] Todas as migrations aplicadas
- [ ] Edge Functions deployadas
- [ ] Variáveis de ambiente configuradas
- [ ] Tabela `gemini_usage_metrics` existe e funciona
- [ ] Frontend conecta no HML corretamente
- [ ] Tracking de custos captura métricas
- [ ] RLS funciona (usuários isolados)
- [ ] Funções de agregação retornam dados

---

## 🚨 Considerações Importantes

### Custos:
- **Free tier** do Supabase deve cobrir testes
- **Monitorar** uso para não exceder limites
- **Cleanup** periódico de dados antigos

### Segurança:
- **Não usar dados reais** de usuários  
- **Senhas de teste** diferentes da produção
- **API Keys** separadas se possível

### Performance:
- **Mesma região** da produção para testes realistas
- **Configurações similares** para resultados válidos

---

*Próximo: Depois do setup, vamos testar o sistema de custos completo! 🚀*