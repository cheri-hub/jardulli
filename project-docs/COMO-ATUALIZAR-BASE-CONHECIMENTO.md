# 🔄 Como Atualizar a Base de Conhecimento

## 🚀 **SISTEMA ATUALIZADO: GEMINI FILE API**

**Importante**: O sistema agora usa **Gemini File API** em vez de processamento de texto local!

### **Benefícios da nova arquitetura:**
- ✅ **Sem limite de tamanho** de documentos
- ✅ **90% economia de tokens** (de ~12.5k para ~1.5k por consulta)
- ✅ **Performance superior** (processamento no Gemini)
- ✅ **Cache inteligente** com SHA256

---

## **Método 1: Upload via Gemini File API (RECOMENDADO)**

### **Via Script Automático:**
```powershell
# Upload de PDF para Gemini File API
.\scripts\upload-gemini-files.ps1 -filePath "caminho\para\documento.pdf"
```

### **Via Edge Function (Programático):**
```powershell
# Registra PDF na tabela e faz upload automático
$body = '{"fileId":"uuid-do-arquivo"}' 
Invoke-RestMethod -Uri "https://gplumtfxxhgckjkgloni.supabase.co/functions/v1/upload-gemini-files" -Method Post -Body $body
```

---

## **Método 2: Gerenciar via Interface Supabase**

### **Via Interface Supabase:**
1. Acesse: https://supabase.com/dashboard/project/gplumtfxxhgckjkgloni
2. Vá em **Storage** → **documentos**
3. Faça upload do arquivo PDF
4. Execute script para registrar na File API:
```powershell
.\scripts\register-pdfs.ps1
```

---

## **Método 3: Gerenciar múltiplos arquivos (File API)**

### **Upload em lote:**
```powershell
# Upload de vários PDFs para File API
.\scripts\upload-gemini-files.ps1 -filePath "catalogo-2025.pdf"
.\scripts\upload-gemini-files.ps1 -filePath "manual-tecnico.pdf"  
.\scripts\upload-gemini-files.ps1 -filePath "precos-atuais.pdf"
```

### **Verificar status dos uploads:**
```powershell
# Lista arquivos na File API
.\scripts\test-database.ps1
```

### **Formatos suportados no Gemini File API:**
- ✅ PDF (.pdf) - **RECOMENDADO**
- ✅ Texto (.txt)
- ✅ Markdown (.md)
- ✅ Word (.docx)
- ✅ Imagens (.png, .jpg) - Futuro suporte multimodal

---

## **Método 3: Organizar por categorias**

### **Estrutura sugerida:**
```
documentos/
├── produtos/
│   ├── catalogo-2025.md
│   ├── especificacoes-tecnicas.md
│   └── precos-atuais.md
├── servicos/
│   ├── manutencao.md
│   ├── garantias.md
│   └── suporte-tecnico.md
├── empresa/
│   ├── sobre-jardulli.md
│   ├── contatos.md
│   └── horarios.md
└── jardulli-info.md (principal)
```

---

## **Método 4: Sistema de versioning**

### **Controle de versões:**
```
documentos/
├── v1.0/
│   └── jardulli-info-v1.md
├── v2.0/
│   └── jardulli-info-v2.md
└── current/
    └── jardulli-info.md (ativa)
```

---

## **🔧 Scripts Disponíveis:**

### **1. Upload de documento:**
```powershell
.\scripts\upload-doc.ps1 -filePath "novo-arquivo.md"
```

### **2. Listar documentos:**
```powershell
.\scripts\list-docs.ps1
```

### **3. Backup automático:**
```powershell
.\scripts\backup-docs.ps1
```

---

## **🔧 Scripts Disponíveis (File API):**

### **1. Upload para Gemini File API:**
```powershell
.\scripts\test-upload-gemini-files.ps1
```

### **2. Verificar arquivos ativos:**
```powershell  
.\scripts\test-database.ps1
```

### **3. Testar chat com File API:**
```powershell
.\scripts\debug-chat.ps1
```

### **4. Verificar cache da tabela:**
```powershell
.\scripts\check-cache-table.ps1
```

---

## **⚡ Atualização Instantânea com File API**

**Ainda mais rápido:** Mudanças são **imediatas** e **otimizadas**!
- ✅ Upload PDF → **Processa uma vez** no Gemini → Usa para sempre
- ✅ **Sem re-download** → Referência direta no Gemini
- ✅ **Sem limite de tamanho** → PDFs grandes funcionam perfeitamente
- ✅ **90% menos tokens** → Muito mais eficiente

### **Status Atual:**
```
📊 Arquivos ativos no Gemini File API:
✅ Documento 01 (files/2fq17czmwe32) - ACTIVE
✅ Documento 02 (files/ojsr3jnxjs3s) - ACTIVE  
✅ Documento 03 (files/fpfmb430cayi) - ACTIVE
```

**Não precisa fazer redeploy do app!** 🚀

**Sistema otimizado e em produção!** 🎯