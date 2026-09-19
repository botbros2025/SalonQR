-- 1. ADD COLUMN TO service_categories
ALTER TABLE public.service_categories ADD COLUMN IF NOT EXISTS image_url text;

-- 2. CREATE STORAGE BUCKET (PUBLIC)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'category_images',
  'category_images',
  true, -- PUBLIC so images can be rendered without signed URLs
  5242880, -- 5MB in bytes
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/jpg']
)
on conflict (id) do update set
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 3. STORAGE POLICIES

-- INSERT POLICY (Only tenant can upload their own images to their folder)
drop policy if exists "Tenant can upload category images" on storage.objects;
create policy "Tenant can upload category images"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'category_images'
  AND split_part(name, '/', 1) = current_tenant_id()::text
);

-- SELECT POLICY (Public can view since the bucket is public, anyone can load the image)
drop policy if exists "Public can view category images" on storage.objects;
create policy "Public can view category images"
on storage.objects
for select
to public
using (
  bucket_id = 'category_images'
);

-- UPDATE POLICY (Only tenant can update their own images)
drop policy if exists "Tenant can update category images" on storage.objects;
create policy "Tenant can update category images"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'category_images'
  AND split_part(name, '/', 1) = current_tenant_id()::text
);

-- DELETE POLICY (Only tenant can delete their own images)
drop policy if exists "Tenant can delete category images" on storage.objects;
create policy "Tenant can delete category images"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'category_images'
  AND split_part(name, '/', 1) = current_tenant_id()::text
);
