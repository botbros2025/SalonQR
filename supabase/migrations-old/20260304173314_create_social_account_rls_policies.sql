alter table public.social_accounts enable row level security;

create policy "Tenant can insert own social accounts"
on public.social_accounts
for insert
with check (
  tenant_id = current_tenant_id()
);

create policy "Tenant can view own social accounts"
on public.social_accounts
for select
using (
  tenant_id = current_tenant_id()
);

create policy "Tenant can update own social accounts"
on public.social_accounts
for update
using (
  tenant_id = auth.uid()
);

create policy "Tenant can delete own social accounts"
on public.social_accounts
for delete
using (
  tenant_id = auth.uid()
);