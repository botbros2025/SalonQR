-- ===============================
-- 1️⃣ ADD CHECK CONSTRAINTS
-- ===============================

alter table public.support_tickets
add constraint support_tickets_category_check
check (
  category in (
    'technical',
    'billing',
    'account',
    'booking',
    'staff',
    'other'
  )
);

alter table public.support_tickets
add constraint support_tickets_priority_check
check (
  priority in (
    'low',
    'medium',
    'high',
    'urgent'
  )
);

alter table public.support_tickets
add constraint support_tickets_status_check
check (
  status in (
    'open',
    'pending',
    'resolved',
    'closed'
  )
);


-- ===============================
-- 2️⃣ HUMAN READABLE TICKET NUMBER
-- ===============================

alter table public.support_tickets
add column ticket_number bigint generated always as identity;


-- ===============================
-- 3️⃣ TRACK LAST MESSAGE ACTIVITY
-- ===============================

alter table public.support_tickets
add column last_message_at timestamptz;

alter table public.support_tickets
add column last_message_id uuid;


-- ===============================
-- 4️⃣ OPTIONAL: WHO RESOLVED TICKET
-- ===============================

alter table public.support_tickets
add column resolved_by uuid;


-- ===============================
-- 5️⃣ MESSAGE TABLE IMPROVEMENTS
-- ===============================

alter table public.support_ticket_messages
alter column sender_type set default 'user';

alter table public.support_ticket_messages
add constraint message_not_empty
check (length(trim(message)) > 0);


-- ===============================
-- 6️⃣ PERFORMANCE INDEXES
-- ===============================

create index idx_support_tickets_status
on public.support_tickets(status);

create index idx_support_tickets_created
on public.support_tickets(created_at desc);

create index idx_ticket_dashboard
on public.support_tickets(status, updated_at desc);


-- ===============================
-- 7️⃣ AUTO SET resolved_at
-- ===============================

create or replace function public.set_ticket_resolved_time()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'resolved' and old.status <> 'resolved' then
    new.resolved_at = now();
  end if;

  return new;
end;
$$;

create trigger ticket_resolved_timestamp
before update on public.support_tickets
for each row
execute function public.set_ticket_resolved_time();


-- ===============================
-- 8️⃣ UPDATE LAST MESSAGE POINTER
-- ===============================

create or replace function public.update_ticket_last_activity()
returns trigger
language plpgsql
as $$
begin
  update public.support_tickets
  set
    updated_at = now(),
    last_message_at = now(),
    last_message_id = new.id
  where id = new.ticket_id;

  return new;
end;
$$;

drop trigger if exists ticket_message_activity
on public.support_ticket_messages;

create trigger ticket_message_activity
after insert on public.support_ticket_messages
for each row
execute function public.update_ticket_last_activity();