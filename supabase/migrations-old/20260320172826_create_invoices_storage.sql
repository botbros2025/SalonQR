-- =========================================
-- 1. CREATE STORAGE BUCKET (PRIVATE)
-- =========================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'invoices',
  'invoices',
  false, -- NOT public
  3145728, -- 3MB in bytes
  array['application/pdf']
)
on conflict (id) do nothing;
-- =========================
-- INSERT POLICY
-- =========================
drop policy if exists "Tenant can upload invoices" on storage.objects;

create policy "Tenant can upload invoices"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'invoices'
  AND split_part(name, '/', 1) = current_tenant_id()::text
);


-- =========================
-- SELECT POLICY
-- =========================
drop policy if exists "Tenant can view invoices" on storage.objects;

create policy "Tenant can view invoices"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'invoices'
  AND split_part(name, '/', 1) = current_tenant_id()::text
);


-- =========================
-- UPDATE POLICY
-- =========================
drop policy if exists "Tenant can update invoices" on storage.objects;

create policy "Tenant can update invoices"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'invoices'
  AND split_part(name, '/', 1) = current_tenant_id()::text
);


-- =========================
-- DELETE POLICY (optional)
-- =========================
drop policy if exists "Tenant can delete invoices" on storage.objects;

create policy "Tenant can delete invoices"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'invoices'
  AND split_part(name, '/', 1) = current_tenant_id()::text
);