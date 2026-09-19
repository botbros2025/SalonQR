CREATE OR REPLACE FUNCTION check_signup_availability(check_phone text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_email text;
BEGIN
  -- Get the email of the currently authenticated user (if any)
  current_user_email := auth.jwt()->>'email';

  -- 1. Check users table for phone
  -- If the phone exists, but it belongs to the CURRENT user, it's a retry of a partial setup, so let it pass!
  IF EXISTS (
    SELECT 1 FROM public.users 
    WHERE phone = check_phone 
    AND (auth.uid() IS NULL OR id != auth.uid())
  ) THEN
    RETURN 'Phone number is already present';
  END IF;

  -- 2. Check tenants table for owner_phone
  -- If it belongs to the CURRENT user, let it pass!
  IF EXISTS (
    SELECT 1 FROM public.tenants 
    WHERE owner_phone = check_phone 
    AND (current_user_email IS NULL OR owner_email != current_user_email)
  ) THEN
    RETURN 'Phone number is already present';
  END IF;

  RETURN NULL;
END;
$$;
