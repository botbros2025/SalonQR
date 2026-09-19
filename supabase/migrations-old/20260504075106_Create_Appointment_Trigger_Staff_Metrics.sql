CREATE OR REPLACE FUNCTION update_staff_metrics_simple()
RETURNS TRIGGER AS $$
BEGIN
  -- ignore if no staff
  IF NEW.primary_staff_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- ensure row exists
  INSERT INTO staff_metrics (
    staff_id,
    tenant_id,
    branch_id,
    total_appointments,
    completed_appointments,
    cancelled_appointments,
    total_revenue_generated,
    total_ratings,
    updated_at
  )
  VALUES (
    NEW.primary_staff_id,
    NEW.tenant_id,
    NEW.branch_id,
    0, 0, 0, 0, 0,
    NOW()
  )
  ON CONFLICT (staff_id) DO NOTHING;

  -- 🟢 INSERT → count everything once
  IF TG_OP = 'INSERT' THEN
    UPDATE staff_metrics
    SET
      total_appointments = total_appointments + 1,

      completed_appointments =
        completed_appointments +
        CASE WHEN NEW.status IN ('COMPLETED', 'BILLED') THEN 1 ELSE 0 END,

      cancelled_appointments =
        cancelled_appointments +
        CASE WHEN NEW.status = 'CANCELLED' THEN 1 ELSE 0 END,

      updated_at = NOW()
    WHERE staff_id = NEW.primary_staff_id;

    RETURN NEW;
  END IF;

  -- 🟡 UPDATE → only adjust if status changed
  IF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
    UPDATE staff_metrics
    SET
      completed_appointments =
        completed_appointments
        - CASE WHEN OLD.status IN ('COMPLETED', 'BILLED') THEN 1 ELSE 0 END
        + CASE WHEN NEW.status IN ('COMPLETED', 'BILLED') THEN 1 ELSE 0 END,

      cancelled_appointments =
        cancelled_appointments
        - CASE WHEN OLD.status = 'CANCELLED' THEN 1 ELSE 0 END
        + CASE WHEN NEW.status = 'CANCELLED' THEN 1 ELSE 0 END,

      updated_at = NOW()
    WHERE staff_id = NEW.primary_staff_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_staff_metrics_simple
AFTER INSERT OR UPDATE OF status ON appointments
FOR EACH ROW
EXECUTE FUNCTION update_staff_metrics_simple();


--TOTAL REVENUE UPDATE 
CREATE OR REPLACE FUNCTION update_revenue_on_invoice_change()
RETURNS TRIGGER AS $$
DECLARE
  v_staff_id uuid;
BEGIN
  -- get staff from appointment
  SELECT primary_staff_id INTO v_staff_id
  FROM appointments
  WHERE id = NEW.appointment_id;

  IF v_staff_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- ensure metrics row exists
  INSERT INTO staff_metrics (
    staff_id,
    tenant_id,
    branch_id,
    total_appointments,
    completed_appointments,
    cancelled_appointments,
    total_revenue_generated,
    total_ratings,
    updated_at
  )
  VALUES (
    v_staff_id,
    NEW.tenant_id,
    NEW.branch_id,
    0,0,0,0,0,
    NOW()
  )
  ON CONFLICT (staff_id) DO NOTHING;

  -- 🔥 CORE LOGIC: adjust based on paid_amount difference
  UPDATE staff_metrics
  SET
    total_revenue_generated =
      total_revenue_generated
      - COALESCE(OLD.paid_amount, 0)
      + COALESCE(NEW.paid_amount, 0),

    updated_at = NOW()
  WHERE staff_id = v_staff_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_invoice_revenue ON invoices;

CREATE TRIGGER trg_invoice_revenue
AFTER UPDATE OF status ON invoices
FOR EACH ROW
EXECUTE FUNCTION update_revenue_on_invoice_change();