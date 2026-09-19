CREATE OR REPLACE FUNCTION get_admin_tenant_clients(p_tenant_id UUID)
RETURNS SETOF clients
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY SELECT * FROM clients WHERE tenant_id = p_tenant_id;
END;
$$;
