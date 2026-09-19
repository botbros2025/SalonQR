-- =========================================
-- 1. UPDATE feedback TABLE
-- =========================================

ALTER TABLE feedback
ADD COLUMN status TEXT DEFAULT 'active',
ADD COLUMN updated_at TIMESTAMPTZ;

-- Optional: enforce allowed values
ALTER TABLE feedback
ADD CONSTRAINT feedback_status_check
CHECK (status IN ('active', 'hidden', 'flagged'));

-- =========================================
-- 2. CREATE review_services TABLE
-- =========================================

CREATE TABLE review_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    review_id UUID NOT NULL REFERENCES feedback(id) ON DELETE CASCADE,
    service_id UUID NOT NULL,

    rating INT4 NOT NULL CHECK (rating BETWEEN 1 AND 5),

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (review_id, service_id)
);

-- Index for performance
CREATE INDEX idx_review_services_review_id ON review_services(review_id);
CREATE INDEX idx_review_services_service_id ON review_services(service_id);

-- =========================================
-- 3. CREATE feedback_tags TABLE
-- =========================================

-- CREATE TABLE feedback_tags (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

--     review_id UUID NOT NULL REFERENCES feedback(id) ON DELETE CASCADE,

--     tag TEXT NOT NULL,

--     created_at TIMESTAMPTZ DEFAULT NOW()
-- );

-- Indexing
-- CREATE INDEX idx_feedback_tags_review_id ON feedback_tags(review_id);
-- CREATE INDEX idx_feedback_tags_tag ON feedback_tags(tag);

-- =========================================
-- 4. OPTIONAL: AUTO update updated_at
-- =========================================

CREATE OR REPLACE FUNCTION update_feedback_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_feedback_updated_at
BEFORE UPDATE ON feedback
FOR EACH ROW
EXECUTE FUNCTION update_feedback_updated_at();



-- =========================================
-- 5. CREATE review_media TABLE
-- =========================================

CREATE TABLE review_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    review_id UUID NOT NULL REFERENCES feedback(id) ON DELETE CASCADE,

    url TEXT NOT NULL,

    media_type TEXT DEFAULT 'image', -- image / video / other

    uploaded_by UUID, -- optional: who uploaded (client/staff)

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_review_media_review_id ON review_media(review_id);
CREATE INDEX idx_review_media_type ON review_media(media_type);

-- Optional constraint (keep clean values)
ALTER TABLE review_media
ADD CONSTRAINT review_media_type_check
CHECK (media_type IN ('image', 'video', 'other'));


--RLS

ALTER TABLE review_services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant can access review_services"
ON review_services
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM feedback
    WHERE feedback.id = review_services.review_id
    AND feedback.tenant_id = current_tenant_id()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM feedback
    WHERE feedback.id = review_services.review_id
    AND feedback.tenant_id = current_tenant_id()
  )
);

ALTER TABLE feedback_tags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant can access feedback_tags"
ON feedback_tags
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM feedback
    WHERE feedback.id = feedback_tags.review_id
    AND feedback.tenant_id = current_tenant_id()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM feedback
    WHERE feedback.id = feedback_tags.review_id
    AND feedback.tenant_id = current_tenant_id()
  )
);

ALTER TABLE review_media ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant can access review_media"
ON review_media
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM feedback
    WHERE feedback.id = review_media.review_id
    AND feedback.tenant_id = current_tenant_id()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM feedback
    WHERE feedback.id = review_media.review_id
    AND feedback.tenant_id = current_tenant_id()
  )
);


ALTER TABLE feedback
ADD CONSTRAINT feedback_staff_id_fkey
FOREIGN KEY (staff_id)
REFERENCES staff(id)
ON DELETE SET NULL;