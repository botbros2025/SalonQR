-- Create RPC function to update only the admin's avatar URL
CREATE OR REPLACE FUNCTION public.update_admin_avatar_url(
    p_admin_id uuid,
    p_avatar_url text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.admin_users
    SET avatar_url = p_avatar_url
    WHERE id = p_admin_id;
END;
$$;
