

--SUPPORT TICKETS TABLE

create table public.support_tickets (
  id uuid primary key default gen_random_uuid(),

  tenant_id uuid not null,
  branch_id uuid,
  user_id uuid not null,

  subject text not null,
  description text not null,

  category text,
  priority text default 'medium',

  status text default 'open',

  attachment_url text,

  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  resolved_at timestamptz
);

--SUPPORT TICKETS MESSAGE TABLE

--SELECT AND INSERT WILL TAKE TENANT_ID CHECK USING RLS

create table public.support_ticket_messages (
  id uuid primary key default gen_random_uuid(),

  ticket_id uuid not null
    references public.support_tickets(id)
    on delete cascade,

  sender_id uuid not null,

  sender_type text
    check (sender_type in ('user','support')),

  message text not null,
  attachment_url text,

  created_at timestamptz default now()
);

--INDEXING

create index idx_support_tickets_tenant
on public.support_tickets(tenant_id);

create index idx_support_tickets_user
on public.support_tickets(user_id);

create index idx_ticket_messages_ticket
on public.support_ticket_messages(ticket_id);

create index idx_ticket_messages_ticket_created
on public.support_ticket_messages(ticket_id, created_at);



--RLS

alter table public.support_tickets enable row level security;
alter table public.support_ticket_messages enable row level security;

--SUPPORT TICKET RLS

create policy "tenant_can_view_tickets"
on public.support_tickets
for select
using (
  tenant_id = current_tenant_id()
);

create policy "tenant_can_create_tickets"
on public.support_tickets
for insert
with check (
  tenant_id = current_tenant_id()
);

create policy "tenant_can_update_tickets"
on public.support_tickets
for update
using (
  tenant_id = current_tenant_id()
);

--SUPPORT TICKET MESSAGE RLS

create policy "tenant_can_view_ticket_messages"
on public.support_ticket_messages
for select
using (
  exists (
    select 1
    from public.support_tickets t
    where t.id = support_ticket_messages.ticket_id
    and t.tenant_id = current_tenant_id()
  )
);

create policy "tenant_can_send_ticket_messages"
on public.support_ticket_messages
for insert
with check (
  exists (
    select 1
    from public.support_tickets t
    where t.id = ticket_id
    and t.tenant_id = current_tenant_id()
  )
);

--AUTO UPDATE UPDATED_AT IN SUPPORT TICKET TABLE

create or replace function public.update_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger ticket_update_timestamp
before update on public.support_tickets
for each row
execute function public.update_updated_at();


--AUTO update on ticket msg update updated_at in table

create or replace function public.update_ticket_last_activity()
returns trigger
language plpgsql
as $$
begin
  update public.support_tickets
  set updated_at = now()
  where id = new.ticket_id;

  return new;
end;
$$;

create trigger ticket_message_activity
after insert on public.support_ticket_messages
for each row
execute function public.update_ticket_last_activity();

-------------------------------------------------

--AUTO UPDATE FOR resolved_at

create or replace function set_ticket_resolved_time()
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
execute function set_ticket_resolved_time();