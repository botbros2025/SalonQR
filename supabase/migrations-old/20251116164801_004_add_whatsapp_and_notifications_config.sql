/*
  # WhatsApp Integration and Notification Configuration
  
  ## Overview
  Adds tables for:
  - WhatsApp provider configuration (Gupshup)
  - Notification templates
  - Notification logs
  - System configuration
  
  ## New Tables
  
  ### 1. whatsapp_config
    - Tenant-specific WhatsApp provider settings
    - Gupshup API keys and sender details
    - Template IDs for different message types
  
  ### 2. notification_templates
    - Message templates for WhatsApp, Email, SMS
    - Customizable per tenant
  
  ### 3. notification_logs
    - Audit trail of all notifications sent
    - Delivery status tracking
  
  ## Security
  - RLS enabled with tenant isolation
  - Only owners can configure WhatsApp
*/

-- =====================================================
-- WHATSAPP CONFIGURATION
-- =====================================================

CREATE TYPE whatsapp_provider AS ENUM ('GUPSHUP', 'TWILIO', 'META');

CREATE TABLE IF NOT EXISTS whatsapp_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL UNIQUE REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Provider
  provider whatsapp_provider NOT NULL DEFAULT 'GUPSHUP',
  
  -- Credentials (encrypted)
  api_key text NOT NULL,
  sender_phone text NOT NULL,
  sender_name text,
  
  -- Template IDs
  appointment_confirmation_template_id text,
  appointment_reminder_template_id text,
  invoice_template_id text,
  feedback_template_id text,
  birthday_template_id text,
  low_stock_alert_template_id text,
  
  -- Status
  is_active boolean NOT NULL DEFAULT true,
  verified boolean NOT NULL DEFAULT false,
  verified_at timestamptz,
  
  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_whatsapp_config_tenant_id ON whatsapp_config(tenant_id);

ALTER TABLE whatsapp_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owners can manage WhatsApp config"
  ON whatsapp_config FOR ALL
  TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

-- =====================================================
-- NOTIFICATION TEMPLATES
-- =====================================================

CREATE TYPE notification_channel AS ENUM ('WHATSAPP', 'EMAIL', 'SMS', 'PUSH');
CREATE TYPE template_type AS ENUM (
  'APPOINTMENT_CONFIRMATION',
  'APPOINTMENT_REMINDER',
  'INVOICE',
  'FEEDBACK_REQUEST',
  'BIRTHDAY_GREETING',
  'LOW_STOCK_ALERT',
  'DAILY_REPORT',
  'WEEKLY_REPORT',
  'CUSTOM'
);

CREATE TABLE IF NOT EXISTS notification_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Template Details
  name text NOT NULL,
  type template_type NOT NULL,
  channel notification_channel NOT NULL,
  
  -- Content (supports variables like {{client_name}}, {{appointment_date}})
  subject text,
  body text NOT NULL,
  
  -- Provider-specific
  provider_template_id text,
  
  -- Status
  is_active boolean NOT NULL DEFAULT true,
  is_system_default boolean NOT NULL DEFAULT false,
  
  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  UNIQUE(tenant_id, type, channel)
);

CREATE INDEX IF NOT EXISTS idx_notification_templates_tenant_id ON notification_templates(tenant_id);
CREATE INDEX IF NOT EXISTS idx_notification_templates_type ON notification_templates(type);

ALTER TABLE notification_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tenant notification templates"
  ON notification_templates FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id() OR tenant_id IS NULL);

-- =====================================================
-- NOTIFICATION LOGS
-- =====================================================

CREATE TYPE notification_status AS ENUM ('PENDING', 'SENT', 'DELIVERED', 'READ', 'FAILED');

CREATE TABLE IF NOT EXISTS notification_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Recipient
  recipient_id uuid,
  recipient_phone text,
  recipient_email text,
  recipient_name text,
  
  -- Message Details
  channel notification_channel NOT NULL,
  template_type template_type,
  subject text,
  body text NOT NULL,
  
  -- Status
  status notification_status NOT NULL DEFAULT 'PENDING',
  
  -- Provider Response
  provider_message_id text,
  provider_response jsonb,
  error_message text,
  
  -- Delivery Tracking
  sent_at timestamptz,
  delivered_at timestamptz,
  read_at timestamptz,
  failed_at timestamptz,
  
  -- References
  appointment_id uuid REFERENCES appointments(id) ON DELETE SET NULL,
  invoice_id uuid REFERENCES invoices(id) ON DELETE SET NULL,
  
  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notification_logs_tenant_id ON notification_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_status ON notification_logs(status);
CREATE INDEX IF NOT EXISTS idx_notification_logs_created_at ON notification_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_notification_logs_recipient_phone ON notification_logs(recipient_phone);

ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tenant notification logs"
  ON notification_logs FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id());

-- =====================================================
-- SYSTEM CONFIGURATION
-- =====================================================

CREATE TABLE IF NOT EXISTS tenant_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL UNIQUE REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Business Settings
  default_appointment_duration int NOT NULL DEFAULT 60,
  appointment_buffer_minutes int NOT NULL DEFAULT 15,
  advance_booking_days int NOT NULL DEFAULT 30,
  cancellation_policy text,
  
  -- Loyalty Tier Thresholds
  silver_threshold numeric(10, 2) NOT NULL DEFAULT 10000,
  gold_threshold numeric(10, 2) NOT NULL DEFAULT 25000,
  platinum_threshold numeric(10, 2) NOT NULL DEFAULT 50000,
  
  -- Tax Settings
  default_tax_rate numeric(5, 2) NOT NULL DEFAULT 18,
  
  -- Notifications
  send_appointment_confirmations boolean NOT NULL DEFAULT true,
  send_appointment_reminders boolean NOT NULL DEFAULT true,
  reminder_hours_before int NOT NULL DEFAULT 1,
  send_birthday_greetings boolean NOT NULL DEFAULT true,
  send_feedback_requests boolean NOT NULL DEFAULT true,
  
  -- Reports
  daily_report_enabled boolean NOT NULL DEFAULT true,
  daily_report_time time NOT NULL DEFAULT '21:00:00',
  weekly_report_enabled boolean NOT NULL DEFAULT true,
  weekly_report_day int NOT NULL DEFAULT 6,
  
  -- Theme
  theme_primary_color text NOT NULL DEFAULT '#0ea5e9',
  theme_accent_color text NOT NULL DEFAULT '#06b6d4',
  theme_font_family text NOT NULL DEFAULT 'Inter',
  
  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tenant_settings_tenant_id ON tenant_settings(tenant_id);

ALTER TABLE tenant_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tenant settings"
  ON tenant_settings FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id());

-- =====================================================
-- TRIGGERS
-- =====================================================

CREATE TRIGGER update_whatsapp_config_updated_at
  BEFORE UPDATE ON whatsapp_config
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_notification_templates_updated_at
  BEFORE UPDATE ON notification_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_tenant_settings_updated_at
  BEFORE UPDATE ON tenant_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- =====================================================
-- SEED DEFAULT TEMPLATES
-- =====================================================

INSERT INTO notification_templates (tenant_id, name, type, channel, subject, body, is_system_default) VALUES
  (NULL, 'Appointment Confirmation', 'APPOINTMENT_CONFIRMATION', 'WHATSAPP', NULL, 
   'Hi {{client_name}}, your appointment is confirmed for {{appointment_date}} at {{appointment_time}}. See you at {{branch_name}}!', 
   true),
  (NULL, 'Appointment Reminder', 'APPOINTMENT_REMINDER', 'WHATSAPP', NULL,
   'Reminder: Your appointment at {{branch_name}} is in 1 hour ({{appointment_time}}). Looking forward to seeing you!',
   true),
  (NULL, 'Invoice Message', 'INVOICE', 'WHATSAPP', NULL,
   'Thank you for visiting {{branch_name}}! Your invoice #{{invoice_number}} for ₹{{total_amount}} is ready. View here: {{invoice_link}}',
   true),
  (NULL, 'Feedback Request', 'FEEDBACK_REQUEST', 'WHATSAPP', NULL,
   'We hope you enjoyed your visit to {{branch_name}}! Please share your feedback: {{feedback_link}}',
   true),
  (NULL, 'Birthday Greeting', 'BIRTHDAY_GREETING', 'WHATSAPP', NULL,
   'Happy Birthday {{client_name}}! 🎉 Enjoy 20% off your next visit. Book now: {{booking_link}}',
   true),
  (NULL, 'Low Stock Alert', 'LOW_STOCK_ALERT', 'WHATSAPP', NULL,
   'Alert: {{item_name}} stock is low ({{current_quantity}} remaining). Please reorder.',
   true)
ON CONFLICT DO NOTHING;

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to create default settings for new tenant
CREATE OR REPLACE FUNCTION create_default_tenant_settings()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO tenant_settings (tenant_id)
  VALUES (NEW.id)
  ON CONFLICT (tenant_id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER initialize_tenant_settings
  AFTER INSERT ON tenants
  FOR EACH ROW
  EXECUTE FUNCTION create_default_tenant_settings();