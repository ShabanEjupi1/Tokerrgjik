# Database Migration Instructions

## Quick Setup for Challenges Table

### Step 1: Get Database URL
```bash
# Option A: From Netlify dashboard
# Go to: https://app.netlify.com/sites/tokerrgjik/configuration/env
# Copy NEON_DATABASE_URL

# Option B: List environment variables
netlify env:list
```

### Step 2: Set Environment Variable
```bash
# On Windows (PowerShell)
$env:NEON_DATABASE_URL = "your_database_url_here"

# On Windows (CMD)
set NEON_DATABASE_URL=your_database_url_here

# On Mac/Linux
export NEON_DATABASE_URL="your_database_url_here"
```

### Step 3: Run Migration
```bash
cd scripts
node add-challenges-table.mjs
```

### Expected Output
```
🔧 Adding challenges table...

Creating challenges table...
✅ challenges table created

Creating indexes...
✅ Indexes created

📊 Verification:
Challenges table structure:
   - id: uuid
   - from_username: character varying
   - to_username: character varying
   - session_id: uuid
   - status: character varying
   - created_at: timestamp without time zone
   - responded_at: timestamp without time zone

✅ Challenges table added successfully!

📝 Next steps:
   1. Deploy the updated Netlify functions
   2. Test challenge sending from the mobile app
```

### Verification
```sql
-- Check if table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'challenges';

-- Check table structure
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_name = 'challenges'
ORDER BY ordinal_position;

-- Test insert (optional)
INSERT INTO challenges (from_username, to_username, status)
VALUES ('testuser1', 'testuser2', 'pending')
RETURNING *;
```

### Troubleshooting

**Error: "Set NEON_DATABASE_URL first!"**
- Solution: Make sure you set the environment variable correctly

**Error: "relation 'users' does not exist"**
- Solution: Run the full database-setup.sql first

**Error: "role does not exist"**
- Solution: Check your database connection string

**Error: "table already exists"**
- Solution: This is OK! The table was already created

### Alternative: Direct SQL
If you prefer to run SQL directly in Neon console:

```sql
-- Copy and paste this into Neon SQL Editor
CREATE TABLE IF NOT EXISTS challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_username VARCHAR(50) NOT NULL REFERENCES users(username) ON DELETE CASCADE,
    to_username VARCHAR(50) NOT NULL REFERENCES users(username) ON DELETE CASCADE,
    session_id UUID REFERENCES game_sessions(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
    created_at TIMESTAMP DEFAULT NOW(),
    responded_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_challenges_from ON challenges(from_username);
CREATE INDEX IF NOT EXISTS idx_challenges_to ON challenges(to_username);
CREATE INDEX IF NOT EXISTS idx_challenges_status ON challenges(status);
CREATE INDEX IF NOT EXISTS idx_challenges_created ON challenges(created_at DESC);
```

## Post-Migration Steps

1. ✅ Verify table exists
2. ✅ Check Netlify functions deployed (already done)
3. ✅ Rebuild mobile app
4. ✅ Test challenge feature

## Support

- Neon Dashboard: https://console.neon.tech/
- Netlify Dashboard: https://app.netlify.com/sites/tokerrgjik
- Function Logs: https://app.netlify.com/projects/tokerrgjik/logs/functions
