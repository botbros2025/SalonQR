DO $$
DECLARE
  v_getting_started_id UUID;
BEGIN
  -- Get the Getting Started category ID
  SELECT id INTO v_getting_started_id 
  FROM public.support_categories 
  WHERE name = 'Getting Started' 
  LIMIT 1;

  IF v_getting_started_id IS NULL THEN
    RAISE NOTICE 'Getting Started category not found. Skipping seed.';
    RETURN;
  END IF;

  -- Remove previous placeholder or existing FAQs for Getting Started to avoid duplicates
  DELETE FROM public.support_faqs 
  WHERE category_id = v_getting_started_id;

  -- Insert FAQs for Getting Started
  INSERT INTO public.support_faqs (category_id, question, answer, display_order)
  VALUES 
    (
      v_getting_started_id,
      'How do I set up my salon?',
      'Go to your profile and salon settings to add your salon information. Then add your staff, services, service categories, and working hours. Once these are set up, you can start managing appointments.',
      1
    ),
    (
      v_getting_started_id,
      'How do I add my salon information?',
      'Open More → Salon/Location Settings and update your salon name, contact details, location, and other available information. Tap Save after making changes.',
      2
    ),
    (
      v_getting_started_id,
      'How do I add staff members?',
      'Go to Staff → Add New Staff. Enter the staff member''s name, phone number, joining date, role, and other required information. You can also send them an invitation to create their account.',
      3
    ),
    (
      v_getting_started_id,
      'How do I add services?',
      'Go to Services → + New Service. Enter the service name, price, duration, category, and description. You can also add variants, add-ons, photos, and a service color before saving.',
      4
    ),
    (
      v_getting_started_id,
      'How do I start accepting appointments?',
      'First make sure your services, staff, and working availability are set up. You can then create appointments from Appointments or the + Quick Actions button.',
      5
    );
END $$;
