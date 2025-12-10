# 📱 Mobile Device Backend Connection Troubleshooting Guide

## Current Configuration Status ✅

- **Computer IP Address:** `192.168.1.76`
- **Backend Port:** `5000`
- **Backend Status:** Running (PID 24048)
- **Backend Binding:** `0.0.0.0` (accessible from network)
- **Frontend Config:** `192.168.1.76:5000` ✅ Correct

## Problem Identified 🔍

Your backend is NOT accessible from your mobile device because **Windows Firewall is blocking incoming connections** on port 5000.

---

## Solution Steps (Follow in Order) 🛠️

### Step 1: Add Windows Firewall Rule ⭐ **REQUIRED**

**Option A: Using PowerShell (Recommended)**

1. Right-click the **Start Menu** → Select **"Windows PowerShell (Admin)"** or **"Terminal (Admin)"**
2. Run this command:

```powershell
netsh advfirewall firewall add rule name="Node.js Server Port 5000" dir=in action=allow protocol=TCP localport=5000
```

3. You should see: `Ok.`

**Option B: Using Windows Firewall GUI**

1. Press `Win + R` → Type `wf.msc` → Press Enter
2. Click **"Inbound Rules"** in the left panel
3. Click **"New Rule..."** in the right panel
4. Select **"Port"** → Click Next
5. Select **"TCP"** → Enter `5000` in "Specific local ports" → Click Next
6. Select **"Allow the connection"** → Click Next
7. Check all profiles (Domain, Private, Public) → Click Next
8. Name: `Node.js Server Port 5000` → Click Finish

---

### Step 2: Verify Firewall Rule ✅

In PowerShell (Admin), run:

```powershell
netsh advfirewall firewall show rule name="Node.js Server Port 5000"
```

You should see the rule details with:
- **Action:** Allow
- **Direction:** In
- **Protocol:** TCP
- **LocalPort:** 5000

---

### Step 3: Ensure Mobile and PC are on Same Network 📶

**Both devices MUST be connected to the same WiFi network.**

1. On your computer, check WiFi name:
   - Click WiFi icon in taskbar
   - Note the connected network name

2. On your mobile device:
   - Settings → WiFi
   - Ensure you're connected to the **SAME** WiFi network

---

### Step 4: Test Backend Accessibility 🧪

**Test from your Mobile Device:**

1. Open a web browser on your mobile (Chrome, Safari, etc.)
2. Navigate to: `http://192.168.1.76:5000/health`
3. You should see a JSON response:
   ```json
   {
     "success": true,
     "message": "Indulink API is healthy",
     "timestamp": "...",
     ...
   }
   ```

**If you see this JSON response, the connection is working!** ✅

**If the browser times out or shows "Can't connect":**
- The firewall rule is not active yet
- Try restarting your computer
- Check antivirus software isn't blocking connections

---

### Step 5: Restart Backend Server (If Needed) 🔄

Sometimes the backend needs to be restarted after adding firewall rules:

1. In your existing terminal where backend is running, press `Ctrl + C` to stop it
2. Restart with:
   ```bash
   cd c:\Users\chaud\Desktop\newINDULINK\backend
   node server.js
   ```

---

### Step 6: Test Your Flutter App 📱

1. Open your Flutter app on your mobile device
2. Try to login or access any feature that requires backend
3. The app should now connect successfully!

---

## Additional Troubleshooting 🔧

### If IP Address Changes

Your IP address (`192.168.1.76`) might change if you reconnect to WiFi. If this happens:

1. Check your new IP:
   ```powershell
   ipconfig
   ```
   Look for "IPv4 Address" under "Wireless LAN adapter Wi-Fi"

2. Update the frontend configuration:
   - Open: `c:\Users\chaud\Desktop\newINDULINK\frontend\lib\core\constants\app_config.dart`
   - Change line 24 to your new IP:
     ```dart
     static const String _hostIp = 'YOUR_NEW_IP';
     ```

3. Rebuild and reinstall your Flutter app

---

### If Using Antivirus Software

Some antivirus software (like Avast, McAfee, Norton) has its own firewall that might block the connection:

1. Open your antivirus settings
2. Look for "Firewall" or "Network Protection"
3. Add an exception for port 5000 or the Node.js process

---

### Test Backend Locally on Computer

To ensure backend is working correctly, test from your computer:

1. Open browser on your PC
2. Go to: `http://localhost:5000/health`
3. Should see the health check JSON response

If this doesn't work, the backend has other issues.

---

## Quick Verification Checklist ✓

- [ ] Windows Firewall rule added for port 5000
- [ ] Backend server is running (see terminal output)
- [ ] Mobile and PC are on the same WiFi network
- [ ] Can access `http://192.168.1.76:5000/health` from mobile browser
- [ ] Flutter app config has correct IP: `192.168.1.76`
- [ ] No antivirus blocking connections

---

## Common Error Messages & Fixes

### "Connection refused" or "Connection timeout"
→ Firewall is blocking. Add firewall rule (Step 1)

### "No internet connection"
→ Mobile and PC are on different networks, or wrong IP address

### "Server error occurred"
→ Backend has crashed. Check terminal for errors

### "Request timeout"
→ Backend is slow or not responding. Check backend logs

---

## Still Having Issues? 🆘

If you've followed all steps and still can't connect:

1. **Temporarily disable Windows Firewall** (for testing only):
   ```powershell
   netsh advfirewall set allprofiles state off
   ```
   
   If this works, the problem is definitely firewall-related.
   
   **IMPORTANT: Re-enable it after testing:**
   ```powershell
   netsh advfirewall set allprofiles state on
   ```

2. **Check if port 5000 is actually open:**
   From mobile browser, try: `http://192.168.1.76:5000`
   
3. **Use a different port** (if port 5000 is blocked by ISP):
   - Change backend `.env` file: `PORT=3000`
   - Update frontend config to use port 3000
   - Add firewall rule for port 3000

---

## Success! 🎉

Once you can access `http://192.168.1.76:5000/health` from your mobile browser, your Flutter app should work perfectly!

The app is configured to connect to `http://192.168.1.76:5000/api` for all API calls.
