-- 1. Add missing profile columns with unique username constraint
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS username TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS pronouns TEXT,
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 2. Index for fast username lookup during login
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles (username);

-- 3. Ensure profile_avatars storage bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile_avatars', 'profile_avatars', false)
ON CONFLICT (id) DO NOTHING;

-- 4. Enable Row Level Security Policies for private avatar storage
CREATE POLICY "Authenticated users can upload profile avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'profile_avatars');

CREATE POLICY "Authenticated users can view profile avatars"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'profile_avatars');

CREATE POLICY "Users can update their own profile avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'profile_avatars');
