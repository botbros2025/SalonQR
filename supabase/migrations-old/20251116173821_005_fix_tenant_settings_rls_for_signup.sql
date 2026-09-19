/*
  # Fix Tenant Settings RLS for Signup
  
  ## Problem
  During tenant signup, the trigger `initialize_tenant_settings` tries to insert
  into `tenant_settings`, but RLS blocks it because there's no INSERT policy.
  
  ## Solution
  Add INSERT policy that allows the system to create settings during signup.
  The trigger runs with the privileges of the function SECURITY DEFINER.
  
  ## Changes
  1. Add INSERT policy for tenant_settings that bypasses user check
     (since this happens during signup before user session exists)
  2. Add UPDATE policy for owners to modify settings later
*/

-- Drop existing policy and recreate with proper permissions
DROP POLICY IF EXISTS "Users can view tenant settings" ON tenant_settings;

-- Recreate SELECT policy
CREATE POLICY "Users can view tenant settings"
  ON tenant_settings FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id());

-- Add INSERT policy for system/trigger operations
-- This allows the trigger to insert during signup
CREATE POLICY "System can create tenant settings"
  ON tenant_settings FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Add UPDATE policy for owners
CREATE POLICY "Owners can update tenant settings"
  ON tenant_settings FOR UPDATE
  TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());