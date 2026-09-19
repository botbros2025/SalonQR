DO $$
DECLARE
  v_settings_id UUID;
  v_profile_subcat_id UUID;
BEGIN
  -- 1. Get the 'Settings' category ID
  SELECT id INTO v_settings_id 
  FROM public.support_categories 
  WHERE name = 'Settings' 
  LIMIT 1;

  IF v_settings_id IS NULL THEN
    RAISE NOTICE 'Settings category not found. Skipping migration.';
    RETURN;
  END IF;

  -- 2. Create or get 'Profile & Account' subcategory under Settings
  SELECT id INTO v_profile_subcat_id 
  FROM public.support_subcategories 
  WHERE category_id = v_settings_id AND name = 'Profile & Account'
  LIMIT 1;

  IF v_profile_subcat_id IS NULL THEN
    INSERT INTO public.support_subcategories (category_id, name, description, display_order)
    VALUES (v_settings_id, 'Profile & Account', 'Manage your profile, personal information, and common questions.', 3)
    RETURNING id INTO v_profile_subcat_id;
  ELSE
    UPDATE public.support_subcategories 
    SET description = 'Manage your profile, personal information, and common questions.', display_order = 3
    WHERE id = v_profile_subcat_id;
  END IF;

  -- 3. Update 'General Settings' display order to 4
  UPDATE public.support_subcategories 
  SET display_order = 4 
  WHERE category_id = v_settings_id AND name = 'General Settings';

  -- 4. Clean up any previous copies of these FAQs under Profile & Account to prevent duplicates
  DELETE FROM public.support_faqs 
  WHERE subcategory_id = v_profile_subcat_id;

  -- 5. Insert the FAQs into 'Profile & Account'
  INSERT INTO public.support_faqs (category_id, subcategory_id, question, answer, display_order)
  VALUES 
    (
      v_settings_id,
      v_profile_subcat_id,
      'How do I edit my Owner profile?',
      'Open your profile from the top-right profile icon and tap Edit. Update your personal information and save the changes.',
      1
    ),
    (
      v_settings_id,
      v_profile_subcat_id,
      'How do I change my profile photo?',
      'Open My Profile, tap the camera/profile photo option, select a new image, and save it.',
      2
    ),
    (
      v_settings_id,
      v_profile_subcat_id,
      'What is Performance Overview?',
      'Performance Overview gives you a quick summary of your performance, including reviews, appointments, and revenue.',
      3
    ),
    (
      v_settings_id,
      v_profile_subcat_id,
      'How do I update my personal information?',
      'Go to My Profile → Edit. You can update the available information such as your name, email address, and phone number.',
      4
    ),
    (
      v_settings_id,
      v_profile_subcat_id,
      'What should I do if I cannot add a staff member?',
      'Check that all required fields are completed and that the phone number or email address is valid. If the problem continues, contact support.',
      5
    ),
    (
      v_settings_id,
      v_profile_subcat_id,
      'Why can''t I assign a staff member to an appointment?',
      'The staff member may be unavailable, on leave, outside their working hours, or may not be permitted to provide the selected service. Check their availability and service permissions.',
      6
    ),
    (
      v_settings_id,
      v_profile_subcat_id,
      'Why can''t I see a service when creating an appointment?',
      'Check that the service is active, correctly categorized, and available for appointment booking.',
      7
    ),
    (
      v_settings_id,
      v_profile_subcat_id,
      'What happens if I make a mistake in an appointment?',
      'Open the appointment, select Edit, correct the information, and save. If the appointment has already been completed or billed, some changes may be restricted.',
      8
    ),
    (
      v_settings_id,
      v_profile_subcat_id,
      'How can I contact support?',
      'Open Help Center and select Contact Support. Choose the available support option and provide details about the issue.',
      9
    );
END $$;
