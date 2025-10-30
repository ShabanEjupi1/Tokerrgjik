# 🚀 Tokerrgjik Quick Setup Script
# Run this in PowerShell to configure your deployment

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "🎮 Tokerrgjik Deployment Setup" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Check if Netlify CLI is installed
Write-Host "Checking Netlify CLI..." -ForegroundColor Yellow
if (!(Get-Command netlify -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Netlify CLI not found. Installing..." -ForegroundColor Red
    npm install -g netlify-cli
} else {
    Write-Host "✅ Netlify CLI installed" -ForegroundColor Green
}

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "📝 STEP 1: Netlify Login" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Cyan
netlify login

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "🔗 STEP 2: Link to Site" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Cyan
netlify link

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "🔑 STEP 3: Environment Variables" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# HuggingFace Token
Write-Host "Opening HuggingFace token page..." -ForegroundColor Yellow
Start-Process "https://huggingface.co/settings/tokens"
Write-Host ""
Write-Host "1. Create a new token with READ permission" -ForegroundColor Cyan
Write-Host "2. Copy the token (starts with hf_...)" -ForegroundColor Cyan
Write-Host ""
$hfToken = Read-Host "Paste your HuggingFace token here (or press Enter to skip)"

if ($hfToken) {
    netlify env:set HUGGINGFACE_TOKEN $hfToken
    Write-Host "✅ HuggingFace token set!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Skipped - AI will use fallback logic" -ForegroundColor Yellow
}

Write-Host ""

# JWT Secret
Write-Host "Generating JWT secret..." -ForegroundColor Yellow
$jwtSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
netlify env:set JWT_SECRET $jwtSecret
Write-Host "✅ JWT secret generated and set!" -ForegroundColor Green

Write-Host ""

# PayPal Configuration
Write-Host "Do you want to configure PayPal payments? (y/n)" -ForegroundColor Yellow
$configPaypal = Read-Host

if ($configPaypal -eq "y") {
    Write-Host ""
    Write-Host "Opening PayPal Developer Dashboard..." -ForegroundColor Yellow
    Start-Process "https://developer.paypal.com/dashboard/applications/sandbox"
    Write-Host ""
    
    $paypalMode = Read-Host "PayPal Mode (sandbox/production) [default: sandbox]"
    if (!$paypalMode) { $paypalMode = "sandbox" }
    
    $paypalClientId = Read-Host "PayPal Client ID"
    $paypalSecret = Read-Host "PayPal Secret"
    
    if ($paypalClientId -and $paypalSecret) {
        netlify env:set PAYPAL_MODE $paypalMode
        netlify env:set PAYPAL_CLIENT_ID $paypalClientId
        netlify env:set PAYPAL_SECRET $paypalSecret
        Write-Host "✅ PayPal configured!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  PayPal configuration incomplete - skipped" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  PayPal payments disabled" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "📦 STEP 4: Install Dependencies" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Cyan

Push-Location netlify/functions
npm install
Pop-Location
Write-Host "✅ Dependencies installed!" -ForegroundColor Green

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "🚀 STEP 5: Deploy!" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ready to deploy? (y/n)" -ForegroundColor Yellow
$deploy = Read-Host

if ($deploy -eq "y") {
    Write-Host "Committing changes..." -ForegroundColor Yellow
    git add .
    git commit -m "Configure deployment with AI, auth, and payment fixes"
    
    Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
    git push origin main
    
    Write-Host ""
    Write-Host "✅ Pushed! Netlify will deploy automatically." -ForegroundColor Green
    Write-Host "Check deployment status: https://app.netlify.com/" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Deployment skipped. Run these commands when ready:" -ForegroundColor Yellow
    Write-Host "  git add ." -ForegroundColor Cyan
    Write-Host "  git commit -m 'Deploy fixes'" -ForegroundColor Cyan
    Write-Host "  git push origin main" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "✅ Setup Complete!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📚 For more details, see DEPLOYMENT_GUIDE.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "Current environment variables:" -ForegroundColor Yellow
netlify env:list

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
