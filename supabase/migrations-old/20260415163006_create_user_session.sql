create table user_sessions (
  id uuid primary key default gen_random_uuid(),

  user_id uuid references users(id),
  tenant_id uuid,
  branch_id uuid,

  device text,
  ip text,
  location text,
  dummy text,
  dummy1 text,
  dummy2 text,
  dummy3 text,
  dummy4 text,
  dummy5 text,

  is_active boolean default true,
  created_at timestamptz default now()
);

--RLS

alter table user_sessions enable row level security;

create policy "Select own sessions"
on user_sessions
for select
using (
  auth.uid() = user_id
  AND tenant_id =  current_tenant_id()
);

create policy "Insert own session"
on user_sessions
for insert
with check (
  auth.uid() = user_id
  AND tenant_id =  current_tenant_id()
);

create policy "Update own session"
on user_sessions
for update
using (
  auth.uid() = user_id
  AND tenant_id =  current_tenant_id()
)
with check (
  auth.uid() = user_id
  AND tenant_id =  current_tenant_id()
);

create policy "Delete own session"
on user_sessions
for delete
using (
  auth.uid() = user_id
  AND tenant_id =  current_tenant_id()
);


-- Add login_alerts_enabled setting to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS login_alerts_enabled boolean DEFAULT true;

ALTER TABLE user_sessions
ADD COLUMN updated_at timestamptz DEFAULT now();

CREATE TRIGGER trg_user_sessions_updated_at
BEFORE UPDATE ON user_sessions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE UNIQUE INDEX user_sessions_device_unique
ON user_sessions(device_id)
WHERE is_active = true;

ALTER TABLE user_sessions
ADD CONSTRAINT user_sessions_user_device_unique
UNIQUE (user_id, device_id);