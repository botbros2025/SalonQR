/*
  # Add INSERT Policy for Branches Table
  
  ## Problem
  During signup, after assigning the Owner role, the application tries to create
  the first branch, but RLS blocks it because there's no INSERT policy.
  
  ## Solution
  Add an INSERT policy that allows owners to create branches for their tenant.
  The policy checks that the branch's tenant_id matches the user's tenant_id.
  
  ## Changes
  1. Add INSERT policy for branches table
  2. Policy ensures branch is created for user's own tenant
*/

-- Add INSERT policy for branch creation
CREATE POLICY "Users can create branches for their tenant"
  ON branches FOR INSERT
  TO authenticated
  WITH CHECK (
    tenant_id IN (
      SELECT tenant_id FROM users WHERE id = auth.uid()
    )
  );

-- Add UPDATE policy for modifying branches
CREATE POLICY "Users can update tenant branches"
  ON branches FOR UPDATE
  TO authenticated
  USING (
    tenant_id IN (
      SELECT tenant_id FROM users WHERE id = auth.uid()
    )
  )
  WITH CHECK (
    tenant_id IN (
      SELECT tenant_id FROM users WHERE id = auth.uid()
    )
  );