-- Add metadata column to support_flow_options to hold dynamic attributes like priority
ALTER TABLE public.support_flow_options
ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb;

-- Assign specific priorities to severe issues based on their option value
UPDATE public.support_flow_options
SET metadata = jsonb_set(metadata, '{priority}', '"urgent"')
WHERE value IN ('app_crash', 'blank_screen', 'security_concern');

UPDATE public.support_flow_options
SET metadata = jsonb_set(metadata, '{priority}', '"high"')
WHERE value IN ('payment_failed', 'cant_sign_in', 'cant_create', 'login_problem');

UPDATE public.support_flow_options
SET metadata = jsonb_set(metadata, '{priority}', '"medium"')
WHERE value IN ('feature_broken', 'payment_not_reflected', 'status_incorrect');
