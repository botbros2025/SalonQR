-- 1. Create tax_rates table
create table if not exists public.tax_rates (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  cgst numeric(5,2) not null default 0,
  sgst numeric(5,2) not null default 0,
  total numeric(5,2) generated always as (cgst + sgst) stored,
  active boolean default false,
  created_at timestamp with time zone default now()
);

-- 2. Ensure only ONE active tax rate at a time
create unique index if not exists one_active_tax_rate
on public.tax_rates (active)
where active = true;

-- 3. Insert default GST (India salon typical = 5%)
insert into public.tax_rates (name, cgst, sgst, active)
values ('GST 5%', 2.5, 2.5, true)
on conflict do nothing;

------------------------------------------------------

-- 4. Add tax snapshot columns to invoices
alter table public.invoices
add column if not exists tax_percent numeric(5,2) default 0;


------------------------------------------------------

-- 5. (Optional but recommended) helper function to get active tax
create or replace function public.get_active_tax_rate()
returns public.tax_rates
language sql
stable
as $$
  select *
  from public.tax_rates
  where active = true
  limit 1;
$$;


-- =========================================
-- 1. ENABLE RLS
-- =========================================
alter table public.tax_rates enable row level security;
alter table public.invoices enable row level security;

-- =========================================
-- 2. RLS POLICIES (authenticated users)
-- =========================================

-- tax_rates: read-only for authenticated users
create policy "Allow read tax_rates"
on public.tax_rates
for select
to authenticated
using (true);

-- (optional) restrict insert/update to service role only
create policy "No public insert tax_rates"
on public.tax_rates
for insert
to authenticated
with check (false);

create policy "No public update tax_rates"
on public.tax_rates
for update
to authenticated
using (false);




-- =========================================
-- 3. FUNCTION: apply active tax automatically
-- =========================================
create or replace function public.apply_tax_to_invoice()
returns trigger
language plpgsql
as $$
declare
  tax_record public.tax_rates;
begin
  -- get active tax rate
  select *
  into tax_record
  from public.tax_rates
  where active = true
  limit 1;

  if tax_record is not null then
    NEW.tax_percent := tax_record.total;
  end if;

  return NEW;
end;
$$;

-- =========================================
-- 4. TRIGGER: before insert on invoices
-- =========================================
drop trigger if exists trg_apply_tax on public.invoices;

create trigger trg_apply_tax
before insert on public.invoices
for each row
execute function public.apply_tax_to_invoice();