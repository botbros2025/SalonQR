/*
  # Add INSERT Policy for User Roles Table
  
  ## Problem
  During signup, after creating the user profile, the application tries to assign
  the Owner role by inserting into `user_roles`, but RLS blocks it.
  
  ## Solution
  Add an INSERT policy that allows users to be assigned their initial role during signup.
  Since this happens during registration, we need to allow the user to have their first
  role assigned.
  
  ## Changes
  1. Add INSERT policy for user_roles table
  2. Policy allows authenticated users to have roles assigned to them
*/

-- Add INSERT policy for initial role assignment during signup
CREATE POLICY "Users can be assigned roles"
  ON user_roles FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());