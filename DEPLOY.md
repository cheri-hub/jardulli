# Deploy para Produção - Jardulli Bot Buddy

## Opção 1: Deploy via Vercel (Recomendado)

### Passo 1: Preparar o repositório
```bash
git add .
git commit -m "Preparar para deploy"
git push origin main
```

### Passo 2: Deploy na Vercel

1. Acesse https://vercel.com
2. Faça login com GitHub
3. Clique em "Add New Project"
4. Selecione o repositório `jardulli-bot-buddy`
5. Configure as variáveis de ambiente:

**Environment Variables (IMPORTANTE!):**
```
VITE_SUPABASE_URL=https://gplumtfxxhgckjkgloni.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3ODU0MTYsImV4cCI6MjA3NjM2MTQxNn0.bGuIT3tLN5rNgvalJD9C8G6tN6FPqfuO2Zez64-ceqg
VITE_SUPABASE_PROJECT_ID=gplumtfxxhgckjkgloni
```

6. Clique em "Deploy"
7. Aguarde o build (2-3 minutos)
8. Sua aplicação estará online em `https://seu-projeto.vercel.app`

### Passo 3: Configurar domínio personalizado (Opcional)

1. No dashboard da Vercel, vá em "Settings" > "Domains"
2. Adicione seu domínio personalizado
3. Configure os DNS conforme instruções

---

## Opção 2: Deploy via Netlify

### Passo 1: Preparar o repositório
```bash
git add .
git commit -m "Preparar para deploy"
git push origin main
```

### Passo 2: Deploy na Netlify

1. Acesse https://netlify.com
2. Faça login com GitHub
3. Clique em "Add new site" > "Import an existing project"
4. Selecione o repositório `jardulli-bot-buddy`
5. Configure:
   - Build command: `npm run build`
   - Publish directory: `dist`
6. Adicione Environment Variables (mesmas da Vercel)
7. Clique em "Deploy"

---

## Opção 3: Deploy Manual (Qualquer servidor)

### Passo 1: Build local
```bash
npm run build
```

### Passo 2: Configurar variáveis de ambiente

Crie arquivo `.env.production` na raiz:
```
VITE_SUPABASE_URL=https://gplumtfxxhgckjkgloni.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3ODU0MTYsImV4cCI6MjA3NjM2MTQxNn0.bGuIT3tLN5rNgvalJD9C8G6tN6FPqfuO2Zez64-ceqg
VITE_SUPABASE_PROJECT_ID=gplumtfxxhgckjkgloni
```

### Passo 3: Upload da pasta `dist`

Faça upload do conteúdo da pasta `dist/` para seu servidor web (Apache, Nginx, etc.)

### Passo 4: Configurar servidor

**Nginx:**
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

**Apache (.htaccess):**
```apache
RewriteEngine On
RewriteBase /
RewriteRule ^index\.html$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.html [L]
```

---

## Checklist Pós-Deploy

- [ ] Testar criação de conta
- [ ] Testar login
- [ ] Testar envio de mensagens
- [ ] Verificar se o bot responde com base nos documentos
- [ ] Testar rate limiting (21 mensagens)
- [ ] Verificar logs de erro no Supabase Dashboard

---

## URLs Importantes

- **Supabase Dashboard**: https://supabase.com/dashboard/project/gplumtfxxhgckjkgloni
- **Edge Functions**: https://supabase.com/dashboard/project/gplumtfxxhgckjkgloni/functions
- **Storage**: https://supabase.com/dashboard/project/gplumtfxxhgckjkgloni/storage/buckets
- **Database**: https://supabase.com/dashboard/project/gplumtfxxhgckjkgloni/editor

---

## Troubleshooting

### Erro: "Supabase URL não configurada"
- Verifique se as variáveis de ambiente foram configuradas corretamente na plataforma de deploy

### Erro 401: Unauthorized
- Verifique se a VITE_SUPABASE_PUBLISHABLE_KEY está correta

### Chat não responde
- Verifique os logs da Edge Function no Supabase Dashboard
- Confirme que o documento está no Storage bucket "documentos"

### Deploy falhou
- Verifique se todas as dependências estão no package.json
- Confirme que o build local funciona: `npm run build`
