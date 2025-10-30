# 🧠 Knowledge Base

Esta pasta contém todos os recursos relacionados à base de conhecimento do sistema de IA.

## 📁 Estrutura

### `pdfs/`
Arquivos PDF que servem como base de conhecimento para o sistema:
- `01.pdf` - [Descrição do documento]
- `02.pdf` - [Descrição do documento]  
- `03.pdf` - [Descrição do documento]

### `scripts/`
Scripts PowerShell para gerenciamento da base de conhecimento:

#### 📤 **Upload e Sincronização**
- `upload-resumable.ps1` - Upload principal de arquivos para Gemini File API
- `recreate-gemini-files.ps1` - Recria arquivos expirados no Gemini
- `reupload-pdfs.ps1` - Re-upload completo dos PDFs

#### 🔍 **Monitoramento**
- `check-gemini-files.ps1` - Verifica status dos arquivos no Gemini
- `check-cache-table.ps1` - Verifica estado do cache no banco

#### 🗄️ **Gerenciamento de Cache**
- `update-cache-table.ps1` - Atualiza tabela de cache
- `fix-cache-ids.ps1` - Corrige IDs inconsistentes no cache
- `save-cache.ps1` - Salva estado atual do cache
- `register-pdfs.ps1` - Registra novos PDFs no sistema

### `jardulli-info.md`
Informações específicas sobre o cliente Jardulli, incluindo:
- Perfil da empresa
- Contexto de negócio
- Informações para personalização das respostas da IA

## 🚀 Como Usar

### Upload Inicial
```bash
.\knowledge-base\scripts\upload-resumable.ps1
```

### Verificar Status
```bash
.\knowledge-base\scripts\check-gemini-files.ps1
```

### Recriar Arquivos Expirados
```bash
.\knowledge-base\scripts\recreate-gemini-files.ps1
```

## ⚠️ Importante

- Arquivos no Gemini File API expiram em 48h
- Sempre verificar status antes de usar o sistema
- Usar `recreate-gemini-files.ps1` quando arquivos expirarem
- Manter cache sincronizado para melhor performance