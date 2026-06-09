-- Add social_links JSONB column to the contractors table to store social media URLs
ALTER TABLE public.contractors ADD COLUMN IF NOT EXISTS social_links JSONB DEFAULT '{}'::jsonb;
