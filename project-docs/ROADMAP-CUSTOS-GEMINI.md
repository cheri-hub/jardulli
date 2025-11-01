# 📊 Roadmap - Sistema de Tracking de Custos Gemini

## 🎯 Objetivo
Implementar sistema completo de monitoramento e controle de custos do Google Gemini API para evitar surpresas na fatura e otimizar o uso.

## 🔥 Prioridade: ALTA
- **Motivo**: Controle financeiro é crítico para sustentabilidade do negócio
- **Impacto**: Evita gastos excessivos e permite otimização de custos
- **Timeline sugerido**: Próximas 2-3 sprints

---

## 📋 Funcionalidades a Implementar

### 1. 📈 Dashboard de Métricas (Backend)

#### 🗃️ Estrutura do Banco
```sql
-- Tabela para tracking de uso do Gemini
CREATE TABLE gemini_usage_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  conversation_id UUID REFERENCES conversations(id),
  message_id UUID REFERENCES messages(id),
  
  -- Métricas técnicas
  model_used TEXT NOT NULL, -- 'gemini-1.5-flash', 'gemini-1.5-pro'
  tokens_input INTEGER NOT NULL,
  tokens_output INTEGER NOT NULL,
  total_tokens INTEGER GENERATED ALWAYS AS (tokens_input + tokens_output) STORED,
  
  -- Métricas financeiras
  cost_input_usd DECIMAL(10,6) NOT NULL,
  cost_output_usd DECIMAL(10,6) NOT NULL,
  total_cost_usd DECIMAL(10,6) GENERATED ALWAYS AS (cost_input_usd + cost_output_usd) STORED,
  
  -- Metadata
  request_duration_ms INTEGER,
  files_processed INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_gemini_usage_user_date ON gemini_usage_metrics(user_id, created_at);
CREATE INDEX idx_gemini_usage_cost ON gemini_usage_metrics(total_cost_usd DESC);
CREATE INDEX idx_gemini_usage_tokens ON gemini_usage_metrics(total_tokens DESC);
```

#### 📊 Métricas a Capturar
- **Tokens por request** (input/output)
- **Custo estimado por request** (baseado na tabela de preços oficial)
- **Modelo usado** (Flash vs Pro)
- **Duração da request**
- **Arquivos processados** (PDFs na base de conhecimento)
- **User e conversation context**

### 2. 🔧 Implementação nas Edge Functions

#### 📝 Modificações na `ai-chat/index.ts`
```typescript
// Adicionar logging de métricas após cada request
const logGeminiUsage = async (metrics: {
  user_id: string,
  conversation_id: string,
  message_id: string,
  model_used: string,
  tokens_input: number,
  tokens_output: number,
  cost_input_usd: number,
  cost_output_usd: number,
  request_duration_ms: number,
  files_processed: number
}) => {
  await supabase.from('gemini_usage_metrics').insert(metrics);
};

// Calcular custos baseado nos preços oficiais do Gemini
const calculateCosts = (model: string, inputTokens: number, outputTokens: number) => {
  const prices = {
    'gemini-1.5-flash': { input: 0.000075, output: 0.0003 }, // por 1K tokens
    'gemini-1.5-pro': { input: 0.00125, output: 0.005 }
  };
  
  const rate = prices[model] || prices['gemini-1.5-flash'];
  return {
    input: (inputTokens / 1000) * rate.input,
    output: (outputTokens / 1000) * rate.output
  };
};
```

### 3. 📱 Dashboard Frontend (Admin)

#### 🎨 Componentes UI
- **`CostDashboard.tsx`** - Visão geral de custos
- **`UsageMetrics.tsx`** - Gráficos de uso por período
- **`UserCostBreakdown.tsx`** - Custos detalhados por usuário
- **`AlertsConfiguration.tsx`** - Configuração de limites

#### 📊 Visualizações
- **Gráfico temporal** de gastos (diário/semanal/mensal)
- **Top usuários** por consumo
- **Breakdown por modelo** (Flash vs Pro)
- **Eficiência por conversa** (custo/mensagem)
- **Projeções de gastos** baseadas no uso atual

### 4. ⚠️ Sistema de Alertas

#### 🚨 Tipos de Alertas
1. **Limite diário** atingido (ex: $10/dia)
2. **Limite mensal** atingido (ex: $200/mês)  
3. **Usuário gastando muito** (ex: >$5/usuário/dia)
4. **Pico de uso anômalo** (ex: 300% acima da média)

#### 📧 Canais de Notificação
- **WhatsApp** (via send-whatsapp-feedback function)
- **Email** (via Supabase Auth)
- **Toast in-app** (para admins logados)

#### 🔧 Implementação
```typescript
// Edge Function: check-cost-limits
const checkCostLimits = async () => {
  const today = new Date().toISOString().split('T')[0];
  
  // Verificar limite diário
  const dailySpent = await supabase
    .from('gemini_usage_metrics')
    .select('total_cost_usd.sum()')
    .gte('created_at', today);
    
  if (dailySpent > DAILY_LIMIT) {
    await sendAlert('daily_limit_exceeded', dailySpent);
  }
};
```

### 5. 🎛️ Controles de Economia

#### ⚡ Otimizações Automáticas
- **Rate limiting inteligente** (reduzir para usuários gastando muito)
- **Modelo switching** (usar Flash em vez de Pro quando possível)
- **Cache de respostas** (evitar requests duplicadas)
- **Truncar contexto** (limitar tokens de histórico)

#### ⚙️ Configurações Admin
- **Limites por usuário** (tokens/dia, $/dia)
- **Limites globais** ($/dia, $/mês)
- **Políticas de uso** (qual modelo usar quando)

---

## 🛣️ Roadmap de Implementação

### 📅 Sprint 1: Infraestrutura Base
- [ ] Criar tabela `gemini_usage_metrics`
- [ ] Implementar logging básico na Edge Function
- [ ] Calcular custos por request
- [ ] Testes de captura de métricas

### 📅 Sprint 2: Dashboard Básico  
- [ ] Componente `CostDashboard`
- [ ] Gráficos básicos (custo/tempo)
- [ ] Lista de usuários por consumo
- [ ] Página admin protegida

### 📅 Sprint 3: Sistema de Alertas
- [ ] Edge Function para check de limites
- [ ] Alertas via WhatsApp
- [ ] Configuração de thresholds
- [ ] Testes de alertas

### 📅 Sprint 4: Otimizações & Controles
- [ ] Rate limiting inteligente
- [ ] Políticas de economia
- [ ] Relatórios detalhados
- [ ] Exportação de dados

---

## 💡 Benefícios Esperados

### 💰 Controle Financeiro
- **Transparência total** dos custos em tempo real
- **Prevenção** de gastos excessivos
- **Otimização** baseada em dados reais

### 📊 Insights de Negócio
- **Usuários mais ativos** e engagement
- **Eficiência** do modelo de IA
- **ROI** por usuário/conversa

### ⚡ Performance
- **Identificar gargalos** de custo
- **Otimizar** uso de modelos
- **Escalar** com confiança

---

## 🔍 Métricas de Sucesso

- **Redução de 30%** nos custos médios por conversa
- **0 surpresas** na fatura mensal
- **Alertas funcionais** com <5min de delay
- **Dashboard responsivo** com dados em tempo real

---

## 🚨 Considerações Importantes

### 🔐 Segurança
- Dados financeiros só para admins
- Logs anonymizados quando necessário
- Rate limiting para evitar spam

### 📈 Escalabilidade  
- Agregar métricas antigas (daily/monthly summaries)
- Otimizar queries de dashboard
- Considerar BigQuery para volumes grandes

### 🎯 UX
- Não impactar performance do chat
- Logging assíncrono
- Fallbacks se logging falhar

---

*Documento criado em: 30/10/2025*  
*Próxima revisão: Após implementação do Sprint 1*