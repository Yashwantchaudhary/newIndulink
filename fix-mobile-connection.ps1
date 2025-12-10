# Quick Fix Script for Mobile Backend Connection
# Run this in PowerShell AS ADMINISTRATOR

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Mobile Backend Connection Quick Fix" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

Write-Host "✓ Running as Administrator" -ForegroundColor Green
Write-Host ""

# Step 1: Get current IP address
Write-Host "Step 1: Checking your IP address..." -ForegroundColor Yellow
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi" -ErrorAction SilentlyContinue).IPAddress

if ($ipAddress) {
    Write-Host "✓ Your IP Address: $ipAddress" -ForegroundColor Green
} else {
    Write-Host "⚠ Could not auto-detect IP. Using default: 192.168.1.76" -ForegroundColor Yellow
    $ipAddress = "192.168.1.76"
}
Write-Host ""

# Step 2: Check if backend is running
Write-Host "Step 2: Checking if backend is running on port 5000..." -ForegroundColor Yellow
$backendRunning = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue

if ($backendRunning) {
    Write-Host "✓ Backend is running on port 5000" -ForegroundColor Green
} else {
    Write-Host "✗ Backend is NOT running on port 5000" -ForegroundColor Red
    Write-Host "  Please start the backend server first!" -ForegroundColor Yellow
    Write-Host "  Run: cd backend && node server.js" -ForegroundColor Cyan
    Write-Host ""
}
Write-Host ""

# Step 3: Add firewall rule
Write-Host "Step 3: Adding Windows Firewall rule for port 5000..." -ForegroundColor Yellow

# Check if rule already exists
$existingRule = Get-NetFirewallRule -DisplayName "Node.js Server Port 5000" -ErrorAction SilentlyContinue

if ($existingRule) {
    Write-Host "⚠ Firewall rule already exists. Removing old rule..." -ForegroundColor Yellow
    Remove-NetFirewallRule -DisplayName "Node.js Server Port 5000"
}

# Add new firewall rule
try {
    New-NetFirewallRule -DisplayName "Node.js Server Port 5000" `
                        -Direction Inbound `
                        -Protocol TCP `
                        -LocalPort 5000 `
                        -Action Allow `
                        -Profile Any `
                        -ErrorAction Stop | Out-Null
    
    Write-Host "✓ Firewall rule added successfully!" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to add firewall rule: $_" -ForegroundColor Red
}
Write-Host ""

# Step 4: Verify firewall rule
Write-Host "Step 4: Verifying firewall rule..." -ForegroundColor Yellow
$rule = Get-NetFirewallRule -DisplayName "Node.js Server Port 5000" -ErrorAction SilentlyContinue

if ($rule) {
    Write-Host "✓ Firewall rule is active" -ForegroundColor Green
    $ruleDetails = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule
    Write-Host "  - Protocol: TCP" -ForegroundColor Cyan
    Write-Host "  - Port: $($ruleDetails.LocalPort)" -ForegroundColor Cyan
    Write-Host "  - Direction: Inbound" -ForegroundColor Cyan
    Write-Host "  - Action: Allow" -ForegroundColor Cyan
} else {
    Write-Host "✗ Firewall rule was not created" -ForegroundColor Red
}
Write-Host ""

# Step 5: Test local connection
Write-Host "Step 5: Testing local connection..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ Backend is responding locally" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Backend is not responding locally" -ForegroundColor Red
    Write-Host "  Make sure the backend server is running!" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Summary & Next Steps" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Your IP Address: $ipAddress" -ForegroundColor White
Write-Host "2. Backend URL for mobile: http://$ipAddress:5000" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Ensure your mobile device is on the SAME WiFi network" -ForegroundColor White
Write-Host ""
Write-Host "2. Test from mobile browser:" -ForegroundColor White
Write-Host "   Open: http://$ipAddress:5000/health" -ForegroundColor Cyan
Write-Host "   You should see a JSON response" -ForegroundColor White
Write-Host ""
Write-Host "3. Verify Flutter app config:" -ForegroundColor White
Write-Host "   File: frontend\lib\core\constants\app_config.dart" -ForegroundColor Cyan
Write-Host "   Line 24 should have: static const String _hostIp = '$ipAddress';" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. If IP is correct, rebuild your Flutter app" -ForegroundColor White
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

pause
