CREATE TABLE staff_compensation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL REFERENCES tenants(id),
    branch_id UUID NOT NULL REFERENCES branches(id),

    staff_id UUID NOT NULL REFERENCES staff(id),
    user_id UUID,

    earning_type TEXT NOT NULL CHECK (
        earning_type IN (
            'salary',
            'revenue_share',
            'salary_plus_target'
        )
    ),

    salary_amount NUMERIC(12,2),

    revenue_share_percent NUMERIC(5,2),

    target_amount NUMERIC(12,2),

    target_commission_percent NUMERIC(5,2),

    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to DATE,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Only one active compensation record per staff
CREATE UNIQUE INDEX idx_staff_compensation_one_active
ON staff_compensation (staff_id)
WHERE is_active = TRUE
  AND deleted_at IS NULL;

-- Common lookup indexes
CREATE INDEX idx_staff_compensation_staff_id
ON staff_compensation (staff_id);

CREATE INDEX idx_staff_compensation_tenant_branch
ON staff_compensation (tenant_id, branch_id);

CREATE INDEX idx_staff_compensation_tenant
ON staff_compensation(tenant_id);

CREATE INDEX idx_staff_compensation_branch
ON staff_compensation(branch_id);


CREATE POLICY "staff_compensation_select"
ON staff_compensation
FOR SELECT
TO authenticated
USING (
    tenant_id = current_tenant_id()
);

CREATE POLICY "staff_compensation_insert"
ON staff_compensation
FOR INSERT
TO authenticated
WITH CHECK (
    tenant_id = current_tenant_id()
);

CREATE POLICY "staff_compensation_update"
ON staff_compensation
FOR UPDATE
TO authenticated
USING (
    tenant_id = current_tenant_id()
)
WITH CHECK (
    tenant_id = current_tenant_id()
);

CREATE POLICY "staff_compensation_delete"
ON staff_compensation
FOR DELETE
TO authenticated
USING (
    tenant_id = current_tenant_id()
);


-------------------------------------------------------------------------
-------------------------------------------------------------------------

CREATE TABLE staff_salary_slips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL REFERENCES tenants(id),
    branch_id UUID NOT NULL REFERENCES branches(id),

    staff_id UUID NOT NULL REFERENCES staff(id),
    compensation_id UUID REFERENCES staff_compensation(id),

    salary_month SMALLINT NOT NULL CHECK (salary_month BETWEEN 1 AND 12),
    salary_year INTEGER NOT NULL,

    base_salary NUMERIC(12,2) NOT NULL DEFAULT 0,
    generated_revenue NUMERIC(12,2) NOT NULL DEFAULT 0,

    commission_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    tip_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    bonus_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    deduction_amount NUMERIC(12,2) NOT NULL DEFAULT 0,

    net_salary NUMERIC(12,2) NOT NULL,

    payment_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (
        payment_status IN (
            'pending',
            'paid',
            'cancelled'
        )
    ),

    paid_at TIMESTAMPTZ,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    UNIQUE (staff_id, salary_month, salary_year)
);

-- Indexes
CREATE INDEX idx_staff_salary_slips_tenant
ON staff_salary_slips (tenant_id);

CREATE INDEX idx_staff_salary_slips_branch
ON staff_salary_slips (branch_id);

CREATE INDEX idx_staff_salary_slips_staff
ON staff_salary_slips (staff_id);

CREATE INDEX idx_staff_salary_slips_period
ON staff_salary_slips (salary_year, salary_month);

CREATE INDEX idx_staff_salary_slips_payment_status
ON staff_salary_slips (payment_status);


-- SELECT
CREATE POLICY "staff_salary_slips_select"
ON staff_salary_slips
FOR SELECT
TO authenticated
USING (
    tenant_id = current_tenant_id()
    AND deleted_at IS NULL
);

-- INSERT
CREATE POLICY "staff_salary_slips_insert"
ON staff_salary_slips
FOR INSERT
TO authenticated
WITH CHECK (
    tenant_id = current_tenant_id()
);

-- UPDATE
CREATE POLICY "staff_salary_slips_update"
ON staff_salary_slips
FOR UPDATE
TO authenticated
USING (
    tenant_id = current_tenant_id()
    AND deleted_at IS NULL
)
WITH CHECK (
    tenant_id = current_tenant_id()
);

-- DELETE
CREATE POLICY "staff_salary_slips_delete"
ON staff_salary_slips
FOR DELETE
TO authenticated
USING (
    tenant_id = current_tenant_id()
);


---------------------------------------------------------------------------------------

DROP TABLE IF EXISTS staff_metrics CASCADE;

CREATE TABLE staff_metrics (
    staff_id UUID NOT NULL REFERENCES staff(id),

    tenant_id UUID NOT NULL REFERENCES tenants(id),
    branch_id UUID NOT NULL REFERENCES branches(id),

    metric_month SMALLINT NOT NULL
    CHECK (metric_month BETWEEN 1 AND 12),

    metric_year INTEGER NOT NULL,

    total_appointments INT NOT NULL DEFAULT 0,
    completed_appointments INT NOT NULL DEFAULT 0,
    cancelled_appointments INT NOT NULL DEFAULT 0,

    total_revenue_generated NUMERIC(12,2) NOT NULL DEFAULT 0,

    tips_received NUMERIC(12,2) NOT NULL DEFAULT 0,

    average_rating NUMERIC(3,2),
    total_ratings INT NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now();

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (
        staff_id,
        metric_month,
        metric_year
    )
);

CREATE INDEX idx_staff_metrics_tenant
ON staff_metrics(tenant_id);

CREATE INDEX idx_staff_metrics_branch
ON staff_metrics(branch_id);

CREATE INDEX idx_staff_metrics_period
ON staff_metrics(metric_year, metric_month);

CREATE INDEX idx_staff_metrics_tenant_branch
ON staff_metrics(tenant_id, branch_id);


CREATE POLICY "staff_metrics_select"
ON staff_metrics
FOR SELECT
TO authenticated
USING (
    tenant_id = current_tenant_id()
);

CREATE POLICY "staff_metrics_insert"
ON staff_metrics
FOR INSERT
TO authenticated
WITH CHECK (
    tenant_id = current_tenant_id()
);

CREATE POLICY "staff_metrics_update"
ON staff_metrics
FOR UPDATE
TO authenticated
USING (
    tenant_id = current_tenant_id()
)
WITH CHECK (
    tenant_id = current_tenant_id()
);

CREATE POLICY "staff_metrics_delete"
ON staff_metrics
FOR DELETE
TO authenticated
USING (
    tenant_id = current_tenant_id()
);



CREATE TABLE staff_salary_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL REFERENCES tenants(id),
    branch_id UUID NOT NULL REFERENCES branches(id),

    staff_id UUID NOT NULL REFERENCES staff(id),

    adjustment_type TEXT NOT NULL
    CHECK (
        adjustment_type IN (
            'bonus',
            'deduction'
        )
    ),

    amount NUMERIC(12,2) NOT NULL
    CHECK (amount > 0),

    adjustment_month SMALLINT NOT NULL
    CHECK (adjustment_month BETWEEN 1 AND 12),

    adjustment_year INTEGER NOT NULL,

    reason TEXT,

    created_by UUID,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);


CREATE INDEX idx_staff_salary_adjustments_staff
ON staff_salary_adjustments(staff_id);

CREATE INDEX idx_staff_salary_adjustments_period
ON staff_salary_adjustments(
    adjustment_year,
    adjustment_month
);

CREATE INDEX idx_staff_salary_adjustments_tenant
ON staff_salary_adjustments(tenant_id);

CREATE INDEX idx_staff_salary_adjustments_branch
ON staff_salary_adjustments(branch_id);


CREATE POLICY "staff_salary_adjustments_select"
ON staff_salary_adjustments
FOR SELECT
TO authenticated
USING (
    tenant_id = current_tenant_id()
    AND deleted_at IS NULL
);

CREATE POLICY "staff_salary_adjustments_insert"
ON staff_salary_adjustments
FOR INSERT
TO authenticated
WITH CHECK (
    tenant_id = current_tenant_id()
);

CREATE POLICY "staff_salary_adjustments_update"
ON staff_salary_adjustments
FOR UPDATE
TO authenticated
USING (
    tenant_id = current_tenant_id()
    AND deleted_at IS NULL
)
WITH CHECK (
    tenant_id = current_tenant_id()
);

CREATE POLICY "staff_salary_adjustments_delete"
ON staff_salary_adjustments
FOR DELETE
TO authenticated
USING (
    tenant_id = current_tenant_id()
);




------------------------------------------------------------------------------------------------------

ALTER TABLE staff_metrics
ADD COLUMN verified_revenue NUMERIC NOT NULL DEFAULT 0,
ADD COLUMN unverified_revenue NUMERIC NOT NULL DEFAULT 0;


CREATE OR REPLACE FUNCTION recalculate_staff_revenue(
    p_staff_id UUID,
    p_month INT,
    p_year INT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_verified NUMERIC := 0;
    v_unverified NUMERIC := 0;
BEGIN

    -- Verified Revenue
    SELECT COALESCE(SUM(i.total_amount),0)
    INTO v_verified
    FROM appointments a
    JOIN invoices i
      ON i.appointment_id = a.id
    WHERE a.primary_staff_id = p_staff_id
      AND a.status = 'COMPLETED'
      AND i.status = 'PAID'
      AND EXTRACT(MONTH FROM a.appointment_date) = p_month
      AND EXTRACT(YEAR FROM a.appointment_date) = p_year;

    -- Unverified Revenue
    SELECT COALESCE(SUM(i.total_amount),0)
    INTO v_unverified
    FROM appointments a
    JOIN invoices i
      ON i.appointment_id = a.id
    WHERE a.primary_staff_id = p_staff_id
      AND a.status = 'COMPLETED'
      AND i.status <> 'PAID'
      AND EXTRACT(MONTH FROM a.appointment_date) = p_month
      AND EXTRACT(YEAR FROM a.appointment_date) = p_year;

    UPDATE staff_metrics
    SET
        verified_revenue = v_verified,
        unverified_revenue = v_unverified,
        total_revenue_generated = v_verified + v_unverified,
        updated_at = now()
    WHERE staff_id = p_staff_id
      AND metric_month = p_month
      AND metric_year = p_year;

END;
$$;


CREATE OR REPLACE FUNCTION trg_appointment_completed_metrics()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_month INT;
    v_year INT;
BEGIN

    v_month := EXTRACT(MONTH FROM NEW.appointment_date);
    v_year  := EXTRACT(YEAR FROM NEW.appointment_date);

    PERFORM recalculate_staff_revenue(
        NEW.primary_staff_id,
        v_month,
        v_year
    );

    RETURN NEW;
END;
$$;


CREATE TRIGGER appointment_completed_metrics
AFTER INSERT OR UPDATE OF status
ON appointments
FOR EACH ROW
WHEN (NEW.status = 'COMPLETED')
EXECUTE FUNCTION trg_appointment_completed_metrics();




CREATE OR REPLACE FUNCTION trg_invoice_metrics()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_staff_id UUID;
    v_month INT;
    v_year INT;
BEGIN

    SELECT
        a.primary_staff_id,
        EXTRACT(MONTH FROM a.appointment_date),
        EXTRACT(YEAR FROM a.appointment_date)
    INTO
        v_staff_id,
        v_month,
        v_year
    FROM appointments a
    WHERE a.id = NEW.appointment_id;

    PERFORM recalculate_staff_revenue(
        v_staff_id,
        v_month,
        v_year
    );

    RETURN NEW;
END;
$$;


CREATE TRIGGER invoice_metrics
AFTER INSERT OR UPDATE OF status,total_amount
ON invoices
FOR EACH ROW
EXECUTE FUNCTION trg_invoice_metrics();


CREATE OR REPLACE FUNCTION public.update_staff_metrics_simple()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_month INT;
    v_year  INT;
BEGIN
    IF NEW.primary_staff_id IS NULL THEN
        RETURN NEW;
    END IF;

    v_month := EXTRACT(MONTH FROM NEW.appointment_date);
    v_year  := EXTRACT(YEAR FROM NEW.appointment_date);

    -- Ensure monthly metric row exists
    INSERT INTO staff_metrics (
        staff_id,
        tenant_id,
        branch_id,
        metric_month,
        metric_year,
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
        v_month,
        v_year,
        0,
        0,
        0,
        0,
        0,
        NOW()
    )
    ON CONFLICT (
        staff_id,
        metric_month,
        metric_year
    )
    DO NOTHING;

    -- INSERT
    IF TG_OP = 'INSERT' THEN

        UPDATE staff_metrics
        SET
            total_appointments = total_appointments + 1,

            completed_appointments =
                completed_appointments +
                CASE
                    WHEN NEW.status IN ('COMPLETED', 'BILLED')
                    THEN 1
                    ELSE 0
                END,

            cancelled_appointments =
                cancelled_appointments +
                CASE
                    WHEN NEW.status = 'CANCELLED'
                    THEN 1
                    ELSE 0
                END,

            updated_at = NOW()
        WHERE staff_id = NEW.primary_staff_id
          AND metric_month = v_month
          AND metric_year = v_year;

        RETURN NEW;
    END IF;

    -- UPDATE STATUS CHANGE
    IF TG_OP = 'UPDATE'
       AND OLD.status IS DISTINCT FROM NEW.status THEN

        UPDATE staff_metrics
        SET
            completed_appointments =
                completed_appointments
                - CASE
                    WHEN OLD.status IN ('COMPLETED', 'BILLED')
                    THEN 1
                    ELSE 0
                  END
                + CASE
                    WHEN NEW.status IN ('COMPLETED', 'BILLED')
                    THEN 1
                    ELSE 0
                  END,

            cancelled_appointments =
                cancelled_appointments
                - CASE
                    WHEN OLD.status = 'CANCELLED'
                    THEN 1
                    ELSE 0
                  END
                + CASE
                    WHEN NEW.status = 'CANCELLED'
                    THEN 1
                    ELSE 0
                  END,

            updated_at = NOW()
        WHERE staff_id = NEW.primary_staff_id
          AND metric_month = v_month
          AND metric_year = v_year;
    END IF;

    RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_staff_metrics_simple ON appointments;

CREATE TRIGGER trg_staff_metrics_simple
AFTER INSERT OR UPDATE OF status
ON appointments
FOR EACH ROW
EXECUTE FUNCTION update_staff_metrics_simple();


DROP TRIGGER IF EXISTS trg_invoice_revenue
ON invoices;

DROP FUNCTION IF EXISTS update_revenue_on_invoice_change();