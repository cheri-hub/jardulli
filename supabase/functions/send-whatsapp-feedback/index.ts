import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { question, answer, comment } = await req.json();

    const phoneNumber = "5519982121616"; // (19) 98212-1616
    
    const message = `🔴 FEEDBACK NEGATIVO - Jardulli IA

📝 Pergunta do usuário:
${question}

🤖 Resposta da IA:
${answer}

💬 Comentário do usuário:
${comment}

⏰ Data/Hora: ${new Date().toLocaleString("pt-BR")}`;

    const encodedMessage = encodeURIComponent(message);
    const whatsappUrl = `https://wa.me/${phoneNumber}?text=${encodedMessage}`;

    // Log the feedback for admin review
    console.log("Negative feedback received:", {
      question,
      answer,
      comment,
      timestamp: new Date().toISOString(),
    });

    return new Response(
      JSON.stringify({ 
        success: true, 
        whatsappUrl,
        message: "Feedback logged successfully" 
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("Error in send-whatsapp-feedback:", error);
    
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    
    return new Response(
      JSON.stringify({ 
        error: errorMessage,
        success: false 
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});