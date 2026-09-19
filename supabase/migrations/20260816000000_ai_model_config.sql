CREATE TABLE IF NOT EXISTS public.ai_model_config (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    tenant_id uuid NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    model_name text NOT NULL,
    model_version text NOT NULL,
    platform text NOT NULL,
    command text NOT NULL DEFAULT 'DONT_USE',
    model_url text,
    sha256_checksum text,
    file_size bigint,
    minimum_app_version text,
    is_active boolean DEFAULT true,
    updated_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT ai_model_config_pkey PRIMARY KEY (id)
);

-- Enable RLS
ALTER TABLE public.ai_model_config ENABLE ROW LEVEL SECURITY;

-- Create policy for viewing
CREATE POLICY "Users can view AI model config for their tenant"
    ON public.ai_model_config
    FOR SELECT
    USING (tenant_id = public.current_tenant_id());
