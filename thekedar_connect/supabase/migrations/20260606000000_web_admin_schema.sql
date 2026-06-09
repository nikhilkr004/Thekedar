-- 1. App Configuration Table
CREATE TABLE IF NOT EXISTS public.app_configurations (
    key VARCHAR(255) PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Feature Flags Table
CREATE TABLE IF NOT EXISTS public.feature_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    is_enabled BOOLEAN DEFAULT false,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. CMS Content Tables
CREATE TABLE IF NOT EXISTS public.app_banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    image_url TEXT NOT NULL,
    redirect_url TEXT,
    position INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Announcements Table
CREATE TABLE IF NOT EXISTS public.app_announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Support Tickets Table
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id),
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(50) CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')) DEFAULT 'open',
    priority VARCHAR(50) CHECK (priority IN ('low', 'medium', 'high', 'critical')) DEFAULT 'medium',
    category VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 6. Audit Logs Table
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID REFERENCES public.users(id),
    action VARCHAR(255) NOT NULL,
    target_table VARCHAR(100) NOT NULL,
    prev_value JSONB,
    new_value JSONB,
    timestamp TIMESTAMPTZ DEFAULT now()
);

-- 7. Broadcast Notifications Table
CREATE TABLE IF NOT EXISTS public.broadcast_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    target_role VARCHAR(50),
    target_city VARCHAR(100),
    status VARCHAR(50) DEFAULT 'sent',
    stats_sent INTEGER DEFAULT 0,
    stats_opened INTEGER DEFAULT 0,
    stats_failed INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 8. Analytics Events Table
CREATE TABLE IF NOT EXISTS public.analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id),
    screen_name VARCHAR(100),
    session_id VARCHAR(100),
    event_type VARCHAR(100),
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 9. Insert some default configurations and flags to ensure the dashboard has initial records
INSERT INTO public.app_configurations (key, value, description) VALUES
('api_endpoint', 'https://api.thekedarconnect.com/v1', 'Base API URL endpoints for mobile App'),
('maintenance_mode', 'false', 'Enable to put the mobile application in maintenance mode'),
('min_version', '1.0.0', 'Minimum supported version of the mobile application'),
('force_update', 'false', 'Enable to force all users to update their mobile apps')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.feature_flags (name, description, is_enabled) VALUES
('chat', 'Real-time peer-to-peer user messaging system', true),
('calls', 'Audio/Video call feature between user and contractors', false),
('payments', 'Payment processing and credits wallet buying flow', true),
('stories', 'Show contractor portfolio update stories', false)
ON CONFLICT (name) DO NOTHING;
