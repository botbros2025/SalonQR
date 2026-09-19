DO $$
DECLARE
  v_clients_id UUID;
  v_services_id UUID;
BEGIN
  -- 1. Ensure 'Services' category exists
  SELECT id INTO v_services_id 
  FROM public.support_categories 
  WHERE name = 'Services' 
  LIMIT 1;

  IF v_services_id IS NULL THEN
    INSERT INTO public.support_categories (name, description, icon, display_order)
    VALUES ('Services', 'Manage services, pricing, variants, and add-ons.', 'cut-outline', 3)
    RETURNING id INTO v_services_id;
  END IF;

  -- 2. Ensure 'Clients' category exists
  SELECT id INTO v_clients_id 
  FROM public.support_categories 
  WHERE name = 'Clients' 
  LIMIT 1;

  IF v_clients_id IS NULL THEN
    INSERT INTO public.support_categories (name, description, icon, display_order)
    VALUES ('Clients', 'Manage client profiles, search, and history.', 'person-outline', 4)
    RETURNING id INTO v_clients_id;
  END IF;

  -- 3. Organize display orders across categories
  UPDATE public.support_categories SET display_order = 1 WHERE name = 'Getting Started';
  UPDATE public.support_categories SET display_order = 2 WHERE name = 'Appointments';
  UPDATE public.support_categories SET display_order = 3 WHERE name = 'Services';
  UPDATE public.support_categories SET display_order = 4 WHERE name = 'Clients';
  UPDATE public.support_categories SET display_order = 5 WHERE name = 'Staff Management';
  UPDATE public.support_categories SET display_order = 6 WHERE name = 'Billing & Payments';
  UPDATE public.support_categories SET display_order = 7 WHERE name = 'Settings';
  UPDATE public.support_categories SET display_order = 8 WHERE name = 'Security & Privacy';
  UPDATE public.support_categories SET display_order = 9 WHERE name = 'Mobile App';

  -- 4. Clean up previous FAQs for Clients and Services to prevent duplicates
  DELETE FROM public.support_faqs 
  WHERE category_id IN (v_clients_id, v_services_id);

  -- 5. Insert FAQs for 'Clients'
  INSERT INTO public.support_faqs (category_id, question, answer, display_order)
  VALUES 
    (
      v_clients_id,
      'How do I add a new client?',
      'Tap + → Add New Client. Enter the client''s available information and save the profile.',
      1
    ),
    (
      v_clients_id,
      'How do I find an existing client?',
      'Open the Clients section and use the search bar to search by the client''s name or available contact information.',
      2
    ),
    (
      v_clients_id,
      'How do I book an appointment for an existing client?',
      'Create a new appointment and select the existing client during Client Selection. Then choose the service, staff member, date, and time.',
      3
    ),
    (
      v_clients_id,
      'What if a client does not have a phone number?',
      'You can create the client profile using the information available to you. A phone number should only be added when the client has one.',
      4
    );

  -- 6. Insert FAQs for 'Services'
  INSERT INTO public.support_faqs (category_id, question, answer, display_order)
  VALUES 
    (
      v_services_id,
      'How do I add a new service?',
      'Go to Services → + New Service. Enter the service name, price type, price, and duration. You can add additional details and then tap Save.',
      1
    ),
    (
      v_services_id,
      'How do I create a service category?',
      'Open Services and select + New Category. Enter the category name and save it. You can then assign services to that category.',
      2
    ),
    (
      v_services_id,
      'How do I set a service price?',
      'When creating or editing a service, select the appropriate Price Type and enter the service price.',
      3
    ),
    (
      v_services_id,
      'How do I set the service duration?',
      'Enter the expected service time in the Duration (Minutes) field when creating or editing a service.',
      4
    ),
    (
      v_services_id,
      'What are Service Variants?',
      'Service Variants allow you to offer different versions of the same service with different prices, durations, or other details.
Example:
Haircut – ₹150 / 20 min
Premium Haircut – ₹250 / 30 min',
      5
    ),
    (
      v_services_id,
      'What are Add-ons?',
      'Add-ons are optional extra services that can be added to a main service.
Example:
Haircut + Hair Wash
Haircut + Head Massage',
      6
    ),
    (
      v_services_id,
      'How do I edit or remove a service?',
      'Open the service from Services, select the available edit or management option, make your changes, and save. Follow the delete/deactivate option if you want to stop offering the service.',
      7
    ),
    (
      v_services_id,
      'Can I add photos and descriptions to a service?',
      'Yes. When creating or editing a service, you can add a description and upload service photos where supported.',
      8
    );
END $$;
