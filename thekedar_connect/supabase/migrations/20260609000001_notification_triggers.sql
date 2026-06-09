-- 1. Create Webhook Secret Key configuration
INSERT INTO public.app_configurations (key, value, description)
VALUES ('webhook_secret_key', 'super-secret-notification-token-2026', 'Auth token for verifying DB webhooks inside Edge Functions')
ON CONFLICT (key) DO NOTHING;

-- 2. Create Placeholder Tables for modules (Attendance, Leave, Payroll, Site, Subscriptions) if not exist
CREATE TABLE IF NOT EXISTS public.placeholder_attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    company_id UUID,
    status VARCHAR(50) NOT NULL, -- 'marked', 'corrected', 'approved', 'rejected'
    created_at TIMESTAMPTZ DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ DEFAULT clock_timestamp()
);

CREATE TABLE IF NOT EXISTS public.placeholder_leaves (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    supervisor_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    company_id UUID,
    status VARCHAR(50) NOT NULL, -- 'pending', 'approved', 'rejected'
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ DEFAULT clock_timestamp()
);

CREATE TABLE IF NOT EXISTS public.placeholder_payroll (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    company_id UUID,
    status VARCHAR(50) NOT NULL, -- 'processed', 'credited', 'advance_approved', 'advance_rejected'
    amount DECIMAL(12,2),
    created_at TIMESTAMPTZ DEFAULT clock_timestamp()
);

CREATE TABLE IF NOT EXISTS public.placeholder_sites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    company_id UUID,
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'updated'
    created_at TIMESTAMPTZ DEFAULT clock_timestamp()
);

CREATE TABLE IF NOT EXISTS public.placeholder_site_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    site_id UUID NOT NULL REFERENCES public.placeholder_sites(id) ON DELETE CASCADE,
    company_id UUID,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT clock_timestamp()
);

CREATE TABLE IF NOT EXISTS public.placeholder_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    status VARCHAR(50) NOT NULL, -- 'active', 'expiring', 'expired', 'payment_failed'
    created_at TIMESTAMPTZ DEFAULT clock_timestamp()
);

-- Enable RLS on placeholder tables
ALTER TABLE public.placeholder_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.placeholder_leaves ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.placeholder_payroll ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.placeholder_sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.placeholder_site_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.placeholder_subscriptions ENABLE ROW LEVEL SECURITY;

-- Dynamic notification generator helper function
CREATE OR REPLACE FUNCTION public.create_system_notification(
    p_company_id UUID,
    p_title VARCHAR,
    p_message TEXT,
    p_type VARCHAR,
    p_priority notification_priority_enum,
    p_user_id UUID
) RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
    v_enabled BOOLEAN;
BEGIN
    -- Resolve preferences
    SELECT 
        CASE 
            WHEN p_type = 'attendance' THEN attendance_enabled
            WHEN p_type = 'leave' THEN leave_enabled
            WHEN p_type = 'payroll' THEN payroll_enabled
            ELSE announcement_enabled
        END INTO v_enabled
    FROM public.notification_settings
    WHERE user_id = p_user_id;

    -- Default to true if preferences are not set
    IF v_enabled IS FALSE THEN
        RETURN NULL;
    END IF;

    -- Insert metadata record
    INSERT INTO public.notifications (company_id, title, message, notification_type, priority, target_type)
    VALUES (p_company_id, p_title, p_message, p_type, p_priority, 'individual')
    RETURNING id INTO v_notification_id;

    -- Insert recipient ledger record
    INSERT INTO public.notification_recipients (notification_id, user_id)
    VALUES (v_notification_id, p_user_id);

    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Triggers for Attendance Change
CREATE OR REPLACE FUNCTION public.tr_on_attendance_change()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        IF (NEW.status = 'marked') THEN
            PERFORM public.create_system_notification(NEW.company_id, 'Attendance Clocked In', 'Your attendance has been marked successfully.', 'attendance', 'low', NEW.user_id);
        END IF;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF OLD.status != NEW.status THEN
            IF NEW.status = 'corrected' THEN
                PERFORM public.create_system_notification(NEW.company_id, 'Attendance Corrected', 'Your supervisor has corrected your attendance record.', 'attendance', 'medium', NEW.user_id);
            ELSIF NEW.status = 'approved' THEN
                PERFORM public.create_system_notification(NEW.company_id, 'Attendance Approved', 'Your attendance record has been approved.', 'attendance', 'medium', NEW.user_id);
            ELSIF NEW.status = 'rejected' THEN
                PERFORM public.create_system_notification(NEW.company_id, 'Attendance Rejected', 'Your attendance record has been rejected.', 'attendance', 'high', NEW.user_id);
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_attendance_notification ON public.placeholder_attendance;
CREATE TRIGGER tr_attendance_notification
    AFTER INSERT OR UPDATE ON public.placeholder_attendance
    FOR EACH ROW EXECUTE FUNCTION public.tr_on_attendance_change();

-- 4. Triggers for Leave Requested / Approved / Rejected
CREATE OR REPLACE FUNCTION public.tr_on_leave_change()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        -- Notify Supervisor
        IF NEW.supervisor_id IS NOT NULL THEN
            PERFORM public.create_system_notification(NEW.company_id, 'Leave Requested', 'A worker has submitted a new leave request.', 'leave', 'medium', NEW.supervisor_id);
        END IF;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF OLD.status != NEW.status THEN
            IF NEW.status = 'approved' THEN
                PERFORM public.create_system_notification(NEW.company_id, 'Leave Approved', 'Your leave request has been approved.', 'leave', 'medium', NEW.user_id);
            ELSIF NEW.status = 'rejected' THEN
                PERFORM public.create_system_notification(NEW.company_id, 'Leave Rejected', 'Your leave request has been rejected.', 'leave', 'high', NEW.user_id);
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_leave_notification ON public.placeholder_leaves;
CREATE TRIGGER tr_leave_notification
    AFTER INSERT OR UPDATE ON public.placeholder_leaves
    FOR EACH ROW EXECUTE FUNCTION public.tr_on_leave_change();

-- 5. Triggers for Payroll
CREATE OR REPLACE FUNCTION public.tr_on_payroll_change()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        IF NEW.status = 'processed' THEN
            PERFORM public.create_system_notification(NEW.company_id, 'Salary Processed', 'Your salary for the month has been processed.', 'payroll', 'medium', NEW.user_id);
        ELSIF NEW.status = 'credited' THEN
            PERFORM public.create_system_notification(NEW.company_id, 'Salary Credited', 'Your salary has been credited to your account.', 'payroll', 'high', NEW.user_id);
        ELSIF NEW.status = 'advance_approved' THEN
            PERFORM public.create_system_notification(NEW.company_id, 'Advance Salary Approved', 'Your request for advance salary has been approved.', 'payroll', 'medium', NEW.user_id);
        ELSIF NEW.status = 'advance_rejected' THEN
            PERFORM public.create_system_notification(NEW.company_id, 'Advance Salary Rejected', 'Your request for advance salary was rejected.', 'payroll', 'high', NEW.user_id);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_payroll_notification ON public.placeholder_payroll;
CREATE TRIGGER tr_payroll_notification
    AFTER INSERT ON public.placeholder_payroll
    FOR EACH ROW EXECUTE FUNCTION public.tr_on_payroll_change();

-- 6. Triggers for Site Assignments & Updates
CREATE OR REPLACE FUNCTION public.tr_on_site_assignment_change()
RETURNS TRIGGER AS $$
DECLARE
    v_site_name VARCHAR;
BEGIN
    SELECT name INTO v_site_name FROM public.placeholder_sites WHERE id = NEW.site_id;
    
    IF (TG_OP = 'INSERT') THEN
        PERFORM public.create_system_notification(NEW.company_id, 'Site Assigned', 'You have been assigned to site: ' || v_site_name, 'site', 'medium', NEW.user_id);
    ELSIF (TG_OP = 'UPDATE') THEN
        IF OLD.is_active = true AND NEW.is_active = false THEN
            PERFORM public.create_system_notification(NEW.company_id, 'Site Removed', 'You have been removed from site: ' || v_site_name, 'site', 'high', NEW.user_id);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_site_assignment_notification ON public.placeholder_site_assignments;
CREATE TRIGGER tr_site_assignment_notification
    AFTER INSERT OR UPDATE ON public.placeholder_site_assignments
    FOR EACH ROW EXECUTE FUNCTION public.tr_on_site_assignment_change();

CREATE OR REPLACE FUNCTION public.tr_on_site_status_change()
RETURNS TRIGGER AS $$
DECLARE
    v_worker_record RECORD;
BEGIN
    IF OLD.status != NEW.status THEN
        FOR v_worker_record IN 
            SELECT user_id FROM public.placeholder_site_assignments 
            WHERE site_id = NEW.id AND is_active = true
        LOOP
            PERFORM public.create_system_notification(
                NEW.company_id,
                'Site Update',
                'Status of site ' || NEW.name || ' was updated to ' || NEW.status,
                'site',
                'medium',
                v_worker_record.user_id
            );
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_site_status_notification ON public.placeholder_sites;
CREATE TRIGGER tr_site_status_notification
    AFTER UPDATE ON public.placeholder_sites
    FOR EACH ROW EXECUTE FUNCTION public.tr_on_site_status_change();

-- 7. Triggers for User Profile / Status Approval / Suspension
CREATE OR REPLACE FUNCTION public.tr_on_user_account_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.is_active = false AND NEW.is_active = true THEN
        PERFORM public.create_system_notification(NULL, 'Account Approved', 'Your profile account has been approved.', 'system', 'high', NEW.id);
    ELSIF OLD.is_active = true AND NEW.is_active = false THEN
        PERFORM public.create_system_notification(NULL, 'Account Suspended', 'Your profile account has been suspended.', 'system', 'critical', NEW.id);
    ELSIF OLD.profile_photo_url IS DISTINCT FROM NEW.profile_photo_url OR OLD.full_name IS DISTINCT FROM NEW.full_name THEN
        PERFORM public.create_system_notification(NULL, 'Profile Updated', 'Your profile information has been updated.', 'system', 'low', NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_user_account_notification ON public.users;
CREATE TRIGGER tr_user_account_notification
    AFTER UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.tr_on_user_account_change();

-- 8. Triggers for Subscription
CREATE OR REPLACE FUNCTION public.tr_on_subscription_change()
RETURNS TRIGGER AS $$
DECLARE
    v_admin_record RECORD;
BEGIN
    IF NEW.status IN ('expiring', 'expired', 'payment_failed') THEN
        -- Find company admins/super admins of this company
        FOR v_admin_record IN 
            SELECT id FROM public.users 
            WHERE role IN ('Company Admin', 'Super Admin')
        LOOP
            PERFORM public.create_system_notification(
                NEW.company_id,
                'Subscription Alert',
                'Your company subscription status has changed to: ' || UPPER(NEW.status),
                'system',
                'critical',
                v_admin_record.id
            );
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_subscription_notification ON public.placeholder_subscriptions;
CREATE TRIGGER tr_subscription_notification
    AFTER INSERT OR UPDATE ON public.placeholder_subscriptions
    FOR EACH ROW EXECUTE FUNCTION public.tr_on_subscription_change();

-- 9. Trigger for Webhook Edge Function Call
CREATE OR REPLACE FUNCTION public.tr_notify_recipient_inserted()
RETURNS TRIGGER AS $$
DECLARE
  v_payload JSONB;
  v_secret TEXT;
  v_url TEXT;
BEGIN
  -- Retrieve configuration variables
  SELECT value INTO v_secret FROM public.app_configurations WHERE key = 'webhook_secret_key';
  v_url := 'https://eswjtunzibrhimcpcnss.supabase.co/functions/v1/dispatch-push';
  
  -- Create Payload JSONB
  v_payload := jsonb_build_object(
    'recipient_id', NEW.id,
    'notification_id', NEW.notification_id,
    'user_id', NEW.user_id
  );
  
  -- Perform POST request to Edge Function via pg_net
  PERFORM net.http_post(
    url := v_url,
    body := v_payload,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'X-Webhook-Secret', v_secret
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_recipient_webhook ON public.notification_recipients;
CREATE TRIGGER tr_recipient_webhook
    AFTER INSERT ON public.notification_recipients
    FOR EACH ROW EXECUTE FUNCTION public.tr_notify_recipient_inserted();
