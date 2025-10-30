-- 🗄️ Tokerrgjik Database - Simple Setup (For Neon Console)
-- Copy and paste this ENTIRE file into Neon SQL Editor
-- Make sure EXPLAIN mode is OFF (toggle button should be gray)

-- USERS TABLE
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

-- GAME HISTORY TABLE
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

-- FRIENDS TABLE
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

-- GAME SESSIONS TABLE
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

-- ACHIEVEMENTS TABLE
CREATE TABLE IF NOT EXISTS achievements (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    achievement_type VARCHAR(100) NOT NULL,
    achievement_data JSONB,
    earned_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE,
    UNIQUE(username, achievement_type)
);

-- TRANSACTIONS TABLE
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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_total_wins ON users(total_wins DESC);
CREATE INDEX IF NOT EXISTS idx_game_history_username ON game_history(username);
CREATE INDEX IF NOT EXISTS idx_game_history_played_at ON game_history(played_at DESC);
CREATE INDEX IF NOT EXISTS idx_friends_user_username ON friends(user_username);
CREATE INDEX IF NOT EXISTS idx_friends_friend_username ON friends(friend_username);
CREATE INDEX IF NOT EXISTS idx_game_sessions_host ON game_sessions(host_username);
CREATE INDEX IF NOT EXISTS idx_game_sessions_status ON game_sessions(status);

-- SUCCESS! All tables created.
