# Simple Database Fix Instructions

Since you don't have Node.js/npm installed, here's the easiest way to fix your database:

## Option 1: Use Neon Dashboard (Recommended - Easiest!)

1. **Open your Neon Dashboard:**
   - Go to: https://console.neon.tech
   - Login to your account
   - Select your TokerrGjik project

2. **Open SQL Editor:**
   - Click on "SQL Editor" in the left sidebar
   - Or look for a "Query" or "SQL" tab

3. **Copy the SQL Script:**
   - Open the file: `c:\Users\Administrator\TokerrGjiks\scripts\fix_database.sql`
   - Select all (Ctrl+A)
   - Copy (Ctrl+C)

4. **Execute the SQL:**
   - Paste into the Neon SQL Editor (Ctrl+V)
   - Click "Run" button (or press Ctrl+Enter)
   - Wait for completion

5. **Verify:**
   - You should see success messages
   - Check that test users are deleted
   - Verify your tables are updated

## Option 2: Use PowerShell Script (Requires Connection String)

If you have your Neon connection string:

```powershell
cd C:\Users\Administrator\TokerrGjiks\scripts
.\run_database_fix_direct.ps1
```

The script will guide you through the process.

## Option 3: Install PostgreSQL Tools (For Future Use)

If you want command-line access:

1. **Download PostgreSQL:**
   - Go to: https://www.postgresql.org/download/windows/
   - Download the installer
   - During installation, select "Command Line Tools"

2. **Then use psql:**
   ```powershell
   psql "YOUR_NEON_CONNECTION_STRING" -f fix_database.sql
   ```

## What the Fix Does:

- ✅ Adds CASCADE delete to all foreign keys (so deleting users auto-deletes their data)
- ✅ Fixes the friends table constraints
- ✅ Fixes the achievements table constraints
- ✅ Adds missing `created_at` columns to game tables
- ✅ Deletes test users: MightyDragon, CalmStorm, Shaban Ejupi, RadFox379, BraveLegend173, MegaFox796, EliteKing136

## After Running the Fix:

1. **Redeploy Netlify Functions:**
   - Your functions should auto-deploy if using Git integration
   - Or manually redeploy in Netlify dashboard

2. **Test Your App:**
   - Achievements should work
   - Friends system should work
   - Online games should work (no more created_at error)
   - New color scheme is already applied (blue/teal instead of purple)

## Need Help?

If you get stuck, the SQL content is in:
`c:\Users\Administrator\TokerrGjiks\scripts\fix_database.sql`

Just copy-paste it into Neon's SQL Editor - that's the simplest method! 🎉
