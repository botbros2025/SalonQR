CREATE OR REPLACE FUNCTION public.get_public_branch_booking_data(p_branch_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_branch json;
  v_services json;
  v_staff json;
BEGIN
  -- 1. Get branch info
  SELECT row_to_json(b) INTO v_branch
  FROM (
    SELECT id, name, address, city, state, phone, business_hours, is_active
    FROM branches
    WHERE id = p_branch_id
  ) b;

  IF v_branch IS NULL THEN
    RETURN NULL;
  END IF;

  -- 2. Get active services for the branch
  SELECT COALESCE(json_agg(row_to_json(s)), '[]'::json) INTO v_services
  FROM (
    SELECT 
      svc.id, 
      svc.name, 
      svc.description, 
      svc.duration_minutes, 
      svc.price, 
      svc.category_id,
      json_build_object('name', cat.name) as service_categories
    FROM services svc
    LEFT JOIN service_categories cat ON svc.category_id = cat.id
    WHERE svc.branch_id = p_branch_id AND svc.is_active = true
  ) s;

  -- 3. Get active staff for the branch
  SELECT COALESCE(json_agg(row_to_json(st)), '[]'::json) INTO v_staff
  FROM (
    SELECT 
      s.id, 
      s.name, 
      s.is_active,
      ROUND(AVG(f.staff_rating)::numeric, 1) as rating,
      COUNT(f.staff_rating)::int as review_count
    FROM staff s
    LEFT JOIN feedback f ON f.staff_id = s.id AND f.staff_rating IS NOT NULL
    WHERE s.branch_id = p_branch_id AND s.is_active = true
    GROUP BY s.id
    ORDER BY rating DESC NULLS LAST
  ) st;

  -- 4. Return combined JSON
  RETURN json_build_object(
    'branch', v_branch,
    'services', v_services,
    'staff', v_staff
  );
END;
$$;
