ALTER TABLE public.appointments ALTER COLUMN created_by DROP NOT NULL;
ALTER TABLE public.appointment_services ALTER COLUMN added_by DROP NOT NULL;
