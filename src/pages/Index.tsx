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
  };

  const handleSelectConversation = (id: string) => {
    setCurrentConversationId(id);
  };

  const handleSendMessage = async () => {
    if (!inputMessage.trim() || !currentConversationId || sending) return;

    const userMessage = inputMessage;
    setInputMessage("");
    setSending(true);

    const { data: userMsg, error: userError } = await supabase
      .from("messages")
      .insert({
        conversation_id: currentConversationId,
        role: "user",
        content: userMessage,
      })
      .select()
      .single();

    if (userError) {
      toast({
        title: "Erro",
        description: "Não foi possível enviar a mensagem",
        variant: "destructive",
      });
      setSending(false);
      return;
    }

    // Simulate AI response (replace with actual AI integration)
    setTimeout(async () => {
      const aiResponse = `Esta é uma resposta simulada para: "${userMessage}". Em produção, aqui seria integrada a IA com a Knowledge Base da Jardulli Máquinas.`;

      const { data: assistantMsg, error: assistantError } = await supabase
        .from("messages")
        .insert({
          conversation_id: currentConversationId,
          role: "assistant",
          content: aiResponse,
        })
        .select()
        .single();

      if (!assistantError && assistantMsg) {
        setUserQuestions((prev) => ({
          ...prev,
          [assistantMsg.id]: userMessage,
        }));
      }

      // Update conversation title with first message
      if (messages.length === 0) {
        await supabase
          .from("conversations")
          .update({ title: userMessage.slice(0, 50) })
          .eq("id", currentConversationId);
      }

      setSending(false);
    }, 1500);
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
                      <p className="whitespace-pre-wrap">{message.content}</p>
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