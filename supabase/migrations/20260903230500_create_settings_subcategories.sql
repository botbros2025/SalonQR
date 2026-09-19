DO $$
DECLARE
  v_settings_id UUID;
  v_clients_subcat_id UUID;
  v_services_subcat_id UUID;
  v_general_subcat_id UUID;
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

  -- 2. Create or get 'Clients' subcategory under Settings
  SELECT id INTO v_clients_subcat_id 
  FROM public.support_subcategories 
  WHERE category_id = v_settings_id AND name = 'Clients'
  LIMIT 1;

  IF v_clients_subcat_id IS NULL THEN
    INSERT INTO public.support_subcategories (category_id, name, description, display_order)
    VALUES (v_settings_id, 'Clients', 'Manage client profiles, search, and history.', 1)
    RETURNING id INTO v_clients_subcat_id;
  ELSE
    UPDATE public.support_subcategories 
    SET description = 'Manage client profiles, search, and history.', display_order = 1
    WHERE id = v_clients_subcat_id;
  END IF;

  -- 3. Create or get 'Services' subcategory under Settings
  SELECT id INTO v_services_subcat_id 
  FROM public.support_subcategories 
  WHERE category_id = v_settings_id AND name = 'Services'
  LIMIT 1;

  IF v_services_subcat_id IS NULL THEN
    INSERT INTO public.support_subcategories (category_id, name, description, display_order)
    VALUES (v_settings_id, 'Services', 'Manage services, pricing, variants, and add-ons.', 2)
    RETURNING id INTO v_services_subcat_id;
  ELSE
    UPDATE public.support_subcategories 
    SET description = 'Manage services, pricing, variants, and add-ons.', display_order = 2
    WHERE id = v_services_subcat_id;
  END IF;

  -- 4. Create or get 'General Settings' subcategory under Settings
  SELECT id INTO v_general_subcat_id 
  FROM public.support_subcategories 
  WHERE category_id = v_settings_id AND name = 'General Settings'
  LIMIT 1;

  IF v_general_subcat_id IS NULL THEN
    INSERT INTO public.support_subcategories (category_id, name, description, display_order)
    VALUES (v_settings_id, 'General Settings', 'Salon profile, hours, tax, notifications, and security.', 3)
    RETURNING id INTO v_general_subcat_id;
  ELSE
    UPDATE public.support_subcategories 
    SET description = 'Salon profile, hours, tax, notifications, and security.', display_order = 3
    WHERE id = v_general_subcat_id;
  END IF;

  -- 5. Move existing 15 Settings FAQs into 'General Settings' subcategory
  UPDATE public.support_faqs
  SET subcategory_id = v_general_subcat_id
  WHERE category_id = v_settings_id
    AND question IN (
      '1. Update Salon Profile',
      '2. Business Hours',
      '3. Notifications',
      '4. Tax (GST)',
      '5. Roles & Permissions',
      '6. Payment Settings',
      '7. Invoice Customization',
      '8. Language Settings',
      '9. Data Security',
      '10. Integrations',
      '11. Reset Password',
      '12. Logout Devices',
      '13. App Updates',
      '14. Common Issues',
      '15. Best Practices'
    );

  -- 6. Clean up previous Clients & Services FAQs under Settings to avoid duplicate entries
  DELETE FROM public.support_faqs 
  WHERE category_id = v_settings_id
    AND question IN (
      'How do I add a new client?',
      'How do I find an existing client?',
      'How do I book an appointment for an existing client?',
      'What if a client does not have a phone number?',
      'How do I add a new service?',
      'How do I create a service category?',
      'How do I set a service price?',
      'How do I set the service duration?',
      'What are Service Variants?',
      'What are Add-ons?',
      'How do I edit or remove a service?',
      'Can I add photos and descriptions to a service?'
    );

  -- 7. Insert Clients FAQs into 'Clients' subcategory
  INSERT INTO public.support_faqs (category_id, subcategory_id, question, answer, display_order)
  VALUES 
    (
      v_settings_id,
      v_clients_subcat_id,
      'How do I add a new client?',
      'Tap + → Add New Client. Enter the client''s available information and save the profile.',
      1
    ),
    (
      v_settings_id,
      v_clients_subcat_id,
      'How do I find an existing client?',
      'Open the Clients section and use the search bar to search by the client''s name or available contact information.',
      2
    ),
    (
      v_settings_id,
      v_clients_subcat_id,
      'How do I book an appointment for an existing client?',
      'Create a new appointment and select the existing client during Client Selection. Then choose the service, staff member, date, and time.',
      3
    ),
    (
      v_settings_id,
      v_clients_subcat_id,
      'What if a client does not have a phone number?',
      'You can create the client profile using the information available to you. A phone number should only be added when the client has one.',
      4
    );

  -- 8. Insert Services FAQs into 'Services' subcategory
  INSERT INTO public.support_faqs (category_id, subcategory_id, question, answer, display_order)
  VALUES 
    (
      v_settings_id,
      v_services_subcat_id,
      'How do I add a new service?',
      'Go to Services → + New Service. Enter the service name, price type, price, and duration. You can add additional details and then tap Save.',
      1
    ),
    (
      v_settings_id,
      v_services_subcat_id,
      'How do I create a service category?',
      'Open Services and select + New Category. Enter the category name and save it. You can then assign services to that category.',
      2
    ),
    (
      v_settings_id,
      v_services_subcat_id,
      'How do I set a service price?',
      'When creating or editing a service, select the appropriate Price Type and enter the service price.',
      3
    ),
    (
      v_settings_id,
      v_services_subcat_id,
      'How do I set the service duration?',
      'Enter the expected service time in the Duration (Minutes) field when creating or editing a service.',
      4
    ),
    (
      v_settings_id,
      v_services_subcat_id,
      'What are Service Variants?',
      'Service Variants allow you to offer different versions of the same service with different prices, durations, or other details.
Example:
Haircut – ₹150 / 20 min
Premium Haircut – ₹250 / 30 min',
      5
    ),
    (
      v_settings_id,
      v_services_subcat_id,
      'What are Add-ons?',
      'Add-ons are optional extra services that can be added to a main service.
Example:
Haircut + Hair Wash
Haircut + Head Massage',
      6
    ),
    (
      v_settings_id,
      v_services_subcat_id,
      'How do I edit or remove a service?',
      'Open the service from Services, select the available edit or management option, make your changes, and save. Follow the delete/deactivate option if you want to stop offering the service.',
      7
    ),
    (
      v_settings_id,
      v_services_subcat_id,
      'Can I add photos and descriptions to a service?',
      'Yes. When creating or editing a service, you can add a description and upload service photos where supported.',
      8
    );
END $$;
