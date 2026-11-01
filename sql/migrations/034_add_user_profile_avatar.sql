ALTER TABLE user_profiles
    ADD COLUMN IF NOT EXISTS avatar_path VARCHAR(512);
