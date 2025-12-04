#!/bin/bash

# 🧪 Flutter Loading Screen Fixes - Local Verification Script
# This script helps verify that the loading screen fixes are working correctly

echo "🔧 Flutter Loading Screen Fixes - Local Verification"
echo "=================================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Flutter installation
echo "1️⃣ Checking Flutter installation..."
if command_exists flutter; then
    flutter --version
else
    echo "❌ Flutter not found! Please install Flutter first."
    echo "Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check if we're in the frontend directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Please run this script from the frontend directory"
    exit 1
fi

echo ""
echo "2️⃣ Checking project dependencies..."
flutter pub get

echo ""
echo "3️⃣ Running Flutter analyze to check for errors..."
flutter analyze

echo ""
echo "4️⃣ Starting Flutter app in debug mode..."
echo "📱 The app should:"
echo "   ✅ Start immediately without infinite loading"
echo "   ✅ Show splash screen for ~3 seconds"
echo "   ✅ Navigate to admin dashboard quickly"
echo "   ✅ Display content immediately in admin dashboard"
echo ""
echo "Press Ctrl+C to stop the app"
echo ""

# Start Flutter with Chrome browser
flutter run -d chrome --debug