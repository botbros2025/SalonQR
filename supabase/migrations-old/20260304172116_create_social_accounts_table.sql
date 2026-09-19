create table social_accounts (
  id uuid primary key default gen_random_uuid(),

  tenant_id uuid not null references tenants(id) on delete cascade,

  platform text not null, -- 'instagram' | 'facebook' | 'twitter' | 'website'
  handle text not null,

  created_at timestamp default now(),
  updated_at timestamp default now()
);

create index idx_social_accounts_tenant
on social_accounts(tenant_id);