# How to Enable Developer Mode & Test Locally

## Option 1: Enable Developer Mode (Recommended for Windows Desktop App)

### Method A: Via Settings (Easy)
1. Press `Windows + I` to open Settings
2. Go to **Privacy & Security** → **For developers**
3. Turn ON **Developer Mode**
4. Restart VS Code or PowerShell

### Method B: Via Registry (If Settings blocked)
Run PowerShell **as Administrator**:
```powershell
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"
```

Then restart your computer.

### After Enabling, Run the App:
```powershell
cd C:\Users\shaban.ejupi\Desktop\Projektet\TokerrGjik\tokerrgjik_mobile
$env:Path += ";C:\src\flutter\bin"
flutter run -d windows
```

---

## Option 2: Test in Chrome (No Developer Mode Required)

### Quick Start:
```powershell
cd C:\Users\shaban.ejupi\Desktop\Projektet\TokerrGjik\tokerrgjik_mobile
$env:Path += ";C:\src\flutter\bin"
flutter run -d chrome
```

**Features you can test:**
- ✅ Golden coin icons
- ✅ Boyish party/confetti colors (blue, gold, green)
- ✅ Flag-themed language settings (🇦🇱 🇬🇧)
- ✅ 3D joystick game icon
- ✅ All game functionality

---

## Option 3: Build APK and Test on Android Emulator

### If you have Android SDK installed:
```powershell
cd C:\Users\shaban.ejupi\Desktop\Projektet\TokerrGjik\tokerrgjik_mobile
$env:Path += ";C:\src\flutter\bin"

# Build APK
flutter build apk --debug

# The APK will be at:
# build\app\outputs\flutter-apk\app-debug.apk
```

Then install on emulator or real device:
```powershell
adb install build\app\outputs\flutter-apk\app-debug.apk
```

---

## Option 4: Use GitHub Actions Built APK

1. Go to: https://github.com/ShabanEjupi/Tokerrgjik/actions
2. Click latest **successful** workflow run
3. Download **android-apks** artifact
4. Extract and install on phone or emulator

---

## What UI Changes to Look For:

### 1. 💰 Golden Coin Icons
- All coin icons should be golden color (#DAA520)
- Look in: Shop, Settings themes, Game rewards

### 2. 🎉 Boyish Party Colors
- Confetti: Blue, Gold, Green, Dark blue-grey, Orange
- No pink or feminine colors
- Check when: Getting daily rewards, winning games

### 3. 🇦🇱 🇬🇧 Flag-Themed Languages
- Settings → Language
- Albanian: Red to Black gradient
- English: Blue to Red gradient

### 4. 🎮 3D Joystick Icon
- Home screen → "Luaj kundër AI" button
- Should show a 3D-style joystick with D-pad and buttons

---

## Troubleshooting

### Chrome not opening?
- Make sure Chrome is installed
- Or try Edge: `flutter run -d edge`

### Flutter command not found?
```powershell
$env:Path += ";C:\src\flutter\bin"
```

### Build errors?
```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

---

## Quick Commands Reference

```powershell
# Add Flutter to PATH (run this in each new terminal)
$env:Path += ";C:\src\flutter\bin"

# Navigate to project
cd C:\Users\shaban.ejupi\Desktop\Projektet\TokerrGjik\tokerrgjik_mobile

# Run on Chrome (easiest)
flutter run -d chrome

# Run on Windows (requires Developer Mode)
flutter run -d windows

# Build APK
flutter build apk --debug

# Check available devices
flutter devices

# See app help
flutter run --help
```
