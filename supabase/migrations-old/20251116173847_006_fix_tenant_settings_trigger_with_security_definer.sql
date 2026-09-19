/*
  # Fix Tenant Settings Trigger for Signup
  
  ## Problem
  The trigger function needs to bypass RLS when creating default settings
  because it runs before the user session is fully established.
  
  ## Solution
  Make the trigger function SECURITY DEFINER so it runs with elevated privileges
  and can bypass RLS policies during the INSERT operation.
  
  ## Changes
  1. Recreate trigger function with SECURITY DEFINER
  2. This allows the function to insert into tenant_settings regardless of RLS
*/

-- Drop and recreate the function with SECURITY DEFINER
DROP FUNCTION IF EXISTS create_default_tenant_settings() CASCADE;

CREATE OR REPLACE FUNCTION create_default_tenant_settings()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO tenant_settings (tenant_id)
  VALUES (NEW.id)
  ON CONFLICT (tenant_id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
DROP TRIGGER IF EXISTS initialize_tenant_settings ON tenants;

CREATE TRIGGER initialize_tenant_settings
  AFTER INSERT ON tenants
  FOR EACH ROW
  EXECUTE FUNCTION create_default_tenant_settings();