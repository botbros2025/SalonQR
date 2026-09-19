-- =========================
-- ENUM TYPES
-- =========================

CREATE TYPE staff_auth_state AS ENUM (
  'uninvited',
  'invited',
  'authenticated'
);

CREATE TYPE staff_employment_state AS ENUM (
  'active',
  'disabled'
);

-- =========================
-- STAFF TABLE
-- =========================

CREATE TABLE public.staff (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  tenant_id uuid NOT NULL,
  user_id uuid NULL,

  name text NOT NULL,
  phone text NOT NULL,

  auth_state staff_auth_state NOT NULL DEFAULT 'uninvited',
  is_active staff_employment_state NOT NULL DEFAULT 'active',

  invite_token text NULL,
  invite_expiry timestamptz NULL,

  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz NULL,

  email text NULL,

  -- Foreign keys
  CONSTRAINT staff_tenant_id_fkey
    FOREIGN KEY (tenant_id)
    REFERENCES public.tenants(id)
    ON DELETE CASCADE,

  CONSTRAINT staff_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES auth.users(id)
    ON DELETE SET NULL
);

-- =========================
-- INDEXES
-- =========================

CREATE INDEX idx_staff_tenant_id
  ON public.staff(tenant_id);

CREATE INDEX idx_staff_user_id
  ON public.staff(user_id);

CREATE INDEX idx_staff_invite_token
  ON public.staff(invite_token);

CREATE INDEX idx_staff_auth_state
  ON public.staff(auth_state);

CREATE INDEX idx_staff_employment_state
  ON public.staff(employment_state);
