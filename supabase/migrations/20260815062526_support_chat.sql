-- 1. Create Tables

CREATE TABLE public.support_flows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_support_flows_active_category ON public.support_flows(is_active, category);

CREATE TABLE public.support_flow_nodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flow_id UUID NOT NULL REFERENCES public.support_flows(id) ON DELETE CASCADE,
    node_type TEXT NOT NULL CHECK (node_type IN ('message', 'question', 'options', 'text_input', 'confirmation', 'create_ticket')),
    message TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_support_flow_nodes_flow_id ON public.support_flow_nodes(flow_id);

CREATE TABLE public.support_flow_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    node_id UUID NOT NULL REFERENCES public.support_flow_nodes(id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    value TEXT NOT NULL,
    next_node_id UUID REFERENCES public.support_flow_nodes(id) ON DELETE SET NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_support_flow_options_node_id ON public.support_flow_options(node_id);
CREATE INDEX idx_support_flow_options_next_node_id ON public.support_flow_options(next_node_id);

-- Enable RLS
ALTER TABLE public.support_flows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_flow_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_flow_options ENABLE ROW LEVEL SECURITY;

-- Create Policies (Authenticated users can SELECT active flows and their nodes/options)
CREATE POLICY "Allow authenticated users to read active flows"
    ON public.support_flows FOR SELECT
    TO authenticated
    USING (is_active = true);

CREATE POLICY "Allow authenticated users to read nodes of active flows"
    ON public.support_flow_nodes FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.support_flows 
            WHERE support_flows.id = support_flow_nodes.flow_id 
            AND support_flows.is_active = true
        )
    );

CREATE POLICY "Allow authenticated users to read options of active flows"
    ON public.support_flow_options FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.support_flow_nodes
            JOIN public.support_flows ON support_flows.id = support_flow_nodes.flow_id
            WHERE support_flow_nodes.id = support_flow_options.node_id
            AND support_flows.is_active = true
        )
    );

-- Seed Data using a DO block to manage IDs safely and keep it idempotent
DO $$
DECLARE
    -- Flow IDs
    flow_tech UUID := gen_random_uuid();
    flow_acc UUID := gen_random_uuid();
    flow_bill UUID := gen_random_uuid();
    flow_pay UUID := gen_random_uuid();
    flow_appt UUID := gen_random_uuid();
    flow_staff UUID := gen_random_uuid();
    flow_app UUID := gen_random_uuid();

    -- Nodes
    tech_node_1 UUID := gen_random_uuid();
    tech_node_details UUID := gen_random_uuid();
    tech_node_conf UUID := gen_random_uuid();
    tech_node_ticket UUID := gen_random_uuid();

    acc_node_1 UUID := gen_random_uuid();
    acc_node_details UUID := gen_random_uuid();
    acc_node_conf UUID := gen_random_uuid();
    acc_node_ticket UUID := gen_random_uuid();

    bill_node_1 UUID := gen_random_uuid();
    bill_node_details UUID := gen_random_uuid();
    bill_node_conf UUID := gen_random_uuid();
    bill_node_ticket UUID := gen_random_uuid();

    pay_node_1 UUID := gen_random_uuid();
    pay_node_details UUID := gen_random_uuid();
    pay_node_conf UUID := gen_random_uuid();
    pay_node_ticket UUID := gen_random_uuid();

    appt_node_1 UUID := gen_random_uuid();
    appt_node_details UUID := gen_random_uuid();
    appt_node_conf UUID := gen_random_uuid();
    appt_node_ticket UUID := gen_random_uuid();

    staff_node_1 UUID := gen_random_uuid();
    staff_node_details UUID := gen_random_uuid();
    staff_node_conf UUID := gen_random_uuid();
    staff_node_ticket UUID := gen_random_uuid();

    app_node_1 UUID := gen_random_uuid();
    app_node_details UUID := gen_random_uuid();
    app_node_conf UUID := gen_random_uuid();
    app_node_ticket UUID := gen_random_uuid();

BEGIN
    -- Only insert if the tables are empty or specific categories don't exist to make it idempotent
    IF NOT EXISTS (SELECT 1 FROM public.support_flows WHERE category = 'technical') THEN

        ---------------------------------------------------------
        -- 1. TECHNICAL SUPPORT FLOW
        ---------------------------------------------------------
        INSERT INTO public.support_flows (id, name, category, is_active) VALUES 
        (flow_tech, 'Technical Support', 'technical', true);

        INSERT INTO public.support_flow_nodes (id, flow_id, node_type, message, metadata, sort_order) VALUES 
        (tech_node_1, flow_tech, 'options', 'What problem are you experiencing?', '{"intent": "identify_problem"}'::jsonb, 1),
        (tech_node_details, flow_tech, 'text_input', 'Please describe what is happening in a little more detail.', '{"intent": "collect_details", "field": "description"}'::jsonb, 2),
        (tech_node_conf, flow_tech, 'options', 'Thanks! I have collected the details of your issue. Would you like me to create a support ticket?', '{"intent": "confirm_ticket"}'::jsonb, 3),
        (tech_node_ticket, flow_tech, 'create_ticket', 'Creating your ticket now...', '{"intent": "create_ticket", "category": "technical"}'::jsonb, 4);

        INSERT INTO public.support_flow_options (node_id, label, value, next_node_id, sort_order) VALUES
        (tech_node_1, 'App is crashing', 'app_crash', tech_node_details, 1),
        (tech_node_1, 'Blank/white screen', 'blank_screen', tech_node_details, 2),
        (tech_node_1, 'App is slow', 'app_slow', tech_node_details, 3),
        (tech_node_1, 'Feature is not working', 'feature_broken', tech_node_details, 4),
        (tech_node_1, 'Login or connection problem', 'login_problem', tech_node_details, 5),
        (tech_node_1, 'Other', 'other', tech_node_details, 6);

        INSERT INTO public.support_flow_options (node_id, label, value, next_node_id, sort_order) VALUES
        (tech_node_conf, 'Create Support Ticket', 'create_ticket', tech_node_ticket, 1),
        (tech_node_conf, 'Not Now', 'not_now', NULL, 2);

        ---------------------------------------------------------
        -- 2. ACCOUNT SUPPORT FLOW
        ---------------------------------------------------------
        INSERT INTO public.support_flows (id, name, category, is_active) VALUES 
        (flow_acc, 'Account Support', 'account', true);

        INSERT INTO public.support_flow_nodes (id, flow_id, node_type, message, metadata, sort_order) VALUES 
        (acc_node_1, flow_acc, 'options', 'What account issue are you facing?', '{"intent": "identify_problem"}'::jsonb, 1),
        (acc_node_details, flow_acc, 'text_input', 'Could you provide a few more details about this account issue?', '{"intent": "collect_details", "field": "description"}'::jsonb, 2),
        (acc_node_conf, flow_acc, 'options', 'Thank you. Would you like me to create a support ticket for this?', '{"intent": "confirm_ticket"}'::jsonb, 3),
        (acc_node_ticket, flow_acc, 'create_ticket', 'Creating your ticket...', '{"intent": "create_ticket", "category": "account"}'::jsonb, 4);

        INSERT INTO public.support_flow_options (node_id, label, value, next_node_id, sort_order) VALUES
        (acc_node_1, 'Can''t sign in', 'cant_sign_in', acc_node_details, 1),
        (acc_node_1, 'Account information issue', 'account_info', acc_node_details, 2),
        (acc_node_1, 'Device/session issue', 'device_session', acc_node_details, 3),
        (acc_node_1, 'Security concern', 'security_concern', acc_node_details, 4),
        (acc_node_1, 'Account access problem', 'access_problem', acc_node_details, 5),
        (acc_node_1, 'Other', 'other', acc_node_details, 6);

        INSERT INTO public.support_flow_options (node_id, label, value, next_node_id, sort_order) VALUES
        (acc_node_conf, 'Create Support Ticket', 'create_ticket', acc_node_ticket, 1),
        (acc_node_conf, 'Not Now', 'not_now', NULL, 2);

        ---------------------------------------------------------
        -- 3. BILLING SUPPORT FLOW
        ---------------------------------------------------------
        INSERT INTO public.support_flows (id, name, category, is_active) VALUES 
        (flow_bill, 'Billing Support', 'billing', true);

        INSERT INTO public.support_flow_nodes (id, flow_id, node_type, message, metadata, sort_order) VALUES 
        (bill_node_1, flow_bill, 'options', 'What kind of billing support do you need?', '{"intent": "identify_problem"}'::jsonb, 1),
        (bill_node_details, flow_bill, 'text_input', 'Please describe your billing inquiry in more detail.', '{"intent": "collect_details", "field": "description"}'::jsonb, 2),
        (bill_node_conf, flow_bill, 'options', 'Got it. Should I create a support ticket for our billing team?', '{"intent": "confirm_ticket"}'::jsonb, 3),
        (bill_node_ticket, flow_bill, 'create_ticket', 'Creating your ticket...', '{"intent": "create_ticket", "category": "billing"}'::jsonb, 4);

        INSERT INTO public.support_flow_options (node_id, label, value, next_node_id, sort_order) VALUES
        (bill_node_1, 'Invoice problem', 'invoice_problem', bill_node_details, 1),
        (bill_node_1, 'Incorrect billing amount', 'incorrect_amount', bill_node_details, 2),
        (bill_node_1, 'Tax/GST issue', 'tax_gst', bill_node_details, 3),
        (bill_node_1, 'Subscription/billing question', 'subscription_question', bill_node_details, 4),
        (bill_node_1, 'Other', 'other', bill_node_details, 5);

        INSERT INTO public.support_flow_options (node_id, label, value, next_node_id, sort_order) VALUES
        (bill_node_conf, 'Create Support Ticket', 'create_ticket', bill_node_ticket, 1),
        (bill_node_conf, 'Not Now', 'not_now', NULL, 2);

        ---------------------------------------------------------
        -- 4. PAYMENT SUPPORT FLOW
        ---------------------------------------------------------
        INSERT INTO public.support_flows (id, name, category, is_active) VALUES 
        (flow_pay, 'Payment Support', 'payment', true);

        INSERT INTO public.support_flow_nodes (id, flow_id, node_type, message, metadata, sort_order) VALUES 
        (pay_node_1, flow_pay, 'options', 'How can we help with your payment?', '{"intent": "identify_problem"}'::jsonb, 1),
        (pay_node_details, flow_pay, 'text_input', 'Please provide any relevant details (like transaction IDs if applicable).', '{"intent": "collect_details", "field": "description"}'::jsonb, 2),
        (pay_node_conf, flow_pay, 'options', 'Thanks! Would you like to create a support ticket for this payment issue?', '{"intent": "confirm_ticket"}'::jsonb, 3),
        (pay_node_ticket, flow_pay, 'create_ticket', 'Creating your ticket...', '{"intent": "create_ticket", "category": "payment"}'::jsonb, 4);

        INSERT INTO public.support_flow_options (node_id, label, value, next_node_id, sort_order) VALUES
        (pay_node_1, 'Payment failed', 'payment_failed', pay_node_details, 1),
        (pay_node_1, 'Payment deducted but not reflected', 'payment_not_reflected', pay_node_details, 2),
        (pay_node_1, 'Payment status incorrect', 'status_incorrect', pay_node_details, 3),
        (pay_node_1, 'Refund problem', 'refund_problem', pay_node_details, 4),
        (pay_node_1, 'Other', 'other', pay_node_details, 5);

        INSERT INTO public.support_flow_options (node_id, label, value, next_node_id, sort_order) VALUES
        (pay_node_conf, 'Create Support Ticket', 'create_ticket', pay_node_ticket, 1),
        (pay_node_conf, 'Not Now', 'not_now', NULL, 2);

        ---------------------------------------------------------
        -- 5. APPOINTMENT SUPPORT FLOW
        ---------------------------------------------------------
        INSERT INTO public.support_flows (id, name, category, is_active) VALUES 
        (flow_appt, 'Appointment Support', 'appointment', true);

        INSERT INTO public.support_flow_nodes (id, flow_id, node_type, message, metadata, sort_order) VALUES 
        (appt_node_1, flow_appt, 'options', 'What issue are you experiencing with appointments?', '{"intent": "identify_problem"}'::jsonb, 1),
        (appt_node_details, flow_appt, 'text_input', 'Could you tell us more about this appointment issue?', '{"intent": "collect_details", "field": "description"}'::jsonb, 2),
        (appt_node_conf, flow_appt, 'options', 'Thank you. Do you want me to open a support ticket?', '{"intent": "confirm_ticket"}'::jsonb, 3),
        (appt_node_ticket, flow_appt, 'create_ticket', 'Creating your ticket...', '{"intent": "create_ticket", "category": "appointment"}'::jsonb, 4);

        INSERT INTO public.support_flow_options (node_id, label, value, next_node_id, sort_order) VALUES
        (appt_node_1, 'Can''t create appointment', 'cant_create', appt_node_details, 1),
        (appt_node_1, 'Appointment not showing', 'not_showing', appt_node_details, 2),
        (appt_node_1, 'Can''t edit appointment', 'cant_edit', appt_node_details, 3),
        (appt_node_1, 'Can''t cancel appointment', 'cant_cancel', appt_node_details, 4),
        (appt_node_1, 'Appointment notification problem', 'notification_problem', appt_node_details, 5),
        (appt_node_1, 'Other', 'other', appt_node_details, 6);

        INSERT INTO public.support_flow_options (node_id, label, value, next_node_id, sort_order) VALUES
        (appt_node_conf, 'Create Support Ticket', 'create_ticket', appt_node_ticket, 1),
        (appt_node_conf, 'Not Now', 'not_now', NULL, 2);

        ---------------------------------------------------------
        -- 6. STAFF SUPPORT FLOW
        ---------------------------------------------------------
        INSERT INTO public.support_flows (id, name, category, is_active) VALUES 
        (flow_staff, 'Staff Support', 'staff', true);

        INSERT INTO public.support_flow_nodes (id, flow_id, node_type, message, metadata, sort_order) VALUES 
        (staff_node_1, flow_staff, 'options', 'What kind of staff-related problem are you having?', '{"intent": "identify_problem"}'::jsonb, 1),
        (staff_node_details, flow_staff, 'text_input', 'Please describe the staff issue in more detail.', '{"intent": "collect_details", "field": "description"}'::jsonb, 2),
        (staff_node_conf, flow_staff, 'options', 'Got it. Should I create a support ticket for this?', '{"intent": "confirm_ticket"}'::jsonb, 3),
        (staff_node_ticket, flow_staff, 'create_ticket', 'Creating your ticket...', '{"intent": "create_ticket", "category": "staff"}'::jsonb, 4);

        INSERT INTO public.support_flow_options (node_id, label, value, next_node_id, sort_order) VALUES
        (staff_node_1, 'Can''t add staff', 'cant_add', staff_node_details, 1),
        (staff_node_1, 'Staff invitation problem', 'invitation_problem', staff_node_details, 2),
        (staff_node_1, 'Staff login/access problem', 'login_access', staff_node_details, 3),
        (staff_node_1, 'Staff information problem', 'info_problem', staff_node_details, 4),
        (staff_node_1, 'Staff permissions problem', 'permissions_problem', staff_node_details, 5),
        (staff_node_1, 'Other', 'other', staff_node_details, 6);

        INSERT INTO public.support_flow_options (node_id, label, value, next_node_id, sort_order) VALUES
        (staff_node_conf, 'Create Support Ticket', 'create_ticket', staff_node_ticket, 1),
        (staff_node_conf, 'Not Now', 'not_now', NULL, 2);

        ---------------------------------------------------------
        -- 7. APP SUPPORT FLOW
        ---------------------------------------------------------
        INSERT INTO public.support_flows (id, name, category, is_active) VALUES 
        (flow_app, 'App Support', 'app', true);

        INSERT INTO public.support_flow_nodes (id, flow_id, node_type, message, metadata, sort_order) VALUES 
        (app_node_1, flow_app, 'options', 'What seems to be the issue with the app?', '{"intent": "identify_problem"}'::jsonb, 1),
        (app_node_details, flow_app, 'text_input', 'Please provide a bit more detail about what is happening.', '{"intent": "collect_details", "field": "description"}'::jsonb, 2),
        (app_node_conf, flow_app, 'options', 'Thanks! Would you like me to create a support ticket?', '{"intent": "confirm_ticket"}'::jsonb, 3),
        (app_node_ticket, flow_app, 'create_ticket', 'Creating your ticket...', '{"intent": "create_ticket", "category": "app"}'::jsonb, 4);

        INSERT INTO public.support_flow_options (node_id, label, value, next_node_id, sort_order) VALUES
        (app_node_1, 'App crash', 'app_crash', app_node_details, 1),
        (app_node_1, 'Blank/white screen', 'blank_screen', app_node_details, 2),
        (app_node_1, 'Feature not working', 'feature_broken', app_node_details, 3),
        (app_node_1, 'Navigation problem', 'navigation_problem', app_node_details, 4),
        (app_node_1, 'Notification problem', 'notification_problem', app_node_details, 5),
        (app_node_1, 'Performance issue', 'performance_issue', app_node_details, 6),
        (app_node_1, 'Other', 'other', app_node_details, 7);

        INSERT INTO public.support_flow_options (node_id, label, value, next_node_id, sort_order) VALUES
        (app_node_conf, 'Create Support Ticket', 'create_ticket', app_node_ticket, 1),
        (app_node_conf, 'Not Now', 'not_now', NULL, 2);

    END IF;
END $$;
