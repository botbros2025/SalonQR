-- Migration: Fix Push Notification Architecture

-- 1. Add channel column to notifications
ALTER TABLE "public"."notifications" ADD COLUMN IF NOT EXISTS "channel" text NOT NULL DEFAULT 'IN_APP';

-- 2. Update create_appointment_notifications
CREATE OR REPLACE FUNCTION create_appointment_notifications(
    p_appointment_id UUID,
    p_notification_type TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_appointment RECORD;
    v_client_name TEXT;
    v_staff_user_id UUID; 
    v_template RECORD;
    v_title TEXT;
    v_body TEXT;
BEGIN

    -- GET APPOINTMENT
    SELECT * INTO v_appointment FROM appointments WHERE id = p_appointment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Appointment not found';
    END IF;

    -- GET CLIENT
    SELECT name INTO v_client_name FROM clients WHERE id = v_appointment.client_id;

    -- GET STAFF USER
    IF v_appointment.primary_staff_id IS NOT NULL THEN
        SELECT user_id INTO v_staff_user_id FROM staff WHERE id = v_appointment.primary_staff_id;
    END IF;

    -- =========================================
    -- STAFF NOTIFICATIONS
    -- =========================================
    IF v_staff_user_id IS NOT NULL THEN
        FOR v_template IN
            SELECT * FROM notification_templates
            WHERE type = p_notification_type || '_staff'
            AND is_active = true
        LOOP
            v_title := replace(COALESCE(v_template.subject, ''), '{{client_name}}', COALESCE(v_client_name, 'Client'));
            v_body := replace(replace(COALESCE(v_template.body, ''), '{{client_name}}', COALESCE(v_client_name, 'Client')), '{{start_time}}', to_char(v_appointment.start_time, 'HH12:MI AM'));

            INSERT INTO notifications (
                tenant_id, branch_id, user_id, staff_id, template_id, type, channel, title, body, reference_id, reference_type, metadata, is_read, created_at
            )
            VALUES (
                v_appointment.tenant_id, v_appointment.branch_id, v_staff_user_id, v_appointment.primary_staff_id, v_template.id, v_template.type, COALESCE(v_template.channel, 'IN_APP'), v_title, v_body, v_appointment.id, 'appointment',
                jsonb_build_object(
                    'appointment_id', v_appointment.id,
                    'client_id', v_appointment.client_id,
                    'client_name', v_client_name,
                    'appointment_date', v_appointment.appointment_date,
                    'start_time', v_appointment.start_time,
                    'status', v_appointment.status
                ), false, now()
            ) ON CONFLICT DO NOTHING;
        END LOOP;
    END IF;

    -- =========================================
    -- OWNER NOTIFICATIONS
    -- =========================================
    FOR v_template IN
        SELECT * FROM notification_templates
        WHERE type = p_notification_type || '_owner'
        AND is_active = true
    LOOP
        v_title := replace(COALESCE(v_template.subject, ''), '{{client_name}}', COALESCE(v_client_name, 'Client'));
        v_body := replace(replace(COALESCE(v_template.body, ''), '{{client_name}}', COALESCE(v_client_name, 'Client')), '{{start_time}}', to_char(v_appointment.start_time, 'HH12:MI AM'));

        INSERT INTO notifications (
            tenant_id, branch_id, user_id, template_id, type, channel, title, body, reference_id, reference_type, metadata, is_read, created_at
        )
        SELECT DISTINCT
            v_appointment.tenant_id, v_appointment.branch_id, ur.user_id, v_template.id, v_template.type, COALESCE(v_template.channel, 'IN_APP'), v_title, v_body, v_appointment.id, 'appointment',
            jsonb_build_object(
                'appointment_id', v_appointment.id,
                'client_id', v_appointment.client_id,
                'client_name', v_client_name,
                'appointment_date', v_appointment.appointment_date,
                'start_time', v_appointment.start_time,
                'status', v_appointment.status
            ), false, now()
        FROM user_roles ur
        JOIN users u ON u.id = ur.user_id
        WHERE ur.tenant_id = v_appointment.tenant_id
        AND ur.role_id = '00000000-0000-0000-0000-000000000001'
        AND u.is_active = true
        AND (v_staff_user_id IS NULL OR ur.user_id <> v_staff_user_id)
        ON CONFLICT DO NOTHING;
    END LOOP;

END;
$$;


-- 3. Update create_staff_notifications
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
    v_template RECORD;
    v_title TEXT;
    v_body TEXT;
BEGIN
    SELECT full_name INTO v_staff_name FROM users WHERE id = p_staff_id;

    FOR v_template IN 
        SELECT * FROM notification_templates 
        WHERE type = p_notification_type || '_owner' AND is_active = true
    LOOP
        v_title := replace(COALESCE(v_template.subject, ''), '{{staff_name}}', COALESCE(v_staff_name, 'Staff'));
        v_body := replace(COALESCE(v_template.body, ''), '{{staff_name}}', COALESCE(v_staff_name, 'Staff'));
        
        IF p_extra_data ? 'leave_date' THEN
            v_body := replace(v_body, '{{leave_date}}', (p_extra_data->>'leave_date')::text);
        END IF;

        INSERT INTO notifications (
            tenant_id, branch_id, user_id, template_id, type, channel, title, body, reference_id, reference_type, metadata, is_read, created_at
        ) 
        SELECT DISTINCT
            p_tenant_id, p_branch_id, user_roles.user_id, v_template.id, v_template.type, COALESCE(v_template.channel, 'IN_APP'), v_title, v_body, p_reference_id, 'staff', p_extra_data, false, now()
        FROM user_roles 
        INNER JOIN roles ON roles.id = user_roles.role_id 
        WHERE roles.name = 'owner' AND user_roles.tenant_id = p_tenant_id
        ON CONFLICT DO NOTHING;
    END LOOP;
END;
$$;


-- 4. Update create_payment_notifications
CREATE OR REPLACE FUNCTION "public"."create_payment_notifications"(
    "p_invoice_id" "uuid",
    "p_notification_type" "text",
    "p_amount" "numeric"
) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_invoice RECORD;
    v_template RECORD;
    v_title TEXT;
    v_body TEXT;
BEGIN
    SELECT * INTO v_invoice FROM invoices WHERE id = p_invoice_id;
    IF NOT FOUND THEN RETURN; END IF;

    FOR v_template IN 
        SELECT * FROM notification_templates 
        WHERE type = p_notification_type || '_owner' AND is_active = true
    LOOP
        v_title := replace(COALESCE(v_template.subject, ''), '{{invoice_number}}', COALESCE(v_invoice.invoice_number, ''));
        v_body := replace(COALESCE(v_template.body, ''), '{{invoice_number}}', COALESCE(v_invoice.invoice_number, ''));
        v_body := replace(v_body, '{{amount}}', p_amount::text);

        INSERT INTO notifications (
            tenant_id, branch_id, user_id, template_id, type, channel, title, body, reference_id, reference_type, metadata, is_read, created_at
        ) 
        SELECT DISTINCT
            v_invoice.tenant_id, v_invoice.branch_id, user_roles.user_id, v_template.id, v_template.type, COALESCE(v_template.channel, 'IN_APP'), v_title, v_body, p_invoice_id, 'payment', jsonb_build_object('invoice_id', p_invoice_id, 'amount', p_amount), false, now()
        FROM user_roles 
        INNER JOIN roles ON roles.id = user_roles.role_id 
        WHERE roles.name = 'owner' AND user_roles.tenant_id = v_invoice.tenant_id
        ON CONFLICT DO NOTHING;
    END LOOP;
END;
$$;


-- 5. Update create_security_notifications
CREATE OR REPLACE FUNCTION "public"."create_security_notifications"(
    "p_user_id" "uuid",
    "p_tenant_id" "uuid",
    "p_notification_type" "text",
    "p_extra_data" "jsonb" DEFAULT '{}'::jsonb
) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_template RECORD;
    v_title TEXT;
    v_body TEXT;
    v_staff_name TEXT := '';
BEGIN
    FOR v_template IN 
        SELECT * FROM notification_templates 
        WHERE type = p_notification_type || '_owner' AND is_active = true
    LOOP
        v_title := COALESCE(v_template.subject, '');
        v_body := COALESCE(v_template.body, '');

        IF p_extra_data ? 'staff_name' THEN
            v_staff_name := p_extra_data->>'staff_name';
            v_title := replace(v_title, '{{staff_name}}', v_staff_name);
            v_body := replace(v_body, '{{staff_name}}', v_staff_name);
        END IF;

        INSERT INTO notifications (
            tenant_id, user_id, template_id, type, channel, title, body, reference_id, reference_type, metadata, is_read, created_at
        ) 
        SELECT DISTINCT
            p_tenant_id, user_roles.user_id, v_template.id, v_template.type, COALESCE(v_template.channel, 'IN_APP'), v_title, v_body, p_user_id, 'security', p_extra_data, false, now()
        FROM user_roles 
        INNER JOIN roles ON roles.id = user_roles.role_id 
        WHERE roles.name = 'owner' AND user_roles.tenant_id = p_tenant_id
        ON CONFLICT DO NOTHING;
    END LOOP;
END;
$$;

-- (Webhook trigger creation removed. Please create the Database Webhook directly in the Supabase Dashboard 
-- to automatically handle Project URLs and Authorization headers securely.)
