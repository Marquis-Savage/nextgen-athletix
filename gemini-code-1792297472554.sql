-- 1. ENABLE UUID EXTENSION
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. USERS & VERIFIED PERSONNEL TABLE
CREATE TABLE public.users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  role TEXT CHECK (role IN ('guest', 'verified_personnel', 'admin')) DEFAULT 'guest',
  is_approved BOOLEAN DEFAULT FALSE,
  title_or_org TEXT,
  accolades TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. ATHLETES TABLE
CREATE TABLE public.athletes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  position TEXT NOT NULL,
  high_school TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  class_year INT NOT NULL,
  height_inches INT NOT NULL,
  weight_lbs INT NOT NULL,
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. COMBINE METRICS TABLE (40-Yard, Vertical, Shuttle + Video Proof)
CREATE TABLE public.combine_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES public.athletes(id) ON DELETE CASCADE,
  metric_name TEXT NOT NULL, -- e.g., '40_yard', 'shuttle', 'vertical'
  score_value TEXT NOT NULL, -- e.g., '4.42'
  video_url TEXT,            -- Link to video proof
  verified_by UUID REFERENCES public.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. CATEGORY GRADES TABLE (Footwork, Speed, Route Running, etc.)
CREATE TABLE public.category_grades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES public.athletes(id) ON DELETE CASCADE,
  category_name TEXT NOT NULL,
  score INT CHECK (score >= 0 AND score <= 100),
  last_graded_by UUID REFERENCES public.users(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. GRADE CHANGELOGS (Immutable Audit Trail)
CREATE TABLE public.grade_changelogs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES public.athletes(id) ON DELETE CASCADE,
  category_name TEXT NOT NULL,
  old_score INT,
  new_score INT NOT NULL,
  evaluation_notes TEXT,
  updated_by UUID REFERENCES public.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. ENABLE ROW LEVEL SECURITY (RLS) FOR READ-ONLY PUBLIC ACCESS
ALTER TABLE public.athletes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.combine_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.category_grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grade_changelogs ENABLE ROW LEVEL SECURITY;

-- Allow anyone (public/recruiters/fans) to read data
CREATE POLICY "Public Read Access" ON public.athletes FOR SELECT USING (true);
CREATE POLICY "Public Read Combine" ON public.combine_metrics FOR SELECT USING (true);
CREATE POLICY "Public Read Grades" ON public.category_grades FOR SELECT USING (true);
CREATE POLICY "Public Read Audit" ON public.grade_changelogs FOR SELECT USING (true);