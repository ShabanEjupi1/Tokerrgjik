# 🚀 QUICK START - IMMEDIATE ACTION REQUIRED

## ⚡ Run This Now to Fix Everything

Open PowerShell in this directory and run:

```powershell
.\setup-deployment.ps1
```

This script will:
1. ✅ Install/verify Netlify CLI
2. ✅ Login to Netlify
3. ✅ Link your site
4. ✅ Set up environment variables (HuggingFace, JWT, PayPal)
5. ✅ Install dependencies
6. ✅ Deploy to production

**Time needed**: ~5 minutes

---

## 🔑 What You'll Need

### 1. HuggingFace Token (for Smart AI)
- The script will open https://huggingface.co/settings/tokens
- Click "New token" → Name: `Tokerrgjik` → Type: **Read**
- Copy the token (starts with `hf_...`)

### 2. PayPal Credentials (if using payments)
- Get from: https://developer.paypal.com/dashboard/
- You'll need: Client ID and Secret

### 3. Neon Database URL
- Should already be set in Netlify
- Format: `postgresql://user:pass@host/db?sslmode=require`

---

## 🛠️ Manual Setup (if script fails)

```powershell
# 1. Login
netlify login

# 2. Link site
netlify link

# 3. Set environment variables
netlify env:set HUGGINGFACE_TOKEN "hf_your_token"
netlify env:set JWT_SECRET "random-32-char-string"
netlify env:set PAYPAL_MODE "sandbox"
netlify env:set PAYPAL_CLIENT_ID "your_client_id"
netlify env:set PAYPAL_SECRET "your_secret"

# 4. Install dependencies
cd netlify/functions
npm install
cd ../..

# 5. Deploy
git add .
git commit -m "Fix all deployment issues"
git push origin main
```

---

## 📋 What Was Fixed

✅ **Netlify deployment** - Functions now deploy properly  
✅ **AI intelligence** - Uses Hugging Face Mixtral model  
✅ **Multi-device login** - JWT tokens work across devices  
✅ **Statistics/Leaderboard** - Queries fixed, error handling added  
✅ **Friend requests** - Validation and error messages improved  
✅ **Game sessions** - Creation errors fixed  
✅ **PayPal** - Better error logging and credential validation  

---

## 🧪 After Deployment - Test These

Replace `your-site.netlify.app` with your actual domain:

### Test AI
```powershell
curl -X POST https://your-site.netlify.app/.netlify/functions/ai-move `
  -H "Content-Type: application/json" `
  -d '{"board":[null,null,null,null,null,null,null,null,null],"phase":"placing","player":2,"difficulty":"medium"}'
```

### Test Login
```powershell
curl -X POST https://your-site.netlify.app/.netlify/functions/auth `
  -H "Content-Type: application/json" `
  -d '{"action":"login","username":"test","password":"test123","device_id":"device1"}'
```

### Test Leaderboard
```powershell
curl https://your-site.netlify.app/.netlify/functions/leaderboard
```

---

## 🆘 Troubleshooting

### "Functions not updating after deploy"
```powershell
# Clear Netlify cache and redeploy
netlify build --clear-cache
git commit --allow-empty -m "Force redeploy"
git push
```

### "Database tables don't exist"
1. Open Neon Console: https://console.neon.tech/
2. Select your project → SQL Editor
3. Run the SQL from `database-schema.sql` file

### "AI returns fallback logic"
- Check: `netlify env:list` - should show HUGGINGFACE_TOKEN
- Verify token at: https://huggingface.co/settings/tokens
- Check function logs in Netlify dashboard

### "PayPal always fails"
- Verify credentials: `netlify env:list`
- Check you're using SANDBOX mode for testing
- View detailed errors in Netlify function logs

---

## 📚 More Info

- **Full Guide**: `DEPLOYMENT_GUIDE.md`
- **Database Schema**: `database-schema.sql`
- **Function Logs**: Netlify Dashboard → Functions → Logs

---

**Ready?** Run `.\setup-deployment.ps1` now! 🚀
