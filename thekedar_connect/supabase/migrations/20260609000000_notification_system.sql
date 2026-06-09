-- Create custom enum types if not exists
DO $$ BEGIN
    CREATE TYPE notification_priority_enum AS ENUM ('low', 'medium', 'high', 'critical');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE notification_target_enum AS ENUM ('all', 'company', 'site', 'role', 'individual');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create user_devices table
CREATE TABLE IF NOT EXISTS public.user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    company_id UUID,
    fcm_token TEXT NOT NULL UNIQUE,
    device_name VARCHAR(100),
    platform VARCHAR(30) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX IF NOT EXISTS idx_user_devices_user ON public.user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_token ON public.user_devices(fcm_token);

-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    image_url TEXT,
    notification_type VARCHAR(50) NOT NULL,
    priority notification_priority_enum NOT NULL DEFAULT 'medium',
    target_type notification_target_enum NOT NULL DEFAULT 'individual',
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(notification_type);

-- Create notification_recipients table
CREATE TABLE IF NOT EXISTS public.notification_recipients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID NOT NULL REFERENCES public.notifications(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    is_read BOOLEAN NOT NULL DEFAULT false,
    read_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX IF NOT EXISTS idx_recipients_user_read ON public.notification_recipients(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_recipients_notification ON public.notification_recipients(notification_id);

-- Create notification_settings table
CREATE TABLE IF NOT EXISTS public.notification_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    attendance_enabled BOOLEAN NOT NULL DEFAULT true,
    leave_enabled BOOLEAN NOT NULL DEFAULT true,
    payroll_enabled BOOLEAN NOT NULL DEFAULT true,
    announcement_enabled BOOLEAN NOT NULL DEFAULT true,
    marketing_enabled BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

-- Trigger to automatically create default settings for new users
CREATE OR REPLACE FUNCTION public.handle_new_user_notification_settings()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notification_settings (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_create_user_notification_settings ON public.users;
CREATE TRIGGER tr_create_user_notification_settings
    AFTER INSERT ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_notification_settings();

-- Enable Row Level Security Policies
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

-- Policies for user_devices
DROP POLICY IF EXISTS "Users can manage their own devices" ON public.user_devices;
CREATE POLICY "Users can manage their own devices" 
    ON public.user_devices 
    FOR ALL 
    USING (auth.uid() = user_id);

-- Policies for notification_recipients
DROP POLICY IF EXISTS "Users can view their own notification receipts" ON public.notification_recipients;
CREATE POLICY "Users can view their own notification receipts" 
    ON public.notification_recipients 
    FOR SELECT 
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update read status on their receipts" ON public.notification_recipients;
CREATE POLICY "Users can update read status on their receipts" 
    ON public.notification_recipients 
    FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policies for notifications
DROP POLICY IF EXISTS "Users can view metadata for matching notifications" ON public.notifications;
CREATE POLICY "Users can view metadata for matching notifications" 
    ON public.notifications 
    FOR SELECT 
    USING (
        company_id IS NULL OR 
        company_id IN (
            SELECT company_id FROM public.user_devices WHERE user_id = auth.uid()
        )
    );

-- Policies for notification_settings
DROP POLICY IF EXISTS "Users can manage their own settings" ON public.notification_settings;
CREATE POLICY "Users can manage their own settings" 
    ON public.notification_settings 
    FOR ALL 
    USING (auth.uid() = user_id);
