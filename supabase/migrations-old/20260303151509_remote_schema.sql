


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."appointment_source" AS ENUM (
    'MANUAL',
    'WHATSAPP',
    'ONLINE',
    'WALK_IN'
);


ALTER TYPE "public"."appointment_source" OWNER TO "postgres";


CREATE TYPE "public"."appointment_status" AS ENUM (
    'SCHEDULED',
    'CONFIRMED',
    'IN_PROGRESS',
    'COMPLETED',
    'BILLED',
    'CANCELLED',
    'NO_SHOW'
);


ALTER TYPE "public"."appointment_status" OWNER TO "postgres";


CREATE TYPE "public"."client_source" AS ENUM (
    'WALK_IN',
    'WHATSAPP',
    'REFERRAL',
    'ONLINE',
    'OTHER'
);


ALTER TYPE "public"."client_source" OWNER TO "postgres";


CREATE TYPE "public"."client_tier" AS ENUM (
    'REGULAR',
    'SILVER',
    'GOLD',
    'PLATINUM'
);


ALTER TYPE "public"."client_tier" OWNER TO "postgres";


CREATE TYPE "public"."inventory_unit" AS ENUM (
    'PIECE',
    'LITER',
    'KILOGRAM',
    'MILLILITER',
    'GRAM',
    'BOX',
    'BOTTLE'
);


ALTER TYPE "public"."inventory_unit" OWNER TO "postgres";


CREATE TYPE "public"."invoice_status" AS ENUM (
    'DRAFT',
    'PENDING',
    'PAID',
    'PARTIALLY_PAID',
    'CANCELLED'
);


ALTER TYPE "public"."invoice_status" OWNER TO "postgres";


CREATE TYPE "public"."line_item_type" AS ENUM (
    'SERVICE',
    'PRODUCT'
);


ALTER TYPE "public"."line_item_type" OWNER TO "postgres";


CREATE TYPE "public"."notification_channel" AS ENUM (
    'WHATSAPP',
    'EMAIL',
    'SMS',
    'PUSH'
);


ALTER TYPE "public"."notification_channel" OWNER TO "postgres";


CREATE TYPE "public"."notification_status" AS ENUM (
    'PENDING',
    'SENT',
    'DELIVERED',
    'READ',
    'FAILED'
);


ALTER TYPE "public"."notification_status" OWNER TO "postgres";


CREATE TYPE "public"."payment_method" AS ENUM (
    'CASH',
    'CARD',
    'UPI',
    'WALLET',
    'BANK_TRANSFER',
    'OTHER'
);


ALTER TYPE "public"."payment_method" OWNER TO "postgres";


CREATE TYPE "public"."po_status" AS ENUM (
    'DRAFT',
    'PENDING_APPROVAL',
    'APPROVED',
    'ORDERED',
    'RECEIVED',
    'CANCELLED'
);


ALTER TYPE "public"."po_status" OWNER TO "postgres";


CREATE TYPE "public"."proof_verification_status" AS ENUM (
    'PENDING',
    'VERIFIED',
    'REJECTED'
);


ALTER TYPE "public"."proof_verification_status" OWNER TO "postgres";


CREATE TYPE "public"."staff_auth_state" AS ENUM (
    'uninvited',
    'invited',
    'authenticated'
);


ALTER TYPE "public"."staff_auth_state" OWNER TO "postgres";


CREATE TYPE "public"."staff_employment_state" AS ENUM (
    'active',
    'disabled'
);


ALTER TYPE "public"."staff_employment_state" OWNER TO "postgres";


CREATE TYPE "public"."subscription_status" AS ENUM (
    'TRIAL',
    'ACTIVE',
    'PAST_DUE',
    'CANCELLED',
    'PAUSED'
);


ALTER TYPE "public"."subscription_status" OWNER TO "postgres";


CREATE TYPE "public"."template_type" AS ENUM (
    'APPOINTMENT_CONFIRMATION',
    'APPOINTMENT_REMINDER',
    'INVOICE',
    'FEEDBACK_REQUEST',
    'BIRTHDAY_GREETING',
    'LOW_STOCK_ALERT',
    'DAILY_REPORT',
    'WEEKLY_REPORT',
    'CUSTOM'
);


ALTER TYPE "public"."template_type" OWNER TO "postgres";


CREATE TYPE "public"."tenant_status" AS ENUM (
    'TRIAL',
    'ACTIVE',
    'SUSPENDED',
    'PAST_DUE',
    'CANCELLED'
);


ALTER TYPE "public"."tenant_status" OWNER TO "postgres";


CREATE TYPE "public"."transaction_type" AS ENUM (
    'PURCHASE',
    'ADJUSTMENT',
    'DEDUCTION',
    'RETURN',
    'TRANSFER'
);


ALTER TYPE "public"."transaction_type" OWNER TO "postgres";


CREATE TYPE "public"."whatsapp_provider" AS ENUM (
    'GUPSHUP',
    'TWILIO',
    'META'
);


ALTER TYPE "public"."whatsapp_provider" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_default_tenant_settings"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
INSERT INTO tenant_settings (tenant_id)
VALUES (NEW.id)
ON CONFLICT (tenant_id) DO NOTHING;

RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."create_default_tenant_settings"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_tenant_id"() RETURNS "uuid"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  SELECT tenant_id FROM users WHERE id = auth.uid();
$$;


ALTER FUNCTION "public"."current_tenant_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_user_role"() RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$
  SELECT auth.jwt() ->> 'role';
$$;


ALTER FUNCTION "public"."current_user_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."deduct_inventory_for_appointment"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
IF NEW.status = 'COMPLETED' AND OLD.status != 'COMPLETED' THEN

INSERT INTO inventory_transactions (
tenant_id,
inventory_item_id,
transaction_type,
quantity,
quantity_before,
quantity_after,
appointment_id,
created_by,
notes
)
SELECT 
NEW.tenant_id,
sii.inventory_item_id,
'DEDUCTION',
-sii.quantity_per_service,
ii.current_quantity,
ii.current_quantity - sii.quantity_per_service,
NEW.id,
NEW.primary_staff_id,
'Auto-deduction for appointment'
FROM appointment_services aps
JOIN service_inventory_items sii ON aps.service_id = sii.service_id
JOIN inventory_items ii ON sii.inventory_item_id = ii.id
WHERE aps.appointment_id = NEW.id
AND aps.removed_at IS NULL;

UPDATE inventory_items ii
SET current_quantity = current_quantity - sii.quantity_per_service
FROM appointment_services aps
JOIN service_inventory_items sii ON aps.service_id = sii.service_id
WHERE aps.appointment_id = NEW.id
AND aps.removed_at IS NULL
AND ii.id = sii.inventory_item_id;

END IF;

RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."deduct_inventory_for_appointment"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_invoice_number"("p_tenant_id" "uuid") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
v_count int;
v_number text;
BEGIN
SELECT COUNT(*) + 1 INTO v_count
FROM invoices
WHERE tenant_id = p_tenant_id
AND EXTRACT(YEAR FROM invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE);

v_number := 'INV-' || 
TO_CHAR(CURRENT_DATE, 'YYYY') || '-' || 
LPAD(v_count::text, 5, '0');

RETURN v_number;
END;
$$;


ALTER FUNCTION "public"."generate_invoice_number"("p_tenant_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_permissions"() RETURNS TABLE("resource" "text", "action" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
SELECT DISTINCT p.resource, p.action
FROM user_roles ur
JOIN role_permissions rp ON ur.role_id = rp.role_id
JOIN permissions p ON rp.permission_id = p.id
WHERE ur.user_id = auth.uid();
$$;


ALTER FUNCTION "public"."get_user_permissions"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_tenant_id"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
SELECT tenant_id FROM users WHERE id = auth.uid();
$$;


ALTER FUNCTION "public"."get_user_tenant_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."initialize_staff_metrics"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$BEGIN
  INSERT INTO staff_metrics (
      staff_id,
      tenant_id,
      branch_id,
      total_appointments,
      completed_appointments,
      cancelled_appointments,
      total_revenue_generated,
      average_rating,
      total_ratings
  )
  VALUES (
      NEW.id,
      NEW.tenant_id,
      NEW.branch_id,
      0, 0, 0, 0, 0, 0
  )
  ON CONFLICT (staff_id) DO NOTHING;

  RETURN NEW;
END;$$;


ALTER FUNCTION "public"."initialize_staff_metrics"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_owner_to_users"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin

  update users
  set 
    full_name = new.owner_name,
    phone = new.owner_phone,
    updated_at = now()
  where tenant_id = new.id
    and email = new.owner_email;

  return new;

end;
$$;


ALTER FUNCTION "public"."sync_owner_to_users"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_client_spend"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$BEGIN

IF NEW.status = 'PAID' AND OLD.status IS DISTINCT FROM 'PAID' THEN

  UPDATE clients
  SET 
    total_spend = (
      SELECT COALESCE(SUM(total_amount),0)
      FROM invoices
      WHERE client_id = NEW.client_id
      AND status = 'PAID'
    ),

    total_visits = (
      SELECT COUNT(*)
      FROM appointments
      WHERE client_id = NEW.client_id
      AND status IN ('COMPLETED','BILLED')
    ),

    last_visit_at = (
      SELECT MAX(appointment_date)
      FROM appointments
      WHERE client_id = NEW.client_id
      AND status IN ('COMPLETED','BILLED')
    )

  WHERE id = NEW.client_id;

END IF;

RETURN NEW;

END;$$;


ALTER FUNCTION "public"."update_client_spend"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_client_tier"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
IF NEW.total_spend >= 50000 THEN
NEW.tier = 'PLATINUM';
ELSIF NEW.total_spend >= 25000 THEN
NEW.tier = 'GOLD';
ELSIF NEW.total_spend >= 10000 THEN
NEW.tier = 'SILVER';
ELSE
NEW.tier = 'REGULAR';
END IF;

RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_client_tier"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_invoice_balance"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
UPDATE invoices
SET 
paid_amount = COALESCE((
SELECT SUM(amount) 
FROM payments 
WHERE invoice_id = NEW.invoice_id
), 0),
updated_at = now()
WHERE id = NEW.invoice_id;

UPDATE invoices
SET 
balance_amount = total_amount - paid_amount,
status = CASE
WHEN paid_amount >= total_amount THEN 'PAID'
WHEN paid_amount > 0 THEN 'PARTIALLY_PAID'
ELSE status
END
WHERE id = NEW.invoice_id;

RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_invoice_balance"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
NEW.updated_at = now();
RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."user_has_permission"("p_resource" "text", "p_action" "text") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
SELECT EXISTS (
SELECT 1
FROM user_roles ur
JOIN role_permissions rp ON ur.role_id = rp.role_id
JOIN permissions p ON rp.permission_id = p.id
WHERE ur.user_id = auth.uid()
AND p.resource = p_resource
AND p.action = p_action
);
$$;


ALTER FUNCTION "public"."user_has_permission"("p_resource" "text", "p_action" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."appointment_services" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "appointment_id" "uuid" NOT NULL,
    "service_id" "uuid" NOT NULL,
    "service_name" "text" NOT NULL,
    "duration_minutes" integer NOT NULL,
    "price" numeric(10,2) NOT NULL,
    "staff_id" "uuid",
    "added_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "added_by" "uuid" NOT NULL,
    "removed_at" timestamp with time zone,
    "removed_by" "uuid",
    "branch_id" "uuid" NOT NULL
);


ALTER TABLE "public"."appointment_services" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."appointments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "client_id" "uuid" NOT NULL,
    "appointment_date" "date" NOT NULL,
    "start_time" time without time zone NOT NULL,
    "end_time" time without time zone NOT NULL,
    "status" "public"."appointment_status" DEFAULT 'SCHEDULED'::"public"."appointment_status" NOT NULL,
    "source" "public"."appointment_source" DEFAULT 'MANUAL'::"public"."appointment_source" NOT NULL,
    "primary_staff_id" "uuid",
    "notes" "text",
    "internal_notes" "text",
    "cancelled_at" timestamp with time zone,
    "cancelled_by" "uuid",
    "cancellation_reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "confirmed_at" timestamp with time zone,
    "started_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "billed_at" timestamp with time zone
);


ALTER TABLE "public"."appointments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "action" "text" NOT NULL,
    "resource_type" "text" NOT NULL,
    "resource_id" "uuid",
    "old_values" "jsonb",
    "new_values" "jsonb",
    "ip_address" "inet",
    "user_agent" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."audit_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."branches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "address" "text" NOT NULL,
    "city" "text" NOT NULL,
    "state" "text" NOT NULL,
    "pincode" "text" NOT NULL,
    "phone" "text",
    "email" "text",
    "business_hours" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."branches" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."client_notes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "client_id" "uuid" NOT NULL,
    "note" "text" NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "branch_id" "uuid" NOT NULL
);


ALTER TABLE "public"."client_notes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."clients" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "phone" "text" NOT NULL,
    "email" "text",
    "date_of_birth" "date",
    "gender" "text",
    "address" "text",
    "city" "text",
    "pincode" "text",
    "total_visits" integer DEFAULT 0 NOT NULL,
    "total_spend" numeric(10,2) DEFAULT 0 NOT NULL,
    "tier" "public"."client_tier" DEFAULT 'REGULAR'::"public"."client_tier" NOT NULL,
    "preferred_staff_id" "uuid",
    "source" "public"."client_source" DEFAULT 'WALK_IN'::"public"."client_source" NOT NULL,
    "referral_code" "text",
    "consent_given" boolean DEFAULT false NOT NULL,
    "consent_given_at" timestamp with time zone,
    "consent_for_marketing" boolean DEFAULT false NOT NULL,
    "data_retention_expires_at" timestamp with time zone,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_visit_at" timestamp with time zone,
    "branch_id" "uuid" NOT NULL
);


ALTER TABLE "public"."clients" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."feedback" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "appointment_id" "uuid" NOT NULL,
    "client_id" "uuid" NOT NULL,
    "overall_rating" integer NOT NULL,
    "service_rating" integer,
    "staff_rating" integer,
    "staff_id" "uuid",
    "comment" "text",
    "response" "text",
    "responded_by" "uuid",
    "responded_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "branch_id" "uuid" NOT NULL,
    CONSTRAINT "feedback_overall_rating_check" CHECK ((("overall_rating" >= 1) AND ("overall_rating" <= 5))),
    CONSTRAINT "feedback_service_rating_check" CHECK ((("service_rating" >= 1) AND ("service_rating" <= 5))),
    CONSTRAINT "feedback_staff_rating_check" CHECK ((("staff_rating" >= 1) AND ("staff_rating" <= 5)))
);


ALTER TABLE "public"."feedback" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inventory_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "branch_id" "uuid",
    "name" "text" NOT NULL,
    "description" "text",
    "sku" "text",
    "barcode" "text",
    "current_quantity" numeric(10,2) DEFAULT 0 NOT NULL,
    "unit" "public"."inventory_unit" DEFAULT 'PIECE'::"public"."inventory_unit" NOT NULL,
    "min_quantity" numeric(10,2) DEFAULT 0 NOT NULL,
    "reorder_quantity" numeric(10,2) DEFAULT 0 NOT NULL,
    "cost_price" numeric(10,2) DEFAULT 0 NOT NULL,
    "selling_price" numeric(10,2),
    "hsn_sac_code" "text",
    "tax_rate" numeric(5,2) DEFAULT 0,
    "is_active" boolean DEFAULT true NOT NULL,
    "low_stock_alert_enabled" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."inventory_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inventory_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "inventory_item_id" "uuid" NOT NULL,
    "transaction_type" "public"."transaction_type" NOT NULL,
    "quantity" numeric(10,2) NOT NULL,
    "quantity_before" numeric(10,2) NOT NULL,
    "quantity_after" numeric(10,2) NOT NULL,
    "unit_cost" numeric(10,2),
    "total_cost" numeric(10,2),
    "appointment_id" "uuid",
    "purchase_order_id" "uuid",
    "notes" "text",
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "branch_id" "uuid"
);


ALTER TABLE "public"."inventory_transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."invoice_lines" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "invoice_id" "uuid" NOT NULL,
    "item_type" "public"."line_item_type" NOT NULL,
    "item_id" "uuid",
    "item_name" "text" NOT NULL,
    "description" "text",
    "quantity" numeric(10,2) DEFAULT 1 NOT NULL,
    "unit_price" numeric(10,2) NOT NULL,
    "hsn_sac_code" "text",
    "tax_rate" numeric(5,2) DEFAULT 0 NOT NULL,
    "tax_amount" numeric(10,2) DEFAULT 0 NOT NULL,
    "subtotal" numeric(10,2) NOT NULL,
    "total" numeric(10,2) NOT NULL,
    "staff_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "branch_id" "uuid" NOT NULL
);


ALTER TABLE "public"."invoice_lines" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."invoices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "invoice_number" "text" NOT NULL,
    "invoice_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "appointment_id" "uuid",
    "client_id" "uuid" NOT NULL,
    "status" "public"."invoice_status" DEFAULT 'DRAFT'::"public"."invoice_status" NOT NULL,
    "subtotal" numeric(10,2) DEFAULT 0 NOT NULL,
    "discount_amount" numeric(10,2) DEFAULT 0 NOT NULL,
    "discount_percentage" numeric(5,2) DEFAULT 0 NOT NULL,
    "tax_amount" numeric(10,2) DEFAULT 0 NOT NULL,
    "cgst" numeric(10,2) DEFAULT 0 NOT NULL,
    "sgst" numeric(10,2) DEFAULT 0 NOT NULL,
    "igst" numeric(10,2) DEFAULT 0 NOT NULL,
    "total_amount" numeric(10,2) DEFAULT 0 NOT NULL,
    "paid_amount" numeric(10,2) DEFAULT 0 NOT NULL,
    "balance_amount" numeric(10,2) DEFAULT 0 NOT NULL,
    "gstin_applied" boolean DEFAULT false NOT NULL,
    "place_of_supply" "text",
    "notes" "text",
    "terms_and_conditions" "text",
    "pdf_url" "text",
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."invoices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notification_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "recipient_id" "uuid",
    "recipient_phone" "text",
    "recipient_email" "text",
    "recipient_name" "text",
    "channel" "public"."notification_channel" NOT NULL,
    "template_type" "public"."template_type",
    "subject" "text",
    "body" "text" NOT NULL,
    "status" "public"."notification_status" DEFAULT 'PENDING'::"public"."notification_status" NOT NULL,
    "provider_message_id" "text",
    "provider_response" "jsonb",
    "error_message" "text",
    "sent_at" timestamp with time zone,
    "delivered_at" timestamp with time zone,
    "read_at" timestamp with time zone,
    "failed_at" timestamp with time zone,
    "appointment_id" "uuid",
    "invoice_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "branch_id" "uuid" NOT NULL
);


ALTER TABLE "public"."notification_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notification_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid",
    "name" "text" NOT NULL,
    "type" "public"."template_type" NOT NULL,
    "channel" "public"."notification_channel" NOT NULL,
    "subject" "text",
    "body" "text" NOT NULL,
    "provider_template_id" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "is_system_default" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "branch_id" "uuid" NOT NULL
);


ALTER TABLE "public"."notification_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."payments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "invoice_id" "uuid" NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "payment_method" "public"."payment_method" NOT NULL,
    "payment_date" timestamp with time zone DEFAULT "now"() NOT NULL,
    "transaction_id" "text",
    "reference_number" "text",
    "notes" "text",
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "branch_id" "uuid" NOT NULL
);


ALTER TABLE "public"."payments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."permissions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "resource" "text" NOT NULL,
    "action" "text" NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."permissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."purchase_order_lines" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "purchase_order_id" "uuid" NOT NULL,
    "inventory_item_id" "uuid" NOT NULL,
    "quantity" numeric(10,2) NOT NULL,
    "unit_price" numeric(10,2) NOT NULL,
    "tax_rate" numeric(5,2) DEFAULT 0 NOT NULL,
    "subtotal" numeric(10,2) NOT NULL,
    "tax_amount" numeric(10,2) NOT NULL,
    "total" numeric(10,2) NOT NULL,
    "quantity_received" numeric(10,2) DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "branch_id" "uuid" NOT NULL
);


ALTER TABLE "public"."purchase_order_lines" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."purchase_orders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "po_number" "text" NOT NULL,
    "vendor_name" "text" NOT NULL,
    "vendor_contact" "text",
    "status" "public"."po_status" DEFAULT 'DRAFT'::"public"."po_status" NOT NULL,
    "subtotal" numeric(10,2) DEFAULT 0 NOT NULL,
    "tax_amount" numeric(10,2) DEFAULT 0 NOT NULL,
    "total_amount" numeric(10,2) DEFAULT 0 NOT NULL,
    "order_date" "date",
    "expected_delivery_date" "date",
    "received_date" "date",
    "approved_by" "uuid",
    "approved_at" timestamp with time zone,
    "notes" "text",
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."purchase_orders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."role_permissions" (
    "role_id" "uuid" NOT NULL,
    "permission_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."role_permissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "is_system_role" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."service_categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "display_order" integer DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "branch_id" "uuid" NOT NULL
);


ALTER TABLE "public"."service_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."service_inventory_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "service_id" "uuid" NOT NULL,
    "inventory_item_id" "uuid" NOT NULL,
    "quantity_per_service" numeric(10,2) DEFAULT 1 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "branch_id" "uuid"
);


ALTER TABLE "public"."service_inventory_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."services" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "category_id" "uuid",
    "name" "text" NOT NULL,
    "description" "text",
    "duration_minutes" integer NOT NULL,
    "price" numeric(10,2) NOT NULL,
    "hsn_sac_code" "text",
    "tax_rate" numeric(5,2) DEFAULT 0,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "branch_id" "uuid" NOT NULL
);


ALTER TABLE "public"."services" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shift_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "start_time" time without time zone NOT NULL,
    "end_time" time without time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."shift_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."staff" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "name" "text" NOT NULL,
    "phone" "text" NOT NULL,
    "auth_state" "public"."staff_auth_state" DEFAULT 'uninvited'::"public"."staff_auth_state" NOT NULL,
    "is_active" boolean,
    "invite_token" "text",
    "invite_expiry" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "email" "text",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "join_date" timestamp with time zone,
    "branch_id" "uuid" NOT NULL
);


ALTER TABLE "public"."staff" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."staff_metrics" (
    "staff_id" "uuid" NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "total_appointments" integer DEFAULT 0 NOT NULL,
    "completed_appointments" integer DEFAULT 0 NOT NULL,
    "cancelled_appointments" integer DEFAULT 0 NOT NULL,
    "total_revenue_generated" numeric(12,2) DEFAULT 0 NOT NULL,
    "average_rating" numeric(3,2) DEFAULT 0,
    "total_ratings" integer DEFAULT 0 NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "branch_id" "uuid" NOT NULL
);


ALTER TABLE "public"."staff_metrics" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."staff_shift_rules" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "staff_id" "uuid" NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "start_time" time without time zone NOT NULL,
    "end_time" time without time zone NOT NULL,
    "repeat_type" "text" NOT NULL,
    "weekday" "text",
    "effective_from" "date" NOT NULL,
    "effective_to" "date",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "updated_at" timestamp without time zone DEFAULT "now"(),
    CONSTRAINT "staff_shift_rules_repeat_type_check" CHECK (("repeat_type" = ANY (ARRAY['daily'::"text", 'weekly'::"text"])))
);


ALTER TABLE "public"."staff_shift_rules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."staff_shifts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "staff_id" "uuid" NOT NULL,
    "shift_date" "date" NOT NULL,
    "start_time" time without time zone NOT NULL,
    "end_time" time without time zone NOT NULL,
    "punch_in_at" timestamp with time zone,
    "punch_out_at" timestamp with time zone,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "attendance_status" "text" DEFAULT 'pending'::"text",
    "marked_by" "uuid",
    "marked_at" timestamp with time zone,
    CONSTRAINT "attendance_status_check" CHECK (("attendance_status" = ANY (ARRAY['pending'::"text", 'present'::"text", 'absent'::"text", 'half_day'::"text", 'leave'::"text"])))
);


ALTER TABLE "public"."staff_shifts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "razorpay_subscription_id" "text",
    "razorpay_plan_id" "text",
    "razorpay_customer_id" "text",
    "status" "public"."subscription_status" DEFAULT 'TRIAL'::"public"."subscription_status" NOT NULL,
    "current_period_start" timestamp with time zone DEFAULT "now"() NOT NULL,
    "current_period_end" timestamp with time zone NOT NULL,
    "trial_end" timestamp with time zone,
    "amount" numeric(10,2) DEFAULT 0 NOT NULL,
    "currency" "text" DEFAULT 'INR'::"text" NOT NULL,
    "billing_cycle" "text" DEFAULT 'monthly'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "cancelled_at" timestamp with time zone
);


ALTER TABLE "public"."subscriptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tenant_settings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "default_appointment_duration" integer DEFAULT 60 NOT NULL,
    "appointment_buffer_minutes" integer DEFAULT 15 NOT NULL,
    "advance_booking_days" integer DEFAULT 30 NOT NULL,
    "cancellation_policy" "text",
    "silver_threshold" numeric(10,2) DEFAULT 10000 NOT NULL,
    "gold_threshold" numeric(10,2) DEFAULT 25000 NOT NULL,
    "platinum_threshold" numeric(10,2) DEFAULT 50000 NOT NULL,
    "default_tax_rate" numeric(5,2) DEFAULT 18 NOT NULL,
    "send_appointment_confirmations" boolean DEFAULT true NOT NULL,
    "send_appointment_reminders" boolean DEFAULT true NOT NULL,
    "reminder_hours_before" integer DEFAULT 1 NOT NULL,
    "send_birthday_greetings" boolean DEFAULT true NOT NULL,
    "send_feedback_requests" boolean DEFAULT true NOT NULL,
    "daily_report_enabled" boolean DEFAULT true NOT NULL,
    "daily_report_time" time without time zone DEFAULT '21:00:00'::time without time zone NOT NULL,
    "weekly_report_enabled" boolean DEFAULT true NOT NULL,
    "weekly_report_day" integer DEFAULT 6 NOT NULL,
    "theme_primary_color" "text" DEFAULT '#0ea5e9'::"text" NOT NULL,
    "theme_accent_color" "text" DEFAULT '#06b6d4'::"text" NOT NULL,
    "theme_font_family" "text" DEFAULT 'Inter'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."tenant_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tenants" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_name" "text" NOT NULL,
    "schema_name" "text" NOT NULL,
    "status" "public"."tenant_status" DEFAULT 'TRIAL'::"public"."tenant_status" NOT NULL,
    "trial_ends_at" timestamp with time zone DEFAULT ("now"() + '30 days'::interval) NOT NULL,
    "has_gstin" boolean DEFAULT false NOT NULL,
    "gstin" "text",
    "gstin_added_at" timestamp with time zone,
    "proof_of_business_url" "text",
    "proof_verification_status" "public"."proof_verification_status" DEFAULT 'PENDING'::"public"."proof_verification_status" NOT NULL,
    "proof_verified_at" timestamp with time zone,
    "proof_verified_by" "uuid",
    "owner_name" "text" NOT NULL,
    "owner_phone" "text" NOT NULL,
    "owner_email" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "onboarding_completed" boolean DEFAULT false,
    CONSTRAINT "gstin_required_when_has_gstin" CHECK ((("has_gstin" = false) OR (("has_gstin" = true) AND ("gstin" IS NOT NULL))))
);


ALTER TABLE "public"."tenants" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_role" (
    "name" "text"
);


ALTER TABLE "public"."user_role" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_roles" (
    "user_id" "uuid" NOT NULL,
    "role_id" "uuid" NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "assigned_by" "uuid",
    "assigned_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "full_name" "text" NOT NULL,
    "phone" "text" NOT NULL,
    "email" "text" NOT NULL,
    "avatar_url" "text",
    "salary" numeric(10,2),
    "join_date" "date",
    "is_active" boolean DEFAULT true NOT NULL,
    "last_login_at" timestamp with time zone,
    "consent_given" boolean DEFAULT false NOT NULL,
    "consent_given_at" timestamp with time zone,
    "data_retention_expires_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "gender" "text",
    "address" "text",
    "date_of_birth" "date",
    "alternate_phone" numeric
);


ALTER TABLE "public"."users" OWNER TO "postgres";


COMMENT ON COLUMN "public"."users"."gender" IS 'gender';



COMMENT ON COLUMN "public"."users"."address" IS 'User_Address';



COMMENT ON COLUMN "public"."users"."date_of_birth" IS 'Date Of Birth Of User';



COMMENT ON COLUMN "public"."users"."alternate_phone" IS 'alternate_phone user';



CREATE TABLE IF NOT EXISTS "public"."whatsapp_config" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid" NOT NULL,
    "provider" "public"."whatsapp_provider" DEFAULT 'GUPSHUP'::"public"."whatsapp_provider" NOT NULL,
    "api_key" "text" NOT NULL,
    "sender_phone" "text" NOT NULL,
    "sender_name" "text",
    "appointment_confirmation_template_id" "text",
    "appointment_reminder_template_id" "text",
    "invoice_template_id" "text",
    "feedback_template_id" "text",
    "birthday_template_id" "text",
    "low_stock_alert_template_id" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "verified" boolean DEFAULT false NOT NULL,
    "verified_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."whatsapp_config" OWNER TO "postgres";


ALTER TABLE ONLY "public"."appointment_services"
    ADD CONSTRAINT "appointment_services_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."branches"
    ADD CONSTRAINT "branches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."client_notes"
    ADD CONSTRAINT "client_notes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."clients"
    ADD CONSTRAINT "clients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."clients"
    ADD CONSTRAINT "clients_tenant_id_phone_key" UNIQUE ("tenant_id", "phone");



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_appointment_id_key" UNIQUE ("appointment_id");



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory_items"
    ADD CONSTRAINT "inventory_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory_items"
    ADD CONSTRAINT "inventory_items_tenant_id_sku_key" UNIQUE ("tenant_id", "sku");



ALTER TABLE ONLY "public"."inventory_transactions"
    ADD CONSTRAINT "inventory_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."invoice_lines"
    ADD CONSTRAINT "invoice_lines_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_tenant_id_invoice_number_key" UNIQUE ("tenant_id", "invoice_number");



ALTER TABLE ONLY "public"."notification_logs"
    ADD CONSTRAINT "notification_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_templates"
    ADD CONSTRAINT "notification_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_templates"
    ADD CONSTRAINT "notification_templates_tenant_id_type_channel_key" UNIQUE ("tenant_id", "type", "channel");



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."permissions"
    ADD CONSTRAINT "permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."permissions"
    ADD CONSTRAINT "permissions_resource_action_key" UNIQUE ("resource", "action");



ALTER TABLE ONLY "public"."purchase_order_lines"
    ADD CONSTRAINT "purchase_order_lines_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."purchase_orders"
    ADD CONSTRAINT "purchase_orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."purchase_orders"
    ADD CONSTRAINT "purchase_orders_tenant_id_po_number_key" UNIQUE ("tenant_id", "po_number");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_pkey" PRIMARY KEY ("role_id", "permission_id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."service_categories"
    ADD CONSTRAINT "service_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."service_categories"
    ADD CONSTRAINT "service_categories_tenant_id_name_key" UNIQUE ("tenant_id", "name");



ALTER TABLE ONLY "public"."service_inventory_items"
    ADD CONSTRAINT "service_inventory_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."service_inventory_items"
    ADD CONSTRAINT "service_inventory_items_service_id_inventory_item_id_key" UNIQUE ("service_id", "inventory_item_id");



ALTER TABLE ONLY "public"."services"
    ADD CONSTRAINT "services_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shift_templates"
    ADD CONSTRAINT "shift_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."staff"
    ADD CONSTRAINT "staff_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."staff_metrics"
    ADD CONSTRAINT "staff_metrics_pkey" PRIMARY KEY ("staff_id");



ALTER TABLE ONLY "public"."staff"
    ADD CONSTRAINT "staff_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."staff_shift_rules"
    ADD CONSTRAINT "staff_shift_rules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."staff_shifts"
    ADD CONSTRAINT "staff_shifts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."staff_shifts"
    ADD CONSTRAINT "staff_shifts_staff_id_shift_date_key" UNIQUE ("staff_id", "shift_date");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_razorpay_subscription_id_key" UNIQUE ("razorpay_subscription_id");



ALTER TABLE ONLY "public"."tenant_settings"
    ADD CONSTRAINT "tenant_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tenant_settings"
    ADD CONSTRAINT "tenant_settings_tenant_id_key" UNIQUE ("tenant_id");



ALTER TABLE ONLY "public"."tenants"
    ADD CONSTRAINT "tenants_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tenants"
    ADD CONSTRAINT "tenants_schema_name_key" UNIQUE ("schema_name");



ALTER TABLE ONLY "public"."staff_shifts"
    ADD CONSTRAINT "unique_staff_shift_per_day" UNIQUE ("staff_id", "shift_date");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_pkey" PRIMARY KEY ("user_id", "role_id", "tenant_id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."whatsapp_config"
    ADD CONSTRAINT "whatsapp_config_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."whatsapp_config"
    ADD CONSTRAINT "whatsapp_config_tenant_id_key" UNIQUE ("tenant_id");



CREATE INDEX "idx_appointment_services_appointment_id" ON "public"."appointment_services" USING "btree" ("appointment_id");



CREATE INDEX "idx_appointment_services_service_id" ON "public"."appointment_services" USING "btree" ("service_id");



CREATE INDEX "idx_appointments_branch_id" ON "public"."appointments" USING "btree" ("branch_id");



CREATE INDEX "idx_appointments_client_id" ON "public"."appointments" USING "btree" ("client_id");



CREATE INDEX "idx_appointments_date" ON "public"."appointments" USING "btree" ("appointment_date");



CREATE INDEX "idx_appointments_staff_id" ON "public"."appointments" USING "btree" ("primary_staff_id");



CREATE INDEX "idx_appointments_status" ON "public"."appointments" USING "btree" ("status");



CREATE INDEX "idx_appointments_tenant_id" ON "public"."appointments" USING "btree" ("tenant_id");



CREATE INDEX "idx_audit_logs_created_at" ON "public"."audit_logs" USING "btree" ("created_at");



CREATE INDEX "idx_audit_logs_resource" ON "public"."audit_logs" USING "btree" ("resource_type", "resource_id");



CREATE INDEX "idx_audit_logs_tenant_id" ON "public"."audit_logs" USING "btree" ("tenant_id");



CREATE INDEX "idx_audit_logs_user_id" ON "public"."audit_logs" USING "btree" ("user_id");



CREATE INDEX "idx_branches_tenant_id" ON "public"."branches" USING "btree" ("tenant_id");



CREATE INDEX "idx_client_notes_client_id" ON "public"."client_notes" USING "btree" ("client_id");



CREATE INDEX "idx_clients_date_of_birth" ON "public"."clients" USING "btree" ("date_of_birth");



CREATE INDEX "idx_clients_phone" ON "public"."clients" USING "btree" ("phone");



CREATE INDEX "idx_clients_tenant_id" ON "public"."clients" USING "btree" ("tenant_id");



CREATE INDEX "idx_clients_tier" ON "public"."clients" USING "btree" ("tier");



CREATE INDEX "idx_feedback_client_id" ON "public"."feedback" USING "btree" ("client_id");



CREATE INDEX "idx_feedback_overall_rating" ON "public"."feedback" USING "btree" ("overall_rating");



CREATE INDEX "idx_feedback_staff_id" ON "public"."feedback" USING "btree" ("staff_id");



CREATE INDEX "idx_feedback_tenant_id" ON "public"."feedback" USING "btree" ("tenant_id");



CREATE INDEX "idx_inventory_items_branch_id" ON "public"."inventory_items" USING "btree" ("branch_id");



CREATE INDEX "idx_inventory_items_low_stock" ON "public"."inventory_items" USING "btree" ("current_quantity", "min_quantity") WHERE ("current_quantity" <= "min_quantity");



CREATE INDEX "idx_inventory_items_sku" ON "public"."inventory_items" USING "btree" ("sku");



CREATE INDEX "idx_inventory_items_tenant_id" ON "public"."inventory_items" USING "btree" ("tenant_id");



CREATE INDEX "idx_inventory_transactions_created_at" ON "public"."inventory_transactions" USING "btree" ("created_at");



CREATE INDEX "idx_inventory_transactions_item_id" ON "public"."inventory_transactions" USING "btree" ("inventory_item_id");



CREATE INDEX "idx_inventory_transactions_tenant_id" ON "public"."inventory_transactions" USING "btree" ("tenant_id");



CREATE INDEX "idx_invoice_lines_invoice_id" ON "public"."invoice_lines" USING "btree" ("invoice_id");



CREATE INDEX "idx_invoices_appointment_id" ON "public"."invoices" USING "btree" ("appointment_id");



CREATE INDEX "idx_invoices_client_id" ON "public"."invoices" USING "btree" ("client_id");



CREATE INDEX "idx_invoices_invoice_date" ON "public"."invoices" USING "btree" ("invoice_date");



CREATE INDEX "idx_invoices_status" ON "public"."invoices" USING "btree" ("status");



CREATE INDEX "idx_invoices_tenant_id" ON "public"."invoices" USING "btree" ("tenant_id");



CREATE INDEX "idx_notification_logs_created_at" ON "public"."notification_logs" USING "btree" ("created_at");



CREATE INDEX "idx_notification_logs_recipient_phone" ON "public"."notification_logs" USING "btree" ("recipient_phone");



CREATE INDEX "idx_notification_logs_status" ON "public"."notification_logs" USING "btree" ("status");



CREATE INDEX "idx_notification_logs_tenant_id" ON "public"."notification_logs" USING "btree" ("tenant_id");



CREATE INDEX "idx_notification_templates_tenant_id" ON "public"."notification_templates" USING "btree" ("tenant_id");



CREATE INDEX "idx_notification_templates_type" ON "public"."notification_templates" USING "btree" ("type");



CREATE INDEX "idx_payments_invoice_id" ON "public"."payments" USING "btree" ("invoice_id");



CREATE INDEX "idx_payments_payment_date" ON "public"."payments" USING "btree" ("payment_date");



CREATE INDEX "idx_payments_tenant_id" ON "public"."payments" USING "btree" ("tenant_id");



CREATE INDEX "idx_purchase_order_lines_po_id" ON "public"."purchase_order_lines" USING "btree" ("purchase_order_id");



CREATE INDEX "idx_purchase_orders_status" ON "public"."purchase_orders" USING "btree" ("status");



CREATE INDEX "idx_purchase_orders_tenant_id" ON "public"."purchase_orders" USING "btree" ("tenant_id");



CREATE INDEX "idx_rule_active" ON "public"."staff_shift_rules" USING "btree" ("tenant_id", "is_active");



CREATE INDEX "idx_rule_effective" ON "public"."staff_shift_rules" USING "btree" ("effective_from", "effective_to");



CREATE INDEX "idx_rule_staff" ON "public"."staff_shift_rules" USING "btree" ("staff_id");



CREATE INDEX "idx_service_categories_tenant_id" ON "public"."service_categories" USING "btree" ("tenant_id");



CREATE INDEX "idx_service_inventory_service_id" ON "public"."service_inventory_items" USING "btree" ("service_id");



CREATE INDEX "idx_services_category_id" ON "public"."services" USING "btree" ("category_id");



CREATE INDEX "idx_services_is_active" ON "public"."services" USING "btree" ("is_active");



CREATE INDEX "idx_services_tenant_id" ON "public"."services" USING "btree" ("tenant_id");



CREATE INDEX "idx_shift_templates_tenant_id" ON "public"."shift_templates" USING "btree" ("tenant_id");



CREATE INDEX "idx_staff_auth_state" ON "public"."staff" USING "btree" ("auth_state");



CREATE INDEX "idx_staff_employment_state" ON "public"."staff" USING "btree" ("is_active");



CREATE INDEX "idx_staff_invite_token" ON "public"."staff" USING "btree" ("invite_token");



CREATE INDEX "idx_staff_metrics_tenant_id" ON "public"."staff_metrics" USING "btree" ("tenant_id");



CREATE INDEX "idx_staff_rules_branch" ON "public"."staff_shift_rules" USING "btree" ("branch_id");



CREATE INDEX "idx_staff_rules_lookup" ON "public"."staff_shift_rules" USING "btree" ("tenant_id", "staff_id", "is_active");



CREATE INDEX "idx_staff_rules_tenant" ON "public"."staff_shift_rules" USING "btree" ("tenant_id");



CREATE INDEX "idx_staff_rules_weekday_active" ON "public"."staff_shift_rules" USING "btree" ("weekday", "is_active");



CREATE INDEX "idx_staff_shifts_shift_date" ON "public"."staff_shifts" USING "btree" ("shift_date");



CREATE INDEX "idx_staff_shifts_staff_id" ON "public"."staff_shifts" USING "btree" ("staff_id");



CREATE INDEX "idx_staff_shifts_tenant_id" ON "public"."staff_shifts" USING "btree" ("tenant_id");



CREATE INDEX "idx_staff_tenant_id" ON "public"."staff" USING "btree" ("tenant_id");



CREATE INDEX "idx_staff_user_id" ON "public"."staff" USING "btree" ("user_id");



CREATE INDEX "idx_subscriptions_status" ON "public"."subscriptions" USING "btree" ("status");



CREATE INDEX "idx_subscriptions_tenant_id" ON "public"."subscriptions" USING "btree" ("tenant_id");



CREATE INDEX "idx_tenant_settings_tenant_id" ON "public"."tenant_settings" USING "btree" ("tenant_id");



CREATE INDEX "idx_tenants_schema_name" ON "public"."tenants" USING "btree" ("schema_name");



CREATE INDEX "idx_tenants_status" ON "public"."tenants" USING "btree" ("status");



CREATE INDEX "idx_user_roles_tenant_id" ON "public"."user_roles" USING "btree" ("tenant_id");



CREATE INDEX "idx_user_roles_user_id" ON "public"."user_roles" USING "btree" ("user_id");



CREATE INDEX "idx_users_email" ON "public"."users" USING "btree" ("email");



CREATE INDEX "idx_users_phone" ON "public"."users" USING "btree" ("phone");



CREATE INDEX "idx_users_tenant_id" ON "public"."users" USING "btree" ("tenant_id");



CREATE INDEX "idx_whatsapp_config_tenant_id" ON "public"."whatsapp_config" USING "btree" ("tenant_id");



CREATE UNIQUE INDEX "unique_active_staff_weekday_rule" ON "public"."staff_shift_rules" USING "btree" ("staff_id", "tenant_id", "weekday") WHERE ("is_active" = true);



CREATE OR REPLACE TRIGGER "auto_deduct_inventory" AFTER UPDATE ON "public"."appointments" FOR EACH ROW WHEN (("old"."status" IS DISTINCT FROM "new"."status")) EXECUTE FUNCTION "public"."deduct_inventory_for_appointment"();



CREATE OR REPLACE TRIGGER "calculate_client_tier" BEFORE UPDATE OF "total_spend" ON "public"."clients" FOR EACH ROW WHEN (("old"."total_spend" IS DISTINCT FROM "new"."total_spend")) EXECUTE FUNCTION "public"."update_client_tier"();



CREATE OR REPLACE TRIGGER "calculate_invoice_balance" AFTER INSERT ON "public"."payments" FOR EACH ROW EXECUTE FUNCTION "public"."update_invoice_balance"();



CREATE OR REPLACE TRIGGER "create_staff_metrics" AFTER INSERT ON "public"."staff" FOR EACH ROW EXECUTE FUNCTION "public"."initialize_staff_metrics"();



CREATE OR REPLACE TRIGGER "initialize_tenant_settings" AFTER INSERT ON "public"."tenants" FOR EACH ROW EXECUTE FUNCTION "public"."create_default_tenant_settings"();



CREATE OR REPLACE TRIGGER "trigger_sync_owner" AFTER UPDATE OF "owner_name", "owner_phone", "owner_email" ON "public"."tenants" FOR EACH ROW EXECUTE FUNCTION "public"."sync_owner_to_users"();



CREATE OR REPLACE TRIGGER "update_appointments_updated_at" BEFORE UPDATE ON "public"."appointments" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "update_branches_updated_at" BEFORE UPDATE ON "public"."branches" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "update_client_metrics" AFTER UPDATE ON "public"."invoices" FOR EACH ROW WHEN (("old"."status" IS DISTINCT FROM "new"."status")) EXECUTE FUNCTION "public"."update_client_spend"();



CREATE OR REPLACE TRIGGER "update_clients_updated_at" BEFORE UPDATE ON "public"."clients" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "update_inventory_items_updated_at" BEFORE UPDATE ON "public"."inventory_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "update_invoices_updated_at" BEFORE UPDATE ON "public"."invoices" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "update_notification_templates_updated_at" BEFORE UPDATE ON "public"."notification_templates" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "update_purchase_orders_updated_at" BEFORE UPDATE ON "public"."purchase_orders" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "update_service_categories_updated_at" BEFORE UPDATE ON "public"."service_categories" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "update_services_updated_at" BEFORE UPDATE ON "public"."services" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "update_shift_templates_updated_at" BEFORE UPDATE ON "public"."shift_templates" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "update_staff_shifts_updated_at" BEFORE UPDATE ON "public"."staff_shifts" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "update_subscriptions_updated_at" BEFORE UPDATE ON "public"."subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "update_tenant_settings_updated_at" BEFORE UPDATE ON "public"."tenant_settings" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "update_tenants_updated_at" BEFORE UPDATE ON "public"."tenants" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "update_users_updated_at" BEFORE UPDATE ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "update_whatsapp_config_updated_at" BEFORE UPDATE ON "public"."whatsapp_config" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



ALTER TABLE ONLY "public"."appointment_services"
    ADD CONSTRAINT "appointment_services_added_by_fkey" FOREIGN KEY ("added_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."appointment_services"
    ADD CONSTRAINT "appointment_services_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "public"."appointments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."appointment_services"
    ADD CONSTRAINT "appointment_services_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."appointment_services"
    ADD CONSTRAINT "appointment_services_removed_by_fkey" FOREIGN KEY ("removed_by") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."appointment_services"
    ADD CONSTRAINT "appointment_services_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "public"."services"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."appointment_services"
    ADD CONSTRAINT "appointment_services_staff_id_fkey" FOREIGN KEY ("staff_id") REFERENCES "public"."staff"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_cancelled_by_fkey" FOREIGN KEY ("cancelled_by") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "public"."clients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_primary_staff_id_fkey" FOREIGN KEY ("primary_staff_id") REFERENCES "public"."staff"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."branches"
    ADD CONSTRAINT "branches_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."client_notes"
    ADD CONSTRAINT "client_notes_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."client_notes"
    ADD CONSTRAINT "client_notes_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "public"."clients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."client_notes"
    ADD CONSTRAINT "client_notes_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."client_notes"
    ADD CONSTRAINT "client_notes_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."clients"
    ADD CONSTRAINT "clients_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."clients"
    ADD CONSTRAINT "clients_preferred_staff_id_fkey" FOREIGN KEY ("preferred_staff_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."clients"
    ADD CONSTRAINT "clients_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "public"."appointments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "public"."clients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_responded_by_fkey" FOREIGN KEY ("responded_by") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_staff_id_fkey" FOREIGN KEY ("staff_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."staff_shift_rules"
    ADD CONSTRAINT "fk_rule_branch" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."staff_shift_rules"
    ADD CONSTRAINT "fk_rule_staff" FOREIGN KEY ("staff_id") REFERENCES "public"."staff"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."staff_shift_rules"
    ADD CONSTRAINT "fk_rule_tenant" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_items"
    ADD CONSTRAINT "inventory_items_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_items"
    ADD CONSTRAINT "inventory_items_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_transactions"
    ADD CONSTRAINT "inventory_transactions_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "public"."appointments"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."inventory_transactions"
    ADD CONSTRAINT "inventory_transactions_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_transactions"
    ADD CONSTRAINT "inventory_transactions_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_transactions"
    ADD CONSTRAINT "inventory_transactions_inventory_item_id_fkey" FOREIGN KEY ("inventory_item_id") REFERENCES "public"."inventory_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_transactions"
    ADD CONSTRAINT "inventory_transactions_purchase_order_id_fkey" FOREIGN KEY ("purchase_order_id") REFERENCES "public"."purchase_orders"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."inventory_transactions"
    ADD CONSTRAINT "inventory_transactions_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."invoice_lines"
    ADD CONSTRAINT "invoice_lines_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."invoice_lines"
    ADD CONSTRAINT "invoice_lines_invoice_id_fkey" FOREIGN KEY ("invoice_id") REFERENCES "public"."invoices"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."invoice_lines"
    ADD CONSTRAINT "invoice_lines_staff_id_fkey" FOREIGN KEY ("staff_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "public"."appointments"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "public"."clients"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_logs"
    ADD CONSTRAINT "notification_logs_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "public"."appointments"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."notification_logs"
    ADD CONSTRAINT "notification_logs_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_logs"
    ADD CONSTRAINT "notification_logs_invoice_id_fkey" FOREIGN KEY ("invoice_id") REFERENCES "public"."invoices"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."notification_logs"
    ADD CONSTRAINT "notification_logs_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_templates"
    ADD CONSTRAINT "notification_templates_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_templates"
    ADD CONSTRAINT "notification_templates_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_invoice_id_fkey" FOREIGN KEY ("invoice_id") REFERENCES "public"."invoices"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."purchase_order_lines"
    ADD CONSTRAINT "purchase_order_lines_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."purchase_order_lines"
    ADD CONSTRAINT "purchase_order_lines_inventory_item_id_fkey" FOREIGN KEY ("inventory_item_id") REFERENCES "public"."inventory_items"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."purchase_order_lines"
    ADD CONSTRAINT "purchase_order_lines_purchase_order_id_fkey" FOREIGN KEY ("purchase_order_id") REFERENCES "public"."purchase_orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."purchase_orders"
    ADD CONSTRAINT "purchase_orders_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."purchase_orders"
    ADD CONSTRAINT "purchase_orders_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."purchase_orders"
    ADD CONSTRAINT "purchase_orders_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."purchase_orders"
    ADD CONSTRAINT "purchase_orders_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "public"."permissions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."service_categories"
    ADD CONSTRAINT "service_categories_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."service_categories"
    ADD CONSTRAINT "service_categories_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."service_inventory_items"
    ADD CONSTRAINT "service_inventory_items_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."service_inventory_items"
    ADD CONSTRAINT "service_inventory_items_inventory_item_id_fkey" FOREIGN KEY ("inventory_item_id") REFERENCES "public"."inventory_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."service_inventory_items"
    ADD CONSTRAINT "service_inventory_items_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "public"."services"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."services"
    ADD CONSTRAINT "services_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."services"
    ADD CONSTRAINT "services_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."service_categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."services"
    ADD CONSTRAINT "services_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shift_templates"
    ADD CONSTRAINT "shift_templates_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shift_templates"
    ADD CONSTRAINT "shift_templates_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."staff"
    ADD CONSTRAINT "staff_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."staff_metrics"
    ADD CONSTRAINT "staff_metrics_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."staff_metrics"
    ADD CONSTRAINT "staff_metrics_staff_id_fkey" FOREIGN KEY ("staff_id") REFERENCES "public"."staff"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."staff_metrics"
    ADD CONSTRAINT "staff_metrics_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."staff_shift_rules"
    ADD CONSTRAINT "staff_shift_rules_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."staff_shifts"
    ADD CONSTRAINT "staff_shifts_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."staff_shifts"
    ADD CONSTRAINT "staff_shifts_staff_id_fkey" FOREIGN KEY ("staff_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."staff_shifts"
    ADD CONSTRAINT "staff_shifts_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."staff"
    ADD CONSTRAINT "staff_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."staff"
    ADD CONSTRAINT "staff_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tenant_settings"
    ADD CONSTRAINT "tenant_settings_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tenants"
    ADD CONSTRAINT "tenants_proof_verified_by_fkey" FOREIGN KEY ("proof_verified_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_assigned_by_fkey" FOREIGN KEY ("assigned_by") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."whatsapp_config"
    ADD CONSTRAINT "whatsapp_config_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



CREATE POLICY "Allow authenticated users to create branches" ON "public"."branches" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "Allow insert for same tenant" ON "public"."staff_metrics" FOR INSERT WITH CHECK (("tenant_id" = "public"."current_tenant_id"()));



CREATE POLICY "Allow insert shifts" ON "public"."staff_shifts" FOR INSERT WITH CHECK (true);



CREATE POLICY "Allow read shifts" ON "public"."staff_shifts" FOR SELECT USING (true);



CREATE POLICY "Allow tenant users to create branches" ON "public"."branches" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" IN ( SELECT "users"."tenant_id"
   FROM "public"."users"
  WHERE ("users"."id" = "auth"."uid"()))));



CREATE POLICY "Authenticated users can view permissions" ON "public"."permissions" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Authenticated users can view role permissions" ON "public"."role_permissions" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Authenticated users can view roles" ON "public"."roles" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Owners can manage WhatsApp config" ON "public"."whatsapp_config" TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Owners can update tenant settings" ON "public"."tenant_settings" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Staff can create appointments for their customers" ON "public"."appointments" FOR INSERT TO "authenticated" WITH CHECK ((("tenant_id" = "public"."get_user_tenant_id"()) AND ("public"."user_has_permission"('appointments'::"text", 'create'::"text") OR ("primary_staff_id" = "auth"."uid"()))));



CREATE POLICY "Staff can update own attendance" ON "public"."staff_shifts" FOR UPDATE TO "authenticated" USING (("staff_id" = "auth"."uid"())) WITH CHECK (("staff_id" = "auth"."uid"()));



CREATE POLICY "Staff can view own metrics" ON "public"."staff_metrics" FOR SELECT TO "authenticated" USING ((("staff_id" = "auth"."uid"()) OR ("tenant_id" = "public"."get_user_tenant_id"())));



CREATE POLICY "Staff can view own shifts" ON "public"."staff_shifts" FOR SELECT TO "authenticated" USING ((("staff_id" = "auth"."uid"()) OR ("tenant_id" = "public"."get_user_tenant_id"())));



CREATE POLICY "System can create audit logs" ON "public"."audit_logs" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "System can create notification logs" ON "public"."notification_logs" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "System can create tenant settings" ON "public"."tenant_settings" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Tenant owners can view subscription" ON "public"."subscriptions" FOR SELECT TO "authenticated" USING (("tenant_id" IN ( SELECT "users"."tenant_id"
   FROM "public"."users"
  WHERE ("users"."id" = "auth"."uid"()))));



CREATE POLICY "Users can add appointment services" ON "public"."appointment_services" FOR INSERT TO "authenticated" WITH CHECK (("appointment_id" IN ( SELECT "appointments"."id"
   FROM "public"."appointments"
  WHERE ("appointments"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can add invoice lines" ON "public"."invoice_lines" FOR INSERT TO "authenticated" WITH CHECK (("invoice_id" IN ( SELECT "invoices"."id"
   FROM "public"."invoices"
  WHERE ("invoices"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can add purchase order lines" ON "public"."purchase_order_lines" FOR INSERT TO "authenticated" WITH CHECK (("purchase_order_id" IN ( SELECT "purchase_orders"."id"
   FROM "public"."purchase_orders"
  WHERE ("purchase_orders"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can assign role permissions" ON "public"."role_permissions" FOR INSERT TO "authenticated" WITH CHECK (("role_id" IN ( SELECT "roles"."id"
   FROM "public"."roles"
  WHERE ("roles"."is_system_role" = false))));



CREATE POLICY "Users can be assigned roles" ON "public"."user_roles" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can create branches for their tenant" ON "public"."branches" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" IN ( SELECT "users"."tenant_id"
   FROM "public"."users"
  WHERE ("users"."id" = "auth"."uid"()))));



CREATE POLICY "Users can create client notes" ON "public"."client_notes" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can create clients" ON "public"."clients" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can create feedback" ON "public"."feedback" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can create inventory items" ON "public"."inventory_items" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can create inventory transactions" ON "public"."inventory_transactions" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can create invoices" ON "public"."invoices" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can create notification templates" ON "public"."notification_templates" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can create own profile" ON "public"."users" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can create payments" ON "public"."payments" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can create purchase orders" ON "public"."purchase_orders" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can create service categories" ON "public"."service_categories" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can create services" ON "public"."services" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can create shift templates" ON "public"."shift_templates" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can create staff shifts" ON "public"."staff_shifts" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can create subscriptions" ON "public"."subscriptions" FOR INSERT TO "authenticated" WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can delete appointment services" ON "public"."appointment_services" FOR DELETE TO "authenticated" USING (("appointment_id" IN ( SELECT "appointments"."id"
   FROM "public"."appointments"
  WHERE ("appointments"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can delete client notes" ON "public"."client_notes" FOR DELETE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can delete clients" ON "public"."clients" FOR DELETE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can delete inventory items" ON "public"."inventory_items" FOR DELETE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can delete invoice lines" ON "public"."invoice_lines" FOR DELETE TO "authenticated" USING (("invoice_id" IN ( SELECT "invoices"."id"
   FROM "public"."invoices"
  WHERE ("invoices"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can delete invoices" ON "public"."invoices" FOR DELETE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can delete notification templates" ON "public"."notification_templates" FOR DELETE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can delete purchase order lines" ON "public"."purchase_order_lines" FOR DELETE TO "authenticated" USING (("purchase_order_id" IN ( SELECT "purchase_orders"."id"
   FROM "public"."purchase_orders"
  WHERE ("purchase_orders"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can delete purchase orders" ON "public"."purchase_orders" FOR DELETE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can delete service categories" ON "public"."service_categories" FOR DELETE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can delete service inventory links" ON "public"."service_inventory_items" FOR DELETE TO "authenticated" USING (("service_id" IN ( SELECT "services"."id"
   FROM "public"."services"
  WHERE ("services"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can delete services" ON "public"."services" FOR DELETE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can delete shift templates" ON "public"."shift_templates" FOR DELETE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can delete staff metrics" ON "public"."staff_metrics" FOR DELETE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can delete staff shifts" ON "public"."staff_shifts" FOR DELETE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can insert shift rules for own tenant" ON "public"."staff_shift_rules" FOR INSERT WITH CHECK (("tenant_id" = "public"."current_tenant_id"()));



CREATE POLICY "Users can link service inventory items" ON "public"."service_inventory_items" FOR INSERT TO "authenticated" WITH CHECK (("service_id" IN ( SELECT "services"."id"
   FROM "public"."services"
  WHERE ("services"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can remove role permissions" ON "public"."role_permissions" FOR DELETE TO "authenticated" USING (("role_id" IN ( SELECT "roles"."id"
   FROM "public"."roles"
  WHERE ("roles"."is_system_role" = false))));



CREATE POLICY "Users can update appointment services" ON "public"."appointment_services" FOR UPDATE TO "authenticated" USING (("appointment_id" IN ( SELECT "appointments"."id"
   FROM "public"."appointments"
  WHERE ("appointments"."tenant_id" = "public"."get_user_tenant_id"())))) WITH CHECK (("appointment_id" IN ( SELECT "appointments"."id"
   FROM "public"."appointments"
  WHERE ("appointments"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can update client notes" ON "public"."client_notes" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can update clients" ON "public"."clients" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can update feedback" ON "public"."feedback" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can update inventory items" ON "public"."inventory_items" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can update inventory transactions" ON "public"."inventory_transactions" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can update invoice lines" ON "public"."invoice_lines" FOR UPDATE TO "authenticated" USING (("invoice_id" IN ( SELECT "invoices"."id"
   FROM "public"."invoices"
  WHERE ("invoices"."tenant_id" = "public"."get_user_tenant_id"())))) WITH CHECK (("invoice_id" IN ( SELECT "invoices"."id"
   FROM "public"."invoices"
  WHERE ("invoices"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can update invoices" ON "public"."invoices" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can update notification templates" ON "public"."notification_templates" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can update own profile" ON "public"."users" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can update own tenant shift rules" ON "public"."staff_shift_rules" FOR UPDATE USING (("tenant_id" = "public"."current_tenant_id"())) WITH CHECK (("tenant_id" = "public"."current_tenant_id"()));



CREATE POLICY "Users can update payments" ON "public"."payments" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can update purchase order lines" ON "public"."purchase_order_lines" FOR UPDATE TO "authenticated" USING (("purchase_order_id" IN ( SELECT "purchase_orders"."id"
   FROM "public"."purchase_orders"
  WHERE ("purchase_orders"."tenant_id" = "public"."get_user_tenant_id"())))) WITH CHECK (("purchase_order_id" IN ( SELECT "purchase_orders"."id"
   FROM "public"."purchase_orders"
  WHERE ("purchase_orders"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can update purchase orders" ON "public"."purchase_orders" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can update role permissions" ON "public"."role_permissions" FOR UPDATE TO "authenticated" USING (("role_id" IN ( SELECT "roles"."id"
   FROM "public"."roles"
  WHERE ("roles"."is_system_role" = false)))) WITH CHECK (("role_id" IN ( SELECT "roles"."id"
   FROM "public"."roles"
  WHERE ("roles"."is_system_role" = false))));



CREATE POLICY "Users can update service categories" ON "public"."service_categories" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can update service inventory links" ON "public"."service_inventory_items" FOR UPDATE TO "authenticated" USING (("service_id" IN ( SELECT "services"."id"
   FROM "public"."services"
  WHERE ("services"."tenant_id" = "public"."get_user_tenant_id"())))) WITH CHECK (("service_id" IN ( SELECT "services"."id"
   FROM "public"."services"
  WHERE ("services"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can update services" ON "public"."services" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can update shift templates" ON "public"."shift_templates" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can update staff metrics" ON "public"."staff_metrics" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can update subscriptions" ON "public"."subscriptions" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can update tenant appointments" ON "public"."appointments" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"())) WITH CHECK (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can update tenant branches" ON "public"."branches" FOR UPDATE TO "authenticated" USING (("tenant_id" IN ( SELECT "users"."tenant_id"
   FROM "public"."users"
  WHERE ("users"."id" = "auth"."uid"())))) WITH CHECK (("tenant_id" IN ( SELECT "users"."tenant_id"
   FROM "public"."users"
  WHERE ("users"."id" = "auth"."uid"()))));



CREATE POLICY "Users can view PO lines" ON "public"."purchase_order_lines" FOR SELECT TO "authenticated" USING (("purchase_order_id" IN ( SELECT "purchase_orders"."id"
   FROM "public"."purchase_orders"
  WHERE ("purchase_orders"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can view appointment services" ON "public"."appointment_services" FOR SELECT TO "authenticated" USING (("appointment_id" IN ( SELECT "appointments"."id"
   FROM "public"."appointments"
  WHERE ("appointments"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can view invoice lines" ON "public"."invoice_lines" FOR SELECT TO "authenticated" USING (("invoice_id" IN ( SELECT "invoices"."id"
   FROM "public"."invoices"
  WHERE ("invoices"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can view own profile" ON "public"."users" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can view own roles" ON "public"."user_roles" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view own tenant shift rules" ON "public"."staff_shift_rules" FOR SELECT USING (("tenant_id" = "public"."current_tenant_id"()));



CREATE POLICY "Users can view service inventory mappings" ON "public"."service_inventory_items" FOR SELECT TO "authenticated" USING (("service_id" IN ( SELECT "services"."id"
   FROM "public"."services"
  WHERE ("services"."tenant_id" = "public"."get_user_tenant_id"()))));



CREATE POLICY "Users can view tenant appointments" ON "public"."appointments" FOR SELECT TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can view tenant audit logs" ON "public"."audit_logs" FOR SELECT TO "authenticated" USING (("tenant_id" IN ( SELECT "users"."tenant_id"
   FROM "public"."users"
  WHERE ("users"."id" = "auth"."uid"()))));



CREATE POLICY "Users can view tenant branches" ON "public"."branches" FOR SELECT TO "authenticated" USING (("tenant_id" IN ( SELECT "users"."tenant_id"
   FROM "public"."users"
  WHERE ("users"."id" = "auth"."uid"()))));



CREATE POLICY "Users can view tenant client notes" ON "public"."client_notes" FOR SELECT TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can view tenant clients" ON "public"."clients" FOR SELECT TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can view tenant feedback" ON "public"."feedback" FOR SELECT TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can view tenant inventory" ON "public"."inventory_items" FOR SELECT TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can view tenant inventory transactions" ON "public"."inventory_transactions" FOR SELECT TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can view tenant invoices" ON "public"."invoices" FOR SELECT TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can view tenant notification logs" ON "public"."notification_logs" FOR SELECT TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can view tenant notification templates" ON "public"."notification_templates" FOR SELECT TO "authenticated" USING ((("tenant_id" = "public"."get_user_tenant_id"()) OR ("tenant_id" IS NULL)));



CREATE POLICY "Users can view tenant payments" ON "public"."payments" FOR SELECT TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can view tenant purchase orders" ON "public"."purchase_orders" FOR SELECT TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can view tenant service categories" ON "public"."service_categories" FOR SELECT TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can view tenant services" ON "public"."services" FOR SELECT TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can view tenant settings" ON "public"."tenant_settings" FOR SELECT TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



CREATE POLICY "Users can view tenant shift templates" ON "public"."shift_templates" FOR SELECT TO "authenticated" USING (("tenant_id" = "public"."get_user_tenant_id"()));



ALTER TABLE "public"."appointment_services" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."appointments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."audit_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."branches" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."client_notes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."clients" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."feedback" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "full debug update" ON "public"."staff" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



ALTER TABLE "public"."inventory_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."inventory_transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."invoice_lines" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."invoices" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notification_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notification_templates" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "owner can insert staff" ON "public"."staff" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."users" "u"
     JOIN "public"."user_roles" "ur" ON (("ur"."user_id" = "u"."id")))
  WHERE (("u"."id" = "auth"."uid"()) AND ("u"."tenant_id" = "staff"."tenant_id") AND ("ur"."role_id" = '00000000-0000-0000-0000-000000000001'::"uuid")))));



ALTER TABLE "public"."payments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."purchase_order_lines" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."purchase_orders" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."role_permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."service_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."service_inventory_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."services" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shift_templates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."staff" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."staff_metrics" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."staff_shift_rules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."staff_shifts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "tenant can select staff" ON "public"."staff" FOR SELECT TO "authenticated" USING (("tenant_id" = "public"."current_tenant_id"()));



CREATE POLICY "tenant can update staff" ON "public"."staff" FOR UPDATE TO "authenticated" USING (("tenant_id" = "public"."current_tenant_id"())) WITH CHECK (("tenant_id" = "public"."current_tenant_id"()));



CREATE POLICY "tenant_admin_can_update_staff_status" ON "public"."users" FOR UPDATE USING (("tenant_id" = "public"."current_tenant_id"())) WITH CHECK (("tenant_id" = "public"."current_tenant_id"()));



ALTER TABLE "public"."tenant_settings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "tenant_user_can_create_staff" ON "public"."users" FOR INSERT WITH CHECK (("tenant_id" = "public"."current_tenant_id"()));



CREATE POLICY "tenant_users_select" ON "public"."users" FOR SELECT USING (("tenant_id" = "public"."current_tenant_id"()));



ALTER TABLE "public"."user_role" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_roles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_roles read same tenant" ON "public"."user_roles" FOR SELECT USING (("tenant_id" = ( SELECT "users"."tenant_id"
   FROM "public"."users"
  WHERE ("users"."id" = "auth"."uid"()))));



ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "users read same tenant" ON "public"."users" FOR SELECT USING (("tenant_id" = "public"."current_tenant_id"()));



ALTER TABLE "public"."whatsapp_config" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."create_default_tenant_settings"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_default_tenant_settings"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_default_tenant_settings"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."current_tenant_id"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."current_tenant_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."current_tenant_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_tenant_id"() TO "service_role";



GRANT ALL ON FUNCTION "public"."current_user_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."current_user_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_user_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."deduct_inventory_for_appointment"() TO "anon";
GRANT ALL ON FUNCTION "public"."deduct_inventory_for_appointment"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."deduct_inventory_for_appointment"() TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_invoice_number"("p_tenant_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."generate_invoice_number"("p_tenant_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_invoice_number"("p_tenant_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_permissions"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_permissions"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_permissions"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_tenant_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_tenant_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_tenant_id"() TO "service_role";



GRANT ALL ON FUNCTION "public"."initialize_staff_metrics"() TO "anon";
GRANT ALL ON FUNCTION "public"."initialize_staff_metrics"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."initialize_staff_metrics"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_owner_to_users"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_owner_to_users"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_owner_to_users"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_client_spend"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_client_spend"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_client_spend"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_client_tier"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_client_tier"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_client_tier"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_invoice_balance"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_invoice_balance"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_invoice_balance"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."user_has_permission"("p_resource" "text", "p_action" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."user_has_permission"("p_resource" "text", "p_action" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."user_has_permission"("p_resource" "text", "p_action" "text") TO "service_role";


















GRANT ALL ON TABLE "public"."appointment_services" TO "anon";
GRANT ALL ON TABLE "public"."appointment_services" TO "authenticated";
GRANT ALL ON TABLE "public"."appointment_services" TO "service_role";



GRANT ALL ON TABLE "public"."appointments" TO "anon";
GRANT ALL ON TABLE "public"."appointments" TO "authenticated";
GRANT ALL ON TABLE "public"."appointments" TO "service_role";



GRANT ALL ON TABLE "public"."audit_logs" TO "anon";
GRANT ALL ON TABLE "public"."audit_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_logs" TO "service_role";



GRANT ALL ON TABLE "public"."branches" TO "anon";
GRANT ALL ON TABLE "public"."branches" TO "authenticated";
GRANT ALL ON TABLE "public"."branches" TO "service_role";



GRANT ALL ON TABLE "public"."client_notes" TO "anon";
GRANT ALL ON TABLE "public"."client_notes" TO "authenticated";
GRANT ALL ON TABLE "public"."client_notes" TO "service_role";



GRANT ALL ON TABLE "public"."clients" TO "anon";
GRANT ALL ON TABLE "public"."clients" TO "authenticated";
GRANT ALL ON TABLE "public"."clients" TO "service_role";



GRANT ALL ON TABLE "public"."feedback" TO "anon";
GRANT ALL ON TABLE "public"."feedback" TO "authenticated";
GRANT ALL ON TABLE "public"."feedback" TO "service_role";



GRANT ALL ON TABLE "public"."inventory_items" TO "anon";
GRANT ALL ON TABLE "public"."inventory_items" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory_items" TO "service_role";



GRANT ALL ON TABLE "public"."inventory_transactions" TO "anon";
GRANT ALL ON TABLE "public"."inventory_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory_transactions" TO "service_role";



GRANT ALL ON TABLE "public"."invoice_lines" TO "anon";
GRANT ALL ON TABLE "public"."invoice_lines" TO "authenticated";
GRANT ALL ON TABLE "public"."invoice_lines" TO "service_role";



GRANT ALL ON TABLE "public"."invoices" TO "anon";
GRANT ALL ON TABLE "public"."invoices" TO "authenticated";
GRANT ALL ON TABLE "public"."invoices" TO "service_role";



GRANT ALL ON TABLE "public"."notification_logs" TO "anon";
GRANT ALL ON TABLE "public"."notification_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_logs" TO "service_role";



GRANT ALL ON TABLE "public"."notification_templates" TO "anon";
GRANT ALL ON TABLE "public"."notification_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_templates" TO "service_role";



GRANT ALL ON TABLE "public"."payments" TO "anon";
GRANT ALL ON TABLE "public"."payments" TO "authenticated";
GRANT ALL ON TABLE "public"."payments" TO "service_role";



GRANT ALL ON TABLE "public"."permissions" TO "anon";
GRANT ALL ON TABLE "public"."permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."permissions" TO "service_role";



GRANT ALL ON TABLE "public"."purchase_order_lines" TO "anon";
GRANT ALL ON TABLE "public"."purchase_order_lines" TO "authenticated";
GRANT ALL ON TABLE "public"."purchase_order_lines" TO "service_role";



GRANT ALL ON TABLE "public"."purchase_orders" TO "anon";
GRANT ALL ON TABLE "public"."purchase_orders" TO "authenticated";
GRANT ALL ON TABLE "public"."purchase_orders" TO "service_role";



GRANT ALL ON TABLE "public"."role_permissions" TO "anon";
GRANT ALL ON TABLE "public"."role_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."role_permissions" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "anon";
GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON TABLE "public"."service_categories" TO "anon";
GRANT ALL ON TABLE "public"."service_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."service_categories" TO "service_role";



GRANT ALL ON TABLE "public"."service_inventory_items" TO "anon";
GRANT ALL ON TABLE "public"."service_inventory_items" TO "authenticated";
GRANT ALL ON TABLE "public"."service_inventory_items" TO "service_role";



GRANT ALL ON TABLE "public"."services" TO "anon";
GRANT ALL ON TABLE "public"."services" TO "authenticated";
GRANT ALL ON TABLE "public"."services" TO "service_role";



GRANT ALL ON TABLE "public"."shift_templates" TO "anon";
GRANT ALL ON TABLE "public"."shift_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."shift_templates" TO "service_role";



GRANT ALL ON TABLE "public"."staff" TO "anon";
GRANT ALL ON TABLE "public"."staff" TO "authenticated";
GRANT ALL ON TABLE "public"."staff" TO "service_role";



GRANT ALL ON TABLE "public"."staff_metrics" TO "anon";
GRANT ALL ON TABLE "public"."staff_metrics" TO "authenticated";
GRANT ALL ON TABLE "public"."staff_metrics" TO "service_role";



GRANT ALL ON TABLE "public"."staff_shift_rules" TO "anon";
GRANT ALL ON TABLE "public"."staff_shift_rules" TO "authenticated";
GRANT ALL ON TABLE "public"."staff_shift_rules" TO "service_role";



GRANT ALL ON TABLE "public"."staff_shifts" TO "anon";
GRANT ALL ON TABLE "public"."staff_shifts" TO "authenticated";
GRANT ALL ON TABLE "public"."staff_shifts" TO "service_role";



GRANT ALL ON TABLE "public"."subscriptions" TO "anon";
GRANT ALL ON TABLE "public"."subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."subscriptions" TO "service_role";



GRANT ALL ON TABLE "public"."tenant_settings" TO "anon";
GRANT ALL ON TABLE "public"."tenant_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."tenant_settings" TO "service_role";



GRANT ALL ON TABLE "public"."tenants" TO "anon";
GRANT ALL ON TABLE "public"."tenants" TO "authenticated";
GRANT ALL ON TABLE "public"."tenants" TO "service_role";



GRANT ALL ON TABLE "public"."user_role" TO "anon";
GRANT ALL ON TABLE "public"."user_role" TO "authenticated";
GRANT ALL ON TABLE "public"."user_role" TO "service_role";



GRANT ALL ON TABLE "public"."user_roles" TO "anon";
GRANT ALL ON TABLE "public"."user_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_roles" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";



GRANT ALL ON TABLE "public"."whatsapp_config" TO "anon";
GRANT ALL ON TABLE "public"."whatsapp_config" TO "authenticated";
GRANT ALL ON TABLE "public"."whatsapp_config" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";



































drop extension if exists "pg_net";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.update_client_tier()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
-- Simple tier logic (configurable later)
IF NEW.total_spend >= 50000 THEN
NEW.tier = 'PLATINUM';
ELSIF NEW.total_spend >= 25000 THEN
NEW.tier = 'GOLD';
ELSIF NEW.total_spend >= 10000 THEN
NEW.tier = 'SILVER';
ELSE
NEW.tier = 'REGULAR';
END IF;

RETURN NEW;
END;
$function$
;


  create policy "avatars_delete_own_file"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using (((bucket_id = 'avatars'::text) AND (split_part(name, '/'::text, 1) = 'users'::text) AND (split_part(name, '/'::text, 2) = ((auth.uid())::text || '.jpg'::text))));



  create policy "avatars_insert_own_file"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'avatars'::text) AND (split_part(name, '/'::text, 1) = 'users'::text) AND (split_part(name, '/'::text, 2) = ((auth.uid())::text || '.jpg'::text))));



  create policy "avatars_read"
  on "storage"."objects"
  as permissive
  for select
  to public
using (((bucket_id = 'avatars'::text) AND (split_part(name, '/'::text, 1) = 'users'::text)));



  create policy "avatars_update_own_file"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'avatars'::text) AND (split_part(name, '/'::text, 1) = 'users'::text) AND (split_part(name, '/'::text, 2) = ((auth.uid())::text || '.jpg'::text))))
with check (((bucket_id = 'avatars'::text) AND (split_part(name, '/'::text, 1) = 'users'::text) AND (split_part(name, '/'::text, 2) = ((auth.uid())::text || '.jpg'::text))));



  create policy "public_read_salon_logos"
  on "storage"."objects"
  as permissive
  for select
  to public
using (((bucket_id = 'avatars'::text) AND (split_part(name, '/'::text, 1) = 'salons'::text)));



  create policy "salon_delete_logo"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using (((bucket_id = 'avatars'::text) AND (split_part(name, '/'::text, 1) = 'salons'::text) AND (split_part(name, '/'::text, 2) = ((public.current_tenant_id())::text || '.jpg'::text))));



  create policy "salon_insert_logo"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'avatars'::text) AND (split_part(name, '/'::text, 1) = 'salons'::text) AND (split_part(name, '/'::text, 2) = ((public.current_tenant_id())::text || '.jpg'::text))));



  create policy "salon_update_logo"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'avatars'::text) AND (split_part(name, '/'::text, 1) = 'salons'::text) AND (split_part(name, '/'::text, 2) = ((public.current_tenant_id())::text || '.jpg'::text))))
with check (((bucket_id = 'avatars'::text) AND (split_part(name, '/'::text, 1) = 'salons'::text) AND (split_part(name, '/'::text, 2) = ((public.current_tenant_id())::text || '.jpg'::text))));



