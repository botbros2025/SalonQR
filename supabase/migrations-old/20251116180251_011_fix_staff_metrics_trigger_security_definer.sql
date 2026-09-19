/*
  # Fix staff_metrics Trigger to Bypass RLS
  
  ## Problem
  The `initialize_staff_metrics()` trigger function doesn't have SECURITY DEFINER,
  so it runs with the invoker's privileges and gets blocked by RLS when trying to
  INSERT into staff_metrics during user signup.
  
  ## Solution
  Add SECURITY DEFINER to the function so it bypasses RLS and can auto-create
  staff_metrics records when users are created.
  
  ## Changes
  - Recreate `initialize_staff_metrics()` function with SECURITY DEFINER
  - Add SET search_path for security
*/

-- Drop and recreate the function with SECURITY DEFINER
CREATE OR REPLACE FUNCTION initialize_staff_metrics()
RETURNS TRIGGER
SECURITY DEFINER  -- Run with function owner's privileges, bypassing RLS
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO staff_metrics (staff_id, tenant_id)
  VALUES (NEW.id, NEW.tenant_id)
  ON CONFLICT (staff_id) DO NOTHING;
  
  RETURN NEW;
END;
$$;