-- 1. Dashboard Stats
CREATE OR REPLACE FUNCTION get_admin_support_dashboard_stats()
RETURNS TABLE (
  open_count BIGINT,
  urgent_count BIGINT,
  resolved_count BIGINT,
  total_count BIGINT
) SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) FILTER (WHERE status IN ('open', 'pending')) AS open_count,
    COUNT(*) FILTER (WHERE status IN ('open', 'pending') AND priority = 'urgent') AS urgent_count,
    COUNT(*) FILTER (WHERE status IN ('resolved', 'closed')) AS resolved_count,
    COUNT(*) AS total_count
  FROM support_tickets;
END;
$$ LANGUAGE plpgsql;

-- 2. Paginated Tickets List
DROP FUNCTION IF EXISTS get_admin_support_tickets_paginated(integer,integer,text,text,text);

CREATE OR REPLACE FUNCTION get_admin_support_tickets_paginated(
  p_limit INT,
  p_offset INT,
  p_status TEXT DEFAULT 'all',
  p_priority TEXT DEFAULT 'all',
  p_search TEXT DEFAULT '',
  p_sort_by TEXT DEFAULT 'updated_at',
  p_sort_order TEXT DEFAULT 'desc'
)
RETURNS TABLE (
  id UUID,
  ticket_number BIGINT,
  subject TEXT,
  category TEXT,
  priority TEXT,
  status TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  business_name TEXT,
  total_count BIGINT
) SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH filtered_tickets AS (
    SELECT 
      t.id,
      t.ticket_number,
      t.subject,
      t.category,
      t.priority,
      t.status,
      t.created_at,
      t.updated_at,
      tn.business_name
    FROM support_tickets t
    LEFT JOIN tenants tn ON t.tenant_id = tn.id
    WHERE (p_status = 'all' OR 
           (p_status = 'needs_action' AND t.status::TEXT IN ('open', 'pending')) OR 
           t.status::TEXT = p_status)
      AND (p_priority = 'all' OR t.priority::TEXT = p_priority)
      AND (p_search = '' OR t.subject ILIKE '%' || p_search || '%' OR t.ticket_number::TEXT ILIKE '%' || p_search || '%')
  )
  SELECT 
    f.id,
    f.ticket_number,
    f.subject,
    f.category,
    f.priority,
    f.status,
    f.created_at,
    f.updated_at,
    f.business_name,
    (SELECT COUNT(*) FROM filtered_tickets) AS total_count
  FROM filtered_tickets f
  ORDER BY 
    CASE WHEN p_sort_by = 'created_at' AND p_sort_order = 'asc' THEN f.created_at END ASC,
    CASE WHEN p_sort_by = 'created_at' AND p_sort_order = 'desc' THEN f.created_at END DESC,
    CASE WHEN p_sort_by = 'updated_at' AND p_sort_order = 'asc' THEN f.updated_at END ASC,
    CASE WHEN p_sort_by = 'updated_at' AND p_sort_order = 'desc' THEN f.updated_at END DESC,
    f.updated_at DESC -- fallback
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- 3. Ticket Details
CREATE OR REPLACE FUNCTION get_admin_support_ticket_details(
  p_ticket_id UUID
)
RETURNS TABLE (
  id UUID,
  ticket_number BIGINT,
  subject TEXT,
  description TEXT,
  category TEXT,
  priority TEXT,
  status TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  business_name TEXT,
  tenant_status TEXT,
  subscription_plan TEXT,
  owner_name TEXT,
  owner_email TEXT,
  user_full_name TEXT,
  user_email TEXT
) SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.ticket_number,
    t.subject,
    t.description,
    t.category,
    t.priority,
    t.status,
    t.created_at,
    t.updated_at,
    tn.business_name,
    tn.status::TEXT AS tenant_status,
    NULL::TEXT AS subscription_plan,
    tn.owner_name,
    tn.owner_email,
    u.full_name AS user_full_name,
    u.email AS user_email
  FROM support_tickets t
  LEFT JOIN tenants tn ON t.tenant_id = tn.id
  LEFT JOIN users u ON t.user_id = u.id
  WHERE t.id = p_ticket_id;
END;
$$ LANGUAGE plpgsql;

-- 4. Ticket Messages
CREATE OR REPLACE FUNCTION get_admin_support_ticket_messages(
  p_ticket_id UUID
)
RETURNS TABLE (
  id UUID,
  message TEXT,
  sender_type TEXT,
  created_at TIMESTAMPTZ,
  user_full_name TEXT
) SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id,
    m.message,
    m.sender_type,
    m.created_at,
    u.full_name AS user_full_name
  FROM support_ticket_messages m
  LEFT JOIN users u ON m.sender_id = u.id
  WHERE m.ticket_id = p_ticket_id
  ORDER BY m.created_at ASC;
END;
$$ LANGUAGE plpgsql;

-- 5. Admin Reply
CREATE OR REPLACE FUNCTION admin_reply_to_ticket(
  p_ticket_id UUID,
  p_sender_id UUID,
  p_message TEXT
)
RETURNS VOID SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO support_ticket_messages (
    ticket_id,
    sender_id,
    sender_type,
    message
  ) VALUES (
    p_ticket_id,
    p_sender_id,
    'support',
    p_message
  );

  UPDATE support_tickets 
  SET 
    status = 'pending',
    updated_at = NOW()
  WHERE id = p_ticket_id;
END;
$$ LANGUAGE plpgsql;

-- 6. Update Ticket Status
CREATE OR REPLACE FUNCTION admin_update_ticket_status(
  p_ticket_id UUID,
  p_status TEXT
)
RETURNS VOID SECURITY DEFINER
AS $$
BEGIN
  UPDATE support_tickets 
  SET 
    status = p_status,
    updated_at = NOW(),
    resolved_at = CASE WHEN p_status = 'resolved' THEN NOW() ELSE resolved_at END
  WHERE id = p_ticket_id;
END;
$$ LANGUAGE plpgsql;
