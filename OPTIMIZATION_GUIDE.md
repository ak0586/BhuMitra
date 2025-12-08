# BhuMitra App - Optimization Guide

## Quick Reference: How to Optimize

### 1. APK Size Optimization (Already Implemented ✅)

#### What Was Done:
- ✅ **ProGuard/R8 enabled** in `android/app/build.gradle.kts`
- ✅ **Resource shrinking enabled** to remove unused resources
- ✅ **ABI splits configured** for smaller per-architecture APKs
- ✅ **ProGuard rules created** to protect Firebase and Flutter code

#### Build Optimized APK:
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build with obfuscation and split per ABI
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols --split-per-abi

# Check APK sizes
dir build\app\outputs\flutter-apk\*.apk
```

**Expected Result**: 
- Individual APKs: ~25-35MB each (arm64-v8a, armeabi-v7a, x86_64)
- Much smaller than the current 54.8MB universal APK

---

### 2. Memory Usage Optimization (Partially Implemented ✅)

#### What Was Done:
- ✅ **Map tile caching reduced**: `keepBuffer: 2` (from default 3)
- ✅ **Firestore cache clearing**: Clears on logout to free memory
- ✅ **Proper resource disposal**: MapController and subscriptions disposed

#### Still To Do:
- ⏳ Optimize Google Fonts (download and bundle locally)
- ⏳ Add image cache limits for CachedNetworkImage
- ⏳ Implement lazy loading for saved plots

---

### 3. Additional Optimizations (Optional)

#### A. Convert Logo to WebP
```bash
# Install ImageMagick or use online converter
# Convert PNG to WebP (smaller size, same quality)
magick assets/images/BhuMitra_logo.png -quality 90 assets/images/BhuMitra_logo.webp
```

Then update `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  image_path: "assets/images/BhuMitra_logo.webp"
```

#### B. Analyze APK Size
```bash
# See what's taking up space
flutter build apk --release --analyze-size
```

#### C. Build App Bundle (For Play Store)
```bash
# Smaller download size for users
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

---

## Testing After Optimization

### 1. Verify APK Size
```bash
# Build and check size
flutter build apk --release --split-per-abi
Get-Item build\app\outputs\flutter-apk\*.apk | Select-Object Name, Length
```

**Target**: Each APK < 35MB

---

### 2. Test Memory Usage

**Using ADB**:
```bash
# Install APK
adb install build\app\outputs\flutter-apk\app-arm64-v8a-release.apk

# Monitor memory
adb shell dumpsys meminfo com.example.bhumitra

# Or use Android Studio Profiler
```

**Manual Testing**:
1. Open app and login
2. Navigate to boundary marking
3. Mark 10+ points
4. Calculate area
5. Save multiple plots
6. Check memory usage

**Target**: Peak memory < 250MB

---

### 3. Functionality Testing
```bash
# Run all tests
flutter test

# Manual testing checklist:
# - Login/Register works
# - Map loads correctly
# - Boundary marking functional
# - Area calculation accurate
# - Settings persist
# - No crashes
```

---

## Expected Results

### APK Size Reduction

| Build Type | Before | After | Reduction |
|------------|--------|-------|-----------|
| Universal APK | 54.8MB | ~40-45MB | ~10-15MB |
| arm64-v8a APK | N/A | ~30-35MB | Best for most devices |
| armeabi-v7a APK | N/A | ~28-32MB | Older devices |

### Memory Usage Reduction

| Scenario | Before | After | Reduction |
|----------|--------|-------|-----------|
| Idle | 128MB | ~120MB | ~8MB |
| Active (Map) | 312MB | ~230-250MB | ~60-80MB |
| Peak Usage | 312MB | ~240-260MB | ~50-70MB |

---

## Troubleshooting

### If App Crashes After ProGuard:

1. **Check ProGuard rules**: Ensure all Firebase classes are kept
2. **Disable minification temporarily**:
   ```kotlin
   isMinifyEnabled = false
   isShrinkResources = false
   ```
3. **Test incrementally**: Enable one optimization at a time

### If Build Fails:

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release
```

### If Memory Still High:

1. Use Android Studio Profiler to identify leaks
2. Check for unclosed streams or listeners
3. Verify images are being cached properly
4. Consider reducing map zoom levels

---

## Files Modified

1. ✅ `android/app/build.gradle.kts` - ProGuard and ABI splits
2. ✅ `android/app/proguard-rules.pro` - ProGuard keep rules (NEW)
3. ✅ `lib/features/boundary/boundary_marking_screen.dart` - Map memory optimization
4. ✅ `lib/core/auth_service.dart` - Firestore cache clearing

---

## Next Steps

1. **Build and test** the optimized APK
2. **Measure** actual size and memory improvements
3. **Fine-tune** if targets not met
4. **Deploy** to beta testers for real-world validation

---

## Quick Commands Summary

```bash
# Build optimized APKs (recommended)
flutter build apk --release --split-per-abi

# Build with obfuscation (extra security)
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols --split-per-abi

# Build App Bundle for Play Store
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Analyze APK size
flutter build apk --release --analyze-size

# Test memory
adb shell dumpsys meminfo com.example.bhumitra
```

---

**Status**: ✅ Core optimizations implemented  
**Next**: Build and test to verify improvements
