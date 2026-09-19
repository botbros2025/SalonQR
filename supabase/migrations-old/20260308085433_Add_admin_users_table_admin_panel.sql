-- =====================================================
-- Admin Users Table
-- =====================================================

create table if not exists public.admin_users (
  id uuid primary key
    references auth.users(id)
    on delete cascade,

  email text unique not null,

  role text not null default 'admin'
    check (role in ('super_admin','admin','support')),

  created_at timestamptz not null default now()
);

-- =====================================================
-- Indexes
-- =====================================================

create index if not exists idx_admin_users_email
on public.admin_users(email);

create index if not exists idx_admin_users_role
on public.admin_users(role);

ALTER TABLE public.admin_users
ADD CONSTRAINT admin_users_id_fkey
FOREIGN KEY (id)
REFERENCES auth.users(id)
ON DELETE CASCADE;s

-- =====================================================
-- Enable Row Level Security
-- =====================================================

alter table public.admin_users enable row level security;

-- =====================================================
-- RLS Policy (Admin can read their own record)
-- =====================================================

create policy "Admin can view own record"
on public.admin_users
for select
using (auth.uid() = id);