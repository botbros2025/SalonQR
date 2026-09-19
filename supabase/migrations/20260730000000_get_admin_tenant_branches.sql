CREATE OR REPLACE FUNCTION get_admin_tenant_branches(p_tenant_id UUID)
RETURNS SETOF public.branches
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT * FROM public.branches WHERE tenant_id = p_tenant_id ORDER BY created_at DESC;
$$;
