CREATE OR REPLACE FUNCTION get_admin_staff_details(p_staff_id UUID)
RETURNS JSON
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'profile', (SELECT row_to_json(p) FROM staff_profile p WHERE p.staff_id = p_staff_id LIMIT 1),
    'compensation', (SELECT json_agg(c) FROM (SELECT * FROM staff_compensation WHERE staff_id = p_staff_id AND is_active = true) c),
    'metrics', (SELECT json_agg(m) FROM (SELECT * FROM staff_metrics WHERE staff_id = p_staff_id ORDER BY metric_year DESC, metric_month DESC LIMIT 6) m),
    'shifts', (SELECT json_agg(s) FROM (SELECT * FROM staff_shifts WHERE staff_id = p_staff_id ORDER BY shift_date DESC LIMIT 10) s),
    'salary_slips', (SELECT json_agg(ss) FROM (SELECT * FROM staff_salary_slips WHERE staff_id = p_staff_id ORDER BY salary_year DESC, salary_month DESC LIMIT 6) ss)
  ) INTO v_result;
  
  RETURN v_result;
END;
$$;
