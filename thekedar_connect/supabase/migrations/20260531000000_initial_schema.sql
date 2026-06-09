CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  phone VARCHAR(15) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE,
  full_name VARCHAR(255) NOT NULL,
  role VARCHAR(50) CHECK (role IN ('customer', 'contractor')),
  city VARCHAR(100),
  state VARCHAR(100),
  location GEOMETRY(Point, 4326),
  profile_photo_url TEXT,
  property_type VARCHAR(50) CHECK (property_type IN ('homeowner', 'builder', 'developer', 'tenant')),
  is_active BOOLEAN DEFAULT true,
  fcm_token TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE contractors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) UNIQUE,
  business_name VARCHAR(255),
  bio TEXT,
  years_experience INTEGER,
  categories TEXT[],
  service_areas TEXT[],
  service_radius_km INTEGER DEFAULT 25,
  trust_score DECIMAL(3,1) DEFAULT 0.0,
  average_rating DECIMAL(3,2) DEFAULT 0.0,
  review_count INTEGER DEFAULT 0,
  projects_completed INTEGER DEFAULT 0,
  aadhaar_verified BOOLEAN DEFAULT false,
  pan_verified BOOLEAN DEFAULT false,
  gst_verified BOOLEAN DEFAULT false,
  selfie_verified BOOLEAN DEFAULT false,
  is_featured BOOLEAN DEFAULT false,
  featured_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES users(id),
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(100) NOT NULL,
  budget_min INTEGER,
  budget_max INTEGER,
  timeline VARCHAR(50) CHECK (timeline IN ('asap', '1week', '1month', '3months', 'flexible')),
  status VARCHAR(50) CHECK (status IN ('draft', 'active', 'in_progress', 'completed', 'cancelled')),
  location GEOMETRY(Point, 4326),
  address_text TEXT NOT NULL,
  city VARCHAR(100),
  photo_urls TEXT[],
  hired_contractor_id UUID REFERENCES contractors(id),
  view_count INTEGER DEFAULT 0,
  application_count INTEGER DEFAULT 0,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES projects(id),
  contractor_id UUID REFERENCES contractors(id),
  status VARCHAR(50) CHECK (status IN ('pending', 'shortlisted', 'rejected', 'hired', 'withdrawn')),
  estimated_cost_min INTEGER,
  estimated_cost_max INTEGER,
  estimated_timeline VARCHAR(100),
  cover_message TEXT NOT NULL,
  portfolio_photo_urls TEXT[],
  credits_used INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(project_id, contractor_id)
);

CREATE TABLE credit_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contractor_id UUID REFERENCES contractors(id) UNIQUE,
  balance INTEGER DEFAULT 0,
  total_purchased INTEGER DEFAULT 0,
  total_spent INTEGER DEFAULT 0,
  total_earned INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE credit_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID REFERENCES credit_wallets(id),
  contractor_id UUID REFERENCES contractors(id),
  type VARCHAR(50) CHECK (type IN ('purchase', 'spend', 'refund', 'reward', 'referral')),
  credits INTEGER NOT NULL,
  amount_inr INTEGER,
  project_id UUID REFERENCES projects(id),
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
