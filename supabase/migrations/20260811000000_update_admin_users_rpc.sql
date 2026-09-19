-- Create RPC function to update admin users securely
CREATE OR REPLACE FUNCTION public.admin_update_admin_user(
  p_target_admin_id uuid,
  p_role text DEFAULT NULL,
  p_full_name text DEFAULT NULL,
  p_phone text DEFAULT NULL,
  p_bio text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.admin_users
  SET 
    role = p_role,
    full_name = p_full_name,
    phone = p_phone,
    bio = p_bio,
    updated_at = NOW()
  WHERE id = p_target_admin_id;
END;
$$;
