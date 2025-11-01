# Test Gemini Cost Tracking System

## 🧪 Testes para validar captura de métricas

### 1. Verificar tabela criada
```sql
-- Conectar no Supabase e executar:
SELECT * FROM gemini_usage_metrics LIMIT 5;
```

### 2. Testar função de cálculo de custos
```typescript
// No console do navegador ou teste unitário:
import { calculateGeminiCosts } from './gemini-cost-calculator.ts';

// Teste Flash model
const flashCost = calculateGeminiCosts('gemini-1.5-flash', 1000, 500);
console.log('Flash cost:', flashCost);
// Esperado: ~$0.000225 ($0.075 + $0.15)

// Teste Pro model  
const proCost = calculateGeminiCosts('gemini-1.5-pro', 1000, 500);
console.log('Pro cost:', proCost);
// Esperado: ~$0.00375 ($1.25 + $2.50)
```

### 3. Testar Edge Function com logging
```bash
# No terminal, testar a função AI Chat:
curl -X POST 'https://gplumtfxxhgckjkgloni.supabase.co/functions/v1/ai-chat' \
  -H 'Authorization: Bearer SEU_TOKEN_AQUI' \
  -H 'apikey: SUA_API_KEY_AQUI' \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "Qual o horário de atendimento da Jardulli?",
    "conversationId": "test-conv-123",
    "userId": "SEU_USER_ID_AQUI"
  }'
```

### 4. Verificar métricas salvas
```sql
-- Após fazer requests, verificar se métricas foram capturadas:
SELECT 
  created_at,
  model_used,
  tokens_input,
  tokens_output,
  total_tokens,
  total_cost_usd,
  request_duration_ms,
  files_processed
FROM gemini_usage_metrics 
ORDER BY created_at DESC 
LIMIT 10;
```

### 5. Testar funções de agregação
```sql
-- Custos do dia atual:
SELECT * FROM get_daily_gemini_costs();

-- Verificar limite de gasto:
SELECT * FROM check_daily_spending_limit('SEU_USER_ID', 5.00);
```

### 6. Validar RLS (Row Level Security)
```sql
-- Como usuário normal (não admin), deve ver apenas suas métricas:
SELECT COUNT(*) FROM gemini_usage_metrics; -- Deve retornar apenas suas próprias

-- Como admin, deve ver todas:
-- (configurar role='admin' no user metadata primeiro)
```

## ✅ Checklist de Validação

- [ ] Tabela `gemini_usage_metrics` criada com sucesso
- [ ] Função `calculateGeminiCosts` retorna valores corretos
- [ ] Edge Function salva métricas após cada request
- [ ] Token counts são capturados corretamente  
- [ ] Custos são calculados baseados no modelo usado
- [ ] RLS funciona (usuários veem apenas suas métricas)
- [ ] Funções de agregação funcionam
- [ ] Performance não foi impactada significativamente

## 🐛 Problemas Conhecidos & Soluções

### Token Count Zerado
- **Problema**: `usageMetadata` retorna 0 tokens
- **Solução**: Verificar versão do Gemini SDK, pode ser propriedade diferente

### Erro de Permissão RLS  
- **Problema**: Edge Function não consegue inserir métricas
- **Solução**: Usar `service_role` key para inserção de métricas

### Performance Impact
- **Problema**: Logging de métricas causa lentidão
- **Solução**: Fazer logging assíncrono sem bloquear resposta

### Custo Calculation Error
- **Problema**: Erro ao calcular custos para modelo desconhecido
- **Solução**: Fallback para Flash model + log de warning

## 📊 Métricas de Sucesso

Após implementação, devemos ver:

1. **Custo por request**: ~$0.001-0.005 para queries típicas
2. **Tempo de logging**: <50ms adicional por request
3. **Precisão**: 100% dos requests com métricas capturadas
4. **Zero erros** relacionados a logging de métricas

## 🔄 Próximos Passos

Após validação básica:
1. Implementar dashboard frontend
2. Configurar alertas automáticos  
3. Otimização de performance
4. Relatórios automatizados