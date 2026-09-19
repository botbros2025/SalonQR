-- =========================================
-- IN-APP NOTIFICATIONS TABLE
-- =========================================

CREATE TABLE public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  tenant_id uuid NOT NULL
    REFERENCES public.tenants(id)
    ON DELETE CASCADE,

  branch_id uuid
    REFERENCES public.branches(id)
    ON DELETE CASCADE,

  user_id uuid
    REFERENCES public.users(id)
    ON DELETE CASCADE,

  staff_id uuid
    REFERENCES public.staff(id)
    ON DELETE CASCADE,

  template_id uuid
    REFERENCES public.notification_templates(id)
    ON DELETE SET NULL,

  type text NOT NULL,

  title text NOT NULL,

  body text NOT NULL,

  reference_id uuid,

  reference_type text,

  metadata jsonb DEFAULT '{}'::jsonb,

  is_read boolean NOT NULL DEFAULT false,

  read_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT notifications_recipient_check
  CHECK (
    user_id IS NOT NULL
    OR staff_id IS NOT NULL
  )
);

-- =========================================
-- INDEXES
-- =========================================

CREATE INDEX idx_notifications_tenant
ON public.notifications(tenant_id);


CREATE INDEX idx_notifications_branch
ON public.notifications(branch_id);

CREATE INDEX idx_notifications_user
ON public.notifications(user_id);

CREATE INDEX idx_notifications_staff
ON public.notifications(staff_id);

CREATE INDEX idx_notifications_unread
ON public.notifications(is_read);

CREATE INDEX idx_notifications_created_at
ON public.notifications(created_at DESC);

CREATE INDEX idx_notifications_reference
ON public.notifications(reference_type, reference_id);

-- =========================================
-- ENABLE RLS
-- =========================================

ALTER TABLE public.notifications
ENABLE ROW LEVEL SECURITY;

-- =========================================
-- SELECT POLICY
-- Users/staff can only view own notifications
-- =========================================

CREATE POLICY "Users can view own notifications"
ON public.notifications
FOR SELECT
USING (
  tenant_id = current_tenant_id()
  AND (
    user_id = auth.uid()

    OR

    staff_id IN (
      SELECT s.id
      FROM public.staff s
      WHERE s.user_id = auth.uid()
    )
  )
);

-- =========================================
-- UPDATE POLICY
-- Users/staff can mark own notifications read
-- =========================================

CREATE POLICY "Users can update own notifications"
ON public.notifications
FOR UPDATE
USING (
  tenant_id = current_tenant_id()
  AND (
    user_id = auth.uid()

    OR

    staff_id IN (
      SELECT s.id
      FROM public.staff s
      WHERE s.user_id = auth.uid()
    )
  )
)
WITH CHECK (
  tenant_id = current_tenant_id()
);

-- =========================================
-- INSERT POLICY
-- Usually inserted by backend/service role
-- =========================================

CREATE POLICY "System can insert notifications"
ON public.notifications
FOR INSERT
WITH CHECK (
  tenant_id = current_tenant_id()
);

-- =========================================
-- DELETE POLICY
-- Prevent client-side deletes
-- =========================================

CREATE POLICY "No deletes allowed on notifications"
ON public.notifications
FOR DELETE
USING (false);


CREATE TYPE notification_type AS ENUM (
  'appointment_created',
  'appointment_rescheduled',
  'appointment_cancelled',
  'appointment_completed',
  'appointment_paid'
);

