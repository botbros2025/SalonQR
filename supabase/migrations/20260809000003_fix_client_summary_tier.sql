-- Fix invalid enum value 'VIP' in get_admin_tenant_client_summary

CREATE OR REPLACE FUNCTION get_admin_tenant_client_summary(p_tenant_id UUID)
RETURNS TABLE (
  branch_id UUID,
  total_customers BIGINT,
  vip_customers BIGINT,
  total_revenue NUMERIC,
  top_clients JSON
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  WITH branch_stats AS (
    SELECT 
      c.branch_id,
      COUNT(c.id) AS total_customers,
      COUNT(c.id) FILTER (WHERE c.tier IN ('GOLD', 'PLATINUM')) AS vip_customers,
      SUM(c.total_spend) AS total_revenue
    FROM clients c
    WHERE c.tenant_id = p_tenant_id
    GROUP BY c.branch_id
  ),
  top_clients_per_branch AS (
    SELECT 
      c.branch_id,
      json_agg(
        json_build_object(
          'id', c.id,
          'name', c.name,
          'email', c.email,
          'phone', c.phone,
          'tier', c.tier,
          'total_spend', c.total_spend,
          'total_visits', c.total_visits,
          'is_active', c.is_active
        )
      ) AS top_clients
    FROM (
      SELECT * FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY branch_id ORDER BY total_spend DESC NULLS LAST) as rn
        FROM clients
        WHERE tenant_id = p_tenant_id
      ) ranked
      WHERE rn <= 10
    ) c
    GROUP BY c.branch_id
  )
  SELECT 
    bs.branch_id,
    bs.total_customers,
    bs.vip_customers,
    COALESCE(bs.total_revenue, 0) as total_revenue,
    COALESCE(tc.top_clients, '[]'::json) as top_clients
  FROM branch_stats bs
  LEFT JOIN top_clients_per_branch tc ON bs.branch_id = tc.branch_id;
END;
$$;
