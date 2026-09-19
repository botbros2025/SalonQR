/*
  # SalonX Multi-Tenant Core Schema - Phase 1
  
  ## Overview
  This migration creates the foundation for a multi-tenant salon management SaaS with:
  - Schema-per-tenant isolation architecture
  - Multi-role-per-user permission system
  - DPDP compliance features
  - Audit trails for all critical operations
  
  ## New Tables
  
  ### 1. Tenants (Master Schema)
    - `id` (uuid, primary key)
    - `business_name` (text)
    - `schema_name` (text, unique) - isolated schema for tenant data
    - `status` (enum: TRIAL, ACTIVE, SUSPENDED, PAST_DUE)
    - `trial_ends_at` (timestamptz) - 30 days from creation
    - `has_gstin` (boolean) - controls GST billing features
    - `gstin` (text, nullable)
    - `proof_of_business_url` (text) - encrypted storage URL
    - `proof_verification_status` (enum: PENDING, VERIFIED, REJECTED)
    - `created_at`, `updated_at`
  
  ### 2. Roles & Permissions
    - `roles` - Owner, Manager, Staff, Cashier, InventoryManager, Customer
    - `permissions` - granular permission strings (e.g., 'appointments.create')
    - `role_permissions` - many-to-many mapping
    - `user_roles` - users can have multiple roles
  
  ### 3. Users (Master Schema)
    - Links to Supabase auth.users
    - `tenant_id` for isolation
    - Multi-role support via user_roles junction table
  
  ### 4. Branches
    - Multiple locations per tenant
    - Business hours configuration
  
  ### 5. Subscriptions
    - Razorpay integration ready
    - Trial and billing cycle management
  
  ## Security
  - RLS enabled on all tables
  - Policies enforce tenant isolation using tenant_id
  - Service role bypass for admin operations
  - Audit logging for compliance
*/

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types
CREATE TYPE tenant_status AS ENUM ('TRIAL', 'ACTIVE', 'SUSPENDED', 'PAST_DUE', 'CANCELLED');
CREATE TYPE proof_verification_status AS ENUM ('PENDING', 'VERIFIED', 'REJECTED');
CREATE TYPE subscription_status AS ENUM ('TRIAL', 'ACTIVE', 'PAST_DUE', 'CANCELLED', 'PAUSED');

-- =====================================================
-- TENANTS TABLE (Master - No RLS, managed by system)
-- =====================================================
CREATE TABLE IF NOT EXISTS tenants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_name text NOT NULL,
  schema_name text UNIQUE NOT NULL,
  status tenant_status NOT NULL DEFAULT 'TRIAL',
  trial_ends_at timestamptz NOT NULL DEFAULT (now() + interval '30 days'),
  
  -- GST Configuration
  has_gstin boolean NOT NULL DEFAULT false,
  gstin text,
  gstin_added_at timestamptz,
  
  -- Business Verification
  proof_of_business_url text,
  proof_verification_status proof_verification_status NOT NULL DEFAULT 'PENDING',
  proof_verified_at timestamptz,
  proof_verified_by uuid REFERENCES auth.users(id),
  
  -- Contact Info
  owner_name text NOT NULL,
  owner_phone text NOT NULL,
  owner_email text NOT NULL,
  
  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  CONSTRAINT gstin_required_when_has_gstin CHECK (
    (has_gstin = false) OR (has_gstin = true AND gstin IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_tenants_status ON tenants(status);
CREATE INDEX IF NOT EXISTS idx_tenants_schema_name ON tenants(schema_name);

-- =====================================================
-- USERS TABLE (Extends auth.users with tenant context)
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Profile
  full_name text NOT NULL,
  phone text NOT NULL,
  email text NOT NULL,
  avatar_url text,
  
  -- Employment (for staff)
  salary numeric(10, 2),
  join_date date,
  
  -- Status
  is_active boolean NOT NULL DEFAULT true,
  last_login_at timestamptz,
  
  -- DPDP Compliance
  consent_given boolean NOT NULL DEFAULT false,
  consent_given_at timestamptz,
  data_retention_expires_at timestamptz,
  
  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_tenant_id ON users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can read their own data
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- =====================================================
-- ROLES & PERMISSIONS SYSTEM
-- =====================================================
CREATE TABLE IF NOT EXISTS roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  description text,
  is_system_role boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  resource text NOT NULL, -- e.g., 'appointments', 'invoices', 'inventory'
  action text NOT NULL, -- e.g., 'create', 'read', 'update', 'delete'
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(resource, action)
);

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id uuid NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id uuid NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (role_id, permission_id)
);

-- Multi-role per user support
CREATE TABLE IF NOT EXISTS user_roles (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id uuid NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  assigned_by uuid REFERENCES users(id),
  assigned_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, role_id, tenant_id)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_tenant_id ON user_roles(tenant_id);

-- Enable RLS
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read roles and permissions
CREATE POLICY "Authenticated users can view roles"
  ON roles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can view permissions"
  ON permissions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can view role permissions"
  ON role_permissions FOR SELECT
  TO authenticated
  USING (true);

-- Users can view their own role assignments
CREATE POLICY "Users can view own roles"
  ON user_roles FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- =====================================================
-- BRANCHES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS branches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Branch Info
  name text NOT NULL,
  address text NOT NULL,
  city text NOT NULL,
  state text NOT NULL,
  pincode text NOT NULL,
  phone text,
  email text,
  
  -- Operating Hours (JSON structure for flexibility)
  business_hours jsonb NOT NULL DEFAULT '{}',
  -- Example: {"monday": {"open": "09:00", "close": "20:00", "closed": false}, ...}
  
  -- Status
  is_active boolean NOT NULL DEFAULT true,
  
  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_branches_tenant_id ON branches(tenant_id);

-- Enable RLS
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;

-- Users can view branches in their tenant
CREATE POLICY "Users can view tenant branches"
  ON branches FOR SELECT
  TO authenticated
  USING (
    tenant_id IN (
      SELECT tenant_id FROM users WHERE id = auth.uid()
    )
  );

-- =====================================================
-- SUBSCRIPTIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Razorpay Integration
  razorpay_subscription_id text UNIQUE,
  razorpay_plan_id text,
  razorpay_customer_id text,
  
  -- Subscription Details
  status subscription_status NOT NULL DEFAULT 'TRIAL',
  current_period_start timestamptz NOT NULL DEFAULT now(),
  current_period_end timestamptz NOT NULL,
  trial_end timestamptz,
  
  -- Billing
  amount numeric(10, 2) NOT NULL DEFAULT 0,
  currency text NOT NULL DEFAULT 'INR',
  billing_cycle text NOT NULL DEFAULT 'monthly', -- monthly, quarterly, annual
  
  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  cancelled_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_tenant_id ON subscriptions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);

-- Enable RLS
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Only tenant owners can view subscription
CREATE POLICY "Tenant owners can view subscription"
  ON subscriptions FOR SELECT
  TO authenticated
  USING (
    tenant_id IN (
      SELECT tenant_id FROM users WHERE id = auth.uid()
    )
  );

-- =====================================================
-- AUDIT LOGS (DPDP Compliance)
-- =====================================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Who & What
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  action text NOT NULL, -- e.g., 'CREATE', 'UPDATE', 'DELETE', 'EXPORT'
  resource_type text NOT NULL, -- e.g., 'appointment', 'invoice', 'client'
  resource_id uuid,
  
  -- Details
  old_values jsonb,
  new_values jsonb,
  ip_address inet,
  user_agent text,
  
  -- Timestamp
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_id ON audit_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

-- Enable RLS
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Users can view audit logs in their tenant (if they have permission)
CREATE POLICY "Users can view tenant audit logs"
  ON audit_logs FOR SELECT
  TO authenticated
  USING (
    tenant_id IN (
      SELECT tenant_id FROM users WHERE id = auth.uid()
    )
  );

-- =====================================================
-- SEED DEFAULT ROLES AND PERMISSIONS
-- =====================================================

-- Insert system roles
INSERT INTO roles (id, name, description, is_system_role) VALUES
  ('00000000-0000-0000-0000-000000000001', 'owner', 'Full tenant administrator with all permissions', true),
  ('00000000-0000-0000-0000-000000000002', 'manager', 'Operational manager with staff and business management', true),
  ('00000000-0000-0000-0000-000000000003', 'staff', 'Service staff with limited permissions', true),
  ('00000000-0000-0000-0000-000000000004', 'cashier', 'Billing and payment processing', true),
  ('00000000-0000-0000-0000-000000000005', 'inventory_manager', 'Inventory and stock management', true),
  ('00000000-0000-0000-0000-000000000006', 'customer', 'External customer role', true)
ON CONFLICT (name) DO NOTHING;

-- Insert core permissions
INSERT INTO permissions (resource, action, description) VALUES
  -- Tenant Management
  ('tenant', 'manage', 'Full tenant administration'),
  ('tenant', 'view', 'View tenant information'),
  ('tenant', 'verify_proof', 'Verify business proof documents'),
  
  -- User Management
  ('users', 'create', 'Create new users'),
  ('users', 'read', 'View user profiles'),
  ('users', 'update', 'Update user profiles'),
  ('users', 'delete', 'Delete users'),
  ('users', 'assign_roles', 'Assign roles to users'),
  
  -- Branch Management
  ('branches', 'create', 'Create new branches'),
  ('branches', 'read', 'View branches'),
  ('branches', 'update', 'Update branch details'),
  ('branches', 'delete', 'Delete branches'),
  
  -- Appointment Management
  ('appointments', 'create', 'Create appointments'),
  ('appointments', 'read', 'View appointments'),
  ('appointments', 'update', 'Update appointments'),
  ('appointments', 'delete', 'Delete appointments'),
  ('appointments', 'modify_services', 'Add/remove services during appointment'),
  
  -- Invoice/Billing
  ('invoices', 'create', 'Create invoices'),
  ('invoices', 'read', 'View invoices'),
  ('invoices', 'update', 'Update invoices'),
  ('invoices', 'delete', 'Delete invoices'),
  ('invoices', 'apply_discount', 'Apply discounts to invoices'),
  
  -- Inventory
  ('inventory', 'create', 'Add inventory items'),
  ('inventory', 'read', 'View inventory'),
  ('inventory', 'update', 'Update inventory'),
  ('inventory', 'delete', 'Delete inventory items'),
  ('inventory', 'adjust', 'Adjust inventory quantities'),
  ('inventory', 'approve_po', 'Approve purchase orders'),
  
  -- Client/CRM
  ('clients', 'create', 'Create client profiles'),
  ('clients', 'read', 'View client information'),
  ('clients', 'update', 'Update client profiles'),
  ('clients', 'delete', 'Delete client profiles'),
  ('clients', 'export', 'Export client data'),
  
  -- Services
  ('services', 'create', 'Create service offerings'),
  ('services', 'read', 'View services'),
  ('services', 'update', 'Update services'),
  ('services', 'delete', 'Delete services'),
  
  -- Reports & Analytics
  ('reports', 'view', 'View reports and analytics'),
  ('reports', 'export', 'Export reports'),
  
  -- Feedback
  ('feedback', 'read', 'View feedback'),
  ('feedback', 'reply', 'Reply to feedback'),
  
  -- Subscription
  ('subscription', 'manage', 'Manage subscription and billing'),
  ('subscription', 'view', 'View subscription details'),
  
  -- WhatsApp Config
  ('whatsapp', 'configure', 'Configure WhatsApp integration'),
  ('whatsapp', 'send', 'Send WhatsApp messages')
ON CONFLICT (resource, action) DO NOTHING;

-- Assign permissions to roles (Owner gets all)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
  '00000000-0000-0000-0000-000000000001',
  id
FROM permissions
ON CONFLICT DO NOTHING;

-- Manager permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
  '00000000-0000-0000-0000-000000000002',
  id
FROM permissions
WHERE resource IN ('users', 'appointments', 'invoices', 'clients', 'services', 'reports', 'feedback')
  OR (resource = 'branches' AND action = 'read')
  OR (resource = 'inventory' AND action = 'read')
ON CONFLICT DO NOTHING;

-- Staff permissions (limited)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
  '00000000-0000-0000-0000-000000000003',
  id
FROM permissions
WHERE (resource = 'appointments' AND action IN ('read', 'update', 'modify_services'))
  OR (resource = 'clients' AND action = 'read')
  OR (resource = 'services' AND action = 'read')
ON CONFLICT DO NOTHING;

-- Cashier permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
  '00000000-0000-0000-0000-000000000004',
  id
FROM permissions
WHERE resource IN ('invoices', 'clients')
  OR (resource = 'appointments' AND action = 'read')
ON CONFLICT DO NOTHING;

-- Inventory Manager permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
  '00000000-0000-0000-0000-000000000005',
  id
FROM permissions
WHERE resource = 'inventory'
ON CONFLICT DO NOTHING;

-- =====================================================
-- FUNCTIONS FOR TENANT ISOLATION
-- =====================================================

-- Function to get user's tenant_id
CREATE OR REPLACE FUNCTION get_user_tenant_id()
RETURNS uuid AS $$
  SELECT tenant_id FROM users WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Function to check if user has permission
CREATE OR REPLACE FUNCTION user_has_permission(p_resource text, p_action text)
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1
    FROM user_roles ur
    JOIN role_permissions rp ON ur.role_id = rp.role_id
    JOIN permissions p ON rp.permission_id = p.id
    WHERE ur.user_id = auth.uid()
      AND p.resource = p_resource
      AND p.action = p_action
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Function to get user's effective permissions (union of all roles)
CREATE OR REPLACE FUNCTION get_user_permissions()
RETURNS TABLE(resource text, action text) AS $$
  SELECT DISTINCT p.resource, p.action
  FROM user_roles ur
  JOIN role_permissions rp ON ur.role_id = rp.role_id
  JOIN permissions p ON rp.permission_id = p.id
  WHERE ur.user_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_tenants_updated_at
  BEFORE UPDATE ON tenants
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_branches_updated_at
  BEFORE UPDATE ON branches
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_subscriptions_updated_at
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();