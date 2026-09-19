-- Migration: Add missing appointment push notification templates

INSERT INTO notification_templates (tenant_id, name, type, channel, subject, body, is_system_default, is_active)
VALUES
  -- Owner Templates
  (NULL, 'Appointment Created (Owner)', 'appointment_created_owner', 'PUSH', 'New Appointment: {{client_name}}', 'A new appointment was booked for {{client_name}} at {{start_time}}.', true, true),
  (NULL, 'Appointment Rescheduled (Owner)', 'appointment_rescheduled_owner', 'PUSH', 'Appointment Rescheduled: {{client_name}}', '{{client_name}}''s appointment has been rescheduled to {{start_time}}.', true, true),
  (NULL, 'Appointment Completed (Owner)', 'appointment_completed_owner', 'PUSH', 'Appointment Completed: {{client_name}}', 'The appointment for {{client_name}} has been completed.', true, true),
  (NULL, 'Appointment Cancelled (Owner)', 'appointment_cancelled_owner', 'PUSH', 'Appointment Cancelled: {{client_name}}', 'The appointment for {{client_name}} has been cancelled.', true, true),

  -- Staff Templates
  (NULL, 'Appointment Created (Staff)', 'appointment_created_staff', 'PUSH', 'New Appointment Assigned', 'You have a new appointment with {{client_name}} at {{start_time}}.', true, true),
  (NULL, 'Appointment Rescheduled (Staff)', 'appointment_rescheduled_staff', 'PUSH', 'Appointment Rescheduled', 'Your appointment with {{client_name}} has been rescheduled to {{start_time}}.', true, true),
  (NULL, 'Appointment Completed (Staff)', 'appointment_completed_staff', 'PUSH', 'Appointment Completed', 'Your appointment with {{client_name}} has been marked as completed.', true, true),
  (NULL, 'Appointment Cancelled (Staff)', 'appointment_cancelled_staff', 'PUSH', 'Appointment Cancelled', 'Your appointment with {{client_name}} has been cancelled.', true, true)
ON CONFLICT DO NOTHING;
