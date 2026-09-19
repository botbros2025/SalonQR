DO $$
DECLARE
  v_settings_category_id UUID;
BEGIN
  -- Get the Settings category ID
  SELECT id INTO v_settings_category_id FROM public.support_categories WHERE name = 'Settings' LIMIT 1;

  IF v_settings_category_id IS NULL THEN
    RAISE NOTICE 'Settings category not found. Skipping seed.';
    RETURN;
  END IF;

  -- Insert FAQs for Settings
  INSERT INTO public.support_faqs (category_id, question, answer, display_order)
  VALUES 
    (v_settings_category_id, '1. Update Salon Profile', '1. Go to Settings -> Salon Profile
2. Update name, address, contact, logo', 1),
    (v_settings_category_id, '2. Business Hours', '1. Go to Settings -> Working Hours
2. Set opening/closing and breaks', 2),
    (v_settings_category_id, '3. Notifications', '1. Enable reminders, alerts, summaries', 3),
    (v_settings_category_id, '4. Tax (GST)', '1. Go to Settings -> Tax
2. Add GST and apply', 4),
    (v_settings_category_id, '5. Roles & Permissions', '1. Assign Admin or Staff roles', 5),
    (v_settings_category_id, '6. Payment Settings', '1. Enable Cash, UPI, Card', 6),
    (v_settings_category_id, '7. Invoice Customization', '1. Add logo, footer, business details', 7),
    (v_settings_category_id, '8. Language Settings', '1. Select language and currency', 8),
    (v_settings_category_id, '9. Data Security', '1. Keep data synced
2. Avoid sharing login', 9),
    (v_settings_category_id, '10. Integrations', '1. WhatsApp, payment gateways', 10),
    (v_settings_category_id, '11. Reset Password', '1. Use Forgot Password
2. Verify OTP', 11),
    (v_settings_category_id, '12. Logout Devices', '1. Log out from shared devices', 12),
    (v_settings_category_id, '13. App Updates', '1. Update app regularly', 13),
    (v_settings_category_id, '14. Common Issues', '1. Fix notifications, tax errors, role issues', 14),
    (v_settings_category_id, '15. Best Practices', '1. Review monthly
2. Restrict admin access', 15);
END $$;
