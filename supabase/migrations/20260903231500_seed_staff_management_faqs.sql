DO $$
DECLARE
  v_staff_id UUID;
BEGIN
  -- 1. Get the 'Staff Management' category ID
  SELECT id INTO v_staff_id 
  FROM public.support_categories 
  WHERE name = 'Staff Management' 
  LIMIT 1;

  IF v_staff_id IS NULL THEN
    RAISE NOTICE 'Staff Management category not found. Skipping migration.';
    RETURN;
  END IF;

  -- 2. Clean up any previous FAQs under Staff Management
  DELETE FROM public.support_faqs 
  WHERE category_id = v_staff_id;

  -- 3. Insert FAQs for Staff Management
  INSERT INTO public.support_faqs (category_id, question, answer, display_order)
  VALUES 
    (
      v_staff_id,
      'How do I add a new staff member?',
      'Go to Staff → Add New Staff. Enter their personal information, joining date, role, and job title. You can also enable Invite & Create Account to send them an invitation.',
      1
    ),
    (
      v_staff_id,
      'How do I invite a staff member?',
      'Enable Invite & Create Account while adding the staff member. The system will send an invitation so they can set up their account.',
      2
    ),
    (
      v_staff_id,
      'What are the different staff roles?',
      'Roles control what a staff member can access.
Manager – Operational management 
Staffer – Service-related work 
Cashier – Billing and payment-related work 
The exact permissions may depend on your salon''s configuration.',
      3
    ),
    (
      v_staff_id,
      'How do I change a staff member''s role?',
      'Open the staff member''s profile and edit their role under Roles & Permissions. Save the changes after selecting the appropriate role.',
      4
    ),
    (
      v_staff_id,
      'How do Roles & Permissions work?',
      'Roles determine which features and actions a staff member can access. Giving someone a role with more permissions allows them to perform additional tasks.',
      5
    ),
    (
      v_staff_id,
      'How do I manage staff leave?',
      'Open the relevant staff member''s availability or leave section and add their leave details. Their availability should then be considered when scheduling appointments.',
      6
    ),
    (
      v_staff_id,
      'How do I deactivate a staff member?',
      'Open the staff member''s profile and use the available Deactivate/Disable option. Deactivated staff should no longer be available for new assignments.',
      7
    );
END $$;
