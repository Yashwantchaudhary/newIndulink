# APK Optimization Guide for Flutter

## Current Size vs Target
- **Current APK**: ~50MB
- **Target APK**: < 20MB
- **Reduction Needed**: 60%

## Optimization Steps

### 1. Code Splitting (Per-ABI)
```bash
# Build separate APKs for each CPU architecture
flutter build apk --split-per-abi

# This creates:
# - app-armeabi-v7a-release.apk (~15MB)
# - app-arm64-v8a-release.apk (~18MB)
# - app-x86_64-release.apk (~20MB)
```

### 2. Enable Code Obfuscation & Minification
```bash
flutter build apk --obfuscate --split-debug-info=./debug-info
```

### 3. Tree Shaking (Remove Unused Icons)
```bash
flutter build apk --tree-shake-icons
```

### 4. Image Optimization

**Add to `pubspec.yaml`:**
```yaml
dependencies:
  flutter_image_compress: ^2.1.0
```

**Optimize existing images:**
```bash
# Install ImageMagick
# Then run:
find assets/images -name "*.png" -exec convert {} -quality 85 -resize 1024x1024\> {} \;
```

### 5. Remove Unused Assets

**Check for unused images:**
```bash
flutter pub run flutter_asset_finder
```

### 6. Use WebP Instead of PNG/JPG

**Convert images:**
```bash
cwebp input.png -q 80 -o output.webp
```

### 7. Reduce Font Files

**Use subset fonts** in `pubspec.yaml`:
```yaml
fonts:
  - family: Roboto
    fonts:
      - asset: fonts/Roboto-Regular.ttf
        weight: 400
      - asset: fonts/Roboto-Bold.ttf
        weight: 700
    # Remove unused weights
```

### 8. ProGuard Rules (Android)

**Create** `android/app/proguard-rules.pro`:
```proguard
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
```

**Enable in** `android/app/build.gradle`:
```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
    }
}
```

### 9. Remove Debug Symbols

```bash
flutter build apk --release --no-pub --no-shrink
```

### 10. Analyze APK Size

```bash
flutter build apk --analyze-size
```

## Expected Results

| Optimization | Size Reduction |
|--------------|----------------|
| Split per ABI | 30-40% |
| Obfuscation | 10-15% |
| Tree shaking | 5-10% |
| Image optimization | 20-30% |
| ProGuard | 10-15% |
| **Total** | **60-70%** |

## Final Command

```bash
flutter build apk \
  --release \
  --obfuscate \
  --split-debug-info=./debug-info \
  --split-per-abi \
  --tree-shake-icons \
  --dart-define=FLUTTER_WEB_AUTO_DETECT=true
```

This should produce APKs around **15-20MB each**! 🎉
