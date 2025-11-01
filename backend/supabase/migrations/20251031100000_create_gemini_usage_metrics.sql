-- Migration: Create Gemini Usage Metrics Infrastructure
-- Created: 2025-10-31
-- Purpose: Track Gemini API usage, costs, and performance metrics

-- Create enum for Gemini models
CREATE TYPE gemini_model AS ENUM ('gemini-1.5-flash', 'gemini-1.5-pro');

-- Create table for tracking Gemini API usage and costs
CREATE TABLE public.gemini_usage_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Foreign keys
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
  message_id UUID REFERENCES public.messages(id) ON DELETE CASCADE,
  
  -- Technical metrics
  model_used gemini_model NOT NULL DEFAULT 'gemini-1.5-flash',
  tokens_input INTEGER NOT NULL CHECK (tokens_input >= 0),
  tokens_output INTEGER NOT NULL CHECK (tokens_output >= 0),
  total_tokens INTEGER GENERATED ALWAYS AS (tokens_input + tokens_output) STORED,
  
  -- Financial metrics (in USD)
  cost_input_usd DECIMAL(10,6) NOT NULL CHECK (cost_input_usd >= 0),
  cost_output_usd DECIMAL(10,6) NOT NULL CHECK (cost_output_usd >= 0),
  total_cost_usd DECIMAL(10,6) GENERATED ALWAYS AS (cost_input_usd + cost_output_usd) STORED,
  
  -- Performance metrics
  request_duration_ms INTEGER CHECK (request_duration_ms >= 0),
  files_processed INTEGER NOT NULL DEFAULT 0 CHECK (files_processed >= 0),
  
  -- Additional context
  request_type TEXT DEFAULT 'chat', -- 'chat', 'file_processing', etc.
  error_occurred BOOLEAN NOT NULL DEFAULT FALSE,
  error_message TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_gemini_usage_user_date ON public.gemini_usage_metrics(user_id, created_at DESC);
CREATE INDEX idx_gemini_usage_conversation ON public.gemini_usage_metrics(conversation_id, created_at DESC);
CREATE INDEX idx_gemini_usage_cost_date ON public.gemini_usage_metrics(created_at DESC, total_cost_usd DESC);
CREATE INDEX idx_gemini_usage_tokens ON public.gemini_usage_metrics(total_tokens DESC, created_at DESC);
CREATE INDEX idx_gemini_usage_model ON public.gemini_usage_metrics(model_used, created_at DESC);
-- Note: For daily aggregations, we'll use the idx_gemini_usage_cost_date index which is sufficient

-- Enable RLS
ALTER TABLE public.gemini_usage_metrics ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Admins can see all metrics
CREATE POLICY "Admins can view all gemini metrics"
  ON public.gemini_usage_metrics FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
  );

-- Users can only see their own metrics
CREATE POLICY "Users can view their own gemini metrics"
  ON public.gemini_usage_metrics FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Only system (service role) can insert metrics
CREATE POLICY "System can insert gemini metrics"
  ON public.gemini_usage_metrics FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_gemini_metrics_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updating updated_at
CREATE TRIGGER update_gemini_metrics_updated_at
  BEFORE UPDATE ON public.gemini_usage_metrics
  FOR EACH ROW
  EXECUTE FUNCTION public.update_gemini_metrics_updated_at();

-- Function to get daily cost summary
CREATE OR REPLACE FUNCTION public.get_daily_gemini_costs(
  target_date DATE DEFAULT CURRENT_DATE,
  target_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
  date DATE,
  user_id UUID,
  total_requests BIGINT,
  total_tokens BIGINT,
  total_cost_usd DECIMAL(10,6),
  avg_cost_per_request DECIMAL(10,6),
  model_breakdown JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    DATE(created_at) as date,
    gum.user_id,
    COUNT(*) as total_requests,
    SUM(gum.total_tokens) as total_tokens,
    SUM(gum.total_cost_usd) as total_cost_usd,
    ROUND(AVG(gum.total_cost_usd), 6) as avg_cost_per_request,
    jsonb_object_agg(
      gum.model_used::text, 
      jsonb_build_object(
        'requests', COUNT(*),
        'cost', SUM(gum.total_cost_usd),
        'tokens', SUM(gum.total_tokens)
      )
    ) as model_breakdown
  FROM public.gemini_usage_metrics gum
  WHERE DATE(gum.created_at) = target_date
    AND (target_user_id IS NULL OR gum.user_id = target_user_id)
    AND gum.error_occurred = FALSE
  GROUP BY DATE(gum.created_at), gum.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check daily spending limits
CREATE OR REPLACE FUNCTION public.check_daily_spending_limit(
  target_user_id UUID,
  daily_limit_usd DECIMAL(10,6) DEFAULT 10.00
)
RETURNS TABLE (
  current_spending DECIMAL(10,6),
  limit_amount DECIMAL(10,6),
  limit_exceeded BOOLEAN,
  percentage_used DECIMAL(5,2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(gum.total_cost_usd), 0) as current_spending,
    daily_limit_usd as limit_amount,
    COALESCE(SUM(gum.total_cost_usd), 0) > daily_limit_usd as limit_exceeded,
    ROUND((COALESCE(SUM(gum.total_cost_usd), 0) / daily_limit_usd * 100), 2) as percentage_used
  FROM public.gemini_usage_metrics gum
  WHERE gum.user_id = target_user_id
    AND DATE(gum.created_at) = CURRENT_DATE
    AND gum.error_occurred = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated, service_role;
GRANT SELECT ON public.gemini_usage_metrics TO authenticated;
GRANT INSERT, SELECT ON public.gemini_usage_metrics TO service_role;
GRANT EXECUTE ON FUNCTION public.get_daily_gemini_costs TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.check_daily_spending_limit TO authenticated, service_role;

-- Add comment for documentation
COMMENT ON TABLE public.gemini_usage_metrics IS 'Tracks Google Gemini API usage metrics including tokens, costs, and performance data for monitoring and optimization';
COMMENT ON COLUMN public.gemini_usage_metrics.model_used IS 'Gemini model used for the request (flash vs pro)';
COMMENT ON COLUMN public.gemini_usage_metrics.tokens_input IS 'Number of input tokens sent to Gemini';
COMMENT ON COLUMN public.gemini_usage_metrics.tokens_output IS 'Number of output tokens received from Gemini';
COMMENT ON COLUMN public.gemini_usage_metrics.cost_input_usd IS 'Cost of input tokens in USD';
COMMENT ON COLUMN public.gemini_usage_metrics.cost_output_usd IS 'Cost of output tokens in USD';
COMMENT ON FUNCTION public.get_daily_gemini_costs IS 'Returns daily cost summary with breakdown by model for specified date and user';
COMMENT ON FUNCTION public.check_daily_spending_limit IS 'Checks if user has exceeded daily spending limit and returns usage percentage';