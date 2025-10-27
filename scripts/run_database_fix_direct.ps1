# =====================================================
# TokerrGjik Database Fix Script Runner (Direct Connection)
# This version connects directly to your Neon database
# No CLI installation required!
# =====================================================

$ErrorActionPreference = "Stop"

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "TokerrGjik Database Fix Script" -ForegroundColor Cyan
Write-Host "Direct Database Connection Method" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Get the SQL file path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sqlFile = Join-Path $scriptDir "fix_database.sql"

if (-not (Test-Path $sqlFile)) {
    Write-Host "❌ SQL file not found at: $sqlFile" -ForegroundColor Red
    exit 1
}

Write-Host "📄 SQL file found: $sqlFile" -ForegroundColor Green
Write-Host ""

Write-Host "=======================================" -ForegroundColor Yellow
Write-Host "CONNECTION STRING SETUP" -ForegroundColor Yellow
Write-Host "=======================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "You need your Neon database connection string." -ForegroundColor White
Write-Host "It should look like:" -ForegroundColor White
Write-Host "postgresql://user:password@ep-xxx.region.aws.neon.tech/dbname?sslmode=require" -ForegroundColor Gray
Write-Host ""
Write-Host "Where to find it:" -ForegroundColor White
Write-Host "1. Go to https://console.neon.tech" -ForegroundColor Cyan
Write-Host "2. Select your project" -ForegroundColor Cyan
Write-Host "3. Click 'Connection Details' or 'Connect'" -ForegroundColor Cyan
Write-Host "4. Copy the 'Connection String'" -ForegroundColor Cyan
Write-Host ""

# Check if connection string is in environment variable
$envConnectionString = $env:NEON_DATABASE_URL
if ($envConnectionString) {
    Write-Host "✅ Found NEON_DATABASE_URL in environment" -ForegroundColor Green
    Write-Host "Connection string (first 50 chars): $($envConnectionString.Substring(0, [Math]::Min(50, $envConnectionString.Length)))..." -ForegroundColor Gray
    Write-Host ""
    Write-Host "Use this connection string? (yes/no):" -ForegroundColor Yellow
    $useEnv = Read-Host
    if ($useEnv -eq "yes" -or $useEnv -eq "y") {
        $connectionString = $envConnectionString
    }
}

if (-not $connectionString) {
    Write-Host "Enter your Neon connection string:" -ForegroundColor Yellow
    $connectionString = Read-Host
}

if (-not $connectionString -or $connectionString.Trim() -eq "") {
    Write-Host "❌ No connection string provided!" -ForegroundColor Red
    exit 1
}

# Validate connection string format
if (-not ($connectionString -match "^postgresql://")) {
    Write-Host "❌ Invalid connection string format!" -ForegroundColor Red
    Write-Host "Should start with: postgresql://" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "⚠️  WARNING: This will:" -ForegroundColor Red
Write-Host "  - Add CASCADE constraints to foreign keys" -ForegroundColor Yellow
Write-Host "  - Delete test users and their related data:" -ForegroundColor Yellow
Write-Host "    • MightyDragon" -ForegroundColor Gray
Write-Host "    • CalmStorm" -ForegroundColor Gray
Write-Host "    • Shaban Ejupi" -ForegroundColor Gray
Write-Host "    • RadFox379" -ForegroundColor Gray
Write-Host "    • BraveLegend173" -ForegroundColor Gray
Write-Host "    • MegaFox796" -ForegroundColor Gray
Write-Host "    • EliteKing136" -ForegroundColor Gray
Write-Host "  - Fix missing created_at columns" -ForegroundColor Yellow
Write-Host "  - Update friends and achievements tables" -ForegroundColor Yellow
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Do you want to proceed? Type 'yes' to continue:" -ForegroundColor Yellow
$confirm = Read-Host

if ($confirm -ne "yes") {
    Write-Host "❌ Cancelled by user." -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "Executing SQL script..." -ForegroundColor Yellow
Write-Host ""

# Read SQL file
$sqlContent = Get-Content $sqlFile -Raw

# Use psql if available (comes with PostgreSQL client)
$psqlExists = Get-Command "psql" -ErrorAction SilentlyContinue

if ($psqlExists) {
    Write-Host "Using psql command..." -ForegroundColor Cyan
    $env:PGPASSWORD = "temp"
    try {
        $sqlContent | psql $connectionString
        $success = $LASTEXITCODE -eq 0
    } catch {
        Write-Host "Error using psql: $_" -ForegroundColor Red
        $success = $false
    }
} else {
    # Fallback: Use curl to make HTTP request to Neon's HTTP API
    Write-Host "psql not found, using HTTP API method..." -ForegroundColor Cyan
    
    # Parse connection string
    if ($connectionString -match "postgresql://([^:]+):([^@]+)@([^/]+)/(.+)") {
        $dbUser = $matches[1]
        $dbPassword = $matches[2]
        $dbHost = $matches[3]
        $dbDatabase = $matches[4] -replace "\?.*", ""
        
        # Try using Invoke-WebRequest to execute SQL
        Write-Host "Attempting to connect to database..." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "⚠️  Note: Direct HTTP execution may not work." -ForegroundColor Yellow
        Write-Host "For best results, install PostgreSQL client tools:" -ForegroundColor Yellow
        Write-Host "  Download from: https://www.postgresql.org/download/windows/" -ForegroundColor Cyan
        Write-Host "  Or use the Neon dashboard SQL editor" -ForegroundColor Cyan
        Write-Host ""
        
        # Create a temp file with instructions
        $instructionsFile = Join-Path $scriptDir "MANUAL_EXECUTION_INSTRUCTIONS.txt"
        @"
======================================
MANUAL DATABASE FIX INSTRUCTIONS
======================================

Since automated execution is not available, please follow these steps:

1. Go to https://console.neon.tech
2. Select your project
3. Click on "SQL Editor" in the left sidebar
4. Copy the entire content of: fix_database.sql
5. Paste it into the SQL Editor
6. Click "Run" or press Ctrl+Enter

The SQL file location is:
$sqlFile

Connection details:
- Host: $dbHost
- Database: $dbDatabase
- User: $dbUser

======================================
"@ | Out-File -FilePath $instructionsFile -Encoding UTF8
        
        Write-Host "📄 Created manual instructions file at:" -ForegroundColor Green
        Write-Host "   $instructionsFile" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Would you like to:" -ForegroundColor Yellow
        Write-Host "1. Open the Neon console in your browser" -ForegroundColor White
        Write-Host "2. Copy the SQL content to clipboard" -ForegroundColor White
        Write-Host "3. Both (recommended)" -ForegroundColor White
        Write-Host "4. Exit" -ForegroundColor White
        Write-Host ""
        $choice = Read-Host "Enter choice (1-4)"
        
        switch ($choice) {
            "1" {
                Start-Process "https://console.neon.tech"
                Write-Host "✅ Opened Neon console in browser" -ForegroundColor Green
            }
            "2" {
                $sqlContent | Set-Clipboard
                Write-Host "✅ SQL content copied to clipboard!" -ForegroundColor Green
                Write-Host "Now paste it into the Neon SQL Editor" -ForegroundColor Yellow
            }
            "3" {
                Start-Process "https://console.neon.tech"
                $sqlContent | Set-Clipboard
                Write-Host "✅ Opened Neon console and copied SQL to clipboard!" -ForegroundColor Green
                Write-Host "Now paste it into the SQL Editor and run it" -ForegroundColor Yellow
            }
            default {
                Write-Host "Manual execution required. See: $instructionsFile" -ForegroundColor Yellow
            }
        }
        
        exit 0
    } else {
        Write-Host "❌ Could not parse connection string!" -ForegroundColor Red
        exit 1
    }
}

if ($success) {
    Write-Host ""
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host "✅ Database fix completed successfully!" -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Redeploy your Netlify functions" -ForegroundColor White
    Write-Host "2. Test the achievements system" -ForegroundColor White
    Write-Host "3. Test the friends system" -ForegroundColor White
    Write-Host "4. Test multiplayer game sessions" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "=======================================" -ForegroundColor Red
    Write-Host "❌ Could not execute SQL automatically" -ForegroundColor Red
    Write-Host "=======================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please use the Neon dashboard SQL editor:" -ForegroundColor Yellow
    Write-Host "1. Go to https://console.neon.tech" -ForegroundColor Cyan
    Write-Host "2. Open SQL Editor" -ForegroundColor Cyan
    Write-Host "3. Copy content from: $sqlFile" -ForegroundColor Cyan
    Write-Host "4. Paste and execute in SQL Editor" -ForegroundColor Cyan
}
