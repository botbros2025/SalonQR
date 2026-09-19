/*
  # SalonX Inventory and Billing Tables - Phase 1
  
  ## Overview
  Creates tables for:
  - Inventory management with transaction tracking
  - Purchase orders and stock management
  - Invoicing with conditional GST support
  - Payments and transaction records
  
  ## New Tables
  
  ### 1. Inventory Items
    - Stock tracking
    - Low stock alerts
    - Auto-deduction on appointment completion
  
  ### 2. Purchase Orders
    - PO creation and approval workflow
    - Stock receipt processing
  
  ### 3. Invoices
    - Conditional GST billing
    - Multi-line items (services + products)
    - Payment tracking
  
  ### 4. Payments
    - Payment method tracking
    - Transaction records
  
  ## Security
  - RLS enabled with tenant isolation
  - Permission-based access control
  - Audit trails for all transactions
*/

-- =====================================================
-- INVENTORY MANAGEMENT
-- =====================================================

CREATE TYPE inventory_unit AS ENUM ('PIECE', 'LITER', 'KILOGRAM', 'MILLILITER', 'GRAM', 'BOX', 'BOTTLE');
CREATE TYPE transaction_type AS ENUM ('PURCHASE', 'ADJUSTMENT', 'DEDUCTION', 'RETURN', 'TRANSFER');

CREATE TABLE IF NOT EXISTS inventory_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id uuid REFERENCES branches(id) ON DELETE CASCADE,
  
  -- Item Details
  name text NOT NULL,
  description text,
  sku text,
  barcode text,
  
  -- Quantity
  current_quantity numeric(10, 2) NOT NULL DEFAULT 0,
  unit inventory_unit NOT NULL DEFAULT 'PIECE',
  
  -- Thresholds
  min_quantity numeric(10, 2) NOT NULL DEFAULT 0,
  reorder_quantity numeric(10, 2) NOT NULL DEFAULT 0,
  
  -- Pricing
  cost_price numeric(10, 2) NOT NULL DEFAULT 0,
  selling_price numeric(10, 2),
  
  -- Tax
  hsn_sac_code text,
  tax_rate numeric(5, 2) DEFAULT 0,
  
  -- Status
  is_active boolean NOT NULL DEFAULT true,
  low_stock_alert_enabled boolean NOT NULL DEFAULT true,
  
  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  UNIQUE(tenant_id, sku)
);

CREATE INDEX IF NOT EXISTS idx_inventory_items_tenant_id ON inventory_items(tenant_id);
CREATE INDEX IF NOT EXISTS idx_inventory_items_branch_id ON inventory_items(branch_id);
CREATE INDEX IF NOT EXISTS idx_inventory_items_sku ON inventory_items(sku);
CREATE INDEX IF NOT EXISTS idx_inventory_items_low_stock ON inventory_items(current_quantity, min_quantity) 
  WHERE current_quantity <= min_quantity;

ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tenant inventory"
  ON inventory_items FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id());

-- Service-Inventory mapping (which items are consumed per service)
CREATE TABLE IF NOT EXISTS service_inventory_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id uuid NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  inventory_item_id uuid NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
  
  quantity_per_service numeric(10, 2) NOT NULL DEFAULT 1,
  
  created_at timestamptz NOT NULL DEFAULT now(),
  
  UNIQUE(service_id, inventory_item_id)
);

CREATE INDEX IF NOT EXISTS idx_service_inventory_service_id ON service_inventory_items(service_id);

ALTER TABLE service_inventory_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view service inventory mappings"
  ON service_inventory_items FOR SELECT
  TO authenticated
  USING (
    service_id IN (
      SELECT id FROM services WHERE tenant_id = get_user_tenant_id()
    )
  );

-- =====================================================
-- PURCHASE ORDERS
-- =====================================================

CREATE TYPE po_status AS ENUM ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'ORDERED', 'RECEIVED', 'CANCELLED');

CREATE TABLE IF NOT EXISTS purchase_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id uuid REFERENCES branches(id) ON DELETE CASCADE,
  
  -- PO Details
  po_number text NOT NULL,
  vendor_name text NOT NULL,
  vendor_contact text,
  
  -- Status
  status po_status NOT NULL DEFAULT 'DRAFT',
  
  -- Amounts
  subtotal numeric(10, 2) NOT NULL DEFAULT 0,
  tax_amount numeric(10, 2) NOT NULL DEFAULT 0,
  total_amount numeric(10, 2) NOT NULL DEFAULT 0,
  
  -- Dates
  order_date date,
  expected_delivery_date date,
  received_date date,
  
  -- Approval
  approved_by uuid REFERENCES users(id) ON DELETE SET NULL,
  approved_at timestamptz,
  
  -- Notes
  notes text,
  
  -- Metadata
  created_by uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  UNIQUE(tenant_id, po_number)
);

CREATE INDEX IF NOT EXISTS idx_purchase_orders_tenant_id ON purchase_orders(tenant_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_status ON purchase_orders(status);

ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tenant purchase orders"
  ON purchase_orders FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id());

-- PO Line Items
CREATE TABLE IF NOT EXISTS purchase_order_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_order_id uuid NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
  inventory_item_id uuid NOT NULL REFERENCES inventory_items(id) ON DELETE RESTRICT,
  
  -- Order Details
  quantity numeric(10, 2) NOT NULL,
  unit_price numeric(10, 2) NOT NULL,
  tax_rate numeric(5, 2) NOT NULL DEFAULT 0,
  
  -- Calculated
  subtotal numeric(10, 2) NOT NULL,
  tax_amount numeric(10, 2) NOT NULL,
  total numeric(10, 2) NOT NULL,
  
  -- Receipt
  quantity_received numeric(10, 2) DEFAULT 0,
  
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_purchase_order_lines_po_id ON purchase_order_lines(purchase_order_id);

ALTER TABLE purchase_order_lines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view PO lines"
  ON purchase_order_lines FOR SELECT
  TO authenticated
  USING (
    purchase_order_id IN (
      SELECT id FROM purchase_orders WHERE tenant_id = get_user_tenant_id()
    )
  );

-- Inventory Transactions (audit trail) - created after purchase_orders
CREATE TABLE IF NOT EXISTS inventory_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  inventory_item_id uuid NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
  
  -- Transaction Details
  transaction_type transaction_type NOT NULL,
  quantity numeric(10, 2) NOT NULL,
  quantity_before numeric(10, 2) NOT NULL,
  quantity_after numeric(10, 2) NOT NULL,
  
  -- Cost tracking
  unit_cost numeric(10, 2),
  total_cost numeric(10, 2),
  
  -- References
  appointment_id uuid REFERENCES appointments(id) ON DELETE SET NULL,
  purchase_order_id uuid REFERENCES purchase_orders(id) ON DELETE SET NULL,
  
  -- Notes
  notes text,
  
  -- Metadata
  created_by uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_inventory_transactions_tenant_id ON inventory_transactions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_item_id ON inventory_transactions(inventory_item_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_created_at ON inventory_transactions(created_at);

ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tenant inventory transactions"
  ON inventory_transactions FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id());

-- =====================================================
-- INVOICING & BILLING
-- =====================================================

CREATE TYPE invoice_status AS ENUM ('DRAFT', 'PENDING', 'PAID', 'PARTIALLY_PAID', 'CANCELLED');
CREATE TYPE payment_method AS ENUM ('CASH', 'CARD', 'UPI', 'WALLET', 'BANK_TRANSFER', 'OTHER');

CREATE TABLE IF NOT EXISTS invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id uuid NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  
  -- Invoice Details
  invoice_number text NOT NULL,
  invoice_date date NOT NULL DEFAULT CURRENT_DATE,
  
  -- References
  appointment_id uuid REFERENCES appointments(id) ON DELETE SET NULL,
  client_id uuid NOT NULL REFERENCES clients(id) ON DELETE RESTRICT,
  
  -- Status
  status invoice_status NOT NULL DEFAULT 'DRAFT',
  
  -- Amounts
  subtotal numeric(10, 2) NOT NULL DEFAULT 0,
  discount_amount numeric(10, 2) NOT NULL DEFAULT 0,
  discount_percentage numeric(5, 2) NOT NULL DEFAULT 0,
  
  -- GST (conditional based on tenant.has_gstin)
  tax_amount numeric(10, 2) NOT NULL DEFAULT 0,
  cgst numeric(10, 2) NOT NULL DEFAULT 0,
  sgst numeric(10, 2) NOT NULL DEFAULT 0,
  igst numeric(10, 2) NOT NULL DEFAULT 0,
  
  total_amount numeric(10, 2) NOT NULL DEFAULT 0,
  paid_amount numeric(10, 2) NOT NULL DEFAULT 0,
  balance_amount numeric(10, 2) NOT NULL DEFAULT 0,
  
  -- GST Details (only if tenant has GSTIN)
  gstin_applied boolean NOT NULL DEFAULT false,
  place_of_supply text,
  
  -- Notes
  notes text,
  terms_and_conditions text,
  
  -- PDF
  pdf_url text,
  
  -- Metadata
  created_by uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  UNIQUE(tenant_id, invoice_number)
);

CREATE INDEX IF NOT EXISTS idx_invoices_tenant_id ON invoices(tenant_id);
CREATE INDEX IF NOT EXISTS idx_invoices_client_id ON invoices(client_id);
CREATE INDEX IF NOT EXISTS idx_invoices_appointment_id ON invoices(appointment_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_date ON invoices(invoice_date);

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tenant invoices"
  ON invoices FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id());

-- Invoice Line Items
CREATE TYPE line_item_type AS ENUM ('SERVICE', 'PRODUCT');

CREATE TABLE IF NOT EXISTS invoice_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  
  -- Item Details
  item_type line_item_type NOT NULL,
  item_id uuid,
  item_name text NOT NULL,
  description text,
  
  -- Quantity & Price
  quantity numeric(10, 2) NOT NULL DEFAULT 1,
  unit_price numeric(10, 2) NOT NULL,
  
  -- Tax
  hsn_sac_code text,
  tax_rate numeric(5, 2) NOT NULL DEFAULT 0,
  tax_amount numeric(10, 2) NOT NULL DEFAULT 0,
  
  -- Calculated
  subtotal numeric(10, 2) NOT NULL,
  total numeric(10, 2) NOT NULL,
  
  -- Staff who performed service
  staff_id uuid REFERENCES users(id) ON DELETE SET NULL,
  
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_invoice_lines_invoice_id ON invoice_lines(invoice_id);

ALTER TABLE invoice_lines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view invoice lines"
  ON invoice_lines FOR SELECT
  TO authenticated
  USING (
    invoice_id IN (
      SELECT id FROM invoices WHERE tenant_id = get_user_tenant_id()
    )
  );

-- =====================================================
-- PAYMENTS
-- =====================================================

CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  invoice_id uuid NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  
  -- Payment Details
  amount numeric(10, 2) NOT NULL,
  payment_method payment_method NOT NULL,
  payment_date timestamptz NOT NULL DEFAULT now(),
  
  -- Transaction Details
  transaction_id text,
  reference_number text,
  
  -- Notes
  notes text,
  
  -- Metadata
  created_by uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payments_tenant_id ON payments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_payments_invoice_id ON payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payments_payment_date ON payments(payment_date);

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tenant payments"
  ON payments FOR SELECT
  TO authenticated
  USING (tenant_id = get_user_tenant_id());

-- =====================================================
-- TRIGGERS
-- =====================================================

CREATE TRIGGER update_inventory_items_updated_at
  BEFORE UPDATE ON inventory_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_purchase_orders_updated_at
  BEFORE UPDATE ON purchase_orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_invoices_updated_at
  BEFORE UPDATE ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- =====================================================
-- BUSINESS LOGIC FUNCTIONS
-- =====================================================

-- Function to deduct inventory when appointment is completed
CREATE OR REPLACE FUNCTION deduct_inventory_for_appointment()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'COMPLETED' AND OLD.status != 'COMPLETED' THEN
    
    INSERT INTO inventory_transactions (
      tenant_id,
      inventory_item_id,
      transaction_type,
      quantity,
      quantity_before,
      quantity_after,
      appointment_id,
      created_by,
      notes
    )
    SELECT 
      NEW.tenant_id,
      sii.inventory_item_id,
      'DEDUCTION',
      -sii.quantity_per_service,
      ii.current_quantity,
      ii.current_quantity - sii.quantity_per_service,
      NEW.id,
      NEW.primary_staff_id,
      'Auto-deduction for appointment'
    FROM appointment_services aps
    JOIN service_inventory_items sii ON aps.service_id = sii.service_id
    JOIN inventory_items ii ON sii.inventory_item_id = ii.id
    WHERE aps.appointment_id = NEW.id
      AND aps.removed_at IS NULL;
    
    UPDATE inventory_items ii
    SET current_quantity = current_quantity - sii.quantity_per_service
    FROM appointment_services aps
    JOIN service_inventory_items sii ON aps.service_id = sii.service_id
    WHERE aps.appointment_id = NEW.id
      AND aps.removed_at IS NULL
      AND ii.id = sii.inventory_item_id;
      
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_deduct_inventory
  AFTER UPDATE ON appointments
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION deduct_inventory_for_appointment();

-- Function to update invoice balance
CREATE OR REPLACE FUNCTION update_invoice_balance()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE invoices
  SET 
    paid_amount = COALESCE((
      SELECT SUM(amount) 
      FROM payments 
      WHERE invoice_id = NEW.invoice_id
    ), 0),
    updated_at = now()
  WHERE id = NEW.invoice_id;
  
  UPDATE invoices
  SET 
    balance_amount = total_amount - paid_amount,
    status = CASE
      WHEN paid_amount >= total_amount THEN 'PAID'
      WHEN paid_amount > 0 THEN 'PARTIALLY_PAID'
      ELSE status
    END
  WHERE id = NEW.invoice_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_invoice_balance
  AFTER INSERT ON payments
  FOR EACH ROW
  EXECUTE FUNCTION update_invoice_balance();

-- Function to update client spend when invoice is paid
CREATE OR REPLACE FUNCTION update_client_spend()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'PAID' AND OLD.status != 'PAID' THEN
    UPDATE clients
    SET 
      total_spend = total_spend + NEW.total_amount,
      total_visits = total_visits + 1,
      last_visit_at = NEW.invoice_date
    WHERE id = NEW.client_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_client_metrics
  AFTER UPDATE ON invoices
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION update_client_spend();

-- Generate next invoice number
CREATE OR REPLACE FUNCTION generate_invoice_number(p_tenant_id uuid)
RETURNS text AS $$
DECLARE
  v_count int;
  v_number text;
BEGIN
  SELECT COUNT(*) + 1 INTO v_count
  FROM invoices
  WHERE tenant_id = p_tenant_id
    AND EXTRACT(YEAR FROM invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE);
  
  v_number := 'INV-' || 
    TO_CHAR(CURRENT_DATE, 'YYYY') || '-' || 
    LPAD(v_count::text, 5, '0');
  
  RETURN v_number;
END;
$$ LANGUAGE plpgsql;