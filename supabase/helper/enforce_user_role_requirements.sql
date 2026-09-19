CREATE OR REPLACE FUNCTION enforce_user_role_requirements()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  user_role text;
BEGIN
  -- Fetch role name
  SELECT r.name
  INTO user_role
  FROM user_roles ur
  JOIN roles r ON r.id = ur.role_id
  WHERE ur.user_id = NEW.id;

  IF user_role = 'owner' THEN
    IF NEW.email IS NULL
       OR NEW.phone IS NULL
       OR NEW.salon_name IS NULL
       OR NEW.business_type IS NULL
       OR NEW.subscription_id IS NULL THEN
      RAISE EXCEPTION
        'Owner must have email, phone, salon_name, business_type, subscription_id';
    END IF;

  ELSIF user_role = 'staff' THEN
    IF NEW.phone IS NULL THEN
      RAISE EXCEPTION 'Staff must have phone';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;
