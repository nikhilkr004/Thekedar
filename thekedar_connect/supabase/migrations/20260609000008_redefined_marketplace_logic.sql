-- Migration to add refined database requirements for lead quality engine, proposal tracking, and contractor trust scores

ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS lead_score INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS lead_grade VARCHAR(2) DEFAULT 'C',
ADD COLUMN IF NOT EXISTS verified_gps POINT,
ADD COLUMN IF NOT EXISTS verified_otp_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.applications 
ADD COLUMN IF NOT EXISTS material_cost_est INTEGER,
ADD COLUMN IF NOT EXISTS labour_cost_est INTEGER,
ADD COLUMN IF NOT EXISTS warranty_years INTEGER,
ADD COLUMN IF NOT EXISTS payment_milestones JSONB,
ADD COLUMN IF NOT EXISTS proposal_quality_score INTEGER;

ALTER TABLE public.contractors 
ADD COLUMN IF NOT EXISTS trust_score INTEGER DEFAULT 50,
ADD COLUMN IF NOT EXISTS completion_rate DECIMAL(5,2) DEFAULT 100.0,
ADD COLUMN IF NOT EXISTS response_time_minutes INTEGER DEFAULT 60;
