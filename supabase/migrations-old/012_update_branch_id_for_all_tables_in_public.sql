DO $$
DECLARE
    tbl text;
    tables text[] := ARRAY[
        'appointments',
        'appointment_services',
        'services',
        'service_categories',
        'clients',
        'client_notes',
        'feedback',
        'invoices',
        'invoice_lines',
        'payments',
        'inventory_items',
        'inventory_transactions',
        'service_inventory_items',
        'staff',
        'staff_shifts',
        'shift_templates',
        'staff_shift_rules',
        'staff_metrics',
        'purchase_orders',
        'purchase_order_lines',
        'notification_logs',
        'notification_templates'
    ];
BEGIN
    FOREACH tbl IN ARRAY tables
    LOOP
        IF NOT EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = tbl
              AND column_name = 'branch_id'
        ) THEN
            EXECUTE format(
                'ALTER TABLE public.%I ADD COLUMN branch_id uuid;',
                tbl
            );
        END IF;
    END LOOP;
END $$;

------------------------------------------------------------------

DO $$
DECLARE
    tbl text;
    tables text[] := ARRAY[
        'appointments',
        'appointment_services',
        'services',
        'service_categories',
        'clients',
        'client_notes',
        'feedback',
        'invoices',
        'invoice_lines',
        'payments',
        'inventory_items',
        'inventory_transactions',
        'service_inventory_items',
        'staff',
        'staff_shifts',
        'shift_templates',
        'staff_shift_rules',
        'staff_metrics',
        'purchase_orders',
        'purchase_order_lines',
        'notification_logs',
        'notification_templates'
    ];
BEGIN
    FOREACH tbl IN ARRAY tables
    LOOP
        IF NOT EXISTS (
            SELECT 1
            FROM information_schema.table_constraints
            WHERE constraint_schema = 'public'
              AND table_name = tbl
              AND constraint_name = tbl || '_branch_id_fkey'
        ) THEN
            EXECUTE format(
                'ALTER TABLE public.%I
                 ADD CONSTRAINT %I
                 FOREIGN KEY (branch_id)
                 REFERENCES public.branches(id)
                 ON DELETE CASCADE;',
                tbl,
                tbl || '_branch_id_fkey'
            );
        END IF;
    END LOOP;
END $$;

-----------------------------------------


SELECT
    tc.constraint_name,
    ccu.table_name AS referenced_table
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu
  ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'staff_metrics'
  AND tc.constraint_type = 'FOREIGN KEY';


  ALTER TABLE staff_metrics
DROP CONSTRAINT staff_metrics_staff_id_fkey;


ALTER TABLE staff_metrics
ADD CONSTRAINT staff_metrics_staff_id_fkey
FOREIGN KEY (staff_id)
REFERENCES staff(id)
ON DELETE CASCADE;


INSERT INTO staff_metrics (
    staff_id,
    tenant_id,
    branch_id,
    total_appointments,
    completed_appointments,
    cancelled_appointments,
    total_revenue_generated,
    average_rating,
    total_ratings
)
SELECT
    id,
    tenant_id,
    branch_id,
    0,0,0,0,0,0
FROM staff
ON CONFLICT (staff_id) DO NOTHING;

ALTER TABLE staff_metrics
ALTER COLUMN branch_id SET NOT NULL;

        'appointments',
        'appointment_services',
        'services',
        'service_categories',
        'clients',
        'client_notes',
        'feedback',
        'invoices',
        'invoice_lines',
        'payments',
        'inventory_items',
        'inventory_transactions',
        'service_inventory_items',
        'staff',
        'staff_shifts',
        'shift_templates',
        'staff_shift_rules',
        'staff_metrics',
        'purchase_orders',
        'purchase_order_lines',
        'notification_logs',
        'notification_templates'