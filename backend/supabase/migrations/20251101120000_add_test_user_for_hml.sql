-- Temporary fix for testing: Make user_id foreign key constraint deferrable for testing
-- This allows us to test metrics without requiring existing users

-- Temporarily drop the constraint
ALTER TABLE public.gemini_usage_metrics 
DROP CONSTRAINT gemini_usage_metrics_user_id_fkey;

-- Add it back as deferrable (can be deferred within a transaction)
ALTER TABLE public.gemini_usage_metrics 
ADD CONSTRAINT gemini_usage_metrics_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

-- Insert a test user directly for testing purposes (HML only)
INSERT INTO auth.users (id, instance_id, email, created_at, updated_at, email_confirmed_at, raw_user_meta_data)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000', -- default instance
  'teste@jardulli.hml',
  NOW(),
  NOW(),
  NOW(),
  '{"role": "test_user", "name": "Usuario Teste HML"}'::jsonb
) ON CONFLICT (id) DO NOTHING;