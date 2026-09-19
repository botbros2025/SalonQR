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
-- REVIEW RECEIVED
-- =====================================================

(
    NULL,
    NULL,
    'Review Received Staff',
    'review_received_staff',
    'IN_APP',
    'New Review Received',
    '{{client_name}} gave you {{rating}}★ review',
    true,
    true
),

(
    NULL,
    NULL,
    'Review Received Owner',
    'review_received_owner',
    'IN_APP',
    'New Customer Review',
    '{{client_name}} submitted {{rating}}★ feedback',
    true,
    true
);





CREATE OR REPLACE FUNCTION create_feedback_notifications(
    p_feedback_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE

    v_feedback RECORD;
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
    -- GET FEEDBACK
    -- =========================================

    SELECT *
    INTO v_feedback
    FROM feedback
    WHERE id = p_feedback_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Feedback not found';
    END IF;

    -- =========================================
    -- GET CLIENT
    -- =========================================

    SELECT name
    INTO v_client_name
    FROM clients
    WHERE id = v_feedback.client_id;

    -- =========================================
    -- GET STAFF USER
    -- =========================================

    IF v_feedback.staff_id IS NOT NULL THEN

        SELECT user_id
        INTO v_staff_user_id
        FROM staff
        WHERE id = v_feedback.staff_id;

    END IF;

    -- =========================================
    -- GET TEMPLATES
    -- =========================================

    SELECT *
    INTO v_staff_template
    FROM notification_templates
    WHERE type = 'review_received_staff'
    AND is_active = true
    LIMIT 1;

    SELECT *
    INTO v_owner_template
    FROM notification_templates
    WHERE type = 'review_received_owner'
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
                '{{rating}}',
                COALESCE(v_feedback.overall_rating::text, '0')
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
                '{{rating}}',
                COALESCE(v_feedback.overall_rating::text, '0')
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
            v_feedback.tenant_id,
            v_feedback.branch_id,
            v_staff_user_id,
            v_feedback.staff_id,
            v_staff_template.id,
            v_staff_template.type,
            v_staff_title,
            v_staff_body,
            v_feedback.id,
            'feedback',

            jsonb_build_object(
                'feedback_id', v_feedback.id,
                'appointment_id', v_feedback.appointment_id,
                'client_id', v_feedback.client_id,
                'client_name', v_client_name,
                'rating', v_feedback.overall_rating,
                'comment', v_feedback.comment,
                'status', v_feedback.status
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
        v_feedback.tenant_id,
        v_feedback.branch_id,
        ur.user_id,
        v_owner_template.id,
        v_owner_template.type,
        v_owner_title,
        v_owner_body,
        v_feedback.id,
        'feedback',

        jsonb_build_object(
            'feedback_id', v_feedback.id,
            'appointment_id', v_feedback.appointment_id,
            'client_id', v_feedback.client_id,
            'client_name', v_client_name,
            'rating', v_feedback.overall_rating,
            'comment', v_feedback.comment,
            'status', v_feedback.status
        ),

        false,
        now()

    FROM user_roles ur

    JOIN users u
        ON u.id = ur.user_id

    WHERE ur.tenant_id = v_feedback.tenant_id

    AND ur.role_id =
        '00000000-0000-0000-0000-000000000001'

    AND u.is_active = true

    AND v_owner_template.id IS NOT NULL

    AND (
        v_staff_user_id IS NULL
        OR ur.user_id <> v_staff_user_id
    )

    ON CONFLICT DO NOTHING;

END;
$$;


CREATE OR REPLACE FUNCTION trigger_feedback_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    PERFORM create_feedback_notifications(NEW.id);

    RETURN NEW;

END;
$$;


DROP TRIGGER IF EXISTS trg_feedback_notifications
ON feedback;

CREATE TRIGGER trg_feedback_notifications
AFTER INSERT ON feedback
FOR EACH ROW
EXECUTE FUNCTION trigger_feedback_notifications();