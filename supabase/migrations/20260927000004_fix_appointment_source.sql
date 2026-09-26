CREATE OR REPLACE FUNCTION public.create_public_booking(
    p_tenant_id uuid,
    p_branch_id uuid,
    p_customer_name text,
    p_customer_phone text,
    p_appointment_date date,
    p_start_time time without time zone,
    p_end_time time without time zone,
    p_staff_id uuid,
    p_services json
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_client_id uuid;
    v_appointment_id uuid;
    v_service json;
BEGIN
    -- 1. Try to find existing client
    SELECT id INTO v_client_id
    FROM clients
    WHERE tenant_id = p_tenant_id AND phone = p_customer_phone
    LIMIT 1;

    -- 2. Create new client if not exists
    IF v_client_id IS NULL THEN
        INSERT INTO clients (tenant_id, branch_id, name, phone, source)
        VALUES (p_tenant_id, p_branch_id, p_customer_name, p_customer_phone, 'ONLINE'::public.client_source)
        RETURNING id INTO v_client_id;
    END IF;

    -- 3. Create appointment
    INSERT INTO appointments (
        tenant_id, 
        branch_id, 
        client_id, 
        appointment_date, 
        start_time, 
        end_time, 
        status, 
        source, 
        primary_staff_id,
        created_by
    )
    VALUES (
        p_tenant_id,
        p_branch_id,
        v_client_id,
        p_appointment_date,
        p_start_time,
        p_end_time,
        'SCHEDULED',
        'ONLINE',
        p_staff_id,
        NULL
    )
    RETURNING id INTO v_appointment_id;

    -- 4. Create appointment services
    FOR v_service IN SELECT * FROM json_array_elements(p_services)
    LOOP
        INSERT INTO appointment_services (
            appointment_id,
            service_id,
            service_name,
            duration_minutes,
            price,
            staff_id,
            branch_id,
            added_by
        )
        VALUES (
            v_appointment_id,
            (v_service->>'id')::uuid,
            v_service->>'name',
            (v_service->>'duration_minutes')::integer,
            (v_service->>'price')::numeric,
            p_staff_id,
            p_branch_id,
            NULL
        );
    END LOOP;

    RETURN json_build_object(
        'success', true,
        'appointmentId', v_appointment_id,
        'bookingId', UPPER(split_part(v_appointment_id::text, '-', 1))
    );

EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$;
