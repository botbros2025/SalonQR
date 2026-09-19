-- Create RPC to check if email exists in auth.users or public.users
CREATE OR REPLACE FUNCTION check_email_exists(email_to_check text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  exists_in_auth boolean;
  exists_in_public boolean;
BEGIN
  -- Check in auth.users
  SELECT EXISTS (
    SELECT 1 FROM auth.users WHERE email = email_to_check
  ) INTO exists_in_auth;

  -- Check in public.users
  SELECT EXISTS (
    SELECT 1 FROM public.users WHERE email = email_to_check
  ) INTO exists_in_public;

  RETURN exists_in_auth OR exists_in_public;
END;
$$;
