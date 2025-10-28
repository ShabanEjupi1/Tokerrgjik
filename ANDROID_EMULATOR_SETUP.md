# Android Emulator Setup Guide

## Step 1: Install Android Studio ✅ (In Progress)

The Android Studio installer is now running. Follow these steps:

1. ✅ **Click "Next"** through the installation wizard
2. ✅ **Choose "Standard" installation** (recommended)
3. ✅ **Accept all licenses**
4. ✅ **Wait for Android SDK to download** (~3-5 GB, takes 5-15 minutes)
5. ✅ **Click "Finish"** when complete

## Step 2: Create Android Emulator (After Installation)

Once Android Studio is installed:

### Method 1: Using Android Studio GUI

1. Open **Android Studio**
2. On the welcome screen, click **"More Actions"** → **"Virtual Device Manager"**
3. Click **"Create Device"**
4. Select **"Pixel 5"** (recommended for testing)
5. Click **"Next"**
6. Select a system image:
   - **Recommended**: "Tiramisu" (API 33) or "UpsideDownCake" (API 34)
   - Click **"Download"** next to the system image
   - Wait for download (~1-2 GB)
7. Click **"Next"**, then **"Finish"**

### Method 2: Using Command Line (Faster)

After Android Studio installs, run these commands in PowerShell:

```powershell
# Set Android SDK path (replace with your actual path if different)
$env:ANDROID_HOME = "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk"
$env:Path += ";$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\emulator"

# List available system images
sdkmanager --list | Select-String "system-images"

# Install system image for Pixel 5 (API 33)
sdkmanager "system-images;android-33;google_apis;x86_64"

# Create emulator
avdmanager create avd -n Pixel5 -k "system-images;android-33;google_apis;x86_64" -d "pixel_5"

# Start emulator
emulator -avd Pixel5
```

## Step 3: Configure Flutter

After Android Studio installation completes:

```powershell
# Tell Flutter where Android SDK is
flutter config --android-sdk "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk"

# Accept Android licenses
flutter doctor --android-licenses

# Verify everything is set up
flutter doctor -v
```

You should see:
```
[√] Android toolchain - develop for Android devices (Android SDK version 34.x.x)
```

## Step 4: Test the Emulator

```powershell
# List available emulators
flutter emulators

# Launch the emulator
flutter emulators --launch Pixel5

# Or use Android Studio's emulator manager
emulator -avd Pixel5
```

## Step 5: Run Your App on Emulator

Once the emulator is running:

```powershell
cd C:\Users\shaban.ejupi\Desktop\Projektet\TokerrGjik\tokerrgjik_mobile

# Check connected devices
flutter devices

# Should show something like:
# • Pixel 5 (mobile) • emulator-5554 • android-x64 • Android 13 (API 33)

# Run the app
flutter run
```

Or press **F5** in VS Code to debug!

## Troubleshooting

### Issue: "Unable to locate Android SDK"
**Solution**: Run this after Android Studio installs:
```powershell
flutter config --android-sdk "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk"
```

### Issue: "Android licenses not accepted"
**Solution**:
```powershell
flutter doctor --android-licenses
# Press 'y' for each license
```

### Issue: Emulator is slow
**Solutions**:
- Enable **Intel HAXM** (Hardware Accelerated Execution Manager) in Android Studio
- OR enable **Hyper-V** in Windows Features
- Allocate more RAM to emulator in AVD settings (4GB+ recommended)

### Issue: Emulator won't start
**Solution**:
```powershell
# Check BIOS virtualization is enabled (Intel VT-x or AMD-V)
# Open Task Manager → Performance → CPU → Virtualization should be "Enabled"

# If not enabled, restart and enter BIOS (usually F2 or DEL key)
# Enable Intel VT-x or AMD-V
```

## Quick Commands Reference

```powershell
# Check Flutter setup
flutter doctor -v

# List emulators
flutter emulators

# Launch emulator
flutter emulators --launch Pixel5

# List connected devices
flutter devices

# Run app on emulator
flutter run

# Run app on specific device
flutter run -d emulator-5554

# Build APK
flutter build apk --release

# Install APK on emulator
flutter install
```

## What to Expect

After successful setup:
- ✅ Android Studio installed with SDK
- ✅ Pixel 5 emulator created
- ✅ Flutter recognizes Android toolchain
- ✅ Can run `flutter run` and app launches in emulator
- ✅ Can test all features: UI, sounds, gameplay, etc.
- ✅ API calls will still fail locally (need Netlify env vars)

## Alternative: Use Physical Android Device

If emulator is too slow or won't work:

1. Enable **Developer Options** on your Android phone:
   - Settings → About Phone → Tap "Build Number" 7 times
2. Enable **USB Debugging**:
   - Settings → Developer Options → USB Debugging → ON
3. Connect phone via USB cable
4. Allow debugging when prompted on phone
5. Run: `flutter devices` (should show your phone)
6. Run: `flutter run` (will install on your phone)

---

**Current Status**: Android Studio installer launched, waiting for completion...
**Next Step**: Complete Android Studio installation, then run the commands in Step 2 & 3.
**Estimated Time**: 10-20 minutes total (depends on download speed)
