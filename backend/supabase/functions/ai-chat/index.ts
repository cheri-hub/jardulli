import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.21.0";

// Import cost calculator
import { 
  calculateGeminiCosts, 
  createUsageMetrics,
  type GeminiModel 
} from "../shared/gemini-cost-calculator.ts";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};
serve(async (req)=>{
  console.log("🚀 Edge Function ai-chat iniciada");
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: corsHeaders
    });
  }
  try {
    console.log("📥 Requisição recebida");
    const supabase = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "");
    console.log("✅ Supabase client criado");
    const body = await req.json();
    console.log("📦 Body recebido:", JSON.stringify(body));
    const { message, conversationId, userId } = body;
    if (!message || !userId) {
      return new Response(JSON.stringify({
        error: "message e userId são obrigatórios"
      }), {
        status: 400,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        }
      });
    }
    console.log(`💬 Mensagem de usuário ${userId}: ${message.substring(0, 50)}...`);
    
    // Track request start time for metrics
    const requestStartTime = performance.now();
    
    // Check if we're in HML environment to skip rate limiting for testing
    const isHMLEnvironment = Deno.env.get("ENVIRONMENT") === "hml";
    
    if (!isHMLEnvironment) {
      // 1. Verifica rate limiting (only in production)
      console.log("🔍 Verificando rate limit...");
      const { data: rateLimitCheck, error: rateLimitError } = await supabase.rpc("check_rate_limit", {
        uid: userId,
        max_messages: 20
      });
      if (rateLimitError) {
        console.error("❌ Erro ao verificar rate limit:", rateLimitError);
        throw new Error(`Erro ao verificar rate limit: ${rateLimitError.message}`);
      }
      console.log("📊 Rate limit check resultado:", rateLimitCheck);
      if (rateLimitCheck && rateLimitCheck.length > 0) {
        const { allowed, remaining } = rateLimitCheck[0];
        if (!allowed) {
          console.log(`⛔ Rate limit excedido para usuário ${userId}`);
          return new Response(JSON.stringify({
            error: "Você atingiu o limite de 20 mensagens por hora. Tente novamente mais tarde.",
            rateLimitExceeded: true
          }), {
            status: 429,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json"
            }
          });
        }
        console.log(`✅ Rate limit OK. Mensagens restantes: ${remaining}`);
      }
    } else {
      console.log("🧪 Ambiente HML detectado - pulando verificação de rate limit");
    }
    // 2. Busca arquivos processados no Gemini File API
    const { data: cachedFiles, error: cacheError } = await supabase
      .from("gemini_file_cache")
      .select("id, display_name, gemini_name, gemini_uri, gemini_file_state, mime_type")
      .eq("gemini_file_state", "ACTIVE");
      
    if (cacheError) {
      console.error("Erro ao buscar cache:", cacheError);
    }
    
    console.log(`📚 ${cachedFiles?.length || 0} arquivo(s) processados no Gemini`);
    
    // 3. Prepara file parts para o Gemini (usando File API nativo)
    const fileParts = [];
    if (cachedFiles && cachedFiles.length > 0) {
      console.log(`� Preparando file parts para Gemini...`);
      
      for (const file of cachedFiles) {
        if (file.gemini_uri && file.mime_type) {
          // Cria part referenciando arquivo já processado no Gemini
          // Estrutura compatível com Gemini API v0.21.0
          fileParts.push({
            fileData: {
              fileUri: file.gemini_uri,
              mimeType: file.mime_type
            }
          });
          console.log(`✅ File part criado para ${file.display_name}`);
        } else {
          console.warn(`⚠️ Arquivo ${file.display_name} sem gemini_uri válido`);
        }
      }
    }
    // 4. Busca histórico da conversa (últimas 10 mensagens)
    let messageHistory = [];
    if (conversationId) {
      const { data, error: historyError } = await supabase.from("messages").select("role, content").eq("conversation_id", conversationId).order("created_at", {
        ascending: true
      }).limit(10);
      if (historyError) {
        console.error("Erro ao buscar histórico:", historyError);
      } else {
        messageHistory = data || [];
      }
    }
    console.log(`📜 ${messageHistory?.length || 0} mensagens no histórico`);
    // 5. Monta prompt do sistema
    const systemPrompt = `Você é o assistente virtual da Jardulli Máquinas.

CONTEXTO DA EMPRESA:
- Especializada em máquinas agrícolas

INSTRUÇÕES IMPORTANTES:
- Responda APENAS com base nos documentos fornecidos
- Se não souber, seja honesto e diga: "Não encontrei essa informação em nossa base de conhecimento"
- Use formatação markdown (listas, negrito, títulos)
- Seja profissional, mas acessível

FORMATO DA RESPOSTA:
- Use títulos e subtítulos quando apropriado
- Listas numeradas para etapas/processos
- Listas com marcadores para múltiplos itens
- **Negrito** para informações importantes
- Parágrafos curtos e objetivos

ESTILO:
- Evite jargões técnicos desnecessários
- Seja proativo: ofereça informações relacionadas
- Finalize sugerindo se pode ajudar com mais alguma coisa

NUNCA:
- Invente preços ou condições comerciais
- Garanta coisas que não estão nos documentos
- Responda perguntas não relacionadas à Jardulli`;
    // 6. Inicializa Gemini
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiApiKey) {
      return new Response(JSON.stringify({
        error: "GEMINI_API_KEY não configurada"
      }), {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        }
      });
    }
    const genAI = new GoogleGenerativeAI(geminiApiKey);
    const modelName = Deno.env.get("GEMINI_MODEL") || "gemini-2.0-flash-exp";
    const model = genAI.getGenerativeModel({
      model: modelName
    });
    // 7. Monta prompt usando Gemini File API (sem limitação de tokens!)
    let systemParts: any[] = [{ text: systemPrompt }];
    
    // Adiciona file parts se existirem arquivos processados
    if (fileParts.length > 0) {
      // File parts são adicionados junto com o texto do sistema
      systemParts = [
        { text: systemPrompt },
        ...fileParts,
        { text: "📚 IMPORTANTE: Use APENAS as informações dos documentos anexados para responder. Se a informação não estiver nos documentos, diga que não encontrou." }
      ];
      console.log(`📎 Incluindo ${fileParts.length} file parts no prompt`);
    } else {
      systemParts.push({ 
        text: "⚠️ Nenhum documento encontrado na base de conhecimento. Informe que a base está vazia e peça para o usuário entrar em contato." 
      });
    }

    const contents = [
      // Sistema - instrução inicial + file parts
      {
        role: "user",
        parts: systemParts
      },
      {
        role: "model",
        parts: [{ text: "Entendido! Vou responder apenas com base nos documentos fornecidos." }]
      },
      // Histórico de mensagens
      ...(messageHistory || []).map((msg)=>({
          role: msg.role === "assistant" ? "model" : "user",
          parts: [
            {
              text: msg.content
            }
          ]
        })),
      // Nova pergunta
      {
        role: "user",
        parts: [
          {
            text: message
          }
        ]
      }
    ];
    console.log(`🤖 Chamando Gemini com ${contents.length} mensagens...`);
    console.log(`📝 Contents:`, JSON.stringify(contents, null, 2));
    // 8. Chama Gemini com retry em caso de erro de quota
    let result;
    let retryCount = 0;
    const maxRetries = 3;
    while(retryCount < maxRetries){
      try {
        result = await model.generateContent({
          contents,
          generationConfig: {
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 1024
          }
        });
        break; // Sucesso, sai do loop
      } catch (error) {
        console.log(`❌ Erro na tentativa ${retryCount + 1}:`, error.message);
        // Se é erro de quota (429), aguarda e tenta novamente
        if (error.message?.includes('429') || error.message?.includes('quota')) {
          retryCount++;
          if (retryCount < maxRetries) {
            const waitTime = Math.pow(2, retryCount) * 1000; // Backoff exponencial
            console.log(`⏳ Aguardando ${waitTime}ms antes da próxima tentativa...`);
            await new Promise((resolve)=>setTimeout(resolve, waitTime));
            continue;
          } else {
            // Máximo de tentativas atingido, retorna erro amigável
            return new Response(JSON.stringify({
              success: false,
              error: "Sistema temporariamente ocupado. Por favor, aguarde alguns segundos e tente novamente.",
              details: "Rate limit exceeded - please try again in a few seconds"
            }), {
              status: 429,
              headers: {
                ...corsHeaders,
                "Content-Type": "application/json"
              }
            });
          }
        } else {
          // Outros erros, não tenta novamente
          throw error;
        }
      }
    }
    const response = result.response;
    const aiResponse = response.text() || "Desculpe, não consegui processar sua pergunta. Por favor, tente novamente.";
    console.log(`✅ Resposta gerada: ${aiResponse.substring(0, 100)}...`);

    // Capture metrics for cost tracking
    const requestEndTime = performance.now();
    const requestDuration = Math.round(requestEndTime - requestStartTime);
    
    // Get token usage from response metadata
    const usageMetadata = result.response.usageMetadata;
    const inputTokens = usageMetadata?.promptTokenCount || 0;
    const outputTokens = usageMetadata?.candidatesTokenCount || 0;
    
    console.log(`📊 Token usage - Input: ${inputTokens}, Output: ${outputTokens}, Duration: ${requestDuration}ms`);

    // Calculate costs and create metrics
    let metricsToLog = null;
    try {
      const currentModel = (modelName as GeminiModel) || 'gemini-1.5-flash';
      const costs = calculateGeminiCosts(currentModel, inputTokens, outputTokens);
      
      console.log(`💰 Cost calculation - Input: $${costs.inputCost}, Output: $${costs.outputCost}, Total: $${costs.totalCost}`);
      
      metricsToLog = {
        user_id: userId,
        conversation_id: conversationId,
        model_used: currentModel,
        tokens_input: inputTokens,
        tokens_output: outputTokens,
        cost_input_usd: costs.inputCost,
        cost_output_usd: costs.outputCost,
        request_duration_ms: requestDuration,
        files_processed: fileParts.length,
        request_type: 'chat',
        error_occurred: false,
        error_message: null
      };
      
    } catch (costError) {
      console.error("❌ Erro ao calcular custos:", costError);
    }

    // 9. Salva mensagens no banco (user + assistant) - apenas se houver conversationId
    if (conversationId) {
      const { error: insertError } = await supabase.from("messages").insert([
        {
          conversation_id: conversationId,
          role: "user",
          content: message
        },
        {
          conversation_id: conversationId,
          role: "assistant",
          content: aiResponse
        }
      ]);
      if (insertError) {
        console.error("Erro ao salvar mensagens:", insertError);
      }
    } else {
      console.warn("⚠️ ConversationId não fornecido, mensagens não foram salvas");
    }
    if (false) {
      console.error("Erro ao salvar mensagens:", null);
    // Não retornamos erro aqui pois a resposta foi gerada
    }
    // 10. Incrementa rate limiting (only in production)
    if (!isHMLEnvironment) {
      await supabase.rpc("increment_rate_limit", {
        uid: userId
      });
    } else {
      console.log("🧪 Ambiente HML detectado - pulando incremento de rate limit");
    }
    
    // 11. Log usage metrics for cost tracking
    if (metricsToLog) {
      try {
        console.log("📊 Salvando métricas de custo...");
        
        // For simplicity, especially in testing, we don't require message_id
        const finalMetrics = {
          ...metricsToLog,
          message_id: null, // Will be updated later if needed
          conversation_id: conversationId || null
        };

        console.log("📊 Dados das métricas:", JSON.stringify(finalMetrics, null, 2));

        const { error: metricsError } = await supabase
          .from("gemini_usage_metrics")
          .insert(finalMetrics);

        if (metricsError) {
          console.error("❌ Erro ao salvar métricas:", metricsError);
        } else {
          console.log(`✅ Métricas salvas com sucesso - Custo: $${metricsToLog.cost_input_usd + metricsToLog.cost_output_usd}`);
        }
      } catch (metricsError) {
        console.error("❌ Erro ao processar métricas:", metricsError);
      }
    }
    
    console.log(`💾 Mensagens salvas, rate limit atualizado e métricas registradas`);
    return new Response(JSON.stringify({
      success: true,
      reply: aiResponse,
      conversationId,
      sourcesCount: cachedFiles?.length || 0
    }), {
      status: 200,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      }
    });
  } catch (error) {
    console.error("❌ Erro completo:", error);
    console.error("❌ Stack:", error?.stack);
    console.error("❌ Message:", error?.message);
    return new Response(JSON.stringify({
      success: false,
      error: error?.message || "Erro ao processar mensagem",
      details: error?.toString(),
      stack: error?.stack
    }), {
      status: 500,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      }
    });
  }
});
