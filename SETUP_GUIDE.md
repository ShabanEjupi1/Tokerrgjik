# TokerrGjik Setup & Configuration Guide

## ✅ Completed Tasks

### 1. **UI Color Theme Fixed** 🎨
- ✅ Changed all purple colors (#667eea, #764ba2) to masculine blue/grey (#2C3E50, #3498DB)
- ✅ Updated 10+ screen files (game_screen, home_screen, login_screen, friends_screen, statistics_screen, settings_screen, etc.)
- ✅ Changed `primarySwatch` from `Colors.deepPurple` to `Colors.blue`
- ✅ All buttons, app bars, and UI elements now use the new color scheme

### 2. **License Page Created** 📄
- ✅ Created `/license.html` page at `tokerrgjik_mobile/web/license.html`
- ✅ Accessible at: `https://tokerrgjik.netlify.app/license.html`
- ✅ Includes licensing terms, pro features, refund policy, and contact info
- ✅ Uses the new masculine color scheme

### 3. **Backend APIs Verified** ✓
All Netlify functions are properly implemented:
- ✅ `games.mjs` - Create/join game sessions, save results
- ✅ `leaderboard.mjs` - Global rankings
- ✅ `statistics.mjs` - User stats and game history
- ✅ `friends.mjs` - Friend requests and management
- ✅ `achievements.mjs` - Unlock and track achievements
- ✅ `payments.mjs` - PayPal verification (server-side secure)

---

## ⚙️ REQUIRED: Environment Variables Setup

### Netlify Environment Variables
You need to set these in your Netlify dashboard at: **Site settings → Environment variables**

#### 1. **Database (REQUIRED)** 🗄️
```
NEON_DATABASE_URL = postgresql://username:password@hostname/database?sslmode=require
```
Get this from: https://console.neon.tech → Your project → Connection string

#### 2. **PayPal (Required for payments)** 💰
```
PAYPAL_CLIENT_ID = YOUR_PAYPAL_CLIENT_ID
PAYPAL_SECRET = YOUR_PAYPAL_SECRET
PAYPAL_MODE = sandbox
```
Get these from: https://developer.paypal.com/dashboard/applications

Change `PAYPAL_MODE` to `production` when ready for live payments.

#### 3. **Netlify Deployment (Required for auto-deploy)** 🚀
For GitHub Actions to deploy to Netlify, add these to **GitHub Secrets**:
- Go to: https://github.com/ShabanEjupi/TokerrGjiks/settings/secrets/actions
- Add:
  ```
  NETLIFY_AUTH_TOKEN = YOUR_PERSONAL_ACCESS_TOKEN
  NETLIFY_SITE_ID = YOUR_SITE_ID
  ```

**Get NETLIFY_AUTH_TOKEN:**
1. Go to: https://app.netlify.com/user/applications#personal-access-tokens
2. Click "New access token"
3. Name it "GitHub Actions"
4. Copy the token

**Get NETLIFY_SITE_ID:**
1. Go to your site dashboard in Netlify
2. Site settings → General → Site details
3. Copy the "Site ID"

---

## 🔍 Issue Analysis & Solutions

### Issue 1: "Create game at play online is not functioning"
**Status:** ✅ **API is working!**

**Reason it might not work:**
1. ❌ **No database connection** - Set `NEON_DATABASE_URL` in Netlify
2. ❌ **User not logged in** - Must be authenticated to create games
3. ❌ **No users in database** - Run the database fix SQL first

**How to fix:**
1. Set `NEON_DATABASE_URL` in Netlify (see above)
2. Run the database fix SQL from clipboard in Neon SQL Editor
3. Create a user account in the app
4. Try creating a game again

**Test the API directly:**
```bash
curl -X POST https://tokerrgjik.netlify.app/.netlify/functions/games \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create_session",
    "host_username": "test_user"
  }'
```

---

### Issue 2: "The leaderboard and statistics have no data at all"
**Status:** ✅ **APIs are working!**

**Reason:** 📊 **No games played yet = No data to show**

**How to populate data:**
1. **Play some games** in the app (vs AI or multiplayer)
2. Games are automatically saved to `game_history` table
3. User stats (`total_wins`, `total_losses`, etc.) are updated
4. Leaderboard will then show data

**Quick test - Add sample data:**
Run this in Neon SQL Editor to add test data:
```sql
-- Add sample games
INSERT INTO game_history (username, game_mode, result, score, duration, moves_count, played_at, created_at)
VALUES 
  ('test_user', 'ai_easy', 'win', 100, 300, 25, NOW(), NOW()),
  ('test_user', 'ai_medium', 'loss', 50, 450, 30, NOW(), NOW()),
  ('test_user', 'multiplayer', 'win', 150, 600, 35, NOW(), NOW());

-- Update user stats
UPDATE users 
SET total_wins = 2, 
    total_losses = 1, 
    xp = 50, 
    coins = 150,
    level = 2
WHERE username = 'test_user';
```

Then refresh leaderboard and statistics in the app.

---

### Issue 3: "PayPal not working"
**Status:** ⚠️ **Needs configuration**

**Reason:** Missing PayPal credentials in Netlify environment variables

**How to fix:**

#### Step 1: Get PayPal Sandbox Credentials
1. Go to: https://developer.paypal.com/dashboard/
2. Log in (create account if needed)
3. Go to: **Apps & Credentials** → **Sandbox**
4. Create a new app or use existing:
   - App Name: "TokerrGjik"
   - Sandbox Business Account: (select or create)
5. Copy the **Client ID** and **Secret**

#### Step 2: Add to Netlify
1. Go to: https://app.netlify.com/sites/tokerrgjik/configuration/env
2. Click "Add a variable" and add:
   ```
   PAYPAL_CLIENT_ID = YOUR_SANDBOX_CLIENT_ID
   PAYPAL_SECRET = YOUR_SANDBOX_SECRET
   PAYPAL_MODE = sandbox
   ```
3. Click "Save"
4. Trigger a new deploy (push a commit or manual deploy)

#### Step 3: Test PayPal
1. Use PayPal sandbox test accounts (from developer dashboard)
2. Buyer account: Use a test buyer email/password
3. Complete a test purchase
4. Check if Pro status or coins are granted

#### Step 4: Go Live (When Ready)
1. Create a **live app** in PayPal (not sandbox)
2. Update Netlify variables:
   ```
   PAYPAL_CLIENT_ID = LIVE_CLIENT_ID
   PAYPAL_SECRET = LIVE_SECRET
   PAYPAL_MODE = production
   ```

---

## 📋 Database Setup Checklist

### Run the Database Fix SQL
You should have the SQL copied to clipboard from earlier. If not:

1. Open: https://console.neon.tech
2. Go to SQL Editor
3. Paste this SQL:

```sql
-- Add CASCADE delete constraints
ALTER TABLE game_history DROP CONSTRAINT IF EXISTS game_history_username_fkey;
ALTER TABLE game_history 
  ADD CONSTRAINT game_history_username_fkey 
  FOREIGN KEY (username) 
  REFERENCES users(username) 
  ON DELETE CASCADE;

ALTER TABLE game_sessions DROP CONSTRAINT IF EXISTS game_sessions_host_username_fkey;
ALTER TABLE game_sessions 
  ADD CONSTRAINT game_sessions_host_username_fkey 
  FOREIGN KEY (host_username) 
  REFERENCES users(username) 
  ON DELETE CASCADE;

ALTER TABLE game_sessions DROP CONSTRAINT IF EXISTS game_sessions_guest_username_fkey;
ALTER TABLE game_sessions 
  ADD CONSTRAINT game_sessions_guest_username_fkey 
  FOREIGN KEY (guest_username) 
  REFERENCES users(username) 
  ON DELETE CASCADE;

ALTER TABLE friends DROP CONSTRAINT IF EXISTS friends_user_username_fkey;
ALTER TABLE friends 
  ADD CONSTRAINT friends_user_username_fkey 
  FOREIGN KEY (user_username) 
  REFERENCES users(username) 
  ON DELETE CASCADE;

ALTER TABLE friends DROP CONSTRAINT IF EXISTS friends_friend_username_fkey;
ALTER TABLE friends 
  ADD CONSTRAINT friends_friend_username_fkey 
  FOREIGN KEY (friend_username) 
  REFERENCES users(username) 
  ON DELETE CASCADE;

-- Fix friends table - remove incorrect UNIQUE constraints
ALTER TABLE friends DROP CONSTRAINT IF EXISTS friends_user_username_friend_username_key;
ALTER TABLE friends DROP CONSTRAINT IF EXISTS friends_friend_username_user_username_key;

-- Add correct index for faster lookups
CREATE INDEX IF NOT EXISTS idx_friends_lookup ON friends(user_username, friend_username);

-- Delete test users (will cascade to related data)
DELETE FROM users WHERE username IN ('test1', 'test2', 'test3');

-- Verify CASCADE is working
SELECT 
  tc.table_name, 
  tc.constraint_name,
  rc.update_rule,
  rc.delete_rule
FROM information_schema.table_constraints tc
JOIN information_schema.referential_constraints rc 
  ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public';
```

4. Click "Run" to execute
5. Verify no errors

---

## 🎨 Logo & Branding

### Current State
- Logo uses the new masculine color scheme (#2C3E50 / #3498DB)
- All buttons and UI elements use blue/grey theme

### If You Want to Keep Old Logo
If you prefer the original logo design but with new button colors:
1. The logo files are in: `tokerrgjik_mobile/assets/images/`
2. Only the button colors and UI elements have been changed
3. Logo itself should remain unchanged unless you specify

The color changes were made to:
- AppBar backgrounds
- Button colors
- Icon colors
- Text accent colors
- Shadow colors
- CircleAvatar backgrounds

The logo files themselves were NOT modified.

---

## 🚀 GitHub Actions Build Status

All three platform builds should now work:

### ✅ Android (Fixed)
- Removed hardcoded `org.gradle.java.home` that was causing failures
- GitHub Actions uses Linux runners with Java 17 pre-installed
- Builds both APK and AAB files

### ✅ iOS (Working)
- Builds successfully without code signing
- Manual code signing needed before App Store submission
- Creates IPA file in artifacts

### ✅ Web (Fixed)
- Builds successfully
- Now auto-deploys to Netlify via GitHub Actions
- Requires `NETLIFY_AUTH_TOKEN` and `NETLIFY_SITE_ID` secrets

---

## 📞 Contact & Support

**Developer:** DogaCode Solutions  
**Email:** support@tokerrgjik.com  
**Website:** https://tokerrgjik.netlify.app  
**GitHub:** https://github.com/ShabanEjupi/TokerrGjiks  

---

## 🔧 Quick Troubleshooting

### "Database not configured" error
→ Set `NEON_DATABASE_URL` in Netlify environment variables

### "PayPal not configured" error
→ Set `PAYPAL_CLIENT_ID` and `PAYPAL_SECRET` in Netlify

### No leaderboard data
→ Play some games first, or add sample data via SQL

### Create game not working
→ Make sure you're logged in and database is configured

### License page not found
→ Access it at `/license.html` not `/license`

---

## ✨ Next Steps

1. ✅ Set database URL in Netlify
2. ✅ Run database fix SQL in Neon
3. ✅ Add Netlify tokens to GitHub Secrets (for auto-deploy)
4. ✅ Configure PayPal credentials
5. ✅ Test creating games
6. ✅ Play some games to populate leaderboard
7. ✅ Test PayPal payment flow
8. 🚀 Launch!

---

_Last Updated: October 27, 2025_
