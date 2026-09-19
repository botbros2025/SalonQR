-- Add profile columns to admin_users

ALTER TABLE public.admin_users
ADD COLUMN IF NOT EXISTS full_name TEXT,
ADD COLUMN IF NOT EXISTS username TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS bio TEXT,
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Create an index for username lookups
CREATE INDEX IF NOT EXISTS idx_admin_users_username ON public.admin_users(username);
