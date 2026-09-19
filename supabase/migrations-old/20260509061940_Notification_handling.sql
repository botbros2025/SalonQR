
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

    v_staff_template RECORD;
    v_owner_template RECORD;

    v_staff_title TEXT;
    v_staff_body TEXT;

    v_owner_title TEXT;
    v_owner_body TEXT;

BEGIN

    -- =========================================
    -- GET APPOINTMENT
    -- =========================================

    SELECT *
    INTO v_appointment
    FROM appointments
    WHERE id = p_appointment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Appointment not found';
    END IF;

    -- =========================================
    -- GET CLIENT
    -- =========================================

    SELECT name
    INTO v_client_name
    FROM clients
    WHERE id = v_appointment.client_id;

    -- =========================================
    -- GET STAFF USER
    -- =========================================

    IF v_appointment.primary_staff_id IS NOT NULL THEN

        SELECT user_id
        INTO v_staff_user_id
        FROM staff
        WHERE id = v_appointment.primary_staff_id;

    END IF;

    -- =========================================
    -- GET STAFF TEMPLATE
    -- =========================================

    SELECT *
    INTO v_staff_template
    FROM notification_templates
    WHERE type = p_notification_type || '_staff'
    AND is_active = true
    LIMIT 1;

    -- =========================================
    -- GET OWNER TEMPLATE
    -- =========================================

    SELECT *
    INTO v_owner_template
    FROM notification_templates
    WHERE type = p_notification_type || '_owner'
    AND is_active = true
    LIMIT 1;

    -- =========================================
    -- RENDER STAFF TEMPLATE
    -- =========================================

    IF v_staff_template.id IS NOT NULL THEN

        v_staff_title :=
            replace(
                COALESCE(v_staff_template.subject, ''),
                '{{client_name}}',
                COALESCE(v_client_name, 'Client')
            );

        v_staff_body :=
            replace(
                replace(
                    COALESCE(v_staff_template.body, ''),
                    '{{client_name}}',
                    COALESCE(v_client_name, 'Client')
                ),
                '{{start_time}}',
                to_char(v_appointment.start_time, 'HH12:MI AM')
            );

    END IF;

    -- =========================================
    -- RENDER OWNER TEMPLATE
    -- =========================================

    IF v_owner_template.id IS NOT NULL THEN

        v_owner_title :=
            replace(
                COALESCE(v_owner_template.subject, ''),
                '{{client_name}}',
                COALESCE(v_client_name, 'Client')
            );

        v_owner_body :=
            replace(
                replace(
                    COALESCE(v_owner_template.body, ''),
                    '{{client_name}}',
                    COALESCE(v_client_name, 'Client')
                ),
                '{{start_time}}',
                to_char(v_appointment.start_time, 'HH12:MI AM')
            );

    END IF;

    -- =========================================
    -- STAFF NOTIFICATION
    -- =========================================

    IF v_staff_user_id IS NOT NULL
    AND v_staff_template.id IS NOT NULL THEN

        INSERT INTO notifications (
            tenant_id,
            branch_id,
            user_id,
            staff_id,
            template_id,
            type,
            title,
            body,
            reference_id,
            reference_type,
            metadata,
            is_read,
            created_at
        )
        VALUES (
            v_appointment.tenant_id,
            v_appointment.branch_id,
            v_staff_user_id,
            v_appointment.primary_staff_id,
            v_staff_template.id,
            v_staff_template.type,
            v_staff_title,
            v_staff_body,
            v_appointment.id,
            'appointment',

            jsonb_build_object(
                'appointment_id', v_appointment.id,
                'client_id', v_appointment.client_id,
                'client_name', v_client_name,
                'appointment_date', v_appointment.appointment_date,
                'start_time', v_appointment.start_time,
                'status', v_appointment.status
            ),

            false,
            now()
        )

        ON CONFLICT DO NOTHING;

    END IF;

    -- =========================================
    -- OWNER NOTIFICATIONS
    -- =========================================

    INSERT INTO notifications (
        tenant_id,
        branch_id,
        user_id,
        template_id,
        type,
        title,
        body,
        reference_id,
        reference_type,
        metadata,
        is_read,
        created_at
    )

    SELECT DISTINCT
        v_appointment.tenant_id,
        v_appointment.branch_id,
        ur.user_id,
        v_owner_template.id,
        v_owner_template.type,
        v_owner_title,
        v_owner_body,
        v_appointment.id,
        'appointment',

        jsonb_build_object(
            'appointment_id', v_appointment.id,
            'client_id', v_appointment.client_id,
            'client_name', v_client_name,
            'appointment_date', v_appointment.appointment_date,
            'start_time', v_appointment.start_time,
            'status', v_appointment.status
        ),

        false,
        now()

    FROM user_roles ur

    JOIN users u
        ON u.id = ur.user_id

    WHERE ur.tenant_id = v_appointment.tenant_id

    AND ur.role_id =
        '00000000-0000-0000-0000-000000000001'

    AND u.is_active = true

    AND v_owner_template.id IS NOT NULL

    -- Prevent duplicate if owner is assigned staff
    AND (
        v_staff_user_id IS NULL
        OR ur.user_id <> v_staff_user_id
    )

    ON CONFLICT DO NOTHING;

END;
$$;


CREATE UNIQUE INDEX IF NOT EXISTS
uniq_notification_per_user_event
ON notifications (
    user_id,
    type,
    reference_id
)
WHERE user_id IS NOT NULL;



INSERT INTO notification_templates (
    tenant_id,
    branch_id,
    name,
    type,
    channel,
    subject,
    body,
    is_active,
    is_system_default
)
VALUES

-- =====================================================
-- APPOINTMENT CREATED
-- =====================================================

(
    NULL,
    NULL,
    'Appointment Created Staff',
    'appointment_created_staff',
    'IN_APP',
    'New Appointment Assigned',
    '{{client_name}} booked appointment at {{start_time}}',
    true,
    true
),

(
    NULL,
    NULL,
    'Appointment Created Owner',
    'appointment_created_owner',
    'IN_APP',
    'New Appointment Booked',
    '{{client_name}} booked appointment at {{start_time}}',
    true,
    true
),

-- =====================================================
-- APPOINTMENT RESCHEDULED
-- =====================================================

(
    NULL,
    NULL,
    'Appointment Rescheduled Staff',
    'appointment_rescheduled_staff',
    'IN_APP',
    'Appointment Rescheduled',
    '{{client_name}} appointment rescheduled to {{start_time}}',
    true,
    true
),

(
    NULL,
    NULL,
    'Appointment Rescheduled Owner',
    'appointment_rescheduled_owner',
    'IN_APP',
    'Appointment Rescheduled',
    '{{client_name}} appointment rescheduled to {{start_time}}',
    true,
    true
),

-- =====================================================
-- APPOINTMENT CANCELLED
-- =====================================================

(
    NULL,
    NULL,
    'Appointment Cancelled Staff',
    'appointment_cancelled_staff',
    'IN_APP',
    'Appointment Cancelled',
    '{{client_name}} cancelled appointment at {{start_time}}',
    true,
    true
),

(
    NULL,
    NULL,
    'Appointment Cancelled Owner',
    'appointment_cancelled_owner',
    'IN_APP',
    'Appointment Cancelled',
    '{{client_name}} cancelled appointment at {{start_time}}',
    true,
    true
),

-- =====================================================
-- APPOINTMENT COMPLETED
-- =====================================================

(
    NULL,
    NULL,
    'Appointment Completed Staff',
    'appointment_completed_staff',
    'IN_APP',
    'Appointment Completed',
    '{{client_name}} appointment marked as completed',
    true,
    true
),

(
    NULL,
    NULL,
    'Appointment Completed Owner',
    'appointment_completed_owner',
    'IN_APP',
    'Appointment Completed',
    '{{client_name}} appointment completed successfully',
    true,
    true
),

-- =====================================================
-- APPOINTMENT PAID
-- =====================================================

(
    NULL,
    NULL,
    'Appointment Paid Staff',
    'appointment_paid_staff',
    'IN_APP',
    'Payment Received',
    '{{client_name}} payment received successfully',
    true,
    true
),

(
    NULL,
    NULL,
    'Appointment Paid Owner',
    'appointment_paid_owner',
    'IN_APP',
    'Payment Received',
    '{{client_name}} payment received for appointment',
    true,
    true
);

ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;--for realtime