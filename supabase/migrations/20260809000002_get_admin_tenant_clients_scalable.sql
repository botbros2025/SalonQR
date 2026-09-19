-- Migration for Scalable Customer Views

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
      COUNT(c.id) FILTER (WHERE c.tier = 'VIP') AS vip_customers,
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


CREATE OR REPLACE FUNCTION get_admin_tenant_branch_clients_paginated(
  p_tenant_id UUID, 
  p_branch_id UUID, 
  p_limit INT, 
  p_offset INT, 
  p_search TEXT DEFAULT '', 
  p_status TEXT DEFAULT 'All'
)
RETURNS JSON
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_total_count INT;
  v_data JSON;
BEGIN
  -- Get total count matching criteria
  SELECT COUNT(*) INTO v_total_count
  FROM clients c
  WHERE c.tenant_id = p_tenant_id
    AND c.branch_id = p_branch_id
    AND (
      p_search = '' OR 
      c.name ILIKE '%' || p_search || '%' OR 
      c.email ILIKE '%' || p_search || '%' OR 
      c.phone ILIKE '%' || p_search || '%'
    )
    AND (
      p_status = 'All' OR 
      (p_status = 'Active' AND c.is_active = true) OR 
      (p_status = 'Inactive' AND c.is_active = false)
    );

  -- Get paginated data
  SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json) INTO v_data
  FROM (
    SELECT *
    FROM clients c
    WHERE c.tenant_id = p_tenant_id
      AND c.branch_id = p_branch_id
      AND (
        p_search = '' OR 
        c.name ILIKE '%' || p_search || '%' OR 
        c.email ILIKE '%' || p_search || '%' OR 
        c.phone ILIKE '%' || p_search || '%'
      )
      AND (
        p_status = 'All' OR 
        (p_status = 'Active' AND c.is_active = true) OR 
        (p_status = 'Inactive' AND c.is_active = false)
      )
    ORDER BY c.total_spend DESC NULLS LAST
    LIMIT p_limit
    OFFSET p_offset
  ) t;

  RETURN json_build_object(
    'data', v_data,
    'total_count', v_total_count
  );
END;
$$;
