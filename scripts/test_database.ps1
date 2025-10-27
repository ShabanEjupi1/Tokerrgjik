# Test Database Connection and Data
# Check if Neon database has users, games, etc.

$dbUrl = $env:NEON_DATABASE_URL
if (!$dbUrl) {
    $dbUrl = "postgresql://neondb_owner:npg_d6WqxY0NaMnR@ep-super-water-aedl5ojl-pooler.c-2.us-east-2.aws.neon.tech/neondb?channel_binding=require&sslmode=require"
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Database Connection Test" -ForegroundColor Yellow
Write-Host "================================================`n" -ForegroundColor Cyan

# Test if psql is available
$psqlPath = Get-Command psql -ErrorAction SilentlyContinue

if (!$psqlPath) {
    Write-Host "ERROR: psql not found!" -ForegroundColor Red
    Write-Host "`nPlease install PostgreSQL client:" -ForegroundColor Yellow
    Write-Host "  Download from: https://www.postgresql.org/download/windows/" -ForegroundColor Cyan
    Write-Host "`nOr use Neon SQL Editor:" -ForegroundColor Yellow
    Write-Host "  https://console.neon.tech" -ForegroundColor Cyan
    Write-Host ""
    
    # Open Neon console
    Write-Host "Opening Neon console..." -ForegroundColor Green
    Start-Process "https://console.neon.tech"
    
    Write-Host "`nRun these queries in the SQL Editor:" -ForegroundColor Yellow
    Write-Host @"

-- Check if tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- Count users
SELECT COUNT(*) as user_count FROM users;

-- Check latest users
SELECT username, email, created_at, coins, level 
FROM users 
ORDER BY created_at DESC 
LIMIT 5;

-- Count games
SELECT COUNT(*) as game_count FROM game_history;

-- Check if game_sessions table exists
SELECT COUNT(*) as session_count FROM game_sessions;

-- Check latest game sessions
SELECT * FROM game_sessions 
ORDER BY created_at DESC 
LIMIT 5;

"@ -ForegroundColor Cyan
    
    exit
}

Write-Host "Testing connection to Neon database..." -ForegroundColor Cyan
Write-Host ""

# Run queries
$queries = @"
-- Tables
\dt

-- User count
SELECT COUNT(*) as user_count FROM users;

-- Latest users
SELECT username, email, created_at, coins, level FROM users ORDER BY created_at DESC LIMIT 5;

-- Game history count
SELECT COUNT(*) as game_count FROM game_history;

-- Game sessions count  
SELECT COUNT(*) as session_count FROM game_sessions;
"@

$queries | & psql $dbUrl

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "Test complete!" -ForegroundColor Green
Write-Host "================================================`n" -ForegroundColor Cyan
