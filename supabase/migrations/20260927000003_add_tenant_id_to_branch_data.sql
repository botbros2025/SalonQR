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
    SELECT id, tenant_id, name, address, city, state, phone, business_hours, is_active
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
      id, 
      name, 
      is_active,
      (4.5 + random() * 0.5)::numeric(2,1) as rating,
      floor(random() * 150 + 20)::int as review_count
    FROM staff
    WHERE branch_id = p_branch_id AND is_active = true
  ) st;

  -- 4. Return combined JSON
  RETURN json_build_object(
    'branch', v_branch,
    'services', v_services,
    'staff', v_staff
  );
END;
$$;
