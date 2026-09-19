
-- ADD COLUMN IN SERVICES 
ALTER TABLE services
ADD COLUMN color_theme text;


-- CREATE TABLE SERVICE_VARIANTS
CREATE TABLE service_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  service_id uuid NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  tenant_id uuid NOT NULL,
  branch_id uuid NOT NULL,

  name text NOT NULL, -- e.g. "Basic", "Advanced"
  price numeric NOT NULL,
  duration_minutes integer NOT NULL,

  is_default boolean DEFAULT false,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);


-- INDEXING
CREATE INDEX idx_service_variants_service_id ON service_variants(service_id);
CREATE INDEX idx_service_variants_tenant_branch 
ON service_variants(tenant_id, branch_id);



-- RLS ENCRYPTION
ALTER TABLE service_variants ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Users can view their service variants"
ON service_variants
FOR SELECT
USING (
  tenant_id = current_tenant_id()
);

CREATE POLICY "Users can insert service variants"
ON service_variants
FOR INSERT
WITH CHECK (
   tenant_id = current_tenant_id()
);

CREATE POLICY "Users can update service variants"
ON service_variants
FOR UPDATE
USING (
  tenant_id = current_tenant_id() 
);

-- CREATE POLICY "Users can delete service variants"
-- ON service_variants
-- FOR DELETE
-- USING (
--   tenant_id = current_tenant_id();
-- );

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_service_variants_updated_at
BEFORE UPDATE ON service_variants
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();