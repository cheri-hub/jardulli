# 📚 Documentação - Jardulli Bot Buddy

Esta pasta contém toda a documentação do projeto Jardulli Bot Buddy.

## 📁 Índice de Documentos

### 📖 Documentação Geral

#### [FUNCIONALIDADES.md](./FUNCIONALIDADES.md)
Documentação completa em português sobre todas as funcionalidades do projeto:
- Visão geral do sistema
- Tecnologias utilizadas
- Funcionalidades principais (autenticação, chat, feedback, etc)
- Estrutura do banco de dados
- Fluxos de uso completos
- Configuração de desenvolvimento

**👥 Para**: Desenvolvedores, Product Owners, Stakeholders

---

#### [MVP-TODO.md](./MVP-TODO.md)
Lista completa de tarefas para transformar o projeto em um MVP funcional:
- Tarefas organizadas por prioridade (Crítico, Importante, Nice to Have)
- Integração com Google Gemini (LLM escolhido)
- Implementação de RAG (Retrieval-Augmented Generation)
- Base de conhecimento e vetorização
- Estimativas de tempo e custos
- Checklist de deploy
- Ordem de implementação sugerida (4 sprints)

**👥 Para**: Desenvolvedores, Tech Leads, Gerentes de Projeto

---

#### [EXEMPLO-GEMINI-DETALHADO.md](./EXEMPLO-GEMINI-DETALHADO.md)
Análise técnica detalhada da implementação de exemplo com Google Gemini:
- Como funciona o backend de exemplo (`agrosinergia_responde_backend`)
- Sistema de cache de arquivos (SHA256)
- Upload para Gemini File API
- Implementação de RAG
- Código explicado linha por linha
- Problemas comuns e soluções
- Adaptação para Supabase Edge Functions

**👥 Para**: Desenvolvedores (nível intermediário/avançado)

---

#### [copilot-instructions.md](./copilot-instructions.md)
Instruções para AI coding agents (GitHub Copilot, Cursor, etc):
- Arquitetura do projeto
- Convenções de código
- Padrões do projeto
- Fluxo de dados
- Pontos de integração
- Referências de arquivos-chave

**👥 Para**: AI Agents, Desenvolvedores novos no projeto

---

## 🎯 Por Onde Começar?

### Se você é novo no projeto:
1. Leia **FUNCIONALIDADES.md** para entender o que o sistema faz
2. Revise **copilot-instructions.md** para conhecer a arquitetura
3. Consulte **MVP-TODO.md** para ver o roadmap

### Se você vai implementar o MVP:
1. Estude **MVP-TODO.md** (roadmap completo)
2. Leia **EXEMPLO-GEMINI-DETALHADO.md** (implementação técnica)
3. Siga a ordem dos sprints no MVP-TODO

### Se você vai trabalhar com Gemini:
1. **EXEMPLO-GEMINI-DETALHADO.md** é seu guia principal
2. Consulte o exemplo em `EXAMPLES/agrosinergia_responde_backend`
3. Adapte para Edge Functions seguindo as instruções

---

## 📂 Outros Documentos no Projeto

- **README.md** (raiz): Informações gerais do projeto, setup básico
- **EXAMPLES/agrosinergia_responde_backend/README.md**: Documentação do backend de exemplo

---

## 🔄 Atualizações

Mantenha esta documentação atualizada conforme o projeto evolui:
- ✅ Novos recursos → atualizar FUNCIONALIDADES.md
- ✅ Tasks concluídas → marcar em MVP-TODO.md
- ✅ Mudanças de arquitetura → atualizar copilot-instructions.md
- ✅ Novas descobertas técnicas → adicionar em EXEMPLO-GEMINI-DETALHADO.md

---

**Última atualização**: Outubro 2025
