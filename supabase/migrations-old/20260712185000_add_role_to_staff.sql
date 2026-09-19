-- Add role column to staff table
ALTER TABLE IF EXISTS public.staff
ADD COLUMN IF NOT EXISTS role TEXT;
