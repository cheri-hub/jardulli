# 🏗️ Estratégia de Ambientes - Jardulli Bot

## 🎯 Problema Identificado
Precisamos de ambientes separados para testar funcionalidades (como tracking de custos) sem impactar usuários em produção.

## 🌍 Proposta de Ambientes

### 1. 🧪 **DEV** (Desenvolvimento Local)
- **Propósito**: Desenvolvimento e testes iniciais
- **Supabase**: Projeto local ou projeto dev dedicado
- **Frontend**: `localhost:8080`
- **Dados**: Dados de teste/mock
- **Custos**: Mínimos (apenas desenvolvimento)

### 2. 🔄 **HML** (Homologação/Staging) 
- **Propósito**: Testes completos antes de produção
- **Supabase**: Projeto separado para staging
- **Frontend**: Deploy em subdomínio (ex: `hml.jardulli.com`)
- **Dados**: Cópia de produção (sanitizada) ou dados realistas
- **Custos**: Controlados para testes

### 3. 🚀 **PRD** (Produção)
- **Propósito**: Usuários reais
- **Supabase**: Projeto atual de produção
- **Frontend**: Domínio principal
- **Dados**: Dados reais dos usuários
- **Custos**: Monitoramento crítico

---

## 📋 Implementação Sugerida

### Opção A: 🏃‍♂️ **Rápida** - Usar mesmo projeto Supabase
```typescript
// Variáveis de ambiente para diferenciar
const ENVIRONMENT = Deno.env.get("ENVIRONMENT") || "dev"; // dev, hml, prd

// Prefixos nas tabelas para separar ambientes
const getTableName = (table: string) => {
  return ENVIRONMENT === "prd" ? table : `${ENVIRONMENT}_${table}`;
};

// Exemplo: dev_gemini_usage_metrics, hml_gemini_usage_metrics
```

**Pros**: Rápido de implementar, um projeto só
**Cons**: Dados misturados, mais complexo de gerenciar

### Opção B: 🏢 **Profissional** - Projetos Supabase separados
```bash
# Criar novo projeto Supabase para HML
# 1. Ir no dashboard Supabase
# 2. New Project > "jardulli-hml"
# 3. Configurar mesmo schema (rodar migrations)
# 4. Variáveis de ambiente diferentes
```

**Pros**: Isolamento total, mais seguro, profissional
**Cons**: Custo adicional, mais setup

### Opção C: 🎯 **Híbrida** - Branch-based testing
```bash
# Branches específicas para ambientes
git checkout -b feature/cost-tracking
git checkout -b hml/cost-tracking
git checkout -b main  # produção

# Deploy automático por branch
# feature/* -> não deploya
# hml/* -> deploy para ambiente HML
# main -> deploy para PRD
```

---

## 🛠️ Implementação Recomendada (Opção B)

### Passo 1: Criar Projeto HML
1. **Novo projeto Supabase**: `jardulli-hml`
2. **Rodar todas as migrations** (incluindo a nova de custos)
3. **Configurar Edge Functions** iguais
4. **Dados de teste** realistas

### Passo 2: Configuração de Deploy
```bash
# .env.hml
SUPABASE_URL=https://seu-projeto-hml.supabase.co
SUPABASE_ANON_KEY=sua_key_hml
SUPABASE_SERVICE_ROLE_KEY=sua_service_key_hml
GEMINI_API_KEY=sua_gemini_key  # Mesmo ou separado

# .env.prod  
SUPABASE_URL=https://gplumtfxxhgckjkgloni.supabase.co
SUPABASE_ANON_KEY=sua_key_prod
SUPABASE_SERVICE_ROLE_KEY=sua_service_key_prod
GEMINI_API_KEY=sua_gemini_key_prod
```

### Passo 3: Scripts de Deploy
```bash
# deploy-hml.ps1
cd frontend
$env:VITE_SUPABASE_URL="https://seu-projeto-hml.supabase.co"
$env:VITE_SUPABASE_ANON_KEY="sua_key_hml"
npm run build
# Deploy para Vercel/Netlify staging

# deploy-prod.ps1  
cd frontend
$env:VITE_SUPABASE_URL="https://gplumtfxxhgckjkgloni.supabase.co"
$env:VITE_SUPABASE_ANON_KEY="sua_key_prod"
npm run build
# Deploy para produção
```

---

## 🧪 Workflow de Testes

### Para novas funcionalidades (como custos):

1. **🔧 DEV**: Desenvolver localmente
2. **🔄 HML**: Deploy para homologação
   - Testar todas as funcionalidades
   - Validar métricas de custos
   - Testar edge cases
   - Performance testing
3. **🚀 PRD**: Deploy para produção apenas após validação completa

### Testes Específicos para Tracking de Custos:

```bash
# Em HML, testar:
# 1. Migration aplicada corretamente
# 2. Métricas sendo salvas
# 3. Cálculos de custo corretos  
# 4. Performance não degradada
# 5. RLS funcionando
# 6. Funções de agregação
```

---

## 💰 Considerações de Custo

### Supabase HML:
- **Gratuito** até certos limites
- **Edge Functions**: 500K requests/mês grátis
- **Database**: 500MB grátis  
- **Storage**: 1GB grátis

### Recomendação:
- Usar **Free tier** para HML
- Monitorar uso para não exceder
- Cleanup periódico de dados antigos

---

## 🎯 Próximos Passos Imediatos

### Opção Rápida (hoje mesmo):
1. Criar prefixo `hml_` nas tabelas
2. Testar migration com `hml_gemini_usage_metrics`
3. Modificar Edge Function para usar tabela HML

### Opção Profissional (recomendada):
1. Criar projeto `jardulli-hml` no Supabase
2. Aplicar todas as migrations
3. Deploy frontend para staging
4. Testar funcionalidade completa

---

## ❓ Decisão Necessária

**Qual opção você prefere?**

- 🏃‍♂️ **A**: Mesmo projeto, tabelas prefixadas (mais rápido)
- 🏢 **B**: Projeto separado (mais profissional) 
- 🎯 **C**: Branch-based (mais automatizado)

Vou implementar a estratégia que você escolher! 🚀