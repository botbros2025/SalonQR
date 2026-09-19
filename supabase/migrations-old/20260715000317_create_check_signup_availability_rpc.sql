CREATE OR REPLACE FUNCTION check_signup_availability(check_email text, check_phone text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 1. Check users table for email
  IF EXISTS (SELECT 1 FROM public.users WHERE email = check_email) THEN
    RETURN 'Email already present';
  END IF;

  -- 2. Check users table for phone
  IF EXISTS (SELECT 1 FROM public.users WHERE phone = check_phone) THEN
    RETURN 'Phone number is already present';
  END IF;

  -- 3. Check tenants table for owner_email
  IF EXISTS (SELECT 1 FROM public.tenants WHERE owner_email = check_email) THEN
    RETURN 'Email already present';
  END IF;

  -- 4. Check tenants table for owner_phone
  IF EXISTS (SELECT 1 FROM public.tenants WHERE owner_phone = check_phone) THEN
    RETURN 'Phone number is already present';
  END IF;

  -- If we get here, both email and phone are available
  RETURN NULL;
END;
$$;
