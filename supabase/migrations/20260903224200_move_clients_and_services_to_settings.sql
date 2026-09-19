DO $$
DECLARE
  v_settings_id UUID;
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

  -- 2. Remove the 'Clients' and 'Services' categories from public.support_categories
  -- (This cascades and cleans up any FAQs tied to them)
  DELETE FROM public.support_categories 
  WHERE name IN ('Clients', 'Services');

  -- 3. Restore original display orders for the original categories
  UPDATE public.support_categories SET display_order = 1 WHERE name = 'Getting Started';
  UPDATE public.support_categories SET display_order = 2 WHERE name = 'Appointments';
  UPDATE public.support_categories SET display_order = 3 WHERE name = 'Billing & Payments';
  UPDATE public.support_categories SET display_order = 4 WHERE name = 'Staff Management';
  UPDATE public.support_categories SET display_order = 5 WHERE name = 'Settings';
  UPDATE public.support_categories SET display_order = 6 WHERE name = 'Security & Privacy';
  UPDATE public.support_categories SET display_order = 7 WHERE name = 'Mobile App';

  -- 4. Clean up any existing duplicates of these specific FAQs under Settings
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

  -- 5. Insert Clients FAQs into 'Settings'
  INSERT INTO public.support_faqs (category_id, question, answer, display_order)
  VALUES 
    (
      v_settings_id,
      'How do I add a new client?',
      'Tap + → Add New Client. Enter the client''s available information and save the profile.',
      16
    ),
    (
      v_settings_id,
      'How do I find an existing client?',
      'Open the Clients section and use the search bar to search by the client''s name or available contact information.',
      17
    ),
    (
      v_settings_id,
      'How do I book an appointment for an existing client?',
      'Create a new appointment and select the existing client during Client Selection. Then choose the service, staff member, date, and time.',
      18
    ),
    (
      v_settings_id,
      'What if a client does not have a phone number?',
      'You can create the client profile using the information available to you. A phone number should only be added when the client has one.',
      19
    );

  -- 6. Insert Services FAQs into 'Settings'
  INSERT INTO public.support_faqs (category_id, question, answer, display_order)
  VALUES 
    (
      v_settings_id,
      'How do I add a new service?',
      'Go to Services → + New Service. Enter the service name, price type, price, and duration. You can add additional details and then tap Save.',
      20
    ),
    (
      v_settings_id,
      'How do I create a service category?',
      'Open Services and select + New Category. Enter the category name and save it. You can then assign services to that category.',
      21
    ),
    (
      v_settings_id,
      'How do I set a service price?',
      'When creating or editing a service, select the appropriate Price Type and enter the service price.',
      22
    ),
    (
      v_settings_id,
      'How do I set the service duration?',
      'Enter the expected service time in the Duration (Minutes) field when creating or editing a service.',
      23
    ),
    (
      v_settings_id,
      'What are Service Variants?',
      'Service Variants allow you to offer different versions of the same service with different prices, durations, or other details.
Example:
Haircut – ₹150 / 20 min
Premium Haircut – ₹250 / 30 min',
      24
    ),
    (
      v_settings_id,
      'What are Add-ons?',
      'Add-ons are optional extra services that can be added to a main service.
Example:
Haircut + Hair Wash
Haircut + Head Massage',
      25
    ),
    (
      v_settings_id,
      'How do I edit or remove a service?',
      'Open the service from Services, select the available edit or management option, make your changes, and save. Follow the delete/deactivate option if you want to stop offering the service.',
      26
    ),
    (
      v_settings_id,
      'Can I add photos and descriptions to a service?',
      'Yes. When creating or editing a service, you can add a description and upload service photos where supported.',
      27
    );
END $$;
