# Cryptolens License Manager for TokerrGjik
# PowerShell script to manage licenses via Cryptolens API

# Configuration
$CRYPTOLENS_ACCESS_TOKEN = "WyIxMTM3MTkwMjIiLCIzdEpPaTM1VjN5Q2V4R3lHTHVGTnJnVUdGQ21mb2N5TkZxYmJ0cnN0Il0="
$PRODUCT_ID = 31344

# API Base URL
$API_BASE = "https://app.cryptolens.io/api"

# Headers for all requests
$headers = @{
    "Content-Type" = "application/json"
}

function Get-CryptolensKeys {
    Write-Host "📋 Fetching all license keys..." -ForegroundColor Cyan
    
    $body = @{
        "token" = $CRYPTOLENS_ACCESS_TOKEN
        "ProductId" = $PRODUCT_ID
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$API_BASE/key/GetKeys" `
            -Method Post `
            -Headers $headers `
            -Body $body
        
        if ($response.result -eq 0) {
            Write-Host "✅ Success! Found $($response.licenses.Count) license keys`n" -ForegroundColor Green
            
            foreach ($license in $response.licenses) {
                $status = if ($license.Blocked) { "🔴 Blocked" } else { "🟢 Active" }
                $expiry = if ($license.Expires) { 
                    [DateTime]::Parse($license.Expires).ToString("yyyy-MM-dd") 
                } else { 
                    "Never" 
                }
                
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                Write-Host "Key: $($license.Key)" -ForegroundColor Yellow
                Write-Host "Status: $status"
                Write-Host "Created: $([DateTime]::Parse($license.Created).ToString('yyyy-MM-dd HH:mm'))"
                Write-Host "Expires: $expiry"
                Write-Host "Max Machines: $($license.MaxNoOfMachines)"
                Write-Host "Activated Machines: $($license.ActivatedMachines.Count)"
                Write-Host ""
            }
            
            return $response.licenses
        } else {
            Write-Host "❌ Error: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Failed to fetch keys: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function New-CryptolensKey {
    param(
        [int]$MaxMachines = 2,
        [int]$ValidDays = 365,
        [string]$Notes = ""
    )
    
    Write-Host "🔑 Creating new license key..." -ForegroundColor Cyan
    
    $body = @{
        "token" = $CRYPTOLENS_ACCESS_TOKEN
        "ProductId" = $PRODUCT_ID
        "Period" = $ValidDays
        "F1" = $true  # Feature 1: Pro Access
        "F2" = $false
        "F3" = $false
        "F4" = $false
        "F5" = $false
        "F6" = $false
        "F7" = $false
        "F8" = $false
        "MaxNoOfMachines" = $MaxMachines
        "Notes" = $Notes
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$API_BASE/key/CreateKey" `
            -Method Post `
            -Headers $headers `
            -Body $body
        
        if ($response.result -eq 0) {
            Write-Host "✅ License key created successfully!" -ForegroundColor Green
            Write-Host "🔑 Key: $($response.key)" -ForegroundColor Yellow
            Write-Host "📅 Valid for: $ValidDays days" -ForegroundColor Cyan
            Write-Host "💻 Max machines: $MaxMachines" -ForegroundColor Cyan
            
            # Copy to clipboard
            Set-Clipboard -Value $response.key
            Write-Host "✅ Key copied to clipboard!" -ForegroundColor Green
            
            return $response.key
        } else {
            Write-Host "❌ Error: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Failed to create key: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-KeyInfo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LicenseKey
    )
    
    Write-Host "🔍 Fetching key information..." -ForegroundColor Cyan
    
    $body = @{
        "token" = $CRYPTOLENS_ACCESS_TOKEN
        "ProductId" = $PRODUCT_ID
        "Key" = $LicenseKey
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$API_BASE/key/GetKey" `
            -Method Post `
            -Headers $headers `
            -Body $body
        
        if ($response.result -eq 0) {
            $license = $response.license
            $status = if ($license.Blocked) { "🔴 Blocked" } else { "🟢 Active" }
            
            Write-Host "`n━━━━━━━━━━━━━━━ License Details ━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            Write-Host "Key: $($license.Key)" -ForegroundColor Yellow
            Write-Host "Status: $status"
            Write-Host "Created: $([DateTime]::Parse($license.Created).ToString('yyyy-MM-dd HH:mm'))"
            Write-Host "Expires: $(if ($license.Expires) { [DateTime]::Parse($license.Expires).ToString('yyyy-MM-dd') } else { 'Never' })"
            Write-Host "Max Machines: $($license.MaxNoOfMachines)"
            Write-Host "Activated: $($license.ActivatedMachines.Count) machines"
            Write-Host "`nFeatures:"
            Write-Host "  F1 (Pro Access): $(if ($license.F1) { '✅ Enabled' } else { '❌ Disabled' })"
            Write-Host "`nNotes: $($license.Notes)"
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n"
            
            return $license
        } else {
            Write-Host "❌ Error: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Failed to fetch key info: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Block-CryptolensKey {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LicenseKey
    )
    
    Write-Host "🔒 Blocking license key..." -ForegroundColor Yellow
    
    $body = @{
        "token" = $CRYPTOLENS_ACCESS_TOKEN
        "ProductId" = $PRODUCT_ID
        "Key" = $LicenseKey
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$API_BASE/key/BlockKey" `
            -Method Post `
            -Headers $headers `
            -Body $body
        
        if ($response.result -eq 0) {
            Write-Host "✅ Key blocked successfully!" -ForegroundColor Green
        } else {
            Write-Host "❌ Error: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Failed to block key: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Unblock-CryptolensKey {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LicenseKey
    )
    
    Write-Host "🔓 Unblocking license key..." -ForegroundColor Cyan
    
    $body = @{
        "token" = $CRYPTOLENS_ACCESS_TOKEN
        "ProductId" = $PRODUCT_ID
        "Key" = $LicenseKey
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$API_BASE/key/UnblockKey" `
            -Method Post `
            -Headers $headers `
            -Body $body
        
        if ($response.result -eq 0) {
            Write-Host "✅ Key unblocked successfully!" -ForegroundColor Green
        } else {
            Write-Host "❌ Error: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Failed to unblock key: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-Menu {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "    🔐 TokerrGjik - Cryptolens Manager" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "`n1. 📋 List all license keys"
    Write-Host "2. 🔑 Create new license key"
    Write-Host "3. 🔍 Get key information"
    Write-Host "4. 🔒 Block a key"
    Write-Host "5. 🔓 Unblock a key"
    Write-Host "6. 🌐 Open Cryptolens Dashboard"
    Write-Host "7. ❌ Exit`n"
}

# Main menu loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Select option (1-7)"
    
    switch ($choice) {
        "1" {
            Get-CryptolensKeys
            Read-Host "`nPress Enter to continue"
        }
        "2" {
            Write-Host "`n━━━━ Create New License ━━━━" -ForegroundColor Cyan
            $maxMachines = Read-Host "Max machines (default: 2)"
            if ([string]::IsNullOrWhiteSpace($maxMachines)) { $maxMachines = 2 }
            
            $validDays = Read-Host "Valid for how many days? (default: 365)"
            if ([string]::IsNullOrWhiteSpace($validDays)) { $validDays = 365 }
            
            $notes = Read-Host "Notes (optional)"
            
            New-CryptolensKey -MaxMachines ([int]$maxMachines) -ValidDays ([int]$validDays) -Notes $notes
            Read-Host "`nPress Enter to continue"
        }
        "3" {
            $key = Read-Host "`nEnter license key"
            Get-KeyInfo -LicenseKey $key
            Read-Host "`nPress Enter to continue"
        }
        "4" {
            $key = Read-Host "`nEnter license key to block"
            Block-CryptolensKey -LicenseKey $key
            Read-Host "`nPress Enter to continue"
        }
        "5" {
            $key = Read-Host "`nEnter license key to unblock"
            Unblock-CryptolensKey -LicenseKey $key
            Read-Host "`nPress Enter to continue"
        }
        "6" {
            Start-Process "https://app.cryptolens.io/Product/31344"
            Write-Host "✅ Opened Cryptolens Dashboard in browser" -ForegroundColor Green
            Read-Host "`nPress Enter to continue"
        }
        "7" {
            Write-Host "`n👋 Goodbye!" -ForegroundColor Cyan
            exit
        }
        default {
            Write-Host "❌ Invalid option. Please select 1-7." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}
