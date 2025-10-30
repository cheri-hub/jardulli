import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};



serve(async (req) => {
  console.log("🚀 Edge Function upload-gemini-files iniciada");
  
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiApiKey) {
      throw new Error("GEMINI_API_KEY não configurada");
    }

    const body = await req.json();
    const { fileId } = body;

    if (!fileId) {
      return new Response(
        JSON.stringify({ error: "fileId é obrigatório" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Busca arquivo na tabela cache
    const { data: fileRecord, error: fetchError } = await supabase
      .from("gemini_file_cache")
      .select("*")
      .eq("id", fileId)
      .single();

    if (fetchError || !fileRecord) {
      throw new Error("Arquivo não encontrado na tabela cache");
    }

    // 2. Verifica se já foi processado
    if (fileRecord.gemini_file_state === "ACTIVE" && fileRecord.gemini_uri) {
      console.log(`✅ Arquivo ${fileRecord.display_name} já processado`);
      return new Response(
        JSON.stringify({
          success: true,
          message: "Arquivo já processado",
          gemini_uri: fileRecord.gemini_uri,
          gemini_name: fileRecord.gemini_name
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Baixa arquivo do storage
    console.log(`📥 Baixando ${fileRecord.original_path} do storage...`);
    const { data: fileData, error: downloadError } = await supabase
      .storage
      .from('documentos')
      .download(fileRecord.original_path);

    if (downloadError) {
      throw new Error(`Erro ao baixar arquivo: ${downloadError.message}`);
    }

    // 4. Calcula hash SHA256
    const arrayBuffer = await fileData.arrayBuffer();
    const hashBuffer = await crypto.subtle.digest("SHA-256", arrayBuffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const sha256Hash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    // 5. Verifica se arquivo com mesmo hash já existe
    const { data: existingFile } = await supabase
      .from("gemini_file_cache")
      .select("*")
      .eq("file_hash_sha256", sha256Hash)
      .eq("gemini_file_state", "ACTIVE")
      .limit(1)
      .single();

    if (existingFile && existingFile.id !== fileId) {
      console.log(`♻️ Reutilizando arquivo existente com mesmo hash`);
      
      await supabase
        .from("gemini_file_cache")
        .update({
          gemini_name: existingFile.gemini_name,
          gemini_uri: existingFile.gemini_uri,
          gemini_file_state: "ACTIVE",
          file_hash_sha256: sha256Hash,
          processed_at: new Date().toISOString()
        })
        .eq("id", fileId);

      return new Response(
        JSON.stringify({
          success: true,
          message: "Reutilizado arquivo existente",
          gemini_uri: existingFile.gemini_uri,
          gemini_name: existingFile.gemini_name
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Marca como processando
    await supabase
      .from("gemini_file_cache")
      .update({ 
        gemini_file_state: "PROCESSING",
        file_hash_sha256: sha256Hash 
      })
      .eq("id", fileId);

    // 6. Upload para Gemini usando formato multipart correto
    console.log(`📤 Fazendo upload para Gemini (${fileRecord.display_name})...`);
    
    // Create boundary for multipart
    const boundary = '----formdata-deno-' + Math.random().toString(36);
    
    // Build multipart body manually
    const textEncoder = new TextEncoder();
    
    // Metadata part
    const metadataPart = 
      `--${boundary}\r\n` +
      `Content-Disposition: form-data; name="metadata"\r\n` +
      `Content-Type: application/json; charset=utf-8\r\n\r\n` +
      `{"file": {"displayName": "${fileRecord.display_name}"}}\r\n`;
    
    // File part
    const filePart = 
      `--${boundary}\r\n` +
      `Content-Disposition: form-data; name="file"; filename="${fileRecord.display_name}"\r\n` +
      `Content-Type: ${fileRecord.mime_type}\r\n\r\n`;
    
    const endBoundary = `\r\n--${boundary}--\r\n`;
    
    // Combine all parts
    const metadataBytes = textEncoder.encode(metadataPart);
    const filePartBytes = textEncoder.encode(filePart);
    const endBoundaryBytes = textEncoder.encode(endBoundary);
    const fileBytes = new Uint8Array(arrayBuffer);
    
    // Calculate total length
    const totalLength = metadataBytes.length + filePartBytes.length + fileBytes.length + endBoundaryBytes.length;
    
    // Create complete multipart body
    const multipartBody = new Uint8Array(totalLength);
    let offset = 0;
    
    multipartBody.set(metadataBytes, offset);
    offset += metadataBytes.length;
    
    multipartBody.set(filePartBytes, offset);
    offset += filePartBytes.length;
    
    multipartBody.set(fileBytes, offset);
    offset += fileBytes.length;
    
    multipartBody.set(endBoundaryBytes, offset);

    // Upload with proper multipart content-type
    const uploadUrl = `https://generativelanguage.googleapis.com/upload/v1beta/files?key=${geminiApiKey}`;
    
    const uploadResponse = await fetch(uploadUrl, {
      method: 'POST',
      headers: {
        'Content-Type': `multipart/related; boundary=${boundary}`,
        'X-Goog-Upload-Protocol': 'multipart',
        'X-Goog-Upload-Command': 'upload, finalize',
        'Content-Length': multipartBody.length.toString(),
      },
      body: multipartBody,
    });

    if (!uploadResponse.ok) {
      const errorText = await uploadResponse.text();
      throw new Error(`Upload failed: ${uploadResponse.status} - ${errorText}`);
    }

    const uploaded = await uploadResponse.json();
    
    // Verificação de segurança
    if (!uploaded?.file?.name || !uploaded?.file?.uri) {
      throw new Error(`Upload não retornou dados válidos para "${fileRecord.display_name}"`);
    }

    console.log(`✅ Upload concluído: ${uploaded.file.name}`);
    console.log(`🔗 URI: ${uploaded.file.uri}`);
    console.log(`📊 Estado: ${uploaded.file.state}`);

    // O arquivo já está ACTIVE, não precisa aguardar processamento
    const getFile = uploaded.file;

    if (getFile.state === "FAILED") {
      await supabase
        .from("gemini_file_cache")
        .update({ 
          gemini_file_state: "FAILED",
          error_message: "Processamento falhou no Gemini"
        })
        .eq("id", fileId);
      
      throw new Error(`Processamento de arquivo falhou: ${fileRecord.display_name}`);
    }

    // Verificação final de segurança
    if (!getFile?.name || !getFile?.uri) {
      throw new Error(
        `Arquivo "${fileRecord.display_name}" processado, mas sem 'name' ou 'uri' retornados.`
      );
    }

    // 8. Atualiza registro com dados do Gemini
    const { error: updateError } = await supabase
      .from("gemini_file_cache")
      .update({
        gemini_name: getFile.name,
        gemini_uri: getFile.uri,
        gemini_file_state: "ACTIVE", 
        processed_at: new Date().toISOString(),
        error_message: null
      })
      .eq("id", fileId);

    if (updateError) {
      console.error("Erro ao atualizar registro:", updateError);
    }

    console.log(`✅ Arquivo ${fileRecord.display_name} processado com sucesso!`);
    console.log(`📍 Gemini URI: ${getFile.uri}`);
    console.log(`🏷️ Gemini Name: ${getFile.name}`);

    return new Response(
      JSON.stringify({
        success: true,
        message: "Arquivo enviado e processado com sucesso",
        gemini_uri: getFile.uri,
        gemini_name: getFile.name,
        file_state: getFile.state,
        display_name: fileRecord.display_name
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error: any) {
    console.error("❌ Erro:", error);
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "Erro interno do servidor"
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      }
    );
  }
});