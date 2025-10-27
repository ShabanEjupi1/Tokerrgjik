-- =====================================================
-- TokerrGjik Database Fix Script
-- Run this in your Neon Database SQL Editor or via Neon CLI
-- =====================================================

-- 1. FIX game_history TABLE - Add created_at column if missing
ALTER TABLE game_history 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();

-- Update existing rows to have created_at based on played_at
UPDATE game_history 
SET created_at = played_at 
WHERE created_at IS NULL;

-- 2. FIX game_sessions TABLE - Add created_at if missing
ALTER TABLE game_sessions 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();

-- Update existing rows with created_at
UPDATE game_sessions 
SET created_at = NOW() 
WHERE created_at IS NULL;

-- 3. ENSURE ALL FOREIGN KEYS HAVE ON DELETE CASCADE
-- This allows automatic deletion of related data when users are deleted

-- game_history table
ALTER TABLE game_history DROP CONSTRAINT IF EXISTS game_history_username_fkey;
ALTER TABLE game_history ADD CONSTRAINT game_history_username_fkey 
    FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE;

-- game_sessions table
ALTER TABLE game_sessions DROP CONSTRAINT IF EXISTS game_sessions_host_username_fkey;
ALTER TABLE game_sessions ADD CONSTRAINT game_sessions_host_username_fkey 
    FOREIGN KEY (host_username) REFERENCES users(username) ON DELETE CASCADE;

ALTER TABLE game_sessions DROP CONSTRAINT IF EXISTS game_sessions_guest_username_fkey;
ALTER TABLE game_sessions ADD CONSTRAINT game_sessions_guest_username_fkey 
    FOREIGN KEY (guest_username) REFERENCES users(username) ON DELETE CASCADE;

-- 4. FIX friends TABLE - Ensure proper constraints and indexes exist
-- The table already exists with columns: id, user_username, friend_username, status, created_at

-- Remove UNIQUE constraints on individual username columns (they should only be unique together)
ALTER TABLE friends DROP CONSTRAINT IF EXISTS friends_user_username_key;
ALTER TABLE friends DROP CONSTRAINT IF EXISTS friends_friend_username_key;

-- Ensure the foreign keys have CASCADE
ALTER TABLE friends DROP CONSTRAINT IF EXISTS friends_user_username_fkey;
ALTER TABLE friends ADD CONSTRAINT friends_user_username_fkey 
    FOREIGN KEY (user_username) REFERENCES users(username) ON DELETE CASCADE;

ALTER TABLE friends DROP CONSTRAINT IF EXISTS friends_friend_username_fkey;
ALTER TABLE friends ADD CONSTRAINT friends_friend_username_fkey 
    FOREIGN KEY (friend_username) REFERENCES users(username) ON DELETE CASCADE;

-- Ensure indexes exist (they should already be there)
CREATE INDEX IF NOT EXISTS idx_friends_user ON friends(user_username);
CREATE INDEX IF NOT EXISTS idx_friends_friend ON friends(friend_username);

-- 5. FIX achievements TABLE - Match the existing structure
-- The table already exists with columns: id, username, achievement_type, unlocked_at

-- Ensure foreign key has CASCADE
ALTER TABLE achievements DROP CONSTRAINT IF EXISTS achievements_username_fkey;
ALTER TABLE achievements ADD CONSTRAINT achievements_username_fkey 
    FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE;

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_achievements_username ON achievements(username);
CREATE INDEX IF NOT EXISTS idx_achievements_type ON achievements(achievement_type);

-- 6. DELETE USERS WITH CASCADE
-- This will automatically delete all related data in:
-- - game_history
-- - game_sessions
-- - friends (both as user and friend)
-- - achievements

DELETE FROM users WHERE username IN (
    'MightyDragon',
    'CalmStorm',
    'Shaban Ejupi',
    'RadFox379',
    'BraveLegend173',
    'MegaFox796',
    'EliteKing136'
);

-- 7. VERIFY DATA
SELECT 'Total users:' as info, COUNT(*) as count FROM users
UNION ALL
SELECT 'Total games:', COUNT(*) FROM game_history
UNION ALL
SELECT 'Total friends:', COUNT(*) FROM friends
UNION ALL
SELECT 'Total achievements:', COUNT(*) FROM achievements;

-- SUCCESS MESSAGE
SELECT '✅ Database fixed successfully! Users and all related data deleted with CASCADE.' as status;
