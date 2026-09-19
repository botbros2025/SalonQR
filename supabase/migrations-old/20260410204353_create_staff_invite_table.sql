-- 1️⃣ staff_invites table
create table if not exists staff_invites (
  id uuid primary key default gen_random_uuid(),

  staff_id uuid not null references staff(id) on delete cascade,

  token text not null unique,

  expires_at timestamptz not null,

  used boolean default false,

  created_at timestamptz default now()
);

-- 2️⃣ Add fields to staff (IMPORTANT FIX)
alter table staff
add column if not exists last_invite_id uuid;


-- 3️⃣ Foreign key
alter table staff
add constraint staff_last_invite_fk
foreign key (last_invite_id)
references staff_invites(id)
on delete set null;

-- 4️⃣ Indexes
create index if not exists idx_staff_invites_token
on staff_invites(token);

create index if not exists idx_staff_invites_staff_id
on staff_invites(staff_id);

create index if not exists idx_staff_invites_expiry
on staff_invites(expires_at);

create index if not exists idx_staff_last_invite
on staff(last_invite_id);

-- 5️⃣ One active invite (still useful but not perfect)
create unique index if not exists idx_one_active_invite
on staff_invites(staff_id)
where used = false;



create or replace function sync_latest_invite()
returns trigger as $$
begin
  update staff
  set
    invite_token = NEW.token,
    invite_expiry = NEW.expires_at,
    last_invite_id = NEW.id   -- ✅ FIX ADDED
  where id = NEW.staff_id;

  return NEW;
end;
$$ language plpgsql;

drop trigger if exists trg_sync_invite on staff_invites;

create trigger trg_sync_invite
after insert on staff_invites
for each row
execute function sync_latest_invite();


--RLS POLICY 
CREATE POLICY "Allow insert on staff_invites"
ON staff_invites
FOR INSERT
TO authenticated
WITH CHECK (true); 

CREATE POLICY "allow all select"
ON staff_invites
FOR SELECT
USING (true);

CREATE POLICY "allow all update"
ON staff_invites
FOR UPDATE
USING (true)
WITH CHECK (true);

--RPC FUNCTION
create or replace function public.get_invite_details(invite_token text)
returns json
language plpgsql
security definer
as $$
declare
  invite_record record;
  staff_record record;
begin
  -- get invite
  select * into invite_record
  from staff_invites
  where token = invite_token;

  if invite_record is null then
    return json_build_object('error', 'Invalid invite');
  end if;

  if invite_record.expires_at < now() then
    return json_build_object('error', 'Invite expired');
  end if;

  -- get staff
  select tenant_id,name, phone, email into staff_record
  from staff
  where id = invite_record.staff_id;

  return json_build_object(
    'name', staff_record.name,
    'phone', staff_record.phone,
    'email', staff_record.email,
    'staff_id',invite_record.staff_id,
    'tenant_id',staff_record.tenant_id
  );
end;
$$;

grant execute on function public.get_invite_details to anon;