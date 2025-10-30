# 🚀 Tokerrgjik Netlify Deployment & Configuration Guide

## 🔧 Critical Fixes Applied

### 1. ✅ Netlify Deployment Fixed
- Updated `package.json` with required dependencies
- Added proper build commands to `netlify.toml`
- Added `"type": "module"` for ES6 support

### 2. 🤖 AI Intelligence Upgrade (Hugging Face)
- Created `ai-move.mjs` serverless function
- Integrated Mixtral-8x7B-Instruct model for smart gameplay
- Added enhanced fallback AI for offline scenarios

### 3. 🔐 Multi-Device Login Fixed
- Implemented proper JWT tokens with `jsonwebtoken` library
- Added device ID tracking for multi-device support
- Tokens now last 30 days with secure validation

### 4. 📊 Statistics & Leaderboard Fixed
- Verified database queries are correct
- Added error handling and debugging logs
- Ensured proper data aggregation

### 5. 👥 Friend Requests Fixed
- Added user existence validation
- Improved error messages
- Better status tracking

### 6. 🎮 Game Session Creation Fixed
- Added comprehensive user validation
- Proper error handling and detailed error messages
- Fixed database insertion with proper initial state

### 7. 💳 PayPal Integration Enhanced
- Added detailed error logging
- Better credential validation
- Improved error messages for debugging

---

## 🌐 Required Netlify Environment Variables

You MUST add these in **Netlify Dashboard** → **Site Settings** → **Environment Variables**:

### **Database (REQUIRED)**
```
NEON_DATABASE_URL=postgresql://username:password@hostname/database?sslmode=require
```

### **Authentication (REQUIRED)**
```
JWT_SECRET=your-super-secret-jwt-key-min-32-characters-long
```

### **Hugging Face AI (REQUIRED for Smart AI)**
```
HUGGINGFACE_TOKEN=hf_your_token_here
```

### **PayPal (REQUIRED for Payments)**
```
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_SECRET=your_paypal_secret
PAYPAL_MODE=sandbox
```
*(Change `PAYPAL_MODE` to `production` when going live)*

---

## 📋 Step-by-Step Setup

### **Step 1: Get Hugging Face Token**
Run this in your terminal to get your HF token:

```powershell
# Open Hugging Face settings
Start-Process "https://huggingface.co/settings/tokens"
```

1. Click **"New token"**
2. Name it: `Tokerrgjik AI`
3. Type: **Read**
4. Copy the token (starts with `hf_...`)

### **Step 2: Configure Netlify Environment Variables**

Run these commands in PowerShell **one by one**, replacing the values:

```powershell
# Install Netlify CLI if not installed
npm install -g netlify-cli

# Login to Netlify
netlify login

# Link to your site
cd C:\Users\shaban.ejupi\Desktop\Projektet\TokerrGjik
netlify link

# Set environment variables
netlify env:set HUGGINGFACE_TOKEN "hf_your_actual_token_here"
netlify env:set JWT_SECRET "your-super-secret-random-string-min-32-chars"
netlify env:set PAYPAL_MODE "sandbox"
netlify env:set PAYPAL_CLIENT_ID "your_paypal_client_id"
netlify env:set PAYPAL_SECRET "your_paypal_secret"
```

**⚠️ IMPORTANT:** Your Neon database URL should already be set. If not:
```powershell
netlify env:set NEON_DATABASE_URL "postgresql://username:password@hostname/database?sslmode=require"
```

### **Step 3: Install Dependencies**

```powershell
cd netlify/functions
npm install
cd ../..
```

### **Step 4: Deploy to Netlify**

```powershell
# Commit changes
git add .
git commit -m "Fix deployment, AI, auth, and payment issues"
git push origin main
```

Netlify will automatically deploy! 🎉

### **Step 5: Verify Deployment**

Check these URLs (replace with your Netlify domain):

1. **AI Endpoint**: `https://your-site.netlify.app/.netlify/functions/ai-move`
2. **Auth Endpoint**: `https://your-site.netlify.app/.netlify/functions/auth`
3. **Statistics**: `https://your-site.netlify.app/.netlify/functions/statistics/username`
4. **Leaderboard**: `https://your-site.netlify.app/.netlify/functions/leaderboard`

---

## 🧪 Testing

### Test AI Endpoint
```powershell
curl -X POST https://your-site.netlify.app/.netlify/functions/ai-move `
  -H "Content-Type: application/json" `
  -d '{"board":[null,null,null,null,null,null,null,null,null],"phase":"placing","player":2,"difficulty":"medium"}'
```

### Test Auth (Login)
```powershell
curl -X POST https://your-site.netlify.app/.netlify/functions/auth `
  -H "Content-Type: application/json" `
  -d '{"action":"login","username":"testuser","password":"test123","device_id":"device1"}'
```

---

## 🐛 Troubleshooting

### **Issue: AI returns fallback logic**
- ✅ Check: `netlify env:list` to verify HUGGINGFACE_TOKEN is set
- ✅ Check Netlify function logs for errors
- ✅ Verify token has "Read" permission on Hugging Face

### **Issue: PayPal always fails**
- ✅ Verify PAYPAL_CLIENT_ID and PAYPAL_SECRET are set
- ✅ For testing, use PAYPAL_MODE=sandbox
- ✅ Check Netlify function logs for detailed errors
- ✅ Test credentials in PayPal Developer Dashboard

### **Issue: Can't login on second device**
- ✅ This should now work! JWT tokens support multiple devices
- ✅ Clear app data on old device if issues persist
- ✅ Check that JWT_SECRET is set in Netlify

### **Issue: Statistics showing no data**
- ✅ Verify games are being saved with `game_history` table
- ✅ Check database connection in Netlify logs
- ✅ Ensure NEON_DATABASE_URL is correctly set

### **Issue: Friend requests not working**
- ✅ Both users must exist in database first (login/register)
- ✅ Check Netlify logs for detailed error messages
- ✅ Verify `friends` table exists in database

---

## 📱 Mobile App Configuration

Update your Flutter app's API configuration:

**File**: `tokerrgjik_mobile/lib/config/api_keys.dart`

```dart
static const String currentServerUrl = 'https://your-site.netlify.app/.netlify/functions';
```

---

## 🔄 Redeploying After Changes

Whenever you modify serverless functions:

```powershell
git add .
git commit -m "Your change description"
git push origin main
```

Netlify auto-deploys in ~2 minutes! ⚡

---

## 📞 Need Help?

1. Check **Netlify Function Logs**: Dashboard → Functions → Logs
2. Check **Netlify Build Logs**: Dashboard → Deploys → [Latest Deploy] → Deploy Log
3. Test endpoints with `curl` or Postman
4. Review error messages carefully - they now include detailed debugging info

---

## ✅ Checklist

- [ ] HuggingFace token obtained and set
- [ ] JWT_SECRET set in Netlify
- [ ] PayPal credentials set (if using payments)
- [ ] Database URL verified
- [ ] Code pushed to GitHub
- [ ] Netlify deployed successfully
- [ ] Tested AI endpoint
- [ ] Tested auth/login
- [ ] Tested on two devices (multi-login)
- [ ] Friend requests working
- [ ] Game sessions creating successfully
- [ ] Statistics showing data
- [ ] Leaderboard populated

---

**Last Updated**: 2025-10-30
**Version**: 2.0.0
