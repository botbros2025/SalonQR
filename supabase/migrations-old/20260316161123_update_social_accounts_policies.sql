DROP POLICY IF EXISTS "Tenant can delete own social accounts"
ON social_accounts;

DROP POLICY IF EXISTS "Tenant can update own social accounts"
ON social_accounts;

-- UPDATE
CREATE POLICY "Tenant can update own social accounts"
ON social_accounts
FOR UPDATE
USING (tenant_id = current_tenant_id());

-- DELETE
CREATE POLICY "Tenant can delete own social accounts"
ON social_accounts
FOR DELETE
USING (tenant_id = current_tenant_id());