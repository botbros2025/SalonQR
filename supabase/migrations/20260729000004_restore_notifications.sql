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
                v_appointment.tenant_id, v_appointment.branch_id, v_staff_user_id, v_appointment.primary_staff_id, v_template.id, v_template.type, COALESCE(v_template.channel::text, 'IN_APP'), v_title, v_body, v_appointment.id, 'appointment',
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
            v_appointment.tenant_id, v_appointment.branch_id, ur.user_id, v_template.id, v_template.type, COALESCE(v_template.channel::text, 'IN_APP'), v_title, v_body, v_appointment.id, 'appointment',
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
