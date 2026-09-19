CREATE OR REPLACE FUNCTION get_admin_tenant_staff(p_tenant_id UUID)
RETURNS SETOF staff
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY SELECT * FROM staff WHERE tenant_id = p_tenant_id;
END;
$$;
