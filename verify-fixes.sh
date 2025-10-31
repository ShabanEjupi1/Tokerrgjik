#!/bin/bash

echo "╔════════════════════════════════════════════════╗"
echo "║     BUILD & EMAIL FIX VERIFICATION             ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Check 1: NDK Version in build.gradle.kts
echo "1️⃣  Checking NDK version..."
if grep -q 'ndkVersion = "27.0.12077973"' tokerrgjik_mobile/android/app/build.gradle.kts; then
    echo "   ✅ NDK version set to 27.0.12077973"
else
    echo "   ❌ NDK version NOT updated"
fi

# Check 2: ProGuard file exists
echo ""
echo "2️⃣  Checking ProGuard rules..."
if [ -f "tokerrgjik_mobile/android/app/proguard-rules.pro" ]; then
    echo "   ✅ ProGuard rules file exists"
    if grep -q "stripe.android.pushProvisioning" tokerrgjik_mobile/android/app/proguard-rules.pro; then
        echo "   ✅ Stripe push provisioning rules present"
    else
        echo "   ❌ Stripe rules missing"
    fi
else
    echo "   ❌ ProGuard rules file NOT found"
fi

# Check 3: ProGuard enabled in build.gradle.kts
echo ""
echo "3️⃣  Checking ProGuard configuration..."
if grep -q "isMinifyEnabled = true" tokerrgjik_mobile/android/app/build.gradle.kts; then
    echo "   ✅ Minification enabled"
else
    echo "   ❌ Minification NOT enabled"
fi

# Check 4: Email function improvements
echo ""
echo "4️⃣  Checking email function..."
if grep -q "JSON.stringify(req.body" netlify/functions/email.mjs; then
    echo "   ✅ Improved logging added"
else
    echo "   ❌ Logging NOT improved"
fi

# Check 5: Environment variables
echo ""
echo "5️⃣  Checking .env file..."
if [ -f ".env" ]; then
    echo "   ✅ .env file exists"
    if grep -q "APP_PASSWORD=" .env; then
        echo "   ✅ APP_PASSWORD set in .env"
    else
        echo "   ❌ APP_PASSWORD missing in .env"
    fi
    if grep -q "FROM_EMAIL=" .env; then
        echo "   ✅ FROM_EMAIL set in .env"
    else
        echo "   ❌ FROM_EMAIL missing in .env"
    fi
else
    echo "   ❌ .env file NOT found"
fi

echo ""
echo "═══════════════════════════════════════════════"
echo "Verification complete!"
echo "═══════════════════════════════════════════════"
echo ""
echo "📋 NEXT STEPS:"
echo ""
echo "1. Commit and push changes:"
echo "   git add ."
echo "   git commit -m \"Fix: Android NDK version & Stripe ProGuard rules\""
echo "   git push"
echo ""
echo "2. Set Netlify environment variables:"
echo "   - Go to Netlify Dashboard"
echo "   - Site Settings → Environment Variables"
echo "   - Add: APP_PASSWORD, FROM_EMAIL, SMTP_HOST, SMTP_PORT"
echo ""
echo "3. Test email function:"
echo "   node test-email.js"
echo ""
