-- Add document URL and portfolio URL columns to contractors table
ALTER TABLE public.contractors
ADD COLUMN IF NOT EXISTS aadhaar_doc_url TEXT,
ADD COLUMN IF NOT EXISTS pan_doc_url TEXT,
ADD COLUMN IF NOT EXISTS gst_doc_url TEXT,
ADD COLUMN IF NOT EXISTS portfolio_urls TEXT[];
