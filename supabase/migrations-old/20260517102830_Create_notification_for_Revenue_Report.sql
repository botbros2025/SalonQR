-- =========================================
-- DAILY REVENUE REPORT SYSTEM
-- OWNER ONLY NOTIFICATIONS
-- =========================================


-- =========================================
-- 1. REVENUE REPORT LOGS TABLE
-- =========================================

create table if not exists revenue_report_logs (
    id uuid primary key default gen_random_uuid(),

    tenant_id uuid not null
        references tenants(id)
        on delete cascade,

    branch_id uuid not null
        references branches(id)
        on delete cascade,

    report_date date not null,

    total_revenue numeric not null default 0,
    paid_revenue numeric not null default 0,
    pending_revenue numeric not null default 0,
    invoice_count integer not null default 0,

    created_at timestamptz not null default now(),

    unique (tenant_id, branch_id, report_date)
);


-- =========================================
-- 2. ENABLE RLS
-- =========================================

alter table revenue_report_logs
enable row level security;


-- =========================================
-- 3. RLS POLICIES
-- =========================================

create policy "Users can view revenue report logs"
on revenue_report_logs
for select
using (
    tenant_id = current_tenant_id()
);

create policy "System can insert revenue report logs"
on revenue_report_logs
for insert
with check (true);


-- =========================================
-- 4. GENERATE DAILY REVENUE SUMMARY
-- =========================================

create or replace function generate_daily_revenue_summary(
    p_tenant_id uuid,
    p_branch_id uuid,
    p_report_date date default current_date
)
returns json
language plpgsql
security definer
as $$
declare
    v_result json;
begin

    select json_build_object(
        'total_revenue',
            coalesce(sum(total_amount), 0),

        'paid_revenue',
            coalesce(sum(paid_amount), 0),

        'pending_revenue',
            coalesce(sum(balance_amount), 0),

        'invoice_count',
            count(*)
    )
    into v_result
    from invoices
    where tenant_id = p_tenant_id
    and branch_id = p_branch_id
    and invoice_date = p_report_date;

    return v_result;

end;
$$;


-- =========================================
-- 5. INSERT NOTIFICATION TEMPLATE
-- =========================================

insert into notification_templates (
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
values (
    null,
    null,

    'Revenue Daily Report',

    'revenue_daily_report',

    'IN_APP',

    'Today''s Revenue Report',

    E'Revenue: ₹{{total_revenue}}\nCollected: ₹{{paid_revenue}}\nPending: ₹{{pending_revenue}}\nInvoices: {{invoice_count}}',

    true,
    true
)

on conflict do nothing;


-- =========================================
-- 6. PROCESS DAILY REVENUE REPORTS
-- =========================================

create or replace function process_daily_revenue_reports()
returns void
language plpgsql
security definer
as $$
declare

    v_branch record;

    v_day_name text;
    v_close_time time;
    v_close_timestamp timestamptz;

    v_summary json;

    v_total_revenue numeric;
    v_paid_revenue numeric;
    v_pending_revenue numeric;
    v_invoice_count integer;

    v_template record;

    v_title text;
    v_body text;

begin

    -- =====================================
    -- GET TEMPLATE
    -- =====================================

    select *
    into v_template
    from notification_templates
    where type = 'revenue_daily_report'
    and is_active = true
    limit 1;

    -- =====================================
    -- LOOP ACTIVE BRANCHES
    -- =====================================

    for v_branch in
        select *
        from branches
        where is_active = true
    loop

        -- CURRENT WEEKDAY

        v_day_name :=
            lower(trim(to_char(current_date, 'Day')));

        -- SKIP CLOSED DAYS

        if coalesce(
            (
                v_branch.business_hours
                -> v_day_name
                ->> 'closed'
            )::boolean,
            false
        ) = true then
            continue;
        end if;

        -- GET CLOSING TIME

        v_close_time :=
            (
                v_branch.business_hours
                -> v_day_name
                ->> 'close'
            )::time;

        -- WAIT 30 MINUTES AFTER CLOSING

        v_close_timestamp :=
            (
                current_date + v_close_time
            ) + interval '30 minutes';

        if now() < v_close_timestamp then
            continue;
        end if;

        -- PREVENT DUPLICATES

        if exists (
            select 1
            from revenue_report_logs
            where tenant_id = v_branch.tenant_id
            and branch_id = v_branch.id
            and report_date = current_date
        ) then
            continue;
        end if;

        -- GENERATE SUMMARY

        v_summary :=
            generate_daily_revenue_summary(
                v_branch.tenant_id,
                v_branch.id,
                current_date
            );

        v_total_revenue :=
            coalesce(
                (v_summary ->> 'total_revenue')::numeric,
                0
            );

        v_paid_revenue :=
            coalesce(
                (v_summary ->> 'paid_revenue')::numeric,
                0
            );

        v_pending_revenue :=
            coalesce(
                (v_summary ->> 'pending_revenue')::numeric,
                0
            );

        v_invoice_count :=
            coalesce(
                (v_summary ->> 'invoice_count')::integer,
                0
            );

        -- =====================================
        -- RENDER TEMPLATE
        -- =====================================

        v_title :=
            v_template.subject;

        v_body :=
            replace(
                replace(
                    replace(
                        replace(
                            v_template.body,
                            '{{total_revenue}}',
                            v_total_revenue::text
                        ),
                        '{{paid_revenue}}',
                        v_paid_revenue::text
                    ),
                    '{{pending_revenue}}',
                    v_pending_revenue::text
                ),
                '{{invoice_count}}',
                v_invoice_count::text
            );

        -- =====================================
        -- OWNER NOTIFICATIONS ONLY
        -- =====================================

        insert into notifications (
            tenant_id,
            branch_id,
            user_id,
            template_id,
            type,
            title,
            body,
            metadata,
            is_read,
            created_at
        )

        select distinct
            v_branch.tenant_id,
            v_branch.id,
            ur.user_id,
            v_template.id,
            v_template.type,
            v_title,
            v_body,

            jsonb_build_object(
                'total_revenue', v_total_revenue,
                'paid_revenue', v_paid_revenue,
                'pending_revenue', v_pending_revenue,
                'invoice_count', v_invoice_count,
                'report_date', current_date,
                'branch_id', v_branch.id
            ),

            false,
            now()

        from user_roles ur

        join users u
            on u.id = ur.user_id

        where ur.tenant_id = v_branch.tenant_id

        and ur.role_id =
            '00000000-0000-0000-0000-000000000001'

        and u.is_active = true

        and v_template.id is not null

        on conflict do nothing;

        -- =====================================
        -- SAVE REPORT LOG
        -- =====================================

        insert into revenue_report_logs (
            tenant_id,
            branch_id,
            report_date,
            total_revenue,
            paid_revenue,
            pending_revenue,
            invoice_count
        )
        values (
            v_branch.tenant_id,
            v_branch.id,
            current_date,
            v_total_revenue,
            v_paid_revenue,
            v_pending_revenue,
            v_invoice_count
        );

    end loop;

end;
$$;


-- =========================================
-- 7. INDEXES
-- =========================================

create index if not exists idx_revenue_report_logs_tenant
on revenue_report_logs (tenant_id);

create index if not exists idx_revenue_report_logs_branch
on revenue_report_logs (branch_id);

create index if not exists idx_revenue_report_logs_date
on revenue_report_logs (report_date);

create index if not exists idx_invoices_report_lookup
on invoices (
    tenant_id,
    branch_id,
    invoice_date
);


-- =========================================
-- 8. ENABLE PG_CRON
-- =========================================

create extension if not exists pg_cron;


-- =========================================
-- 9. SCHEDULE CRON JOB
-- RUNS EVERY 15 MINUTES
-- =========================================

select cron.schedule(
    'daily-revenue-report-job',
    '*/15 * * * *',
    $$select process_daily_revenue_reports();$$
);