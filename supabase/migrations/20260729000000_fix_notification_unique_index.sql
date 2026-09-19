-- Drop the old unique index that prevents multiple channels for the same event
DROP INDEX IF EXISTS "public"."uniq_notification_per_user_event";

-- Recreate the unique index to include the channel column so IN_APP and PUSH can coexist
CREATE UNIQUE INDEX "uniq_notification_per_user_event" ON "public"."notifications" USING "btree" ("user_id", "type", "channel", "reference_id") WHERE ("user_id" IS NOT NULL);
