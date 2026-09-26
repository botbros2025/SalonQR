CREATE OR REPLACE FUNCTION public.get_public_staff_appointments(p_branch_id uuid, p_staff_id uuid, p_date date)
RETURNS TABLE (
  start_time time,
  end_time time,
  status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.start_time, 
    a.end_time, 
    a.status::text
  FROM appointments a
  WHERE a.branch_id = p_branch_id
    AND a.primary_staff_id = p_staff_id
    AND a.appointment_date = p_date
    AND a.status IN ('SCHEDULED', 'CONFIRMED','IN_PROGRESS');
END;
$$;
