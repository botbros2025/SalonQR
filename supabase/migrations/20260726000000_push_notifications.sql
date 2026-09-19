-- Migration: Push Notification System Setup

-- 1. Insert Notification Templates for Staff, Payment, and Security Events (Owner targeted)
INSERT INTO notification_templates (tenant_id, name, type, channel, subject, body, is_system_default, is_active)
VALUES
  -- Staff Events
  (NULL, 'Staff Invite Accepted', 'staff_invite_accepted_owner', 'PUSH', 'Staff Joined: {{staff_name}}', '{{staff_name}} has accepted the invitation and joined the salon.', true, true),
  (NULL, 'Staff Leave Requested', 'staff_leave_requested_owner', 'PUSH', 'Leave Request: {{staff_name}}', '{{staff_name}} has requested leave for {{leave_date}}.', true, true),
  (NULL, 'Staff Resigned/Removed', 'staff_resigned_owner', 'PUSH', 'Staff Departure: {{staff_name}}', '{{staff_name}} is no longer active at the salon.', true, true),
  (NULL, 'New Staff Joined', 'staff_joined_owner', 'PUSH', 'New Staff: {{staff_name}}', '{{staff_name}} has been added to the system.', true, true),
  
  -- Payment Events
  (NULL, 'Payment Received', 'payment_success_owner', 'PUSH', 'Payment Received', 'A payment of {{amount}} was received for Invoice {{invoice_number}}.', true, true),
  (NULL, 'Refund Processed', 'payment_refund_owner', 'PUSH', 'Refund Processed', 'A refund of {{amount}} was processed for Invoice {{invoice_number}}.', true, true),
  (NULL, 'Payment Failed', 'payment_failed_owner', 'PUSH', 'Payment Failed', 'A payment attempt for Invoice {{invoice_number}} failed.', true, true),
  (NULL, 'Subscription Success', 'sub_success_owner', 'PUSH', 'Subscription Renewed', 'Your subscription payment was successful.', true, true),
  (NULL, 'Subscription Expiring', 'sub_expiring_owner', 'PUSH', 'Subscription Expiring', 'Your subscription expires in {{days}} days. Please renew.', true, true),
  
  -- Security Events
  (NULL, 'New Device Login', 'security_new_device_owner', 'PUSH', 'New Login Detected', 'A new device logged into your owner account.', true, true),
  (NULL, 'Suspicious Login', 'security_suspicious_owner', 'PUSH', 'Suspicious Login', 'We detected an unusual login attempt on your account.', true, true),
  (NULL, 'Password Changed', 'security_password_changed_owner', 'PUSH', 'Password Changed', 'Your account password was recently changed.', true, true),
  (NULL, 'Staff Role Changed', 'security_role_changed_owner', 'PUSH', 'Role Changed: {{staff_name}}', '{{staff_name}}''s role was changed by an admin.', true, true)
ON CONFLICT DO NOTHING;

-- 2. RPC for Staff Notifications
CREATE OR REPLACE FUNCTION "public"."create_staff_notifications"(
    "p_staff_id" "uuid",
    "p_notification_type" "text",
    "p_reference_id" "uuid",
    "p_tenant_id" "uuid",
    "p_branch_id" "uuid",
    "p_extra_data" "jsonb" DEFAULT '{}'::jsonb
) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_staff_name TEXT;
    v_owner_user_id UUID;
    v_owner_template RECORD;
    v_owner_title TEXT;
    v_owner_body TEXT;
BEGIN
    -- Get staff name
    SELECT full_name INTO v_staff_name FROM users WHERE id = p_staff_id;

    -- Get owner user ID for the tenant
    SELECT id INTO v_owner_user_id FROM users 
    WHERE tenant_id = p_tenant_id AND id IN (
        SELECT user_id FROM user_roles 
        INNER JOIN roles ON roles.id = user_roles.role_id 
        WHERE roles.name = 'owner'
    ) LIMIT 1;

    -- Get template
    SELECT * INTO v_owner_template FROM notification_templates 
    WHERE type = p_notification_type || '_owner' AND is_active = true LIMIT 1;

    IF v_owner_template.id IS NOT NULL AND v_owner_user_id IS NOT NULL THEN
        -- Replace variables
        v_owner_title := replace(COALESCE(v_owner_template.subject, ''), '{{staff_name}}', COALESCE(v_staff_name, 'Staff'));
        v_owner_body := replace(COALESCE(v_owner_template.body, ''), '{{staff_name}}', COALESCE(v_staff_name, 'Staff'));
        
        -- Additional replacements from extra data if provided
        IF p_extra_data ? 'leave_date' THEN
            v_owner_body := replace(v_owner_body, '{{leave_date}}', (p_extra_data->>'leave_date')::text);
        END IF;

        INSERT INTO notifications (
            tenant_id, branch_id, user_id, template_id, type, title, body, reference_id, reference_type, metadata, is_read, created_at
        ) VALUES (
            p_tenant_id, p_branch_id, v_owner_user_id, v_owner_template.id, v_owner_template.type, v_owner_title, v_owner_body, p_reference_id, 'staff', p_extra_data, false, now()
        );
    END IF;
END;
$$;

-- 3. RPC for Payment Notifications
CREATE OR REPLACE FUNCTION "public"."create_payment_notifications"(
    "p_invoice_id" "uuid",
    "p_notification_type" "text",
    "p_amount" "numeric"
) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_invoice RECORD;
    v_owner_user_id UUID;
    v_owner_template RECORD;
    v_owner_title TEXT;
    v_owner_body TEXT;
BEGIN
    SELECT * INTO v_invoice FROM invoices WHERE id = p_invoice_id;
    IF NOT FOUND THEN RETURN; END IF;

    -- Get owner user ID
    SELECT id INTO v_owner_user_id FROM users 
    WHERE tenant_id = v_invoice.tenant_id AND id IN (
        SELECT user_id FROM user_roles 
        INNER JOIN roles ON roles.id = user_roles.role_id 
        WHERE roles.name = 'owner'
    ) LIMIT 1;

    SELECT * INTO v_owner_template FROM notification_templates 
    WHERE type = p_notification_type || '_owner' AND is_active = true LIMIT 1;

    IF v_owner_template.id IS NOT NULL AND v_owner_user_id IS NOT NULL THEN
        v_owner_title := replace(COALESCE(v_owner_template.subject, ''), '{{invoice_number}}', COALESCE(v_invoice.invoice_number, ''));
        v_owner_body := replace(COALESCE(v_owner_template.body, ''), '{{invoice_number}}', COALESCE(v_invoice.invoice_number, ''));
        v_owner_body := replace(v_owner_body, '{{amount}}', p_amount::text);

        INSERT INTO notifications (
            tenant_id, branch_id, user_id, template_id, type, title, body, reference_id, reference_type, metadata, is_read, created_at
        ) VALUES (
            v_invoice.tenant_id, v_invoice.branch_id, v_owner_user_id, v_owner_template.id, v_owner_template.type, v_owner_title, v_owner_body, p_invoice_id, 'payment', jsonb_build_object('invoice_id', p_invoice_id, 'amount', p_amount), false, now()
        );
    END IF;
END;
$$;

-- 4. RPC for Security Notifications
CREATE OR REPLACE FUNCTION "public"."create_security_notifications"(
    "p_user_id" "uuid",
    "p_tenant_id" "uuid",
    "p_notification_type" "text",
    "p_extra_data" "jsonb" DEFAULT '{}'::jsonb
) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_owner_user_id UUID;
    v_owner_template RECORD;
    v_owner_title TEXT;
    v_owner_body TEXT;
    v_staff_name TEXT := '';
BEGIN
    -- For security, usually the notification goes to the owner of the tenant
    SELECT id INTO v_owner_user_id FROM users 
    WHERE tenant_id = p_tenant_id AND id IN (
        SELECT user_id FROM user_roles 
        INNER JOIN roles ON roles.id = user_roles.role_id 
        WHERE roles.name = 'owner'
    ) LIMIT 1;

    SELECT * INTO v_owner_template FROM notification_templates 
    WHERE type = p_notification_type || '_owner' AND is_active = true LIMIT 1;

    IF v_owner_template.id IS NOT NULL AND v_owner_user_id IS NOT NULL THEN
        v_owner_title := COALESCE(v_owner_template.subject, '');
        v_owner_body := COALESCE(v_owner_template.body, '');

        IF p_extra_data ? 'staff_name' THEN
            v_staff_name := p_extra_data->>'staff_name';
            v_owner_title := replace(v_owner_title, '{{staff_name}}', v_staff_name);
            v_owner_body := replace(v_owner_body, '{{staff_name}}', v_staff_name);
        END IF;

        INSERT INTO notifications (
            tenant_id, user_id, template_id, type, title, body, reference_id, reference_type, metadata, is_read, created_at
        ) VALUES (
            p_tenant_id, v_owner_user_id, v_owner_template.id, v_owner_template.type, v_owner_title, v_owner_body, p_user_id, 'security', p_extra_data, false, now()
        );
    END IF;
END;
$$;
