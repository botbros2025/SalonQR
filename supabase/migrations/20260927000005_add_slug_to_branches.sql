-- 1. Add slug column
ALTER TABLE public.branches ADD COLUMN IF NOT EXISTS slug text UNIQUE;

-- 2. Populate existing branches with a basic slug, handling duplicates
WITH numbered_branches AS (
  SELECT id, 
         LOWER(REGEXP_REPLACE(name, '[^a-zA-Z0-9]+', '-', 'g')) as base_slug,
         ROW_NUMBER() OVER (PARTITION BY LOWER(REGEXP_REPLACE(name, '[^a-zA-Z0-9]+', '-', 'g')) ORDER BY id) as rn
  FROM public.branches
)
UPDATE public.branches b
SET slug = nb.base_slug || CASE WHEN nb.rn > 1 THEN '-' || (nb.rn - 1)::text ELSE '' END
FROM numbered_branches nb
WHERE b.id = nb.id AND b.slug IS NULL;

-- 3. Drop the old function since the argument type changes from uuid to text
DROP FUNCTION IF EXISTS public.get_public_branch_booking_data(uuid);

-- 4. Recreate the function with the exact same name, but accepting the slug
CREATE OR REPLACE FUNCTION public.get_public_branch_booking_data(p_slug text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_branch json;
  v_services json;
  v_staff json;
  v_branch_id uuid;
BEGIN
  -- 1. Get branch info
  SELECT row_to_json(b), b.id INTO v_branch, v_branch_id
  FROM (
    SELECT id, tenant_id, name, address, city, state, phone, business_hours, is_active, slug
    FROM branches
    WHERE slug = p_slug
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
    WHERE svc.branch_id = v_branch_id AND svc.is_active = true
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
    WHERE branch_id = v_branch_id AND is_active = true
  ) st;

  -- 4. Return combined JSON
  RETURN json_build_object(
    'branch', v_branch,
    'services', v_services,
    'staff', v_staff
  );
END;
$$;
