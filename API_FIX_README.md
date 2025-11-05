# API Connection Fix for TokerrGjik Flutter Web

## Problem
APIs were not working when running Flutter web in development mode with error:
```
ClientException: Failed to fetch
```

## Root Cause
When running `flutter run -d chrome`, the app runs on `localhost` and makes cross-origin requests to `https://tokerrgjik.netlify.app`. This triggers browser CORS (Cross-Origin Resource Sharing) restrictions. The standard `http` package in Flutter doesn't handle CORS preflight requests optimally for web applications.

## Solution Implemented

### 1. Added Dio Package
Added `dio: ^5.4.0` to `pubspec.yaml` - Dio is a more robust HTTP client with better CORS support for Flutter web.

### 2. Updated API Service
Modified `lib/services/api_service.dart` to:
- Use Dio for web requests (better CORS handling)
- Keep `http` package for mobile (Android/iOS)
- Improved error handling with specific Dio exception catching
- Better error messages for debugging

### 3. Development Workaround
For local development, run Flutter web with CORS disabled:

```bash
cd C:\Users\Administrator\TokerrGjik\tokerrgjik_mobile
flutter run -d chrome --web-browser-flag="--disable-web-security" --web-browser-flag="--user-data-dir=C:\Temp\chrome_dev"
```

### 4. Added VS Code Launch Configuration
Created `.vscode/launch.json` with pre-configured debug configurations including CORS-disabled Chrome option.

## How to Run

### Development Mode (with CORS disabled)
```bash
flutter run -d chrome --web-browser-flag="--disable-web-security" --web-browser-flag="--user-data-dir=C:\Temp\chrome_dev"
```

### Production Build
Production builds deployed to Netlify don't have CORS issues because they're served from the same domain as the API:

```bash
flutter build web --release
# Deploy the build/web folder to Netlify
```

## Verification

1. **APIs are deployed and working**: Verified via curl that Netlify functions respond correctly:
   ```powershell
   curl "https://tokerrgjik.netlify.app/.netlify/functions/leaderboard?limit=10&offset=0"
   # Returns 200 OK with leaderboard data
   ```

2. **CORS headers are set**: Netlify functions have proper CORS headers:
   ```javascript
   'Access-Control-Allow-Origin': '*'
   'Access-Control-Allow-Headers': 'Content-Type'
   'Access-Control-Allow-Methods': 'GET, OPTIONS'
   ```

3. **Dio handles CORS better**: The Dio package properly handles preflight OPTIONS requests and CORS headers in browser environment.

## Why This Happens

- **Development**: `localhost:port` → `tokerrgjik.netlify.app` = Cross-origin ❌
- **Production**: `tokerrgjik.netlify.app` → `tokerrgjik.netlify.app/.netlify/functions` = Same-origin ✅

## Additional Notes

- The `--disable-web-security` flag should ONLY be used during development
- Production builds work without this flag because they're served from the same domain
- Mobile apps (Android/iOS) don't have CORS restrictions
- The Dio package is used for web only, mobile still uses the lighter `http` package

## Files Modified

1. `tokerrgjik_mobile/pubspec.yaml` - Added Dio package
2. `tokerrgjik_mobile/lib/services/api_service.dart` - Updated to use Dio for web
3. `tokerrgjik_mobile/.vscode/launch.json` - Added debug configurations

## Testing

After implementing these changes:
1. Run the app with CORS disabled flag
2. APIs should now work properly
3. Check console for "API GET: ..." logs showing successful requests
4. Leaderboard, statistics, and other API features should load data

## Production Deployment

When deploying to production:
1. Build: `flutter build web --release`
2. Deploy `build/web` to Netlify (same domain as functions)
3. No CORS issues in production because same-origin requests
