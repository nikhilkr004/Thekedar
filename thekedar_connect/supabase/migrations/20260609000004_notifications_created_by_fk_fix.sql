-- Fix foreign key constraint for notifications.created_by to reference auth.users instead of public.users
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_created_by_fkey;
ALTER TABLE public.notifications 
ADD CONSTRAINT notifications_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;

-- Fix foreign key constraint for audit_logs.actor_id to reference auth.users instead of public.users
ALTER TABLE public.audit_logs DROP CONSTRAINT IF EXISTS audit_logs_actor_id_fkey;
ALTER TABLE public.audit_logs 
ADD CONSTRAINT audit_logs_actor_id_fkey 
FOREIGN KEY (actor_id) REFERENCES auth.users(id) ON DELETE SET NULL;
