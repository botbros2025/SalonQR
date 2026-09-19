-- Create the bucket for admin avatars
INSERT INTO storage.buckets (id, name, public) 
VALUES ('admin-avatars', 'admin-avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Policies for the bucket
-- Allow public read access to admin avatars
CREATE POLICY "Public Access" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'admin-avatars');

-- Allow authenticated users to upload avatars
CREATE POLICY "Admin Upload Access" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'admin-avatars' AND auth.role() = 'authenticated');

-- Allow authenticated users to update their own avatars
CREATE POLICY "Admin Update Access" 
ON storage.objects FOR UPDATE
USING (bucket_id = 'admin-avatars' AND auth.role() = 'authenticated');

-- Modify the RPC to accept avatar_url
CREATE OR REPLACE FUNCTION public.update_admin_profile(
    p_admin_id uuid,
    p_full_name text DEFAULT NULL,
    p_username text DEFAULT NULL,
    p_phone text DEFAULT NULL,
    p_bio text DEFAULT NULL,
    p_avatar_url text DEFAULT NULL
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
        bio = COALESCE(p_bio, bio),
        avatar_url = COALESCE(p_avatar_url, avatar_url)
    WHERE id = p_admin_id;
END;
$$;
