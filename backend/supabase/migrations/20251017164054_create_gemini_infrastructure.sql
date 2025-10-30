-- Migration: Infraestrutura para integração Google Gemini
-- Criado em: 2025-10-17
-- Descrição: Cria tabelas para cache de arquivos Gemini e rate limiting

-- ============================================
-- 1. TABELA DE CACHE DE ARQUIVOS DO GEMINI
-- ============================================
-- Armazena metadados de arquivos já enviados para Gemini File API
-- Evita reupload de arquivos através de hash SHA256

CREATE TABLE IF NOT EXISTS public.gemini_file_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_hash TEXT NOT NULL UNIQUE,
  gemini_name TEXT NOT NULL,
  gemini_uri TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  display_name TEXT NOT NULL,
  original_path TEXT NOT NULL,
  file_size_bytes BIGINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índice para busca rápida por hash
CREATE INDEX IF NOT EXISTS idx_gemini_cache_hash 
  ON public.gemini_file_cache(file_hash);

-- Índice para busca por caminho original
CREATE INDEX IF NOT EXISTS idx_gemini_cache_path 
  ON public.gemini_file_cache(original_path);

-- Comentários para documentação
COMMENT ON TABLE public.gemini_file_cache IS 
  'Cache de arquivos enviados para Google Gemini File API';
COMMENT ON COLUMN public.gemini_file_cache.file_hash IS 
  'Hash SHA256 do conteúdo do arquivo para detecção de duplicatas';
COMMENT ON COLUMN public.gemini_file_cache.gemini_name IS 
  'Nome do arquivo no Gemini (ex: files/abc123xyz)';
COMMENT ON COLUMN public.gemini_file_cache.gemini_uri IS 
  'URI completa do arquivo no Gemini File API';

-- ============================================
-- 2. TABELA DE RATE LIMITING
-- ============================================
-- Controla quantas mensagens cada usuário pode enviar por hora

CREATE TABLE IF NOT EXISTS public.user_rate_limit (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  message_count INT NOT NULL DEFAULT 0,
  window_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índice para consultas por janela de tempo
CREATE INDEX IF NOT EXISTS idx_rate_limit_window 
  ON public.user_rate_limit(window_start);

COMMENT ON TABLE public.user_rate_limit IS 
  'Controle de rate limiting: 20 mensagens por hora por usuário';
COMMENT ON COLUMN public.user_rate_limit.message_count IS 
  'Contador de mensagens na janela atual';
COMMENT ON COLUMN public.user_rate_limit.window_start IS 
  'Início da janela de 1 hora para contagem';

-- ============================================
-- 3. POLÍTICAS RLS (Row Level Security)
-- ============================================

-- RLS para gemini_file_cache
ALTER TABLE public.gemini_file_cache ENABLE ROW LEVEL SECURITY;

-- Apenas service role pode gerenciar cache de arquivos
CREATE POLICY "Service role full access on gemini_file_cache"
  ON public.gemini_file_cache
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');

-- Usuários autenticados podem ver o cache (read-only)
CREATE POLICY "Authenticated users can view gemini_file_cache"
  ON public.gemini_file_cache
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- RLS para user_rate_limit
ALTER TABLE public.user_rate_limit ENABLE ROW LEVEL SECURITY;

-- Usuários podem ver apenas seu próprio rate limit
CREATE POLICY "Users can view their own rate limit"
  ON public.user_rate_limit
  FOR SELECT
  USING (auth.uid() = user_id);

-- Service role tem acesso total
CREATE POLICY "Service role full access on user_rate_limit"
  ON public.user_rate_limit
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ============================================
-- 4. FUNÇÕES HELPER
-- ============================================

-- Função para atualizar timestamp updated_at automaticamente
CREATE OR REPLACE FUNCTION public.update_gemini_cache_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para gemini_file_cache
CREATE TRIGGER trigger_gemini_cache_updated_at
  BEFORE UPDATE ON public.gemini_file_cache
  FOR EACH ROW
  EXECUTE FUNCTION public.update_gemini_cache_updated_at();

-- Função para incrementar rate limit
CREATE OR REPLACE FUNCTION public.increment_rate_limit(uid UUID)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.user_rate_limit (user_id, message_count, window_start)
  VALUES (uid, 1, NOW())
  ON CONFLICT (user_id) 
  DO UPDATE SET 
    message_count = public.user_rate_limit.message_count + 1,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para verificar e resetar rate limit
CREATE OR REPLACE FUNCTION public.check_rate_limit(uid UUID, max_messages INT DEFAULT 20)
RETURNS TABLE(allowed BOOLEAN, remaining INT) AS $$
DECLARE
  current_count INT;
  window_start_time TIMESTAMPTZ;
  hours_passed NUMERIC;
BEGIN
  -- Busca dados do usuário
  SELECT message_count, window_start 
  INTO current_count, window_start_time
  FROM public.user_rate_limit 
  WHERE user_id = uid;
  
  -- Se usuário não existe, cria entrada
  IF NOT FOUND THEN
    INSERT INTO public.user_rate_limit (user_id, message_count, window_start)
    VALUES (uid, 0, NOW());
    RETURN QUERY SELECT true, max_messages;
    RETURN;
  END IF;
  
  -- Calcula tempo passado
  hours_passed := EXTRACT(EPOCH FROM (NOW() - window_start_time)) / 3600;
  
  -- Se passou mais de 1 hora, reseta contador
  IF hours_passed >= 1 THEN
    UPDATE public.user_rate_limit 
    SET message_count = 0, window_start = NOW(), updated_at = NOW()
    WHERE user_id = uid;
    RETURN QUERY SELECT true, max_messages;
    RETURN;
  END IF;
  
  -- Verifica se está dentro do limite
  IF current_count < max_messages THEN
    RETURN QUERY SELECT true, (max_messages - current_count - 1);
  ELSE
    RETURN QUERY SELECT false, 0;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.increment_rate_limit IS 
  'Incrementa contador de mensagens do usuário';
COMMENT ON FUNCTION public.check_rate_limit IS 
  'Verifica se usuário pode enviar mensagem (retorna allowed e remaining)';

-- ============================================
-- 5. GRANTS (Permissões)
-- ============================================

-- Service role precisa de acesso total
GRANT ALL ON public.gemini_file_cache TO service_role;
GRANT ALL ON public.user_rate_limit TO service_role;

-- Usuários autenticados podem executar funções
GRANT EXECUTE ON FUNCTION public.check_rate_limit TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_rate_limit TO service_role;
