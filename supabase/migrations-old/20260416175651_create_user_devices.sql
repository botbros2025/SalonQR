--------------------------------------------------
-- TABLE: user_devices
--------------------------------------------------

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null references public.users(id) on delete cascade,
  tenant_id uuid not null,

  device_id text not null,
  push_token text,

  platform text check (platform in ('ios', 'android', 'web')),

  is_active boolean default true,

  last_active_at timestamptz default now(),
  created_at timestamptz default now(),

  -- prevent duplicate device per user
  constraint user_devices_unique_device unique (user_id, device_id)
);

--------------------------------------------------
-- INDEXES (important for performance)
--------------------------------------------------

create index if not exists idx_user_devices_user_id
on public.user_devices(user_id);

create index if not exists idx_user_devices_tenant_id
on public.user_devices(tenant_id);

create index if not exists idx_user_devices_active
on public.user_devices(user_id, is_active);

--------------------------------------------------
-- AUTO SET tenant_id (optional but recommended)
--------------------------------------------------

create or replace function public.set_user_devices_tenant()
returns trigger as $$
begin
  if new.tenant_id is null then
    new.tenant_id := current_tenant_id();
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trg_set_user_devices_tenant
before insert on public.user_devices
for each row execute function public.set_user_devices_tenant();

--------------------------------------------------
-- ENABLE RLS
--------------------------------------------------

alter table public.user_devices enable row level security;

--------------------------------------------------
-- RLS POLICIES
--------------------------------------------------

-- SELECT
create policy "Users can view their devices"
on public.user_devices
for select
using (
  tenant_id = current_tenant_id()
  and user_id = auth.uid()
);

-- INSERT
create policy "Users can insert their devices"
on public.user_devices
for insert
with check (
  tenant_id = current_tenant_id()
  and user_id = auth.uid()
);

-- UPDATE
create policy "Users can update their devices"
on public.user_devices
for update
using (
  tenant_id = current_tenant_id()
  and user_id = auth.uid()
);

-- DELETE
create policy "Users can delete their devices"
on public.user_devices
for delete
using (
  tenant_id = current_tenant_id()
  and user_id = auth.uid()
);

ALTER TABLE user_devices
ADD COLUMN updated_at timestamptz DEFAULT now();

CREATE TRIGGER trg_user_devices_updated_at
BEFORE UPDATE ON user_devices
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE users
ADD COLUMN max_devices integer NOT NULL DEFAULT 1;
--------------------------------------------------
-- OPTIONAL: HELPER FUNCTION (GET ACTIVE DEVICES)
--------------------------------------------------

-- create or replace function public.get_active_devices(p_user_id uuid)
-- returns table (
--   device_id text,
--   push_token text,
--   last_active_at timestamptz
-- )
-- language sql
-- security definer
-- as $$
--   select device_id, push_token, last_active_at
--   from public.user_devices
--   where user_id = p_user_id
--     and tenant_id = current_tenantId()
--     and is_active = true;
-- $$;

--------------------------------------------------
-- OPTIONAL: CLEANUP OLD INACTIVE DEVICES (CRON READY)
--------------------------------------------------

-- you can later schedule this
-- create or replace function public.cleanup_old_devices()
-- returns void
-- language sql
-- as $$
--   delete from public.user_devices
--   where is_active = false
--   and last_active_at < now() - interval '30 days';
-- $$;