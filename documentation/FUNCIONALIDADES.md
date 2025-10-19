# Documentação de Funcionalidades - Jardulli Bot Buddy

## Visão Geral do Projeto

O Jardulli Bot Buddy é um assistente de IA baseado em chat, desenvolvido para a Jardulli Máquinas. A aplicação permite que usuários autenticados tenham conversas com inteligência artificial alimentada por uma base de conhecimento, forneçam feedback sobre as respostas e compartilhem informações.

## Tecnologias Utilizadas

- **Frontend**: React 18 + TypeScript + Vite
- **UI/UX**: shadcn/ui + Tailwind CSS + Lucide Icons
- **Backend**: Supabase (Auth, Database, Realtime, Edge Functions)
- **Gerenciamento de Estado**: TanStack React Query
- **Roteamento**: React Router DOM v6
- **Temas**: next-themes (modo claro/escuro)

## Funcionalidades Principais

### 1. Sistema de Autenticação

**Localização**: `src/pages/Auth.tsx`

#### Cadastro de Usuário
- Formulário com campos: nome completo, e-mail e senha
- Validação de dados no frontend
- Criação automática de perfil no banco de dados via trigger `handle_new_user()`
- Confirmação por e-mail (configurável)

#### Login de Usuário
- Autenticação via e-mail e senha
- Sessão persistente usando localStorage
- Redirecionamento automático para página principal após login
- Verificação de sessão ativa ao acessar página de auth

#### Segurança
- Row Level Security (RLS) habilitado em todas as tabelas
- Políticas de acesso que garantem que usuários só vejam seus próprios dados
- Tokens de autenticação gerenciados automaticamente pelo Supabase
- Refresh automático de tokens

**Fluxo de Autenticação**:
```
1. Usuário acessa /auth
2. Escolhe entre cadastro ou login
3. Supabase Auth valida credenciais
4. Trigger cria perfil automaticamente (apenas no cadastro)
5. Redirecionamento para página principal (/)
6. Verificação contínua de sessão ativa
```

### 2. Gestão de Conversas

**Localização**: `src/components/ChatSidebar.tsx`

#### Criação de Conversas
- Botão "Nova Conversa" sempre visível no topo da sidebar
- Conversas criadas com título padrão "Nova Conversa"
- Título atualizado automaticamente com a primeira mensagem do usuário
- Cada conversa possui ID único (UUID)

#### Listagem de Conversas
- Exibição em ordem decrescente por data de atualização (mais recentes primeiro)
- Indicador visual da conversa ativa (highlight)
- Truncamento de títulos longos para melhor visualização
- Ícone de mensagem ao lado de cada conversa

#### Navegação entre Conversas
- Clique em conversa carrega histórico completo de mensagens
- Transição suave entre conversas
- Estado preservado ao alternar entre conversas

#### Logout
- Botão de sair fixo na parte inferior da sidebar
- Limpeza de sessão ao fazer logout
- Redirecionamento automático para página de autenticação
- Notificação toast de confirmação

**Estrutura da Sidebar**:
```
┌─────────────────────────┐
│  [+ Nova Conversa]      │
├─────────────────────────┤
│                         │
│  📄 Conversa 1 (ativa) │
│  📄 Conversa 2          │
│  📄 Conversa 3          │
│  ...                    │
│                         │
├─────────────────────────┤
│  [🚪 Sair]              │
└─────────────────────────┘
```

### 3. Sistema de Chat em Tempo Real

**Localização**: `src/pages/Index.tsx`

#### Interface de Mensagens
- Layout responsivo com mensagens alinhadas:
  - Mensagens do usuário: alinhadas à direita, fundo azul primário
  - Mensagens da IA: alinhadas à esquerda, fundo card com borda
- Suporte a texto multi-linha
- Scroll automático para última mensagem
- Área de texto expansível (textarea)

#### Envio de Mensagens
- Campo de entrada com textarea responsivo
- Botão de envio com ícone de avião
- Atalho de teclado: Enter envia, Shift+Enter quebra linha
- Validação para evitar envio de mensagens vazias
- Estado de "enviando" com indicador de loading
- Desabilitação de botão durante envio

#### Recebimento de Respostas da IA
- **Modo Atual**: Simulação com delay de 1.5 segundos
- **Integração Futura**: Ponto de integração preparado em `handleSendMessage()`
- Indicador visual de "IA digitando" (Loader2 animado)
- Respostas inseridas no banco de dados
- Associação de resposta com pergunta original

#### Realtime com Supabase
- Subscrição a INSERT events na tabela `messages`
- Atualização instantânea da UI quando novas mensagens são inseridas
- Canal de comunicação específico por conversa
- Limpeza automática de subscrições ao desmontar componente
- Prevenção de memory leaks

**Fluxo de Mensagem**:
```
1. Usuário digita e envia mensagem
2. Mensagem inserida no banco (role: 'user')
3. UI atualizada via Realtime
4. IA processa mensagem (simulado)
5. Resposta inserida no banco (role: 'assistant')
6. UI atualizada via Realtime
7. Ações de feedback disponibilizadas
```

### 4. Sistema de Feedback

**Localização**: `src/components/MessageActions.tsx`

#### Feedback Positivo
- Botão "👍 Bom" abaixo de cada resposta da IA
- Registro imediato no banco de dados (`message_feedback`)
- Notificação toast de confirmação
- Sem necessidade de comentário adicional

#### Feedback Negativo
- Botão "👎 Ruim" abre modal de feedback
- Campo de texto obrigatório para comentário
- Descrição do problema/sugestão de melhoria
- Integração com Edge Function do Supabase

#### Integração WhatsApp
**Localização**: `supabase/functions/send-whatsapp-feedback/index.ts`

Quando feedback negativo é enviado:
1. Dados salvos na tabela `message_feedback`
2. Edge Function invocada com payload:
   - Pergunta do usuário
   - Resposta da IA
   - Comentário do usuário
   - Data/hora
3. Mensagem formatada para WhatsApp
4. URL do WhatsApp Web gerada
5. Log do feedback para revisão administrativa

**Formato da Mensagem WhatsApp**:
```
🔴 FEEDBACK NEGATIVO - Jardulli IA

📝 Pergunta do usuário:
[pergunta original]

🤖 Resposta da IA:
[resposta fornecida]

💬 Comentário do usuário:
[feedback detalhado]

⏰ Data/Hora: DD/MM/AAAA HH:MM:SS
```

**Número de Contato**: (19) 98212-1616

### 5. Funcionalidades de Compartilhamento

**Localização**: `src/components/MessageActions.tsx`

#### Copiar Resposta
- Botão com ícone de copiar
- Copia texto completo da resposta para área de transferência
- Notificação toast de confirmação
- Funciona em todos os navegadores modernos

#### Compartilhar via WhatsApp
- Botão dedicado para compartilhamento WhatsApp
- Abre WhatsApp Web ou app com texto pré-preenchido
- Codificação URL adequada para caracteres especiais
- Abre em nova aba do navegador

#### Compartilhar via E-mail
- Botão para envio por e-mail
- Assunto pré-definido: "Resposta do Assistente Jardulli"
- Corpo do e-mail com resposta completa
- Abre cliente de e-mail padrão do sistema

**Barra de Ações**:
```
┌─────────────────────────────────────────────────┐
│ [📋 Copiar] [👍 Bom] [👎 Ruim]     [💬] [✉️]    │
└─────────────────────────────────────────────────┘
```

### 6. Sistema de Temas (Claro/Escuro)

**Localização**: `src/components/ThemeToggle.tsx`

#### Alternância de Temas
- Botão no cabeçalho principal
- Ícones dinâmicos: 🌞 Sol (modo claro) / 🌙 Lua (modo escuro)
- Transição suave entre temas
- Persistência da preferência do usuário

#### Definições de Cores
**Localização**: `src/index.css`

- Todas as cores definidas em HSL
- Variáveis CSS customizadas (`--background`, `--foreground`, etc.)
- Cores específicas para sidebar
- Gradientes e sombras personalizadas
- Compatibilidade total com shadcn/ui

**Paleta de Cores**:
- **Primária**: Azul profissional (220° HSL)
- **Secundária**: Cinza neutro
- **Destaque**: Azul vibrante
- **Sucesso/Erro**: Verde/Vermelho padrão

## Estrutura do Banco de Dados

**Localização**: `supabase/migrations/20251005150233_*.sql`

### Tabelas Principais

#### `profiles`
- **id**: UUID (referência a auth.users)
- **email**: TEXT (e-mail do usuário)
- **full_name**: TEXT (nome completo)
- **created_at**: TIMESTAMPTZ
- **updated_at**: TIMESTAMPTZ

#### `conversations`
- **id**: UUID (gerado automaticamente)
- **user_id**: UUID (referência a auth.users)
- **title**: TEXT (padrão: "Nova Conversa")
- **created_at**: TIMESTAMPTZ
- **updated_at**: TIMESTAMPTZ

#### `messages`
- **id**: UUID (gerado automaticamente)
- **conversation_id**: UUID (referência a conversations)
- **role**: TEXT ('user' ou 'assistant')
- **content**: TEXT (conteúdo da mensagem)
- **created_at**: TIMESTAMPTZ

#### `message_feedback`
- **id**: UUID (gerado automaticamente)
- **message_id**: UUID (referência a messages)
- **user_id**: UUID (referência a auth.users)
- **feedback_type**: TEXT ('positive' ou 'negative')
- **comment**: TEXT (opcional para positive, obrigatório para negative)
- **created_at**: TIMESTAMPTZ

### Triggers e Funções

#### `handle_new_user()`
- Trigger executado após INSERT em `auth.users`
- Cria automaticamente perfil em `profiles`
- Extrai `full_name` de `raw_user_meta_data`

#### `update_updated_at_column()`
- Atualiza campo `updated_at` automaticamente
- Aplicado em `profiles` e `conversations`

### Row Level Security (RLS)

Todas as tabelas possuem políticas RLS:
- **SELECT**: Usuário vê apenas seus próprios dados
- **INSERT**: Usuário cria apenas para si mesmo
- **UPDATE**: Usuário atualiza apenas seus próprios dados
- **DELETE**: Usuário deleta apenas seus próprios dados

## Fluxos de Uso Completos

### Fluxo: Primeira Utilização

```
1. Usuário acessa aplicação (redireciona para /auth)
2. Clica em aba "Cadastrar"
3. Preenche: Nome, E-mail, Senha
4. Clica em "Cadastrar"
5. Supabase cria usuário em auth.users
6. Trigger cria perfil em profiles
7. Redirecionamento para página principal
8. Tela de boas-vindas exibida
9. Clica em "Iniciar Conversa"
10. Primeira conversa criada
11. Campo de mensagem habilitado
12. Usuário faz primeira pergunta
```

### Fluxo: Conversa com Feedback Negativo

```
1. Usuário envia pergunta
2. IA responde (simulado)
3. Usuário lê resposta
4. Considera resposta inadequada
5. Clica em botão "👎 Ruim"
6. Modal de feedback abre
7. Escreve comentário detalhado
8. Clica em "Enviar Feedback"
9. Feedback salvo no banco
10. Edge Function invocada
11. Mensagem formatada para WhatsApp
12. Log criado para revisão
13. Toast de confirmação exibido
```

### Fluxo: Compartilhamento de Resposta

```
1. Usuário recebe resposta útil da IA
2. Decide compartilhar informação
3. Clica em "📋 Copiar" OU
4. Clica em "💬 WhatsApp" OU
5. Clica em "✉️ E-mail"
   
   Opção A (Copiar):
   - Texto copiado para clipboard
   - Toast de confirmação
   
   Opção B (WhatsApp):
   - WhatsApp Web abre em nova aba
   - Texto pré-preenchido
   - Usuário escolhe contato
   
   Opção C (E-mail):
   - Cliente de e-mail abre
   - Assunto e corpo pré-preenchidos
   - Usuário adiciona destinatário
```

## Configuração de Desenvolvimento

### Pré-requisitos
- Node.js (v18+)
- npm ou bun
- Conta Supabase (gratuita)

### Variáveis de Ambiente

Criar arquivo `.env` na raiz:
```env
VITE_SUPABASE_URL=https://seu-projeto.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sua-chave-publica-aqui
```

### Comandos Principais

```bash
# Instalar dependências
npm install

# Desenvolvimento (porta 8080)
npm run dev

# Build de produção
npm run build

# Build de desenvolvimento
npm run build:dev

# Verificar código (ESLint)
npm run lint

# Preview do build
npm run preview
```

### Adicionar Componentes shadcn/ui

```bash
# Exemplo: adicionar componente alert
npx shadcn@latest add alert

# Componente será adicionado em src/components/ui/alert.tsx
```

## Pontos de Integração Futura

### 1. Integração com IA Real

**Local**: `src/pages/Index.tsx` - função `handleSendMessage()`

**Código Atual** (simulado):
```typescript
setTimeout(async () => {
  const aiResponse = `Esta é uma resposta simulada...`;
  // Inserir no banco
}, 1500);
```

**Substituir por**:
```typescript
// Exemplo com OpenAI
const response = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [{ role: "user", content: userMessage }],
});
const aiResponse = response.choices[0].message.content;
// Inserir no banco
```

### 2. Base de Conhecimento

**Integração sugerida**:
- RAG (Retrieval-Augmented Generation)
- Vetorização de documentos da Jardulli
- Busca semântica antes de enviar para LLM
- Cache de respostas frequentes

### 3. Analytics e Métricas

**Dados para coletar**:
- Taxa de feedback positivo vs negativo
- Tempo médio de resposta
- Tópicos mais consultados
- Taxa de retenção de usuários
- Conversas mais longas

## Boas Práticas do Projeto

### TypeScript
- Todas as interfaces explicitamente tipadas
- Props de componentes com interfaces nomeadas
- Tipos auto-gerados do Supabase em `src/integrations/supabase/types.ts`

### Estilização
- Usar função `cn()` para merge de classes Tailwind
- Preferir componentes shadcn/ui para consistência
- Todas as cores via variáveis CSS (HSL)
- Evitar valores hard-coded de cores

### Estado e Dados
- React Query para dados do servidor
- useState para estado local de UI
- Sempre limpar subscrições no cleanup
- Tratamento de erros com toasts

### Segurança
- Nunca expor chaves privadas no frontend
- Validar dados antes de enviar ao banco
- Confiar nas políticas RLS do Supabase
- Sanitizar inputs de usuário

## Limitações Conhecidas

1. **IA Simulada**: Atualmente respostas são simuladas com delay fixo
2. **Sem Busca**: Não há funcionalidade de busca em conversas antigas
3. **Sem Edição**: Mensagens não podem ser editadas após envio
4. **Sem Anexos**: Sistema não suporta envio de arquivos/imagens
5. **WhatsApp Manual**: Feedback negativo requer abertura manual do WhatsApp

## Roadmap Futuro

- [ ] Integração com LLM real (OpenAI/Claude/outros)
- [ ] Base de conhecimento vetorizada
- [ ] Busca em conversas históricas
- [ ] Exportação de conversas (PDF/TXT)
- [ ] Suporte a anexos e imagens
- [ ] Streaming de respostas da IA
- [ ] Sugestões de perguntas relacionadas
- [ ] Dashboard administrativo
- [ ] Analytics de uso
- [ ] API pública para integrações

## Suporte e Contato

Para dúvidas ou suporte:
- **WhatsApp**: (19) 98212-1616
- **E-mail**: Via feedback negativo no sistema
- **Repositório**: GitHub (privado)

---

**Última atualização**: Outubro 2025  
**Versão**: 0.0.0  
**Desenvolvido para**: Jardulli Máquinas
