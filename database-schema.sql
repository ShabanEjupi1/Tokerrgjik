-- 🗄️ Tokerrgjik Database Schema Setup
-- Run this in your Neon PostgreSQL console to ensure all tables exist

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    password VARCHAR(255),
    full_name VARCHAR(100),
    coins INTEGER DEFAULT 100,
    level INTEGER DEFAULT 1,
    xp INTEGER DEFAULT 0,
    total_wins INTEGER DEFAULT 0,
    total_losses INTEGER DEFAULT 0,
    total_draws INTEGER DEFAULT 0,
    is_pro BOOLEAN DEFAULT FALSE,
    pro_expires_at TIMESTAMP,
    avatar_url TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_login_at TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_total_wins ON users(total_wins DESC);

-- ============================================
-- GAME HISTORY TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS game_history (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    game_mode VARCHAR(50) NOT NULL,
    result VARCHAR(20) NOT NULL CHECK (result IN ('win', 'loss', 'draw')),
    opponent_username VARCHAR(50),
    score INTEGER,
    duration INTEGER,
    moves_count INTEGER,
    played_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE
);

-- Create indexes for queries
CREATE INDEX IF NOT EXISTS idx_game_history_username ON game_history(username);
CREATE INDEX IF NOT EXISTS idx_game_history_played_at ON game_history(played_at DESC);
CREATE INDEX IF NOT EXISTS idx_game_history_result ON game_history(result);

-- ============================================
-- FRIENDS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS friends (
    id SERIAL PRIMARY KEY,
    user_username VARCHAR(50) NOT NULL,
    friend_username VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (user_username) REFERENCES users(username) ON DELETE CASCADE,
    FOREIGN KEY (friend_username) REFERENCES users(username) ON DELETE CASCADE,
    UNIQUE(user_username, friend_username)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_friends_user_username ON friends(user_username);
CREATE INDEX IF NOT EXISTS idx_friends_friend_username ON friends(friend_username);
CREATE INDEX IF NOT EXISTS idx_friends_status ON friends(status);

-- ============================================
-- GAME SESSIONS TABLE (for multiplayer)
-- ============================================
CREATE TABLE IF NOT EXISTS game_sessions (
    id SERIAL PRIMARY KEY,
    host_username VARCHAR(50) NOT NULL,
    guest_username VARCHAR(50),
    status VARCHAR(20) DEFAULT 'waiting' CHECK (status IN ('waiting', 'active', 'completed', 'abandoned')),
    board_state JSONB DEFAULT '{}',
    current_turn VARCHAR(50),
    winner VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    FOREIGN KEY (host_username) REFERENCES users(username) ON DELETE CASCADE,
    FOREIGN KEY (guest_username) REFERENCES users(username) ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_game_sessions_host ON game_sessions(host_username);
CREATE INDEX IF NOT EXISTS idx_game_sessions_guest ON game_sessions(guest_username);
CREATE INDEX IF NOT EXISTS idx_game_sessions_status ON game_sessions(status);

-- ============================================
-- ACHIEVEMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS achievements (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    achievement_type VARCHAR(100) NOT NULL,
    achievement_data JSONB,
    earned_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE,
    UNIQUE(username, achievement_type)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_achievements_username ON achievements(username);
CREATE INDEX IF NOT EXISTS idx_achievements_type ON achievements(achievement_type);

-- ============================================
-- TRANSACTIONS TABLE (for coin purchases, etc.)
-- ============================================
CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    amount INTEGER NOT NULL,
    payment_provider VARCHAR(50),
    payment_id VARCHAR(255),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_transactions_username ON transactions(username);
CREATE INDEX IF NOT EXISTS idx_transactions_payment_id ON transactions(payment_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);

-- ============================================
-- LEADERBOARD VIEW (for faster queries)
-- ============================================
CREATE OR REPLACE VIEW leaderboard_view AS
SELECT 
    username,
    coins,
    total_wins,
    total_losses,
    total_draws,
    level,
    xp,
    avatar_url,
    ROUND(
        CASE 
            WHEN (total_wins + total_losses) > 0 
            THEN (total_wins::DECIMAL / (total_wins + total_losses)) * 100 
            ELSE 0 
        END, 
        1
    ) as win_rate,
    ROW_NUMBER() OVER (ORDER BY total_wins DESC, level DESC, xp DESC) as rank
FROM users
ORDER BY total_wins DESC, level DESC, xp DESC;

-- ============================================
-- SAMPLE DATA (for testing)
-- ============================================
-- Uncomment to insert test data

-- INSERT INTO users (username, email, password, coins, level, total_wins, total_losses)
-- VALUES 
--     ('testuser1', 'test1@example.com', 'password123', 500, 5, 10, 3),
--     ('testuser2', 'test2@example.com', 'password123', 300, 3, 5, 5),
--     ('testuser3', 'test3@example.com', 'password123', 200, 2, 2, 8)
-- ON CONFLICT (username) DO NOTHING;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Run these to check if everything is set up correctly

-- Check all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check users table structure
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'users';

-- Count records in each table
SELECT 
    'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'game_history', COUNT(*) FROM game_history
UNION ALL
SELECT 'friends', COUNT(*) FROM friends
UNION ALL
SELECT 'game_sessions', COUNT(*) FROM game_sessions
UNION ALL
SELECT 'achievements', COUNT(*) FROM achievements
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions;

-- Test leaderboard view
SELECT * FROM leaderboard_view LIMIT 10;

-- ✅ Setup complete!
