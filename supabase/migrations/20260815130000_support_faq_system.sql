-- 1. Create support_categories table
CREATE TABLE IF NOT EXISTS public.support_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Create support_subcategories table
CREATE TABLE IF NOT EXISTS public.support_subcategories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES public.support_categories(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT support_subcategories_id_category_id_key UNIQUE (id, category_id)
);

-- 3. Create support_faqs table
CREATE TABLE IF NOT EXISTS public.support_faqs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES public.support_categories(id) ON DELETE CASCADE,
    subcategory_id UUID,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT support_faqs_subcategory_fk 
      FOREIGN KEY (subcategory_id, category_id) 
      REFERENCES public.support_subcategories (id, category_id)
      ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_support_categories_is_active ON public.support_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_support_subcategories_category_id ON public.support_subcategories(category_id);
CREATE INDEX IF NOT EXISTS idx_support_faqs_category_id ON public.support_faqs(category_id);
CREATE INDEX IF NOT EXISTS idx_support_faqs_subcategory_id ON public.support_faqs(subcategory_id);

-- Triggers for updated_at
CREATE TRIGGER update_support_categories_updated_at
BEFORE UPDATE ON public.support_categories
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_support_subcategories_updated_at
BEFORE UPDATE ON public.support_subcategories
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_support_faqs_updated_at
BEFORE UPDATE ON public.support_faqs
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies
ALTER TABLE public.support_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_subcategories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_faqs ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to SELECT
CREATE POLICY "Enable read access for all authenticated users" ON public.support_categories
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for all authenticated users" ON public.support_subcategories
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for all authenticated users" ON public.support_faqs
    FOR SELECT TO authenticated USING (true);

-- Allow only admins to INSERT/UPDATE/DELETE (Assuming 'admin' or checking admin auth isn't natively trivial without a function, we'll follow general secure defaults by not having an insert/update/delete policy for standard users)

-- Seed Data

DO $$
DECLARE
  get_started_id UUID := gen_random_uuid();
  appointments_id UUID := gen_random_uuid();
  billing_id UUID := gen_random_uuid();
  staff_id UUID := gen_random_uuid();
  settings_id UUID := gen_random_uuid();
  security_id UUID := gen_random_uuid();
  mobile_id UUID := gen_random_uuid();

  app_creation_id UUID := gen_random_uuid();
  app_management_id UUID := gen_random_uuid();
  billing_invoices_id UUID := gen_random_uuid();
  billing_payments_id UUID := gen_random_uuid();
BEGIN
  -- Insert Categories
  INSERT INTO public.support_categories (id, name, description, icon, display_order)
  VALUES 
    (get_started_id, 'Getting Started', 'Basic guides to set up your salon.', 'book-outline', 1),
    (appointments_id, 'Appointments', 'Manage your calendar and bookings.', 'calendar-outline', 2),
    (billing_id, 'Billing & Payments', 'Invoices, payments, and financial settings.', 'card-outline', 3),
    (staff_id, 'Staff Management', 'Add staff, manage roles, and track performance.', 'people-outline', 4),
    (settings_id, 'Settings', 'Account configurations and system settings.', 'settings-outline', 5),
    (security_id, 'Security & Privacy', 'Protect your account and data.', 'shield-checkmark-outline', 6),
    (mobile_id, 'Mobile App', 'Features and troubleshooting for the mobile app.', 'phone-portrait-outline', 7);

  -- Direct FAQs for Getting Started (No subcategories)
  INSERT INTO public.support_faqs (category_id, question, answer, display_order)
  VALUES 
    (get_started_id, 'How do I get started?', 'To get started, navigate to your profile and fill out your salon details. Then, add your services and staff members.', 1),
    (get_started_id, 'How do I set up my salon?', 'You can set up your salon by going to Settings > Salon Profile and entering your business information.', 2);

  -- Subcategories for Appointments
  INSERT INTO public.support_subcategories (id, category_id, name, description, display_order)
  VALUES 
    (app_creation_id, appointments_id, 'Creating Appointments', 'How to book new clients.', 1),
    (app_management_id, appointments_id, 'Managing Appointments', 'How to reschedule or cancel.', 2);

  -- FAQs for Appointments > Creating Appointments
  INSERT INTO public.support_faqs (category_id, subcategory_id, question, answer, display_order)
  VALUES 
    (appointments_id, app_creation_id, 'How do I create an appointment?', 'Go to the Calendar tab and tap the "+" button in the top right corner.', 1),
    (appointments_id, app_creation_id, 'Can I edit an appointment?', 'Yes, tap on any existing appointment in the Calendar to edit its details.', 2);

  -- FAQs for Appointments > Managing Appointments
  INSERT INTO public.support_faqs (category_id, subcategory_id, question, answer, display_order)
  VALUES 
    (appointments_id, app_management_id, 'How do I reschedule an appointment?', 'Drag and drop the appointment on the calendar or open it and edit the date and time.', 1);

  -- Subcategories for Billing
  INSERT INTO public.support_subcategories (id, category_id, name, description, display_order)
  VALUES 
    (billing_invoices_id, billing_id, 'Invoices', 'Managing client invoices.', 1),
    (billing_payments_id, billing_id, 'Payments', 'Processing client payments.', 2);

  -- FAQs for Billing > Invoices
  INSERT INTO public.support_faqs (category_id, subcategory_id, question, answer, display_order)
  VALUES 
    (billing_id, billing_invoices_id, 'How do I generate an invoice?', 'Open a completed appointment and tap "Generate Invoice".', 1);

  -- FAQs for Billing > Payments
  INSERT INTO public.support_faqs (category_id, subcategory_id, question, answer, display_order)
  VALUES 
    (billing_id, billing_payments_id, 'How do I process a refund?', 'Go to the Payments tab, select the transaction, and tap "Issue Refund".', 1);
    
END $$;
