-- ============================================
-- TokerrGjik Database Setup Script for Neon
-- Complete schema for all tables
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    avatar_url TEXT,
    coins INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    xp INTEGER DEFAULT 0,
    total_games INTEGER DEFAULT 0,
    total_wins INTEGER DEFAULT 0,
    total_losses INTEGER DEFAULT 0,
    total_draws INTEGER DEFAULT 0,
    is_pro BOOLEAN DEFAULT FALSE,
    pro_expires_at TIMESTAMP,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add updated_at column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='updated_at') THEN
        ALTER TABLE users ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Create index on username for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- ============================================
-- 2. FRIENDS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS friends (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_username VARCHAR(50) NOT NULL REFERENCES users(username) ON DELETE CASCADE,
    friend_username VARCHAR(50) NOT NULL REFERENCES users(username) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT unique_friendship UNIQUE (user_username, friend_username)
);

-- Create indexes for friends queries
CREATE INDEX IF NOT EXISTS idx_friends_user ON friends(user_username);
CREATE INDEX IF NOT EXISTS idx_friends_friend ON friends(friend_username);
CREATE INDEX IF NOT EXISTS idx_friends_status ON friends(status);

-- ============================================
-- 3. GAME_SESSIONS TABLE (Multiplayer)
-- ============================================
CREATE TABLE IF NOT EXISTS game_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_username VARCHAR(50) NOT NULL REFERENCES users(username) ON DELETE CASCADE,
    guest_username VARCHAR(50) REFERENCES users(username) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'waiting' CHECK (status IN ('waiting', 'active', 'completed', 'cancelled')),
    board_state JSONB,
    current_turn VARCHAR(50),
    winner_username VARCHAR(50) REFERENCES users(username) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- Add updated_at column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='game_sessions' AND column_name='updated_at') THEN
        ALTER TABLE game_sessions ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Create indexes for game session queries
CREATE INDEX IF NOT EXISTS idx_sessions_host ON game_sessions(host_username);
CREATE INDEX IF NOT EXISTS idx_sessions_guest ON game_sessions(guest_username);
CREATE INDEX IF NOT EXISTS idx_sessions_status ON game_sessions(status);
CREATE INDEX IF NOT EXISTS idx_sessions_created ON game_sessions(created_at DESC);

-- ============================================
-- 4. GAME_HISTORY TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS game_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL REFERENCES users(username) ON DELETE CASCADE,
    game_mode VARCHAR(20) NOT NULL,
    result VARCHAR(10) NOT NULL CHECK (result IN ('win', 'loss', 'draw')),
    opponent_username VARCHAR(50),
    score INTEGER DEFAULT 0,
    duration INTEGER DEFAULT 0,
    moves_count INTEGER DEFAULT 0,
    played_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for game history queries
CREATE INDEX IF NOT EXISTS idx_history_username ON game_history(username);
CREATE INDEX IF NOT EXISTS idx_history_played ON game_history(played_at DESC);
CREATE INDEX IF NOT EXISTS idx_history_result ON game_history(result);

-- ============================================
-- 5. ACHIEVEMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    achievement_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    points INTEGER DEFAULT 0,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_achievements_id ON achievements(achievement_id);

-- ============================================
-- 6. USER_ACHIEVEMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL REFERENCES users(username) ON DELETE CASCADE,
    achievement_id VARCHAR(50) NOT NULL REFERENCES achievements(achievement_id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT unique_user_achievement UNIQUE (username, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_user_achievements_username ON user_achievements(username);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement ON user_achievements(achievement_id);

-- ============================================
-- 7. LEADERBOARD VIEW (Virtual table)
-- ============================================
CREATE OR REPLACE VIEW leaderboard_view AS
SELECT 
    username,
    level,
    xp,
    total_wins,
    total_games,
    total_losses,
    coins,
    avatar_url,
    is_pro,
    CASE 
        WHEN total_games > 0 THEN ROUND((total_wins::DECIMAL / total_games) * 100, 2)
        ELSE 0
    END as win_rate
FROM users
ORDER BY xp DESC, total_wins DESC;

-- ============================================
-- 8. STATISTICS TABLE (Optional - for analytics)
-- ============================================
CREATE TABLE IF NOT EXISTS statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL REFERENCES users(username) ON DELETE CASCADE,
    stat_type VARCHAR(50) NOT NULL,
    stat_value JSONB,
    recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_statistics_username ON statistics(username);
CREATE INDEX IF NOT EXISTS idx_statistics_type ON statistics(stat_type);

-- ============================================
-- 9. PAYMENTS/TRANSACTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL REFERENCES users(username) ON DELETE CASCADE,
    transaction_type VARCHAR(50) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'EUR',
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_method VARCHAR(50),
    stripe_payment_id VARCHAR(100),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add updated_at column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='transactions' AND column_name='updated_at') THEN
        ALTER TABLE transactions ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_transactions_username ON transactions(username);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);

-- ============================================
-- 10. CHALLENGES TABLE (Friend Challenges)
-- ============================================
CREATE TABLE IF NOT EXISTS challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_username VARCHAR(50) NOT NULL REFERENCES users(username) ON DELETE CASCADE,
    to_username VARCHAR(50) NOT NULL REFERENCES users(username) ON DELETE CASCADE,
    session_id UUID REFERENCES game_sessions(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
    created_at TIMESTAMP DEFAULT NOW(),
    responded_at TIMESTAMP
);

-- Create indexes for challenges queries
CREATE INDEX IF NOT EXISTS idx_challenges_from ON challenges(from_username);
CREATE INDEX IF NOT EXISTS idx_challenges_to ON challenges(to_username);
CREATE INDEX IF NOT EXISTS idx_challenges_status ON challenges(status);
CREATE INDEX IF NOT EXISTS idx_challenges_created ON challenges(created_at DESC);

-- ============================================
-- 11. HEALTH CHECK TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS health_check (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    status VARCHAR(10) DEFAULT 'ok',
    message TEXT,
    checked_at TIMESTAMP DEFAULT NOW()
);

-- Insert initial health check
INSERT INTO health_check (status, message) 
VALUES ('ok', 'Database initialized successfully')
ON CONFLICT DO NOTHING;

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Insert sample achievements if they don't exist
INSERT INTO achievements (achievement_id, name, description, icon, points, category)
VALUES 
    ('first_win', 'E Para Fitore', 'Fito lojën e parë', '🏆', 10, 'gameplay'),
    ('win_streak_5', '5 Fitore Rresht', 'Fito 5 loja rresht', '🔥', 25, 'gameplay'),
    ('level_10', 'Niveli 10', 'Arrij nivelin 10', '⭐', 20, 'progression'),
    ('friend_master', 'Mbreti i Miqve', 'Ki 10 miq', '👥', 15, 'social'),
    ('coin_collector', 'Grumbullues Monedhash', 'Grumbulloji 1000 monedha', '💰', 30, 'economy')
ON CONFLICT (achievement_id) DO NOTHING;

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for users table
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for game_sessions table
DROP TRIGGER IF EXISTS update_game_sessions_updated_at ON game_sessions;
CREATE TRIGGER update_game_sessions_updated_at 
    BEFORE UPDATE ON game_sessions 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for transactions table
DROP TRIGGER IF EXISTS update_transactions_updated_at ON transactions;
CREATE TRIGGER update_transactions_updated_at 
    BEFORE UPDATE ON transactions 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check game_sessions structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'game_sessions'
ORDER BY ordinal_position;

-- Check friends table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'friends'
ORDER BY ordinal_position;

-- Display summary
DO $$
BEGIN
    RAISE NOTICE '✅ Database setup completed successfully!';
    RAISE NOTICE '📊 Tables created/verified:';
    RAISE NOTICE '   - users';
    RAISE NOTICE '   - friends';
    RAISE NOTICE '   - game_sessions';
    RAISE NOTICE '   - game_history';
    RAISE NOTICE '   - achievements';
    RAISE NOTICE '   - user_achievements';
    RAISE NOTICE '   - statistics';
    RAISE NOTICE '   - transactions';
    RAISE NOTICE '   - challenges';
    RAISE NOTICE '   - health_check';
    RAISE NOTICE '🔧 Triggers and functions configured';
    RAISE NOTICE '🎯 Sample achievements inserted';
END $$;
