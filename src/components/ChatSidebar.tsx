import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import { PlusCircle, MessageSquare, LogOut } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useToast } from "@/hooks/use-toast";

interface Conversation {
  id: string;
  title: string;
  created_at: string;
}

interface ChatSidebarProps {
  currentConversationId: string | null;
  onSelectConversation: (id: string) => void;
  onNewConversation: () => void;
}

export const ChatSidebar = ({
  currentConversationId,
  onSelectConversation,
  onNewConversation,
}: ChatSidebarProps) => {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const navigate = useNavigate();
  const { toast } = useToast();

  useEffect(() => {
    fetchConversations();
  }, []);

  const fetchConversations = async () => {
    const { data, error } = await supabase
      .from("conversations")
      .select("*")
      .order("updated_at", { ascending: false });

    if (error) {
      console.error("Error fetching conversations:", error);
      return;
    }

    setConversations(data || []);
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
    toast({
      title: "Logout realizado",
      description: "Até logo!",
    });
    navigate("/auth");
  };

  return (
    <div className="w-64 bg-sidebar border-r border-sidebar-border flex flex-col h-screen">
      <div className="p-4 border-b border-sidebar-border">
        <Button
          onClick={onNewConversation}
          className="w-full justify-start gap-2"
          variant="default"
        >
          <PlusCircle className="h-4 w-4" />
          Nova Conversa
        </Button>
      </div>

      <ScrollArea className="flex-1 p-2">
        <div className="space-y-1">
          {conversations.map((conv) => (
            <Button
              key={conv.id}
              onClick={() => onSelectConversation(conv.id)}
              variant={currentConversationId === conv.id ? "secondary" : "ghost"}
              className="w-full justify-start gap-2 text-left"
            >
              <MessageSquare className="h-4 w-4 flex-shrink-0" />
              <span className="truncate">{conv.title}</span>
            </Button>
          ))}
        </div>
      </ScrollArea>

      <div className="p-4 border-t border-sidebar-border">
        <Button
          onClick={handleLogout}
          variant="ghost"
          className="w-full justify-start gap-2"
        >
          <LogOut className="h-4 w-4" />
          Sair
        </Button>
      </div>
    </div>
  );
};