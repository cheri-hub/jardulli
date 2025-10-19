-- Create storage bucket for documents
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documentos',
  'documentos',
  false,
  10485760, -- 10MB in bytes
  ARRAY['application/pdf', 'text/plain', 'text/markdown']::text[]
)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Service role can upload to documentos" ON storage.objects;
DROP POLICY IF EXISTS "Service role can download from documentos" ON storage.objects;
DROP POLICY IF EXISTS "Service role can update documentos" ON storage.objects;
DROP POLICY IF EXISTS "Service role can delete from documentos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can list documentos" ON storage.objects;

-- Service role can upload files
CREATE POLICY "Service role can upload to documentos"
ON storage.objects FOR INSERT
TO service_role
WITH CHECK (bucket_id = 'documentos');

-- Service role can download files
CREATE POLICY "Service role can download from documentos"
ON storage.objects FOR SELECT
TO service_role
USING (bucket_id = 'documentos');

-- Service role can update files
CREATE POLICY "Service role can update documentos"
ON storage.objects FOR UPDATE
TO service_role
USING (bucket_id = 'documentos');

-- Service role can delete files
CREATE POLICY "Service role can delete from documentos"
ON storage.objects FOR DELETE
TO service_role
USING (bucket_id = 'documentos');

-- Authenticated users can list files (read-only)
CREATE POLICY "Authenticated users can list documentos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'documentos');
