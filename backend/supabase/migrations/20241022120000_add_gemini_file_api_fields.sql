-- Adiciona campos para Gemini File API
-- Executa: supabase db push (ou supabase migration new add_gemini_file_api_fields)

ALTER TABLE gemini_file_cache 
ADD COLUMN IF NOT EXISTS gemini_file_state text DEFAULT 'NOT_UPLOADED',
ADD COLUMN IF NOT EXISTS file_hash_sha256 text,
ADD COLUMN IF NOT EXISTS processed_at timestamp,
ADD COLUMN IF NOT EXISTS error_message text;