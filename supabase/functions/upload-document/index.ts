import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleGenerativeAI, GoogleAIFileManager } from "https://esm.sh/@google/generative-ai@0.21.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { fileName, fileUrl } = await req.json();

    if (!fileName || !fileUrl) {
      return new Response(
        JSON.stringify({ error: "fileName e fileUrl são obrigatórios" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`📥 Processando: ${fileName}`);

    // 1. Baixa arquivo do Supabase Storage
    const { data: fileData, error: downloadError } = await supabase.storage
      .from("documentos")
      .download(fileUrl);

    if (downloadError || !fileData) {
      console.error("Erro ao baixar arquivo:", downloadError);
      return new Response(
        JSON.stringify({ error: "Erro ao baixar arquivo do Storage" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Calcula hash SHA-256 usando Web Crypto API
    const arrayBuffer = await fileData.arrayBuffer();
    const hashBuffer = await crypto.subtle.digest("SHA-256", arrayBuffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const hash = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");

    console.log(`🔐 Hash calculado: ${hash.substring(0, 16)}...`);

    // 3. Verifica se já existe no cache
    const { data: cached, error: cacheError } = await supabase
      .from("gemini_file_cache")
      .select("*")
      .eq("file_hash", hash)
      .single();

    if (cached && !cacheError) {
      console.log(`✅ Cache HIT: ${fileName}`);
      return new Response(
        JSON.stringify({
          success: true,
          cached: true,
          file: {
            name: cached.gemini_name,
            uri: cached.gemini_uri,
            displayName: cached.display_name,
            mimeType: cached.mime_type,
          },
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`📤 Cache MISS: Enviando para Gemini...`);

    // 4. Upload para Gemini File API
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiApiKey) {
      return new Response(
        JSON.stringify({ error: "GEMINI_API_KEY não configurada" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const fileManager = new GoogleAIFileManager(geminiApiKey);
    
    // Converter arrayBuffer para File object
    const file = new File([arrayBuffer], fileName, { type: fileData.type || "text/markdown" });

    const uploadResult = await fileManager.uploadFile(file, {
      displayName: fileName,
    });

    if (!uploadResult?.file?.name) {
      throw new Error("Upload não retornou 'name' válido");
    }

    console.log(`⏳ Aguardando processamento...`);

    // 5. Aguarda processamento do arquivo (polling)
    let geminiFile = await fileManager.getFile(uploadResult.file.name);
    let attempts = 0;
    const maxAttempts = 30; // 30 * 2s = 60s timeout

    while (geminiFile.state === "PROCESSING" && attempts < maxAttempts) {
      await new Promise((r) => setTimeout(r, 2000)); // Aguarda 2 segundos
      geminiFile = await fileManager.getFile(uploadResult.file.name);
      attempts++;
      console.log(`⏳ Tentativa ${attempts}/${maxAttempts} - Estado: ${geminiFile.state}`);
    }

    if (geminiFile.state === "FAILED") {
      throw new Error(`Processamento falhou: ${fileName}`);
    }

    if (geminiFile.state === "PROCESSING") {
      throw new Error(`Timeout: arquivo ainda processando após 60s`);
    }

    if (!geminiFile?.name || !geminiFile?.uri) {
      throw new Error("Arquivo processado mas sem 'name' ou 'uri'");
    }

    console.log(`✅ Arquivo processado: ${geminiFile.name}`);

    // 6. Salva no cache
    const { error: insertError } = await supabase
      .from("gemini_file_cache")
      .insert({
        file_hash: hash,
        gemini_name: geminiFile.name,
        gemini_uri: geminiFile.uri,
        mime_type: fileData.type,
        display_name: fileName,
        original_path: fileUrl,
        file_size_bytes: arrayBuffer.byteLength,
      });

    if (insertError) {
      console.error("Erro ao salvar cache:", insertError);
      // Não falhamos aqui, pois o upload foi bem-sucedido
    }

    console.log(`💾 Salvo no cache`);

    return new Response(
      JSON.stringify({
        success: true,
        cached: false,
        file: {
          name: geminiFile.name,
          uri: geminiFile.uri,
          displayName: fileName,
          mimeType: fileData.type,
        },
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("❌ Erro:", error);
    const errorMessage = error instanceof Error ? error.message : "Erro ao processar upload";
    const errorDetails = error instanceof Error ? error.toString() : String(error);
    
    return new Response(
      JSON.stringify({
        error: errorMessage,
        details: errorDetails,
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
