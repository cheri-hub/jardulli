# 🆕 Como Criar Projeto HML no Supabase - Guia Visual

## 🎯 Objetivo
Criar um projeto Supabase dedicado para ambiente de homologação (HML) para testar o sistema de custos com segurança.

---

## 📱 Passo a Passo Visual

### **Passo 1**: Acessar Dashboard
1. 🌐 Abra seu navegador
2. 🔗 Vá para: **https://supabase.com/dashboard**
3. 🔑 Faça login na sua conta Supabase

### **Passo 2**: Criar Novo Projeto
1. 📊 No dashboard principal, você verá seus projetos existentes
2. 🆕 Clique no botão **"New Project"** (botão verde/azul no canto superior direito)
3. 📂 Ou clique em **"+ Create a new project"** se não tiver projetos

### **Passo 3**: Configurar o Projeto
Na tela de criação, preencha:

#### 🏢 **Organization**
- Selecione sua organização existente (onde está o projeto de produção)

#### 📝 **Project Settings**
- **Name**: `jardulli-hml` 
- **Database Password**: 
  - Clique em "Generate a password" 
  - ⚠️ **IMPORTANTE**: Copie e salve essa senha em local seguro!
- **Region**: 
  - Escolha **a mesma região** do projeto de produção
  - Ex: "South America (São Paulo)" se produção estiver lá

#### 💰 **Pricing Plan**
- Deixe **"Free"** selecionado para HML
- Suficiente para testes e homologação

### **Passo 4**: Finalizar Criação
1. ✅ Revise as informações
2. 🚀 Clique em **"Create new project"**
3. ⏳ Aguarde 2-3 minutos (o Supabase está criando a infraestrutura)

---

## 📊 Informações Importantes para Coletar

### Após o projeto ser criado, vá em **Settings > API**:

#### 📋 **Anote estas informações:**

1. **🆔 Project URL**:
   ```
   https://[project-id-hml].supabase.co
   ```

2. **🔑 API Keys**:
   - **anon/public**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - **service_role**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

3. **🆔 Project ID** (encontrado na URL):
   ```
   https://supabase.com/dashboard/project/[ESTE-E-O-PROJECT-ID]
   ```

---

## 🔧 Configurações Iniciais Importantes

### **Database Settings**
Em **Settings > Database**:
- ✅ Verifique se a região está correta
- ✅ Anote a connection string se necessário

### **Authentication Settings**  
Em **Authentication > Settings**:
- 🔒 Pode manter as configurações padrão para HML
- 📧 Email templates podem ser diferentes de produção

### **Storage Settings**
Em **Storage > Settings**:
- 📁 Os buckets serão criados via migrations
- 🔐 Políticas RLS serão aplicadas automaticamente

---

## ⚠️ Dicas Importantes

### 🛡️ **Segurança**
- **NÃO copiar dados de produção** para HML inicialmente
- **Usar senhas diferentes** da produção
- **API Keys são diferentes** - não confundir com produção

### 💰 **Custos**
- **Free tier** tem limites generosos:
  - 500MB database
  - 1GB storage  
  - 2GB bandwidth
  - 500K Edge Function requests
- ✅ Suficiente para testes de HML

### 🎯 **Naming Convention**
- Projeto: `jardulli-hml` 
- Facilita identificação
- Evita confusão com produção

---

## 🚀 Após a Criação

### **Verificar Status**
1. 🟢 Projeto aparece como "Active" no dashboard
2. 🔗 URL funciona e retorna página do Supabase
3. ⚡ Database está "Healthy"

### **Próximo Passo**
Após criar o projeto, execute:
```powershell
cd c:\repo\jardulli-bot-buddy
.\tools\setup-hml-environment.ps1
```

O script vai pedir as informações que você coletou (URL, Keys, Project ID).

---

## ❓ Problemas Comuns

### **"Organization not found"**
- 👤 Verifique se está logado na conta correta
- 🏢 Crie uma organização se necessário

### **"Region not available"**  
- 🌍 Escolha região disponível mais próxima
- 📍 South America (São Paulo) é boa opção para Brasil

### **"Free tier limit exceeded"**
- 📊 Você já tem muitos projetos free
- 🗑️ Delete projetos não utilizados ou upgrade plan

### **Projeto criado mas não aparece**
- ⏳ Aguarde alguns minutos
- 🔄 Atualize a página
- 🚪 Faça logout/login novamente

---

## 📝 Resumo Rápido

1. 🌐 **supabase.com/dashboard**
2. 🆕 **New Project**  
3. 📝 **Nome**: `jardulli-hml`
4. 🔑 **Senha**: Gerar e salvar
5. 🌍 **Região**: Mesma de produção
6. 🆓 **Plan**: Free
7. 📋 **Coletar**: URL + API Keys + Project ID
8. 🚀 **Executar**: `setup-hml-environment.ps1`

---

*Depois de criar, volte aqui e execute o script de setup! 🎯*