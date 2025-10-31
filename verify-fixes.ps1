# Build & Email Fix Verification Script (PowerShell)

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "     BUILD & EMAIL FIX VERIFICATION             " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

# Check 1: NDK Version
Write-Host "1. Checking NDK version..." -ForegroundColor Yellow
$buildGradle = Get-Content "tokerrgjik_mobile\android\app\build.gradle.kts" -Raw
if ($buildGradle -match 'ndkVersion = "27\.0\.12077973"') {
    Write-Host "   SUCCESS NDK version set to 27.0.12077973" -ForegroundColor Green
} else {
    Write-Host "   FAILED NDK version NOT updated" -ForegroundColor Red
}

# Check 2: ProGuard file
Write-Host ""
Write-Host "2. Checking ProGuard rules..." -ForegroundColor Yellow
if (Test-Path "tokerrgjik_mobile\android\app\proguard-rules.pro") {
    Write-Host "   SUCCESS ProGuard rules file exists" -ForegroundColor Green
    $proguard = Get-Content "tokerrgjik_mobile\android\app\proguard-rules.pro" -Raw
    if ($proguard -match "stripe\.android\.pushProvisioning") {
        Write-Host "   SUCCESS Stripe push provisioning rules present" -ForegroundColor Green
    } else {
        Write-Host "   FAILED Stripe rules missing" -ForegroundColor Red
    }
} else {
    Write-Host "   FAILED ProGuard rules file NOT found" -ForegroundColor Red
}

# Check 3: Minification enabled
Write-Host ""
Write-Host "3. Checking ProGuard configuration..." -ForegroundColor Yellow
if ($buildGradle -match 'isMinifyEnabled = true') {
    Write-Host "   SUCCESS Minification enabled" -ForegroundColor Green
} else {
    Write-Host "   FAILED Minification NOT enabled" -ForegroundColor Red
}

# Check 4: Email function
Write-Host ""
Write-Host "4. Checking email function..." -ForegroundColor Yellow
$emailFunc = Get-Content "netlify\functions\email.mjs" -Raw
if ($emailFunc -match "JSON\.stringify\(req\.body") {
    Write-Host "   SUCCESS Improved logging added" -ForegroundColor Green
} else {
    Write-Host "   FAILED Logging NOT improved" -ForegroundColor Red
}

# Check 5: Environment variables
Write-Host ""
Write-Host "5. Checking .env file..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Write-Host "   SUCCESS .env file exists" -ForegroundColor Green
    $env = Get-Content ".env" -Raw
    if ($env -match "APP_PASSWORD=") {
        Write-Host "   SUCCESS APP_PASSWORD set in .env" -ForegroundColor Green
    } else {
        Write-Host "   FAILED APP_PASSWORD missing in .env" -ForegroundColor Red
    }
    if ($env -match "FROM_EMAIL=") {
        Write-Host "   SUCCESS FROM_EMAIL set in .env" -ForegroundColor Green
    } else {
        Write-Host "   FAILED FROM_EMAIL missing in .env" -ForegroundColor Red
    }
} else {
    Write-Host "   FAILED .env file NOT found" -ForegroundColor Red
}

Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "Verification complete!" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Commit and push changes:" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor Cyan
Write-Host "   git commit -m `"Fix: Android NDK version & Stripe ProGuard rules`"" -ForegroundColor Cyan
Write-Host "   git push" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Set Netlify environment variables:" -ForegroundColor White
Write-Host "   - Go to Netlify Dashboard" -ForegroundColor Cyan
Write-Host "   - Site Settings -> Environment Variables" -ForegroundColor Cyan
Write-Host "   - Add: APP_PASSWORD, FROM_EMAIL, SMTP_HOST, SMTP_PORT" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Test email function:" -ForegroundColor White
Write-Host "   node test-email.js" -ForegroundColor Cyan
Write-Host ""
