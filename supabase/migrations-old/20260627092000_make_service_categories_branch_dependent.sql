ALTER TABLE "public"."service_categories" DROP CONSTRAINT IF EXISTS "service_categories_tenant_id_name_key";

ALTER TABLE "public"."service_categories" ADD CONSTRAINT "service_categories_tenant_branch_name_key" UNIQUE ("tenant_id", "branch_id", "name");
