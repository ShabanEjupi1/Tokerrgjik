-- Database Cleanup & Fix Script for Tokerrgjik
-- Run this in your Neon database console

-- ============================================
-- 1. FIX NULL VALUES IN USER STATS
-- ============================================
UPDATE users 
SET 
  total_wins = COALESCE(total_wins, 0),
  total_losses = COALESCE(total_losses, 0),
  total_draws = COALESCE(total_draws, 0),
  coins = COALESCE(coins, 100),
  level = COALESCE(level, 1),
  xp = COALESCE(xp, 0),
  is_pro = COALESCE(is_pro, false)
WHERE total_wins IS NULL 
   OR total_losses IS NULL 
   OR total_draws IS NULL
   OR coins IS NULL
   OR level IS NULL
   OR xp IS NULL;

SELECT '✅ Fixed NULL values in user stats' as status;

-- ============================================
-- 2. CHECK FOR DUPLICATE USERS
-- ============================================
SELECT username, COUNT(*) as count
FROM users
GROUP BY username
HAVING COUNT(*) > 1;

-- If duplicates found, keep the one with most data
-- (Run this only if duplicates exist)
/*
DELETE FROM users a USING users b
WHERE a.id > b.id 
  AND a.username = b.username;
*/

-- ============================================
-- 3. REMOVE TEST/INVALID GUEST USERS (OPTIONAL)
-- ============================================
-- Check how many guest users exist
SELECT COUNT(*) as guest_count 
FROM users 
WHERE username LIKE 'guest_%';

-- Uncomment to delete guest users (CAREFUL!)
-- DELETE FROM users WHERE username LIKE 'guest_%';

-- ============================================
-- 4. VIEW DATABASE STATISTICS
-- ============================================
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN username LIKE 'guest_%' THEN 1 END) as guest_users,
  COUNT(CASE WHEN is_pro = true THEN 1 END) as pro_users,
  SUM(total_wins) as total_wins_all,
  SUM(total_losses) as total_losses_all,
  AVG(level) as avg_level
FROM users;

-- ============================================
-- 5. CHECK LEADERBOARD QUERY
-- ============================================
SELECT 
  username,
  coins,
  total_wins,
  total_losses,
  level,
  CASE 
    WHEN (total_wins + total_losses) > 0 
    THEN ROUND((total_wins::numeric / (total_wins + total_losses)) * 100, 1)
    ELSE 0 
  END as win_rate
FROM users
WHERE username NOT LIKE 'guest_%'
ORDER BY total_wins DESC, level DESC, xp DESC
LIMIT 20;

-- ============================================
-- 6. VERIFY USER AUTHENTICATION DATA
-- ============================================
SELECT 
  username,
  email,
  CASE WHEN password IS NOT NULL THEN '✓' ELSE '✗' END as has_password,
  created_at,
  last_login_at
FROM users
WHERE username NOT LIKE 'guest_%'
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 7. CHECK FOR ORPHANED GAME RECORDS
-- ============================================
SELECT 
  gh.username,
  COUNT(*) as game_count
FROM game_history gh
LEFT JOIN users u ON gh.username = u.username
WHERE u.username IS NULL
GROUP BY gh.username;

-- ============================================
-- 8. OPTIMIZE INDEXES (if needed)
-- ============================================
-- Ensure indexes exist for performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_total_wins ON users(total_wins DESC);
CREATE INDEX IF NOT EXISTS idx_game_history_username ON game_history(username);
CREATE INDEX IF NOT EXISTS idx_game_history_played_at ON game_history(played_at DESC);

SELECT '✅ Database cleanup complete!' as status;

-- ============================================
-- 9. BACKUP RECOMMENDED QUERIES
-- ============================================
-- Save these for regular maintenance

-- Get user stats
-- SELECT * FROM users WHERE username = 'YOUR_USERNAME';

-- Get recent games
-- SELECT * FROM game_history WHERE username = 'YOUR_USERNAME' ORDER BY played_at DESC LIMIT 10;

-- Reset user stats (for testing)
-- UPDATE users SET total_wins = 0, total_losses = 0, total_draws = 0, coins = 100, level = 1, xp = 0 WHERE username = 'test_user';
