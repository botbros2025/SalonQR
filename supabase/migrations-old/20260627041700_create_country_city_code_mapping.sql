-- Migration: create country_city_code_mapping table
-- Created at: 2026-06-27T04:17:00

create table if not exists public.country_city_code_mapping (
  country_code text not null,
  state_code text not null,
  city text not null default '',
  cities text[],
  pincodes text[],
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint country_city_code_mapping_pkey primary key (country_code, state_code, city)
);

-- Indexing city for quick direct parent/pincode lookups
create index if not exists idx_country_city_code_mapping_city 
on public.country_city_code_mapping (city);

-- Enable Row Level Security
alter table public.country_city_code_mapping enable row level security;

-- RLS Policies for authenticated users
create policy "Authenticated users can select mapping"
on public.country_city_code_mapping
for select
to authenticated
using (true);

create policy "Authenticated users can insert mapping"
on public.country_city_code_mapping
for insert
to authenticated
with check (true);

create policy "Authenticated users can update mapping"
on public.country_city_code_mapping
for update
to authenticated
using (true)
with check (true);

create policy "Authenticated users can delete mapping"
on public.country_city_code_mapping
for delete
to authenticated
using (true);
