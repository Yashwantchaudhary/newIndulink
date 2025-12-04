@echo off
REM 🧪 Flutter Loading Screen Fixes - Windows Verification Script
REM This script helps verify that the loading screen fixes are working correctly

echo 🔧 Flutter Loading Screen Fixes - Windows Verification
echo ==================================================

REM Check Flutter installation
echo 1️⃣ Checking Flutter installation...
where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ❌ Flutter not found! Please install Flutter first.
    echo Visit: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

flutter --version

REM Check if we're in the frontend directory
if not exist "pubspec.yaml" (
    echo ❌ Please run this script from the frontend directory
    pause
    exit /b 1
)

echo.
echo 2️⃣ Checking project dependencies...
flutter pub get

echo.
echo 3️⃣ Running Flutter analyze to check for errors...
flutter analyze

echo.
echo 4️⃣ Starting Flutter app in debug mode...
echo 📱 The app should:
echo    ✅ Start immediately without infinite loading
echo    ✅ Show splash screen for ~3 seconds
echo    ✅ Navigate to admin dashboard quickly
echo    ✅ Display content immediately in admin dashboard
echo.
echo Press Ctrl+C to stop the app
echo.

REM Start Flutter with Chrome browser
flutter run -d chrome --debug

pause