-- ============================================================================
-- PlantCare AI — Professional Supabase Database Schema
-- ============================================================================
-- This script initializes all database tables, indexes, Row-Level Security
-- (RLS) policies, and seeding configurations for the PlantCare AI ecosystem.
-- Copy and execute this script directly in the Supabase SQL Editor.
-- ============================================================================

-- ── 1. EXPERT PATHOLOGY DATABASE (PLANT DISEASES) ───────────────────────────

CREATE TABLE IF NOT EXISTS public.plant_diseases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plant_name VARCHAR(100) NOT NULL,
    disease_name VARCHAR(100) NOT NULL,
    severity VARCHAR(30) NOT NULL DEFAULT 'Moderate' CHECK (severity IN ('Low', 'Moderate', 'High', 'Critical')),
    description TEXT NOT NULL DEFAULT '',
    symptoms JSONB NOT NULL DEFAULT '[]'::jsonb,
    treatment JSONB NOT NULL DEFAULT '[]'::jsonb,
    prevention JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    
    -- Ensure unique constraint on combination of plant and disease for cache resolution
    CONSTRAINT unique_plant_disease UNIQUE (plant_name, disease_name)
);

-- Comments describing columns for developers
COMMENT ON TABLE public.plant_diseases IS 'Cache and expert database of plant species and their diagnosed conditions.';
COMMENT ON COLUMN public.plant_diseases.plant_name IS 'Common name of the plant species (e.g., Tomato, Pomegranate, Apple).';
COMMENT ON COLUMN public.plant_diseases.disease_name IS 'Specific diagnosed condition or disease (e.g., Early Blight, Healthy).';
COMMENT ON COLUMN public.plant_diseases.symptoms IS 'List of visual markers indicating the disease, stored as a JSON array of strings.';
COMMENT ON COLUMN public.plant_diseases.treatment IS 'Step-by-step horticultural treatment instructions, stored as a JSON array of strings.';
COMMENT ON COLUMN public.plant_diseases.prevention IS 'Preventative gardening habits to avoid re-occurrence, stored as a JSON array of strings.';

-- Performance Indexes (Critical for case-insensitive lookup queries)
CREATE INDEX IF NOT EXISTS idx_plant_diseases_lookup 
ON public.plant_diseases (lower(plant_name), lower(disease_name));


-- ── 2. COMMUNITY FORUM SCHEMAS ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.forum_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_name VARCHAR(100) NOT NULL,
    author_title VARCHAR(150) NOT NULL DEFAULT 'Gardener',
    is_verified_expert BOOLEAN DEFAULT FALSE,
    category VARCHAR(50) NOT NULL DEFAULT 'General',
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    tags VARCHAR(50)[] DEFAULT '{}',
    upvotes INT DEFAULT 0,
    attached_image_paths TEXT[] DEFAULT '{}',
    diagnosis_name VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.forum_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.forum_posts(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES public.forum_comments(id) ON DELETE CASCADE, -- Supports threaded nested replies
    author_name VARCHAR(100) NOT NULL,
    author_title VARCHAR(150) NOT NULL DEFAULT 'Gardener',
    is_verified_expert BOOLEAN DEFAULT FALSE,
    content TEXT NOT NULL,
    upvotes INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_forum_posts_category ON public.forum_posts (category);
CREATE INDEX IF NOT EXISTS idx_forum_comments_post ON public.forum_comments (post_id);


-- ── 3. USER CLOUD SYNC SCHEMAS (FUTURE EXPANSION) ───────────────────────────

CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    role VARCHAR(30) DEFAULT 'user' NOT NULL,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.user_plants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    nickname VARCHAR(100) NOT NULL,
    species VARCHAR(100) NOT NULL,
    scientific_name VARCHAR(150),
    image_url TEXT,
    date_acquired TIMESTAMP WITH TIME ZONE NOT NULL,
    last_watered TIMESTAMP WITH TIME ZONE NOT NULL,
    last_fertilized TIMESTAMP WITH TIME ZONE NOT NULL,
    watering_frequency_days INT NOT NULL DEFAULT 7,
    fertilizing_frequency_days INT NOT NULL DEFAULT 30,
    health_score INT NOT NULL DEFAULT 100,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);


-- ── 4. ROW LEVEL SECURITY (RLS) POLICIES ───────────────────────────────────

-- Enable RLS on all tables
ALTER TABLE public.plant_diseases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_plants ENABLE ROW LEVEL SECURITY;

-- 4.1 plant_diseases Policies
CREATE POLICY "Enable read access for all users" ON public.plant_diseases
    FOR SELECT USING (true);

CREATE POLICY "Enable insert/update access for authenticated users only" ON public.plant_diseases
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 4.2 forum_posts Policies
CREATE POLICY "Enable read access to forum posts for anyone" ON public.forum_posts
    FOR SELECT USING (true);

CREATE POLICY "Enable insert/update access for authenticated/guest posts" ON public.forum_posts
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- 4.3 forum_comments Policies
CREATE POLICY "Enable read access to comments for anyone" ON public.forum_comments
    FOR SELECT USING (true);

CREATE POLICY "Enable comment writing for anyone" ON public.forum_comments
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- 4.4 user_profiles Policies
CREATE POLICY "Users can only manage their own profile" ON public.user_profiles
    FOR ALL TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 4.5 user_plants Policies
CREATE POLICY "Users can only manage their own plants" ON public.user_plants
    FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);


-- ── 5. AUTOMATIC TRIGGER FOR UPDATED_AT TIMESTAMP ───────────────────────────

CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_plant_diseases_modtime
    BEFORE UPDATE ON public.plant_diseases
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();
