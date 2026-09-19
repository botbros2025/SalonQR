-- RPC functions for admin profile management
CREATE OR REPLACE FUNCTION public.get_admin_profile(p_admin_id uuid)
RETURNS TABLE (
    id uuid,
    email text,
    role text,
    created_at timestamptz,
    full_name text,
    username text,
    phone text,
    bio text,
    avatar_url text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.email,
        a.role,
        a.created_at,
        a.full_name,
        a.username,
        a.phone,
        a.bio,
        a.avatar_url
    FROM public.admin_users a
    WHERE a.id = p_admin_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_admin_profile(
    p_admin_id uuid,
    p_full_name text DEFAULT NULL,
    p_username text DEFAULT NULL,
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
        full_name = COALESCE(p_full_name, full_name),
        username = COALESCE(p_username, username),
        phone = COALESCE(p_phone, phone),
        bio = COALESCE(p_bio, bio)
    WHERE id = p_admin_id;
END;
$$;
