# Quick Cryptolens Commands
# Use these commands to manage your licenses

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Cryptolens License Management - TokerrGjik" -ForegroundColor Yellow  
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Product ID: 31344" -ForegroundColor Green
Write-Host "Access Token: WyIxMTM3MTkwMjIiLCIzdEpPaTM1VjN5Q2V4R3lHTHVGTnJnVUdGQ21mb2N5TkZxYmJ0cnN0Il0=" -ForegroundColor Green
Write-Host ""

Write-Host "=== WEB DASHBOARD (EASIEST) ===" -ForegroundColor Yellow
Write-Host "Opening Cryptolens Dashboard..." -ForegroundColor Cyan
Start-Process "https://app.cryptolens.io/Product/31344"
Write-Host "Dashboard opened in browser!" -ForegroundColor Green
Write-Host ""

Write-Host "In the dashboard you can:" -ForegroundColor Cyan
Write-Host "  1. Click 'Create Key' to generate new licenses"
Write-Host "  2. View all existing keys and their status"
Write-Host "  3. Block/Unblock keys"
Write-Host "  4. See machine activations"
Write-Host "  5. Manage license features"
Write-Host ""

Write-Host "=== PYTHON CLI (ALTERNATIVE) ===" -ForegroundColor Yellow
Write-Host "The cryptolens CLI has compatibility issues with Python 3.11+"
Write-Host "Recommended: Use the web dashboard above"
Write-Host ""
Write-Host "Or downgrade Python to 3.9 and reinstall:"
Write-Host "  pip uninstall cryptolens"
Write-Host "  pip install cryptolens"
Write-Host ""

Write-Host "=== YOUR APP INTEGRATION ===" -ForegroundColor Yellow
Write-Host "Your Flutter app already integrates with Cryptolens:" -ForegroundColor Cyan
Write-Host "  - License validation in CryptolensService"
Write-Host "  - RSA signature verification"
Write-Host "  - Machine activation (max 2 devices)"
Write-Host "  - Feature flags (F1 = Pro access)"
Write-Host ""

Write-Host "License purchase page:" -ForegroundColor Cyan
Write-Host "  https://tokerrgjik.netlify.app/license.html"
Write-Host ""

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
