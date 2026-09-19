-- Create RPC function to fetch all admin users
CREATE OR REPLACE FUNCTION public.get_all_admin_users()
RETURNS SETOF public.admin_users
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT *
  FROM public.admin_users
  ORDER BY created_at DESC;
$$;
