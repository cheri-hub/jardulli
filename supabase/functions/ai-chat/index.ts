import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.21.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  console.log("🚀 Edge Function ai-chat iniciada");
  
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    console.log("📥 Requisição recebida");
    
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    console.log("✅ Supabase client criado");

    const body = await req.json();
    console.log("📦 Body recebido:", JSON.stringify(body));
    
    const { message, conversationId, userId } = body;

    if (!message || !userId) {
      return new Response(
        JSON.stringify({
          error: "message e userId são obrigatórios",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`💬 Mensagem de usuário ${userId}: ${message.substring(0, 50)}...`);

    // 1. Verifica rate limiting
    console.log("🔍 Verificando rate limit...");
    const { data: rateLimitCheck, error: rateLimitError } = await supabase.rpc("check_rate_limit", {
      uid: userId,
      max_messages: 20,
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
        return new Response(
          JSON.stringify({
            error:
              "Você atingiu o limite de 20 mensagens por hora. Tente novamente mais tarde.",
            rateLimitExceeded: true,
          }),
          {
            status: 429,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      console.log(`✅ Rate limit OK. Mensagens restantes: ${remaining}`);
    }

    // 2. Busca arquivos em cache e lê conteúdo do storage
    const { data: cachedFiles, error: cacheError } = await supabase
      .from("gemini_file_cache")
      .select("original_path, display_name, mime_type");

    if (cacheError) {
      console.error("Erro ao buscar cache:", cacheError);
    }

    console.log(`📚 ${cachedFiles?.length || 0} arquivo(s) na base de conhecimento`);

    // 3. Lê conteúdo dos arquivos do storage
    let documentsContent = "";
    
    if (cachedFiles && cachedFiles.length > 0) {
      console.log(`📄 Lendo conteúdo dos documentos...`);
      
      for (const file of cachedFiles) {
        try {
          // Busca arquivo do storage bucket "documentos"
          const { data: fileData, error: downloadError } = await supabase
            .storage
            .from('documentos')
            .download(file.original_path);

          if (downloadError) {
            console.error(`Erro ao baixar ${file.display_name}:`, downloadError);
            continue;
          }

          // Converte blob para texto
          const text = await fileData.text();
          documentsContent += `\n\n=== DOCUMENTO: ${file.display_name} ===\n${text}\n=== FIM DO DOCUMENTO ===\n`;
          
          console.log(`✅ Documento ${file.display_name} carregado (${text.length} caracteres)`);
        } catch (error) {
          console.error(`Erro ao processar ${file.display_name}:`, error);
        }
      }
    }

    // 4. Busca histórico da conversa (últimas 10 mensagens)
    let messageHistory = [];
    
    if (conversationId) {
      const { data, error: historyError } = await supabase
        .from("messages")
        .select("role, content")
        .eq("conversation_id", conversationId)
        .order("created_at", { ascending: true })
        .limit(10);

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
- Especializada em máquinas de café profissionais
- Atua em vendas, locação, assistência técnica e suporte
- Atende diversos segmentos: escritórios, cafeterias, eventos

INSTRUÇÕES IMPORTANTES:
- Responda APENAS com base nos documentos fornecidos
- Se não souber, seja honesto e diga: "Não encontrei essa informação em nossa base de conhecimento"
- Sugira sempre o contato: (19) 98212-1616
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
      return new Response(
        JSON.stringify({ error: "GEMINI_API_KEY não configurada" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const genAI = new GoogleGenerativeAI(geminiApiKey);
    const modelName = Deno.env.get("GEMINI_MODEL") || "gemini-2.0-flash-exp";
    const model = genAI.getGenerativeModel({ model: modelName });

    // 7. Monta prompt com conteúdo dos documentos incluído
    let enhancedSystemPrompt = systemPrompt;
    
    if (documentsContent) {
      enhancedSystemPrompt += `\n\n📚 BASE DE CONHECIMENTO:\n${documentsContent}\n\nIMPORTANTE: Use APENAS as informações dos documentos acima para responder. Se a informação não estiver nos documentos, diga que não encontrou.`;
    }

    const contents = [
      // Sistema - instrução inicial com documentos
      { 
        role: "user", 
        parts: [{ text: enhancedSystemPrompt }] 
      },
      {
        role: "model",
        parts: [{ text: "Entendido! Vou responder apenas com base nos documentos fornecidos." }],
      },
      // Histórico de mensagens
      ...(messageHistory || []).map((msg: any) => ({
        role: msg.role === "assistant" ? "model" : "user",
        parts: [{ text: msg.content }],
      })),
      // Nova pergunta
      {
        role: "user",
        parts: [{ text: message }],
      },
    ];

    console.log(`🤖 Chamando Gemini com ${contents.length} mensagens...`);
    console.log(`📝 Contents:`, JSON.stringify(contents, null, 2));

    // 8. Chama Gemini
    const result = await model.generateContent({
      contents,
      generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      },
    });

    const response = result.response;
    const aiResponse = response.text() ||
      "Desculpe, não consegui processar sua pergunta. Por favor, tente novamente.";

    console.log(`✅ Resposta gerada: ${aiResponse.substring(0, 100)}...`);

    // 9. Salva mensagens no banco (user + assistant) - apenas se houver conversationId
    if (conversationId) {
      const { error: insertError } = await supabase.from("messages").insert([
        {
          conversation_id: conversationId,
          role: "user",
          content: message,
        },
        {
          conversation_id: conversationId,
          role: "assistant",
          content: aiResponse,
        },
      ]);

      if (insertError) {
        console.error("Erro ao salvar mensagens:", insertError);
      }
    } else {
      console.warn("⚠️ ConversationId não fornecido, mensagens não foram salvas");
    }

    if (false) { // Placeholder para manter estrutura do código
      console.error("Erro ao salvar mensagens:", null);
      // Não retornamos erro aqui pois a resposta foi gerada
    }

    // 10. Incrementa rate limiting
    await supabase.rpc("increment_rate_limit", { uid: userId });

    console.log(`💾 Mensagens salvas e rate limit atualizado`);

    return new Response(
      JSON.stringify({
        success: true,
        reply: aiResponse,
        conversationId,
        sourcesCount: cachedFiles?.length || 0,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error: any) {
    console.error("❌ Erro completo:", error);
    console.error("❌ Stack:", error?.stack);
    console.error("❌ Message:", error?.message);
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error?.message || "Erro ao processar mensagem",
        details: error?.toString(),
        stack: error?.stack,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
