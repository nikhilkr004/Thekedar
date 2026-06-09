-- Create admin whitelist table
CREATE TABLE IF NOT EXISTS public.admin_users (
    email VARCHAR(255) PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('Super Admin', 'Admin', 'Moderator', 'Support', 'Accountant')),
    created_at TIMESTAMPTZ DEFAULT clock_timestamp()
);

-- Enable RLS
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

-- Policy to allow authenticated reads
DROP POLICY IF EXISTS "Allow public reads of admin list" ON public.admin_users;
CREATE POLICY "Allow public reads of admin list" 
    ON public.admin_users FOR SELECT USING (true);

-- Insert default admin emails
INSERT INTO public.admin_users (email, full_name, role)
VALUES 
('admin@thekedar.com', 'System Admin', 'Super Admin'),
('nikhilkr004@gmail.com', 'Nikhil Kumar', 'Super Admin')
ON CONFLICT (email) DO NOTHING;
