import { useState } from "react";
import { Button } from "@/components/ui/button";
import { useToast } from "@/hooks/use-toast";
import {
  Copy,
  ThumbsUp,
  ThumbsDown,
  Share2,
  Mail,
  MessageCircle,
} from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { supabase } from "@/integrations/supabase/client";

interface MessageActionsProps {
  messageId: string;
  messageContent: string;
  userQuestion: string;
}

export const MessageActions = ({
  messageId,
  messageContent,
  userQuestion,
}: MessageActionsProps) => {
  const { toast } = useToast();
  const [showFeedbackDialog, setShowFeedbackDialog] = useState(false);
  const [feedbackComment, setFeedbackComment] = useState("");
  const [sendingFeedback, setSendingFeedback] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(messageContent);
    toast({
      title: "Copiado!",
      description: "Resposta copiada para a área de transferência",
    });
  };

  const handlePositiveFeedback = async () => {
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) return;

    const { error } = await supabase.from("message_feedback").insert({
      message_id: messageId,
      user_id: user.id,
      feedback_type: "positive",
    });

    if (error) {
      toast({
        title: "Erro",
        description: "Não foi possível registrar o feedback",
        variant: "destructive",
      });
      return;
    }

    toast({
      title: "Obrigado!",
      description: "Seu feedback foi registrado",
    });
  };

  const handleNegativeFeedback = () => {
    setShowFeedbackDialog(true);
  };

  const handleSubmitNegativeFeedback = async () => {
    setSendingFeedback(true);

    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      setSendingFeedback(false);
      return;
    }

    const { error: feedbackError } = await supabase.from("message_feedback").insert({
      message_id: messageId,
      user_id: user.id,
      feedback_type: "negative",
      comment: feedbackComment,
    });

    if (feedbackError) {
      toast({
        title: "Erro",
        description: "Não foi possível registrar o feedback",
        variant: "destructive",
      });
      setSendingFeedback(false);
      return;
    }

    const { error: whatsappError } = await supabase.functions.invoke("send-whatsapp-feedback", {
      body: {
        question: userQuestion,
        answer: messageContent,
        comment: feedbackComment,
      },
    });

    setSendingFeedback(false);

    if (whatsappError) {
      console.error("WhatsApp error:", whatsappError);
    }

    toast({
      title: "Feedback enviado!",
      description: "Obrigado por nos ajudar a melhorar",
    });

    setShowFeedbackDialog(false);
    setFeedbackComment("");
  };

  const handleShareWhatsApp = () => {
    const text = encodeURIComponent(messageContent);
    window.open(`https://wa.me/?text=${text}`, "_blank");
  };

  const handleShareEmail = () => {
    const subject = encodeURIComponent("Resposta do Assistente Jardulli");
    const body = encodeURIComponent(messageContent);
    window.location.href = `mailto:?subject=${subject}&body=${body}`;
  };

  return (
    <>
      <div className="flex items-center gap-2 mt-3 pt-3 border-t border-border">
        <Button
          variant="ghost"
          size="sm"
          onClick={handleCopy}
          className="gap-1.5"
        >
          <Copy className="h-3.5 w-3.5" />
          Copiar
        </Button>

        <Button
          variant="ghost"
          size="sm"
          onClick={handlePositiveFeedback}
          className="gap-1.5"
        >
          <ThumbsUp className="h-3.5 w-3.5" />
          Bom
        </Button>

        <Button
          variant="ghost"
          size="sm"
          onClick={handleNegativeFeedback}
          className="gap-1.5"
        >
          <ThumbsDown className="h-3.5 w-3.5" />
          Ruim
        </Button>

        <div className="ml-auto flex gap-2">
          <Button
            variant="ghost"
            size="sm"
            onClick={handleShareWhatsApp}
            className="gap-1.5"
          >
            <MessageCircle className="h-3.5 w-3.5" />
            WhatsApp
          </Button>

          <Button
            variant="ghost"
            size="sm"
            onClick={handleShareEmail}
            className="gap-1.5"
          >
            <Mail className="h-3.5 w-3.5" />
            Email
          </Button>
        </div>
      </div>

      <Dialog open={showFeedbackDialog} onOpenChange={setShowFeedbackDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Feedback sobre a resposta</DialogTitle>
            <DialogDescription>
              Por favor, descreva o que poderia ser melhorado nesta resposta.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <Textarea
              placeholder="Descreva o motivo da não conformidade..."
              value={feedbackComment}
              onChange={(e) => setFeedbackComment(e.target.value)}
              rows={4}
            />
            <Button
              onClick={handleSubmitNegativeFeedback}
              disabled={!feedbackComment.trim() || sendingFeedback}
              className="w-full"
            >
              {sendingFeedback ? "Enviando..." : "Enviar Feedback"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
};