-- Add a unique constraint so we don't have duplicate configurations for the same model and platform per tenant
ALTER TABLE public.ai_model_config 
    ADD CONSTRAINT ai_model_config_tenant_model_platform_key UNIQUE (tenant_id, model_name, platform);

-- Insert default AI model config for all existing tenants
INSERT INTO public.ai_model_config (
    tenant_id,
    model_name,
    model_version,
    platform,
    command,
    model_url,
    sha256_checksum,
    file_size,
    minimum_app_version,
    is_active
)
SELECT 
    id as tenant_id,
    'Gemma-3-1b-it' as model_name,
    '1.0' as model_version,
    'android' as platform,
    'DOWNLOAD' as command,
    'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task' as model_url,
    'e3d981c01aeaaac69a84ffa0d4be13281b3176731063f1bea1c9fe6887bd9dee' as sha256_checksum,
    570000 as file_size, -- Approx 1.3GB
    '1.0.0' as minimum_app_version,
    true as is_active
FROM public.tenants
ON CONFLICT (tenant_id, model_name, platform) DO NOTHING;

-- Also create a trigger to automatically add this config for new tenants
CREATE OR REPLACE FUNCTION public.seed_ai_config_for_new_tenant()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.ai_model_config (
        tenant_id,
        model_name,
        model_version,
        platform,
        command,
        model_url,
        sha256_checksum,
        file_size,
        minimum_app_version,
        is_active
    ) VALUES (
        NEW.id,
        'Gemma-3-1b-it' as model_name,
        '1.0' as model_version,
        'android' as platform,
        'DOWNLOAD' as command,
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task' as model_url,
        'e3d981c01aeaaac69a84ffa0d4be13281b3176731063f1bea1c9fe6887bd9dee' as sha256_checksum,
        570000 as file_size,
        '1.0.0',
        true
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_tenant_created_seed_ai
    AFTER INSERT ON public.tenants
    FOR EACH ROW
    EXECUTE FUNCTION public.seed_ai_config_for_new_tenant();
