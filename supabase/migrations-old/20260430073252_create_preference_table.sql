create table public.user_preferences (
    id uuid primary key default gen_random_uuid(),

    user_id uuid not null,
    tenant_id uuid not null,
    branch_id uuid,

    -- preference data (flexible but structured)
    preferences jsonb not null default '{}'::jsonb,

    -- audit
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    -- constraints
    constraint fk_user
        foreign key (user_id) references auth.users(id)
        on delete cascade
);

create unique index ux_user_preferences_unique
on public.user_preferences(user_id, tenant_id);

-- Fast filtering by tenant
create index idx_user_preferences_tenant
on public.user_preferences(tenant_id);

-- User-specific lookups
create index idx_user_preferences_user
on public.user_preferences(user_id);

-- Branch filtering
create index idx_user_preferences_branch
on public.user_preferences(branch_id);

-- JSONB search (optional but powerful)
create index idx_user_preferences_jsonb
on public.user_preferences using gin (preferences);


create or replace function public.update_updated_at_column()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger trg_update_user_preferences
before update on public.user_preferences
for each row
execute function public.update_updated_at_column();


--RLS
create policy "select_own_preferences"
on public.user_preferences
for select
using (
    tenant_id = current_tenant_id()
    and user_id = auth.uid()
);

create policy "insert_own_preferences"
on public.user_preferences
for insert
with check (
    tenant_id = current_tenant_id()
    and user_id = auth.uid()
);

create policy "update_own_preferences"
on public.user_preferences
for update
using (
    tenant_id = current_tenant_id()
    and user_id = auth.uid()
)
with check (
    tenant_id = current_tenant_id()
    and user_id = auth.uid()
);

create policy "delete_own_preferences"
on public.user_preferences
for delete
using (
    tenant_id = current_tenant_id()
    and user_id = auth.uid()
);



-- {
--   "theme": "dark",
--   "language": "en",
--   "notifications": {
--     "email": true,
--     "sms": false
--   }
-- }