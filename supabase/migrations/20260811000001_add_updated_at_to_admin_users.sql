-- Add updated_at column to admin_users table if it does not exist
ALTER TABLE public.admin_users
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();
