# Email SMTP Configuration Guide

## Setup Gmail for Sending Emails

### 1. Enable 2-Step Verification on Gmail
1. Go to https://myaccount.google.com/security
2. Enable **2-Step Verification**

### 2. Generate App Password
1. Go to https://myaccount.google.com/apppasswords
2. Select app: **Mail**
3. Select device: **Other (Custom name)**
4. Enter name: **Tokerrgjik App**
5. Click **Generate**
6. **Copy the 16-character password** (format: xxxx xxxx xxxx xxxx)

### 3. Configure Environment Variables

#### For Netlify (Production):
1. Go to **Netlify Dashboard** → **Site Settings** → **Environment Variables**
2. Add these variables:
   ```
   APP_PASSWORD=your-16-character-app-password
   FROM_EMAIL=your-email@gmail.com
   FROM_NAME=Tokerrgjik Game
   ```

#### For Local Testing (.env file):
Already configured in your `.env` file:
```properties
APP_PASSWORD=ztyl dmzc ficd fcgi
FROM_EMAIL=your-email@gmail.com  # Add this
```

### 4. Update Netlify Functions Package

The `nodemailer` package has been added to `netlify/functions/package.json`.

When you push to GitHub, Netlify will automatically install it.

### 5. Test Email Sending

#### Method 1: Through the App
1. Register a new user with a real email
2. Check if you receive the welcome email

#### Method 2: Test Function Directly
Use this curl command (replace values):
```bash
curl -X POST https://tokerrgjik.netlify.app/.netlify/functions/email \
  -H "Content-Type: application/json" \
  -d '{
    "type": "welcome",
    "username": "test_user",
    "data": {}
  }'
```

### 6. Supported Email Types

The email function supports these types:

| Type | Description | Data Required |
|------|-------------|---------------|
| `welcome` | New user registration | None |
| `pro_purchase` | PRO subscription | `months`, `amount` |
| `coins_purchase` | Coins purchase | `coins`, `amount` |
| `password_reset` | Password reset link | `reset_token` |
| `friend_request` | Friend request | `from_username` |
| `game_invite` | Game invitation | `from_username` |
| `achievement_unlocked` | New achievement | `achievement_title`, `achievement_icon`, `achievement_description` |

### 7. Troubleshooting

#### Emails not sending?
1. Check Netlify function logs:
   - Go to **Netlify Dashboard** → **Functions** → **email**
   - Click on a recent invocation
   - Look for error messages

2. Common issues:
   - ❌ **Invalid credentials**: Double-check `APP_PASSWORD` and `FROM_EMAIL`
   - ❌ **Less secure app access**: Must use App Password, not regular password
   - ❌ **Gmail blocking**: Check your Gmail account for security alerts

#### Still not working?
- Verify 2-Step Verification is enabled
- Generate a new App Password
- Make sure the App Password has no spaces when setting in environment variables
- Check that `FROM_EMAIL` matches the Gmail account used

### 8. Testing Locally with Netlify Dev

To test the email function locally:

```bash
# Install Netlify CLI (if not installed)
npm install -g netlify-cli

# Navigate to project root
cd C:\Users\shaban.ejupi\Desktop\Projektet\TokerrGjik

# Start Netlify Dev server
netlify dev

# The functions will be available at:
# http://localhost:8888/.netlify/functions/email
```

Then test with:
```bash
curl -X POST http://localhost:8888/.netlify/functions/email \
  -H "Content-Type: application/json" \
  -d '{
    "type": "welcome",
    "username": "your_actual_username",
    "data": {}
  }'
```

### 9. Security Notes

✅ **Good practices:**
- App passwords are safer than regular passwords
- They can be revoked anytime
- They're specific to one application

❌ **Never:**
- Commit `.env` to Git (it's in `.gitignore`)
- Share your App Password
- Use your regular Gmail password in code

### 10. Alternative Email Services

If Gmail doesn't work, you can use:

#### SendGrid (Free tier: 100 emails/day)
```javascript
// In email.mjs
import sgMail from '@sendgrid/mail';
sgMail.setApiKey(process.env.SENDGRID_API_KEY);
```

#### Mailgun (Free tier: 1000 emails/month)
#### AWS SES (Free tier: 62,000 emails/month for first year)

---

## Current Status

✅ Email function configured with nodemailer  
✅ Gmail SMTP support added  
⚠️ Need to set `FROM_EMAIL` in environment variables  
⚠️ Need to add GitHub secret `APP_PASSWORD` for CI/CD  

## Next Steps

1. **Add `FROM_EMAIL` to your `.env` file**
2. **Add GitHub Secrets** (for CI/CD):
   - Go to GitHub Repository → Settings → Secrets and variables → Actions
   - Add: `APP_PASSWORD`
   - Add: `FROM_EMAIL`
3. **Push changes** to GitHub
4. **Test** email sending through the app
