import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { ChatSidebar } from "@/components/ChatSidebar";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Send, Loader2 } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { MessageActions } from "@/components/MessageActions";
import { ThemeToggle } from "@/components/ThemeToggle";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import logo from "@/assets/jardulli-logo.png";

interface Message {
  id: string;
  role: "user" | "assistant";
  content: string;
  created_at: string;
}

const Index = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [loading, setLoading] = useState(true);
  const [currentConversationId, setCurrentConversationId] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputMessage, setInputMessage] = useState("");
  const [sending, setSending] = useState(false);
  const [userQuestions, setUserQuestions] = useState<{ [key: string]: string }>({});
  const [refreshSidebar, setRefreshSidebar] = useState(0);

  useEffect(() => {
    checkAuth();
  }, []);

  useEffect(() => {
    if (currentConversationId) {
      fetchMessages();
      subscribeToMessages();
    }
  }, [currentConversationId]);

  const checkAuth = async () => {
    const { data: { session } } = await supabase.auth.getSession();
    
    if (!session) {
      navigate("/auth");
      return;
    }

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (!session) {
        navigate("/auth");
      }
    });

    setLoading(false);

    return () => {
      subscription.unsubscribe();
    };
  };

  const fetchMessages = async () => {
    if (!currentConversationId) return;

    const { data, error } = await supabase
      .from("messages")
      .select("*")
      .eq("conversation_id", currentConversationId)
      .order("created_at", { ascending: true });

    if (error) {
      console.error("Error fetching messages:", error);
      return;
    }

    setMessages((data || []) as Message[]);
  };

  const subscribeToMessages = () => {
    if (!currentConversationId) return;

    const channel = supabase
      .channel("messages")
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "messages",
          filter: `conversation_id=eq.${currentConversationId}`,
        },
        (payload) => {
          setMessages((prev) => [...prev, payload.new as Message]);
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  };

  const createNewConversation = async () => {
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) return;

    const { data, error } = await supabase
      .from("conversations")
      .insert({
        user_id: user.id,
        title: "Nova Conversa",
      })
      .select()
      .single();

    if (error) {
      toast({
        title: "Erro",
        description: "Não foi possível criar uma nova conversa",
        variant: "destructive",
      });
      return;
    }

    setCurrentConversationId(data.id);
    setMessages([]);
    // Forçar refresh da sidebar
    setRefreshSidebar(prev => prev + 1);
  };

  const handleSelectConversation = (id: string) => {
    setCurrentConversationId(id);
  };

  const handleSendMessage = async () => {
    if (!inputMessage.trim() || sending) return;

    const userMessage = inputMessage.trim();
    setInputMessage("");
    setSending(true);

    try {
      // Obtém sessão do usuário
      const { data: { session } } = await supabase.auth.getSession();
      
      if (!session?.user?.id) {
        throw new Error("Usuário não autenticado");
      }

      // Se não houver conversa, cria automaticamente
      let conversationId = currentConversationId;
      if (!conversationId) {
        const { data: newConv, error: convError } = await supabase
          .from("conversations")
          .insert({
            user_id: session.user.id,
            title: userMessage.slice(0, 50),
          })
          .select()
          .single();

        if (convError) throw convError;
        
        conversationId = newConv.id;
        setCurrentConversationId(conversationId);
      }

      // Chama Edge Function de IA
      const { data: aiData, error: aiError } = await supabase.functions.invoke(
        'ai-chat',
        {
          body: {
            message: userMessage,
            conversationId: conversationId,
            userId: session.user.id
          }
        }
      );

      if (aiError) {
        console.error("Erro ao chamar Edge Function:", aiError);
        
        // Debug: ver resposta completa
        try {
          const debugResponse = await fetch(
            `https://gplumtfxxhgckjkgloni.supabase.co/functions/v1/ai-chat`,
            {
              method: 'POST',
              headers: {
                'Authorization': `Bearer ${session.access_token}`,
                'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbHVtdGZ4eGhnY2tqa2dsb25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3ODU0MTYsImV4cCI6MjA3NjM2MTQxNn0.bGuIT3tLN5rNgvalJD9C8G6tN6FPqfuO2Zez64-ceqg',
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                message: userMessage,
                conversationId: conversationId,
                userId: session.user.id
              })
            }
          );
          const debugText = await debugResponse.text();
          console.error("🔍 Erro detalhado:", debugText);
        } catch (e) {}
        
        throw aiError;
      }

      if (!aiData?.success) {
        throw new Error(aiData?.error || "Erro ao processar mensagem");
      }

      // Edge Function já salvou as mensagens no banco
      // Realtime vai atualizar a UI automaticamente

      // Mapeia pergunta para resposta (para feedback)
      const assistantMessages = messages.filter(m => m.role === 'assistant');
      if (assistantMessages.length > 0) {
        const lastAssistantMsg = assistantMessages[assistantMessages.length - 1];
        setUserQuestions((prev) => ({
          ...prev,
          [lastAssistantMsg.id]: userMessage,
        }));
      }

      // Atualiza título da conversa com primeira mensagem (se não foi definido na criação)
      if (messages.length === 0 && currentConversationId) {
        await supabase
          .from("conversations")
          .update({ title: userMessage.slice(0, 50) })
          .eq("id", conversationId);
      }

    } catch (error: any) {
      console.error("Erro ao enviar mensagem:", error);
      
      // Tratamento especial para diferentes tipos de erro
      if (error.message?.includes("limite") || error.message?.includes("rate limit")) {
        toast({
          title: "Limite de mensagens atingido",
          description: "Você atingiu o limite de 20 mensagens por hora. Tente novamente mais tarde.",
          variant: "destructive",
          duration: 5000,
        });
      } else if (error.message?.includes("quota") || error.message?.includes("429") || error.message?.includes("Too Many Requests")) {
        toast({
          title: "Sistema temporariamente ocupado",
          description: "Muitas pessoas estão usando o sistema agora. Por favor, aguarde alguns segundos e tente novamente.",
          variant: "destructive",
          duration: 5000,
        });
      } else if (error.message?.includes("temporariamente ocupado")) {
        toast({
          title: "Sistema ocupado",
          description: "Por favor, aguarde alguns segundos e tente novamente.",
          variant: "destructive",
          duration: 3000,
        });
      } else {
        toast({
          title: "Erro ao processar mensagem",
          description: error.message || "Não foi possível enviar a mensagem. Tente novamente.",
          variant: "destructive",
        });
      }
    } finally {
      setSending(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="flex h-screen w-full overflow-hidden">
      <ChatSidebar
        currentConversationId={currentConversationId}
        onSelectConversation={handleSelectConversation}
        onNewConversation={createNewConversation}
        refreshTrigger={refreshSidebar}
      />

      <div className="flex-1 flex flex-col">
        <header className="h-16 border-b border-border bg-background px-6 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <img src={logo} alt="Jardulli Máquinas" className="h-10 object-contain" />
            <div>
              <h1 className="text-lg font-semibold text-foreground">Assistente IA</h1>
              <p className="text-sm text-muted-foreground">Jardulli Máquinas</p>
            </div>
          </div>
          <ThemeToggle />
        </header>

        {!currentConversationId ? (
          <div className="flex-1 flex items-center justify-center">
            <div className="text-center space-y-4">
              <h2 className="text-2xl font-semibold text-foreground">
                Bem-vindo ao Assistente IA
              </h2>
              <p className="text-muted-foreground">
                Inicie uma nova conversa para começar
              </p>
              <Button onClick={createNewConversation} size="lg">
                Iniciar Conversa
              </Button>
            </div>
          </div>
        ) : (
          <>
            <ScrollArea className="flex-1 p-6">
              <div className="max-w-3xl mx-auto space-y-6">
                {messages.map((message) => (
                  <div
                    key={message.id}
                    className={`flex ${
                      message.role === "user" ? "justify-end" : "justify-start"
                    }`}
                  >
                    <div
                      className={`max-w-[80%] rounded-lg p-4 ${
                        message.role === "user"
                          ? "bg-primary text-primary-foreground"
                          : "bg-card border border-border"
                      }`}
                    >
                      {message.role === "assistant" ? (
                        <div className="prose prose-sm dark:prose-invert max-w-none">
                          <ReactMarkdown remarkPlugins={[remarkGfm]}>
                            {message.content}
                          </ReactMarkdown>
                        </div>
                      ) : (
                        <p className="whitespace-pre-wrap">{message.content}</p>
                      )}
                      {message.role === "assistant" && (
                        <MessageActions
                          messageId={message.id}
                          messageContent={message.content}
                          userQuestion={userQuestions[message.id] || ""}
                        />
                      )}
                    </div>
                  </div>
                ))}
                {sending && (
                  <div className="flex justify-start">
                    <div className="bg-card border border-border rounded-lg p-4">
                      <Loader2 className="h-5 w-5 animate-spin text-primary" />
                    </div>
                  </div>
                )}
              </div>
            </ScrollArea>

            <div className="border-t border-border p-4">
              <div className="max-w-3xl mx-auto flex gap-2">
                <Textarea
                  value={inputMessage}
                  onChange={(e) => setInputMessage(e.target.value)}
                  placeholder="Digite sua pergunta sobre a base de conhecimento..."
                  className="min-h-[60px] resize-none"
                  onKeyDown={(e) => {
                    if (e.key === "Enter" && !e.shiftKey) {
                      e.preventDefault();
                      handleSendMessage();
                    }
                  }}
                />
                <Button
                  onClick={handleSendMessage}
                  disabled={!inputMessage.trim() || sending}
                  size="icon"
                  className="h-[60px] w-[60px]"
                >
                  <Send className="h-5 w-5" />
                </Button>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default Index;