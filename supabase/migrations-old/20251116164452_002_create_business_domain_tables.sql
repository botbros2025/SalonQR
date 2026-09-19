/*
  # SalonX Business Domain Tables - Phase 1
  
  ## Overview
  Creates core business tables for salon operations:
  - Services catalog with pricing
  - Client/Customer management with CRM features
  - Appointments with lifecycle tracking
  - Staff shifts and scheduling
  
  ## New Tables
  
  ### 1. Services
    - Service offerings (haircut, spa, etc.)
    - Pricing and duration
    - Inventory items linked to services
  
  ### 2. Clients
    - Customer profiles
    - Visit history and spend tracking
    - Loyalty tier calculation
    - DPDP consent tracking
  
  ### 3. Appointments
    - Booking management
    - Status lifecycle (SCHEDULED -> COMPLETED)
    - Multi-service support
    - Staff assignment
  
  ### 4. Staff Shifts
    - Shift templates and assignments
    - Attendance tracking
  
  ## Security
  - All tables have RLS enabled
  - Tenant isolation enforced
  - Permission-based access control
*/

-- =====================================================
-- SERVICE CATEGORIES & SERVICES
-- =====================================================

CREATE TABLE IF NOT EXISTS service_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  name text NOT NULL,
  description text,
  display_order int NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  UNIQUE(tenant_id, name)
);

CREATE INDEX IF NOT EXISTS idx_service_categories_tenant_id ON service_categories(tenant_id);

ALTER TABLE service_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tenant service categories"
  ON service_categories FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id());

CREATE TABLE IF NOT EXISTS services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  category_id uuid REFERENCES service_categories(id) ON DELETE SET NULL,
  
  -- Service Details
  name text NOT NULL,
  description text,
  duration_minutes int NOT NULL,
  
  -- Pricing
  price numeric(10, 2) NOT NULL,
  
  -- Tax (HSN/SAC for GST)
  hsn_sac_code text,
  tax_rate numeric(5, 2) DEFAULT 0,
  
  -- Status
  is_active boolean NOT NULL DEFAULT true,
  
  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_services_tenant_id ON services(tenant_id);
CREATE INDEX IF NOT EXISTS idx_services_category_id ON services(category_id);
CREATE INDEX IF NOT EXISTS idx_services_is_active ON services(is_active);

ALTER TABLE services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tenant services"
  ON services FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id());

-- =====================================================
-- CLIENTS (CUSTOMERS)
-- =====================================================

CREATE TYPE client_tier AS ENUM ('REGULAR', 'SILVER', 'GOLD', 'PLATINUM');
CREATE TYPE client_source AS ENUM ('WALK_IN', 'WHATSAPP', 'REFERRAL', 'ONLINE', 'OTHER');

CREATE TABLE IF NOT EXISTS clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Personal Info
  name text NOT NULL,
  phone text NOT NULL,
  email text,
  date_of_birth date,
  gender text,
  
  -- Address
  address text,
  city text,
  pincode text,
  
  -- CRM Metrics
  total_visits int NOT NULL DEFAULT 0,
  total_spend numeric(10, 2) NOT NULL DEFAULT 0,
  tier client_tier NOT NULL DEFAULT 'REGULAR',
  preferred_staff_id uuid REFERENCES users(id) ON DELETE SET NULL,
  
  -- Source
  source client_source NOT NULL DEFAULT 'WALK_IN',
  referral_code text,
  
  -- DPDP Compliance
  consent_given boolean NOT NULL DEFAULT false,
  consent_given_at timestamptz,
  consent_for_marketing boolean NOT NULL DEFAULT false,
  data_retention_expires_at timestamptz,
  
  -- Status
  is_active boolean NOT NULL DEFAULT true,
  
  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  last_visit_at timestamptz,
  
  UNIQUE(tenant_id, phone)
);

CREATE INDEX IF NOT EXISTS idx_clients_tenant_id ON clients(tenant_id);
CREATE INDEX IF NOT EXISTS idx_clients_phone ON clients(phone);
CREATE INDEX IF NOT EXISTS idx_clients_tier ON clients(tier);
CREATE INDEX IF NOT EXISTS idx_clients_date_of_birth ON clients(date_of_birth);

ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tenant clients"
  ON clients FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id());

-- Client notes
CREATE TABLE IF NOT EXISTS client_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  client_id uuid NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  
  note text NOT NULL,
  created_by uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_client_notes_client_id ON client_notes(client_id);

ALTER TABLE client_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tenant client notes"
  ON client_notes FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id());

-- =====================================================
-- SHIFTS & STAFF SCHEDULING
-- =====================================================

CREATE TABLE IF NOT EXISTS shift_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id uuid REFERENCES branches(id) ON DELETE CASCADE,
  
  name text NOT NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,
  
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_shift_templates_tenant_id ON shift_templates(tenant_id);

ALTER TABLE shift_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tenant shift templates"
  ON shift_templates FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id());

CREATE TABLE IF NOT EXISTS staff_shifts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id uuid NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  staff_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  shift_date date NOT NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,
  
  -- Attendance
  punch_in_at timestamptz,
  punch_out_at timestamptz,
  
  notes text,
  
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  UNIQUE(staff_id, shift_date)
);

CREATE INDEX IF NOT EXISTS idx_staff_shifts_tenant_id ON staff_shifts(tenant_id);
CREATE INDEX IF NOT EXISTS idx_staff_shifts_staff_id ON staff_shifts(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_shifts_shift_date ON staff_shifts(shift_date);

ALTER TABLE staff_shifts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view own shifts"
  ON staff_shifts FOR SELECT
  TO authenticated
  USING (staff_id = auth.uid() OR tenant_id = get_user_tenant_id());

CREATE POLICY "Staff can update own attendance"
  ON staff_shifts FOR UPDATE
  TO authenticated
  USING (staff_id = auth.uid())
  WITH CHECK (staff_id = auth.uid());

-- =====================================================
-- APPOINTMENTS
-- =====================================================

CREATE TYPE appointment_status AS ENUM (
  'SCHEDULED',
  'CONFIRMED', 
  'IN_PROGRESS',
  'COMPLETED',
  'BILLED',
  'CANCELLED',
  'NO_SHOW'
);

CREATE TYPE appointment_source AS ENUM ('MANUAL', 'WHATSAPP', 'ONLINE', 'WALK_IN');

CREATE TABLE IF NOT EXISTS appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id uuid NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  client_id uuid NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  
  -- Scheduling
  appointment_date date NOT NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,
  
  -- Status
  status appointment_status NOT NULL DEFAULT 'SCHEDULED',
  source appointment_source NOT NULL DEFAULT 'MANUAL',
  
  -- Staff Assignment
  primary_staff_id uuid REFERENCES users(id) ON DELETE SET NULL,
  
  -- Notes
  notes text,
  internal_notes text,
  
  -- Cancellation
  cancelled_at timestamptz,
  cancelled_by uuid REFERENCES users(id) ON DELETE SET NULL,
  cancellation_reason text,
  
  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Timestamps for lifecycle
  confirmed_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  billed_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_appointments_tenant_id ON appointments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_appointments_branch_id ON appointments(branch_id);
CREATE INDEX IF NOT EXISTS idx_appointments_client_id ON appointments(client_id);
CREATE INDEX IF NOT EXISTS idx_appointments_staff_id ON appointments(primary_staff_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);

ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tenant appointments"
  ON appointments FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id());

CREATE POLICY "Staff can create appointments for their customers"
  ON appointments FOR INSERT
  TO authenticated
  WITH CHECK (
    tenant_id = get_user_tenant_id() AND
    (user_has_permission('appointments', 'create') OR primary_staff_id = auth.uid())
  );

CREATE POLICY "Users can update tenant appointments"
  ON appointments FOR UPDATE
  TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

-- Appointment Services (many-to-many with modifications during session)
CREATE TABLE IF NOT EXISTS appointment_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id uuid NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
  service_id uuid NOT NULL REFERENCES services(id) ON DELETE RESTRICT,
  
  -- Service details at time of appointment (price may change later)
  service_name text NOT NULL,
  duration_minutes int NOT NULL,
  price numeric(10, 2) NOT NULL,
  
  -- Staff who performed this service
  staff_id uuid REFERENCES users(id) ON DELETE SET NULL,
  
  -- Modification tracking (for mid-session changes)
  added_at timestamptz NOT NULL DEFAULT now(),
  added_by uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  removed_at timestamptz,
  removed_by uuid REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_appointment_services_appointment_id ON appointment_services(appointment_id);
CREATE INDEX IF NOT EXISTS idx_appointment_services_service_id ON appointment_services(service_id);

ALTER TABLE appointment_services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view appointment services"
  ON appointment_services FOR SELECT
  TO authenticated
  USING (
    appointment_id IN (
      SELECT id FROM appointments WHERE tenant_id = get_user_tenant_id()
    )
  );

-- =====================================================
-- FEEDBACK
-- =====================================================

CREATE TABLE IF NOT EXISTS feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  appointment_id uuid NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
  client_id uuid NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  
  -- Ratings
  overall_rating int NOT NULL CHECK (overall_rating >= 1 AND overall_rating <= 5),
  service_rating int CHECK (service_rating >= 1 AND service_rating <= 5),
  staff_rating int CHECK (staff_rating >= 1 AND staff_rating <= 5),
  
  -- Staff specific
  staff_id uuid REFERENCES users(id) ON DELETE SET NULL,
  
  -- Comments
  comment text,
  
  -- Response from management
  response text,
  responded_by uuid REFERENCES users(id) ON DELETE SET NULL,
  responded_at timestamptz,
  
  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  
  UNIQUE(appointment_id)
);

CREATE INDEX IF NOT EXISTS idx_feedback_tenant_id ON feedback(tenant_id);
CREATE INDEX IF NOT EXISTS idx_feedback_client_id ON feedback(client_id);
CREATE INDEX IF NOT EXISTS idx_feedback_staff_id ON feedback(staff_id);
CREATE INDEX IF NOT EXISTS idx_feedback_overall_rating ON feedback(overall_rating);

ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tenant feedback"
  ON feedback FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id());

-- =====================================================
-- STAFF METRICS (Denormalized for performance)
-- =====================================================

CREATE TABLE IF NOT EXISTS staff_metrics (
  staff_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Counters
  total_appointments int NOT NULL DEFAULT 0,
  completed_appointments int NOT NULL DEFAULT 0,
  cancelled_appointments int NOT NULL DEFAULT 0,
  
  -- Revenue
  total_revenue_generated numeric(12, 2) NOT NULL DEFAULT 0,
  
  -- Ratings
  average_rating numeric(3, 2) DEFAULT 0,
  total_ratings int NOT NULL DEFAULT 0,
  
  -- Last updated
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_staff_metrics_tenant_id ON staff_metrics(tenant_id);

ALTER TABLE staff_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view own metrics"
  ON staff_metrics FOR SELECT
  TO authenticated
  USING (staff_id = auth.uid() OR tenant_id = get_user_tenant_id());

-- =====================================================
-- TRIGGERS
-- =====================================================

CREATE TRIGGER update_service_categories_updated_at
  BEFORE UPDATE ON service_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_services_updated_at
  BEFORE UPDATE ON services
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_clients_updated_at
  BEFORE UPDATE ON clients
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_appointments_updated_at
  BEFORE UPDATE ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_shift_templates_updated_at
  BEFORE UPDATE ON shift_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_staff_shifts_updated_at
  BEFORE UPDATE ON staff_shifts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- =====================================================
-- FUNCTIONS FOR BUSINESS LOGIC
-- =====================================================

-- Function to update client tier based on total spend
CREATE OR REPLACE FUNCTION update_client_tier()
RETURNS TRIGGER AS $$
BEGIN
  -- Simple tier logic (configurable later)
  IF NEW.total_spend >= 50000 THEN
    NEW.tier = 'PLATINUM';
  ELSIF NEW.total_spend >= 25000 THEN
    NEW.tier = 'GOLD';
  ELSIF NEW.total_spend >= 10000 THEN
    NEW.tier = 'SILVER';
  ELSE
    NEW.tier = 'REGULAR';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_client_tier
  BEFORE UPDATE OF total_spend ON clients
  FOR EACH ROW
  WHEN (OLD.total_spend IS DISTINCT FROM NEW.total_spend)
  EXECUTE FUNCTION update_client_tier();

-- Function to initialize staff metrics when user is created
CREATE OR REPLACE FUNCTION initialize_staff_metrics()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO staff_metrics (staff_id, tenant_id)
  VALUES (NEW.id, NEW.tenant_id)
  ON CONFLICT (staff_id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_staff_metrics
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION initialize_staff_metrics();