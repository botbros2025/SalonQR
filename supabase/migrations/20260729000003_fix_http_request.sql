CREATE OR REPLACE FUNCTION supabase_functions.http_request()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    DECLARE
      request_id bigint;
      payload jsonb;
      url text := TG_ARGV[0]::text;
      method text := TG_ARGV[1]::text;
      headers jsonb DEFAULT '{}'::jsonb;
      params jsonb DEFAULT '{}'::jsonb;
      timeout_ms integer DEFAULT 1000;
    BEGIN
      IF TG_ARGV[2]::text IS NOT NULL THEN
        headers := TG_ARGV[2]::jsonb;
      END IF;
      IF TG_ARGV[3]::text IS NOT NULL THEN
        params := TG_ARGV[3]::jsonb;
      END IF;
      IF TG_ARGV[4]::text IS NOT NULL THEN
        timeout_ms := TG_ARGV[4]::integer;
      END IF;

      -- FIX: Use net.http_post directly. The old net.http_request function was removed in newer versions of pg_net!
      request_id := net.http_post(
          url := url,
          headers := headers,
          body := jsonb_build_object(
            'old_record', OLD,
            'record', NEW,
            'type', TG_OP,
            'table', TG_TABLE_NAME,
            'schema', TG_TABLE_SCHEMA
          ),
          timeout_milliseconds := timeout_ms
      );

      RETURN COALESCE(NEW, OLD);
    END;
$function$;
