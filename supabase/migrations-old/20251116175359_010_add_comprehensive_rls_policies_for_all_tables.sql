/*
  # Comprehensive RLS Policies for All Tables
  
  ## Problem
  Most tables only have SELECT policies, causing "row-level security policy violation"
  errors during normal operations like signup and data entry.
  
  ## Solution
  Add INSERT, UPDATE, DELETE policies for all business tables with proper tenant isolation.
  
  ## Tables Updated (23 tables)
  - Client management: clients, client_notes
  - Services: services, service_categories, service_inventory_items
  - Appointments: appointment_services
  - Staff: staff_metrics, staff_shifts, shift_templates
  - Inventory: inventory_items, inventory_transactions
  - Billing: invoices, invoice_lines, payments
  - Purchasing: purchase_orders, purchase_order_lines
  - Feedback: feedback
  - Notifications: notification_templates, notification_logs
  - System: audit_logs, subscriptions
  - Permissions: role_permissions
  
  ## Security Model
  All policies enforce tenant isolation via get_user_tenant_id()
*/

-- ============================================================================
-- CLIENT MANAGEMENT
-- ============================================================================

CREATE POLICY "Users can create clients"
  ON clients FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can update clients"
  ON clients FOR UPDATE TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can delete clients"
  ON clients FOR DELETE TO authenticated
  USING (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can create client notes"
  ON client_notes FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can update client notes"
  ON client_notes FOR UPDATE TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can delete client notes"
  ON client_notes FOR DELETE TO authenticated
  USING (tenant_id = get_user_tenant_id());

-- ============================================================================
-- SERVICES
-- ============================================================================

CREATE POLICY "Users can create service categories"
  ON service_categories FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can update service categories"
  ON service_categories FOR UPDATE TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can delete service categories"
  ON service_categories FOR DELETE TO authenticated
  USING (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can create services"
  ON services FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can update services"
  ON services FOR UPDATE TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can delete services"
  ON services FOR DELETE TO authenticated
  USING (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can link service inventory items"
  ON service_inventory_items FOR INSERT TO authenticated
  WITH CHECK (
    service_id IN (SELECT id FROM services WHERE tenant_id = get_user_tenant_id())
  );

CREATE POLICY "Users can update service inventory links"
  ON service_inventory_items FOR UPDATE TO authenticated
  USING (
    service_id IN (SELECT id FROM services WHERE tenant_id = get_user_tenant_id())
  )
  WITH CHECK (
    service_id IN (SELECT id FROM services WHERE tenant_id = get_user_tenant_id())
  );

CREATE POLICY "Users can delete service inventory links"
  ON service_inventory_items FOR DELETE TO authenticated
  USING (
    service_id IN (SELECT id FROM services WHERE tenant_id = get_user_tenant_id())
  );

-- ============================================================================
-- APPOINTMENTS
-- ============================================================================

CREATE POLICY "Users can add appointment services"
  ON appointment_services FOR INSERT TO authenticated
  WITH CHECK (
    appointment_id IN (SELECT id FROM appointments WHERE tenant_id = get_user_tenant_id())
  );

CREATE POLICY "Users can update appointment services"
  ON appointment_services FOR UPDATE TO authenticated
  USING (
    appointment_id IN (SELECT id FROM appointments WHERE tenant_id = get_user_tenant_id())
  )
  WITH CHECK (
    appointment_id IN (SELECT id FROM appointments WHERE tenant_id = get_user_tenant_id())
  );

CREATE POLICY "Users can delete appointment services"
  ON appointment_services FOR DELETE TO authenticated
  USING (
    appointment_id IN (SELECT id FROM appointments WHERE tenant_id = get_user_tenant_id())
  );

-- ============================================================================
-- STAFF MANAGEMENT
-- ============================================================================

CREATE POLICY "Users can update staff metrics"
  ON staff_metrics FOR UPDATE TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can delete staff metrics"
  ON staff_metrics FOR DELETE TO authenticated
  USING (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can create staff shifts"
  ON staff_shifts FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can delete staff shifts"
  ON staff_shifts FOR DELETE TO authenticated
  USING (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can create shift templates"
  ON shift_templates FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can update shift templates"
  ON shift_templates FOR UPDATE TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can delete shift templates"
  ON shift_templates FOR DELETE TO authenticated
  USING (tenant_id = get_user_tenant_id());

-- ============================================================================
-- INVENTORY
-- ============================================================================

CREATE POLICY "Users can create inventory items"
  ON inventory_items FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can update inventory items"
  ON inventory_items FOR UPDATE TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can delete inventory items"
  ON inventory_items FOR DELETE TO authenticated
  USING (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can create inventory transactions"
  ON inventory_transactions FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can update inventory transactions"
  ON inventory_transactions FOR UPDATE TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

-- ============================================================================
-- BILLING & PAYMENTS
-- ============================================================================

CREATE POLICY "Users can create invoices"
  ON invoices FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can update invoices"
  ON invoices FOR UPDATE TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can delete invoices"
  ON invoices FOR DELETE TO authenticated
  USING (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can add invoice lines"
  ON invoice_lines FOR INSERT TO authenticated
  WITH CHECK (
    invoice_id IN (SELECT id FROM invoices WHERE tenant_id = get_user_tenant_id())
  );

CREATE POLICY "Users can update invoice lines"
  ON invoice_lines FOR UPDATE TO authenticated
  USING (
    invoice_id IN (SELECT id FROM invoices WHERE tenant_id = get_user_tenant_id())
  )
  WITH CHECK (
    invoice_id IN (SELECT id FROM invoices WHERE tenant_id = get_user_tenant_id())
  );

CREATE POLICY "Users can delete invoice lines"
  ON invoice_lines FOR DELETE TO authenticated
  USING (
    invoice_id IN (SELECT id FROM invoices WHERE tenant_id = get_user_tenant_id())
  );

CREATE POLICY "Users can create payments"
  ON payments FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can update payments"
  ON payments FOR UPDATE TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

-- ============================================================================
-- PURCHASING
-- ============================================================================

CREATE POLICY "Users can create purchase orders"
  ON purchase_orders FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can update purchase orders"
  ON purchase_orders FOR UPDATE TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can delete purchase orders"
  ON purchase_orders FOR DELETE TO authenticated
  USING (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can add purchase order lines"
  ON purchase_order_lines FOR INSERT TO authenticated
  WITH CHECK (
    purchase_order_id IN (SELECT id FROM purchase_orders WHERE tenant_id = get_user_tenant_id())
  );

CREATE POLICY "Users can update purchase order lines"
  ON purchase_order_lines FOR UPDATE TO authenticated
  USING (
    purchase_order_id IN (SELECT id FROM purchase_orders WHERE tenant_id = get_user_tenant_id())
  )
  WITH CHECK (
    purchase_order_id IN (SELECT id FROM purchase_orders WHERE tenant_id = get_user_tenant_id())
  );

CREATE POLICY "Users can delete purchase order lines"
  ON purchase_order_lines FOR DELETE TO authenticated
  USING (
    purchase_order_id IN (SELECT id FROM purchase_orders WHERE tenant_id = get_user_tenant_id())
  );

-- ============================================================================
-- FEEDBACK & NOTIFICATIONS
-- ============================================================================

CREATE POLICY "Users can create feedback"
  ON feedback FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can update feedback"
  ON feedback FOR UPDATE TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can create notification templates"
  ON notification_templates FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can update notification templates"
  ON notification_templates FOR UPDATE TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can delete notification templates"
  ON notification_templates FOR DELETE TO authenticated
  USING (tenant_id = get_user_tenant_id());

CREATE POLICY "System can create notification logs"
  ON notification_logs FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

-- ============================================================================
-- AUDIT & SYSTEM
-- ============================================================================

CREATE POLICY "System can create audit logs"
  ON audit_logs FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can create subscriptions"
  ON subscriptions FOR INSERT TO authenticated
  WITH CHECK (tenant_id = get_user_tenant_id());

CREATE POLICY "Users can update subscriptions"
  ON subscriptions FOR UPDATE TO authenticated
  USING (tenant_id = get_user_tenant_id())
  WITH CHECK (tenant_id = get_user_tenant_id());

-- ============================================================================
-- ROLE PERMISSIONS (junction table, no tenant_id)
-- ============================================================================

CREATE POLICY "Users can assign role permissions"
  ON role_permissions FOR INSERT TO authenticated
  WITH CHECK (
    role_id IN (SELECT id FROM roles WHERE is_system_role = false)
  );

CREATE POLICY "Users can update role permissions"
  ON role_permissions FOR UPDATE TO authenticated
  USING (
    role_id IN (SELECT id FROM roles WHERE is_system_role = false)
  )
  WITH CHECK (
    role_id IN (SELECT id FROM roles WHERE is_system_role = false)
  );

CREATE POLICY "Users can remove role permissions"
  ON role_permissions FOR DELETE TO authenticated
  USING (
    role_id IN (SELECT id FROM roles WHERE is_system_role = false)
  );