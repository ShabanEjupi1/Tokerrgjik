# Cryptolens License Manager for TokerrGjik
# Simple PowerShell script to manage licenses

$CRYPTOLENS_TOKEN = "WyIxMTM3MTkwMjIiLCIzdEpPaTM1VjN5Q2V4R3lHTHVGTnJnVUdGQ21mb2N5TkZxYmJ0cnN0Il0="
$PRODUCT_ID = 31344
$API_BASE = "https://app.cryptolens.io/api"

function Get-AllKeys {
    Write-Host "Fetching all license keys..." -ForegroundColor Cyan
    
    $body = @{
        token = $CRYPTOLENS_TOKEN
        ProductId = $PRODUCT_ID
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$API_BASE/key/GetKeys" -Method Post -ContentType "application/json" -Body $body
    
    if ($response.result -eq 0) {
        Write-Host "SUCCESS! Found $($response.licenses.Count) keys" -ForegroundColor Green
        $response.licenses | ForEach-Object {
            Write-Host "===================="
            Write-Host "Key: $($_.Key)"
            Write-Host "Status: $(if ($_.Blocked) { 'BLOCKED' } else { 'ACTIVE' })"
            Write-Host "Expires: $(if ($_.Expires) { $_.Expires } else { 'Never' })"
            Write-Host "Machines: $($_.ActivatedMachines.Count) / $($_.MaxNoOfMachines)"
        }
    } else {
        Write-Host "ERROR: $($response.message)" -ForegroundColor Red
    }
}

function New-Key {
    param(
        [int]$Days = 365,
        [int]$MaxMachines = 2
    )
    
    Write-Host "Creating new license key..." -ForegroundColor Cyan
    
    $body = @{
        token = $CRYPTOLENS_TOKEN
        ProductId = $PRODUCT_ID
        Period = $Days
        F1 = $true
        MaxNoOfMachines = $MaxMachines
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$API_BASE/key/CreateKey" -Method Post -ContentType "application/json" -Body $body
    
    if ($response.result -eq 0) {
        Write-Host "SUCCESS! New key created:" -ForegroundColor Green
        Write-Host $response.key -ForegroundColor Yellow
        Set-Clipboard -Value $response.key
        Write-Host "Key copied to clipboard!" -ForegroundColor Green
        return $response.key
    } else {
        Write-Host "ERROR: $($response.message)" -ForegroundColor Red
    }
}

# Run list keys by default
Get-AllKeys

Write-Host "`nTo create a new key, run: New-Key -Days 365 -MaxMachines 2" -ForegroundColor Cyan
