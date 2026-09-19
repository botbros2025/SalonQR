-- STAFF PROFILE TABLE
CREATE TABLE public.staff_profile (
    staff_id uuid PRIMARY KEY REFERENCES public.staff(id) ON DELETE CASCADE,

    -- professional info
    job_title text,
    bio text,
    experience_years int,
    dummy text,
    dummy1 text,
    dummy2 text,

    specializations jsonb DEFAULT '[]'::jsonb,

    shift_start time,
    shift_end time,

    -- payments
    upi_id text,
    dummy3 text,
    dummy4 text,
    account_holder_name text,
    account_number text,
    ifsc_code text,
    pan_number text,
    dummy5 text,
    dummy6 text,
    dummy7 text,
    dummy8 text,
    dummy9 text,
    dummy10 text,



    -- emergency contact
    emergency_contact_name text,
    emergency_contact_phone text,
    emergency_contact_relation text,
    dummy11 text,
    dummy12 text,
    dummy13 text,


    -- social
    instagram text,
    facebook text,
    website text,
    dummy14 text,
    dummy15 text,
    dummy16 text,



    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);


-- system role
ALTER TABLE public.staff
ADD COLUMN system_role text;

-- employee code
ALTER TABLE public.staff
ADD COLUMN employee_code text;

-- salary
ALTER TABLE public.staff
ADD COLUMN salary numeric;



--RLS POLICIES

CREATE POLICY "Staff can view own profile"
ON staff_profile
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM staff s
    WHERE s.id = staff_profile.staff_id
    AND s.user_id = auth.uid()
  )
);

CREATE POLICY "Staff can insert own profile"
ON staff_profile
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM staff s
    WHERE s.id = staff_profile.staff_id
    AND s.user_id = auth.uid()
  )
);

CREATE POLICY "Staff can update own profile"
ON staff_profile
FOR UPDATE
USING (
  EXISTS (
    SELECT 1
    FROM staff s
    WHERE s.id = staff_profile.staff_id
    AND s.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM staff s
    WHERE s.id = staff_profile.staff_id
    AND s.user_id = auth.uid()
  )
);

--RLS OWNER LEVEL

CREATE POLICY "Owner/Admin can view staff profiles in same tenant"
ON staff_profile
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM staff s_owner
    JOIN staff s_target 
      ON s_owner.tenant_id = s_target.tenant_id
    WHERE s_owner.user_id = auth.uid()
      AND s_owner.system_role IN ('owner', 'admin','manager')
      AND s_target.id = staff_profile.staff_id
  )
);

CREATE POLICY "Owner/Admin can update staff profiles in same tenant"
ON staff_profile
FOR UPDATE
USING (
  EXISTS (
    SELECT 1
    FROM staff s_owner
    JOIN staff s_target 
      ON s_owner.tenant_id = s_target.tenant_id
    WHERE s_owner.user_id = auth.uid()
      AND s_owner.system_role IN ('owner', 'admin','manager')
      AND s_target.id = staff_profile.staff_id
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM staff s_owner
    JOIN staff s_target 
      ON s_owner.tenant_id = s_target.tenant_id
    WHERE s_owner.user_id = auth.uid()
      AND s_owner.system_role IN ('owner', 'admin','manager')
      AND s_target.id = staff_profile.staff_id
  )
);



-- role validation
ALTER TABLE public.staff
ADD CONSTRAINT staff_system_role_check
CHECK (
  system_role IS NULL
  OR system_role IN ('owner','manager','staff')
);

-- employee_code rule (safe)
ALTER TABLE public.staff
ADD CONSTRAINT employee_code_required_for_staff
CHECK (
    system_role IS NULL
    OR
    (system_role = 'staff' AND employee_code IS NOT NULL)
    OR
    (system_role IN ('owner','manager'))
);

-- prevent duplicate user linkage
ALTER TABLE public.staff
ADD CONSTRAINT unique_user_id UNIQUE (user_id);

--Auto update time
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_staff_profile_updated_at
BEFORE UPDATE ON public.staff_profile
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();



--UPDATE ROLE in STAFF TABLE

CREATE OR REPLACE FUNCTION get_primary_role(p_user_id uuid)
RETURNS text AS $$
DECLARE
  role_name text;
BEGIN
  SELECT r.name INTO role_name
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = p_user_id
  ORDER BY 
    CASE r.name
      WHEN 'owner' THEN 1
      WHEN 'manager' THEN 2
      ELSE 3
    END
  LIMIT 1;

  RETURN role_name;
END;
$$ LANGUAGE plpgsql;

----------ROLE FETCH TRIGGER
CREATE OR REPLACE FUNCTION set_role_on_user_link()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.user_id IS NOT NULL
     AND NEW.system_role IS NULL
     AND (
       TG_OP = 'INSERT'
       OR (TG_OP = 'UPDATE' AND OLD.user_id IS NULL)
     )
  THEN
    NEW.system_role := get_primary_role(NEW.user_id);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_role_on_user_link
BEFORE INSERT OR UPDATE OF user_id ON public.staff
FOR EACH ROW
EXECUTE FUNCTION set_role_on_user_link();
-----------------

--UPDATE ON ROLE CHANGE IN STAFF TABLE

CREATE OR REPLACE FUNCTION sync_staff_role_on_user_role_change()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id uuid;
  v_role text;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_user_id := OLD.user_id;
  ELSE
    v_user_id := NEW.user_id;
  END IF;

  v_role := get_primary_role(v_user_id);

  UPDATE public.staff
  SET system_role = v_role
  WHERE user_id = v_user_id
  AND system_role IS DISTINCT FROM v_role;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_sync_staff_role
AFTER INSERT OR UPDATE OR DELETE ON public.user_roles
FOR EACH ROW
EXECUTE FUNCTION sync_staff_role_on_user_role_change();





----EMP CODE TRIGGER


-- 1. Counter table (same as before)
CREATE TABLE IF NOT EXISTS public.staff_code_counter (
  year TEXT PRIMARY KEY,
  last_number INT NOT NULL DEFAULT 0
);

-- 2. Function (same logic, but works for insert/update)
CREATE OR REPLACE FUNCTION generate_employee_code()
RETURNS TRIGGER AS $$
DECLARE
  v_year TEXT;
  v_seq INT;
BEGIN
  -- Only generate if:
  -- 1. system_role = 'staff'
  -- 2. employee_code is NULL (avoid overwrite)
  -- 3. user_id is present
  -- 4. AND (on update) user_id was previously NULL → now set

  IF NEW.system_role = 'staff'
     AND NEW.employee_code IS NULL
     AND NEW.user_id IS NOT NULL
     AND (
       TG_OP = 'INSERT'
       OR (TG_OP = 'UPDATE' AND OLD.user_id IS NULL AND NEW.user_id IS NOT NULL)
     )
  THEN

    v_year := TO_CHAR(NOW(), 'YYYY');

    INSERT INTO public.staff_code_counter (year, last_number)
    VALUES (v_year, 1)
    ON CONFLICT (year)
    DO UPDATE
    SET last_number = staff_code_counter.last_number + 1
    RETURNING last_number INTO v_seq;

    NEW.employee_code := 'SLX' || v_year || LPAD(v_seq::TEXT, 4, '0');

  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Drop old trigger
DROP TRIGGER IF EXISTS trg_generate_employee_code ON public.staff;

-- 4. Create new trigger (IMPORTANT change here)
CREATE TRIGGER trg_generate_employee_code
BEFORE INSERT OR UPDATE OF user_id ON public.staff
FOR EACH ROW
EXECUTE FUNCTION generate_employee_code();

ALTER TABLE public.staff
ADD CONSTRAINT unique_employee_code UNIQUE (employee_code);




--STAFF TABLE DEPENDENCY on USER_ID