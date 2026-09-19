DO $$
DECLARE
  v_appointments_id UUID;
  v_creating_subcat_id UUID;
  v_managing_subcat_id UUID;
BEGIN
  -- 1. Get the Appointments category ID
  SELECT id INTO v_appointments_id 
  FROM public.support_categories 
  WHERE name = 'Appointments' 
  LIMIT 1;

  IF v_appointments_id IS NULL THEN
    RAISE NOTICE 'Appointments category not found. Skipping seed.';
    RETURN;
  END IF;

  -- 2. Get or create 'Creating Appointments' subcategory
  SELECT id INTO v_creating_subcat_id 
  FROM public.support_subcategories 
  WHERE category_id = v_appointments_id AND name = 'Creating Appointments'
  LIMIT 1;

  IF v_creating_subcat_id IS NULL THEN
    INSERT INTO public.support_subcategories (category_id, name, description, display_order)
    VALUES (v_appointments_id, 'Creating Appointments', 'How to book new clients and assign staff.', 1)
    RETURNING id INTO v_creating_subcat_id;
  ELSE
    UPDATE public.support_subcategories 
    SET description = 'How to book new clients and assign staff.', display_order = 1
    WHERE id = v_creating_subcat_id;
  END IF;

  -- 3. Get or create 'Managing Appointments' subcategory
  SELECT id INTO v_managing_subcat_id 
  FROM public.support_subcategories 
  WHERE category_id = v_appointments_id AND name = 'Managing Appointments'
  LIMIT 1;

  IF v_managing_subcat_id IS NULL THEN
    INSERT INTO public.support_subcategories (category_id, name, description, display_order)
    VALUES (v_appointments_id, 'Managing Appointments', 'View, search, filter, and edit appointments.', 2)
    RETURNING id INTO v_managing_subcat_id;
  ELSE
    UPDATE public.support_subcategories 
    SET description = 'View, search, filter, and edit appointments.', display_order = 2
    WHERE id = v_managing_subcat_id;
  END IF;

  -- 4. Remove previous placeholder/outdated FAQs for Appointments to prevent duplicates
  DELETE FROM public.support_faqs 
  WHERE category_id = v_appointments_id;

  -- 5. Insert FAQs for 'Creating Appointments'
  INSERT INTO public.support_faqs (category_id, subcategory_id, question, answer, display_order)
  VALUES 
    (
      v_appointments_id,
      v_creating_subcat_id,
      'How do I create a new appointment?',
      'Tap the + button and select Add New Appointment. Select the client, service, date and time, and staff member. Review the details and confirm the appointment.',
      1
    ),
    (
      v_appointments_id,
      v_creating_subcat_id,
      'How do I assign a staff member to an appointment?',
      'While creating or editing an appointment, select the staff member who will provide the service. Only staff who are available for that time should be assigned.',
      2
    );

  -- 6. Insert FAQs for 'Managing Appointments'
  INSERT INTO public.support_faqs (category_id, subcategory_id, question, answer, display_order)
  VALUES 
    (
      v_appointments_id,
      v_managing_subcat_id,
      'How do I view appointments?',
      'Go to Appointments. Use Calendar to see appointments by time or List to see them as a list.',
      1
    ),
    (
      v_appointments_id,
      v_managing_subcat_id,
      'How do I search for an appointment?',
      'Open Appointments and tap the Search icon. Search using available client, appointment, or service information.',
      2
    ),
    (
      v_appointments_id,
      v_managing_subcat_id,
      'How do I filter appointments?',
      'Tap the Filter icon on the Appointments screen. Select the relevant filters, such as staff, appointment status, date, or service.',
      3
    ),
    (
      v_appointments_id,
      v_managing_subcat_id,
      'How do I change an appointment?',
      'Open the appointment and select Edit. Update the required information and save the changes. The updated appointment will appear in the schedule.',
      4
    );
END $$;
