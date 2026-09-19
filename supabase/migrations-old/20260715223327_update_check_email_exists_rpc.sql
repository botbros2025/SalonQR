-- Update RPC to only block signup if the user has a FULLY completed profile (exists in public.users)
-- This allows users who abandoned signup at the OTP step (only in auth.users) to restart and finish setup.
CREATE OR REPLACE FUNCTION check_email_exists(email_to_check text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  exists_in_public boolean;
  exists_in_tenant boolean;
BEGIN
  -- Check in public.users (means they completed staff or owner signup)
  SELECT EXISTS (
    SELECT 1 FROM public.users WHERE email = email_to_check
  ) INTO exists_in_public;

  -- Check in public.tenants (means they completed owner signup)
  SELECT EXISTS (
    SELECT 1 FROM public.tenants WHERE owner_email = email_to_check
  ) INTO exists_in_tenant;

  -- If they are in public.users or public.tenants, they are fully registered.
  -- (We no longer block if they are ONLY in auth.users, so they can finish abandoned signups)
  RETURN exists_in_public OR exists_in_tenant;
END;
$$;
