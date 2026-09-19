CREATE TABLE feedback_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    appointment_id UUID NOT NULL UNIQUE, -- one link per appointment
    token TEXT UNIQUE NOT NULL,

    expires_at TIMESTAMPTZ,
    used BOOLEAN DEFAULT false,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- --RLS POLICY 
-- CREATE POLICY "Allow insert on staff_invites"
-- ON feedback_links
-- FOR INSERT
-- TO authenticated
-- WITH CHECK (true); 

-- CREATE POLICY "allow all select"
-- ON feedback_links
-- FOR SELECT
-- USING (true);

-- CREATE POLICY "allow all update"
-- ON feedback_links
-- FOR UPDATE
-- USING (true)
-- WITH CHECK (true);


-- Enable RLS
ALTER TABLE feedback_links ENABLE ROW LEVEL SECURITY;

-- Only backend (service_role) can insert
CREATE POLICY "service insert feedback_links"
ON feedback_links
FOR INSERT
TO service_role
WITH CHECK (true);

-- Only backend can read
CREATE POLICY "service select feedback_links"
ON feedback_links
FOR SELECT
TO service_role
USING (true);

-- Only backend can update (mark used etc.)
CREATE POLICY "service update feedback_links"
ON feedback_links
FOR UPDATE
TO service_role
USING (true)
WITH CHECK (true);


CREATE UNIQUE INDEX unique_active_token
ON feedback_links (token)
WHERE used = false;

ALTER TABLE feedback_links
ADD CONSTRAINT unique_appointment UNIQUE (appointment_id);


--RPC TO GENERATE LINK TOKEN

CREATE OR REPLACE FUNCTION create_or_update_feedback_link(p_appointment_id uuid)
RETURNS TABLE (token text) AS $$
DECLARE
  v_token text;
  v_attempts int := 0;
BEGIN
  -- ensure appointment belongs to current tenant
  IF NOT EXISTS (
    SELECT 1
    FROM appointments a
    WHERE a.id = p_appointment_id
      AND a.tenant_id = current_tenant_id()
  ) THEN
    RAISE EXCEPTION 'Not allowed';
  END IF;

  LOOP
    v_attempts := v_attempts + 1;

    -- generate 10-char token
    v_token := upper(
      substr(
        replace(encode(gen_random_bytes(8), 'base64'), '/', ''),
        1,
        10
      )
    );

    BEGIN
      INSERT INTO feedback_links (appointment_id, token, expires_at)
      VALUES (p_appointment_id, v_token, now() + interval '7 days')
      ON CONFLICT (appointment_id)
      DO UPDATE SET
        token = EXCLUDED.token,
        expires_at = EXCLUDED.expires_at,
        used = false
      RETURNING feedback_links.token INTO v_token;

      EXIT;

    EXCEPTION
      WHEN unique_violation THEN
        -- token already exists with used = false → retry
        IF v_attempts > 5 THEN
          RAISE EXCEPTION 'Could not generate unique token';
        END IF;
    END;
  END LOOP;

  RETURN QUERY SELECT v_token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


ALTER TABLE feedback DROP CONSTRAINT IF EXISTS feedback_staff_id_fkey;

alter table feedback add column tags jsonb default '[]'::jsonb;
