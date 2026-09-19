/*
  # Add INSERT Policy for Users Table
  
  ## Problem
  During signup, after Supabase Auth creates the user, the application tries
  to insert into the `users` table to create the profile, but RLS blocks it
  because there's no INSERT policy.
  
  ## Solution
  Add an INSERT policy that allows authenticated users to create their own
  profile record (where the id matches their auth.uid()).
  
  ## Changes
  1. Add INSERT policy for users table
  2. Policy ensures user can only create their own record (id = auth.uid())
*/

-- Add INSERT policy for user profile creation during signup
CREATE POLICY "Users can create own profile"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);