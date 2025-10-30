# 🌐 Netlify Setup via Web Dashboard (No CLI Needed!)

Since Node.js isn't installed, you can configure everything through Netlify's web dashboard!

## 🚀 Quick Setup Steps

### Step 1: Open Netlify Dashboard
1. Go to: https://app.netlify.com/
2. Login to your account
3. Find your "Tokerrgjik" site

### Step 2: Set Environment Variables

Click: **Site Settings** → **Environment Variables** → **Add a variable**

Add these one by one:

#### 🔑 JWT Secret (REQUIRED)
```
Variable: JWT_SECRET
Value: your-super-secret-jwt-key-min-32-characters-long-random-string
```
*(Generate a random 32+ character string)*

#### 🤖 HuggingFace Token (REQUIRED for Smart AI)
1. Get token: https://huggingface.co/settings/tokens
2. Click "New token" → Name: `Tokerrgjik` → Type: **Read**
3. Copy the token (starts with `hf_...`)

```
Variable: HUGGINGFACE_TOKEN
Value: hf_your_actual_token_here
```

#### 💳 PayPal (Optional - for payments)
```
Variable: PAYPAL_MODE
Value: sandbox

Variable: PAYPAL_CLIENT_ID
Value: your_paypal_client_id_from_developer_dashboard

Variable: PAYPAL_SECRET
Value: your_paypal_secret_from_developer_dashboard
```

Get PayPal credentials: https://developer.paypal.com/dashboard/

#### 🗄️ Database (Should already be set)
```
Variable: NEON_DATABASE_URL
Value: postgresql://username:password@hostname/database?sslmode=require
```

### Step 3: Deploy

After adding environment variables:

1. Go to: **Deploys** tab
2. Click: **Trigger deploy** → **Deploy site**

OR just push to GitHub:

```powershell
cd C:\Users\shaban.ejupi\Desktop\Projektet\TokerrGjik
git add .
git commit -m "Fix deployment, AI, auth, and payment issues"
git push origin main
```

Netlify will auto-deploy! ⚡

---

## ✅ Verification

After deploy completes (2-3 minutes):

### Check Environment Variables are Set
Netlify Dashboard → Site Settings → Environment Variables

You should see:
- ✅ `NEON_DATABASE_URL`
- ✅ `JWT_SECRET`
- ✅ `HUGGINGFACE_TOKEN`
- ✅ `PAYPAL_MODE` (if using payments)
- ✅ `PAYPAL_CLIENT_ID` (if using payments)
- ✅ `PAYPAL_SECRET` (if using payments)

### Test Endpoints

Replace `your-site-name` with your actual Netlify site name:

**Test AI:**
```
https://tokerrgjik.netlify.app/.netlify/functions/ai-move
```

**Test Auth:**
```
https://tokerrgjik.netlify.app/.netlify/functions/auth
```

**Test Leaderboard:**
```
https://tokerrgjik.netlify.app/.netlify/functions/leaderboard
```

---

## 🎯 Generate JWT Secret

Need a secure random string? Use this PowerShell command:

```powershell
-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
```

Copy the output and use it as your `JWT_SECRET`

---

## 📱 After Deployment

Make sure your Flutter app points to the correct URL:

**File**: `tokerrgjik_mobile/lib/config/api_keys.dart`

```dart
static const String currentServerUrl = 
  'https://your-site-name.netlify.app/.netlify/functions';
```

---

## 🆘 Troubleshooting

### Can't find environment variables section?
- Look for: **Site Settings** → **Build & Deploy** → **Environment**
- Or: **Site Settings** → **Environment Variables** (newer UI)

### Deploy failed?
- Check: **Deploys** → Click on failed deploy → **Deploy log**
- Look for error messages
- Common issues:
  - Missing dependencies (should be fixed now)
  - Build command failed (check `netlify.toml`)

### Functions not working?
- Check: **Functions** tab → Click function name → **Function log**
- Look for runtime errors
- Verify environment variables are set

---

## ✅ You're Done!

Once environment variables are set and deploy succeeds:

1. ✅ AI will use Hugging Face (smart moves!)
2. ✅ Multi-device login will work
3. ✅ Statistics/leaderboard will show data
4. ✅ Friend requests will function properly
5. ✅ Game sessions will create successfully
6. ✅ PayPal will work (if configured)

All without installing Node.js or CLI! 🎉
