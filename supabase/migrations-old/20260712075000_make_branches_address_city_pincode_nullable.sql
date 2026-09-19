-- Migration: Make address, city, state, pincode nullable on branches table
-- Reason: These fields are useful but not strictly required for branch creation.
--         Allows progressive onboarding where location details can be filled later.
-- Date: 2026-07-12

-- =========================================================
-- 1. Drop NOT NULL constraints on branches table
-- =========================================================
ALTER TABLE public.branches
  ALTER COLUMN address DROP NOT NULL,
  ALTER COLUMN state DROP NOT NULL,
  ALTER COLUMN city    DROP NOT NULL,
  ALTER COLUMN pincode DROP NOT NULL;

-- =========================================================
-- 2. (Optional) Set existing empty-string values to NULL
--    Uncomment these lines if you want to normalise any
--    accidental empty strings already in the database.
-- =========================================================
-- UPDATE public.branches SET address = NULL WHERE address = '';
-- UPDATE public.branches SET city    = NULL WHERE city    = '';
-- UPDATE public.branches SET state   = NULL WHERE state   = '';
-- UPDATE public.branches SET pincode = NULL WHERE pincode = '';
