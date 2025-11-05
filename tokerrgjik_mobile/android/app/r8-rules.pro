# R8 Rules for handling missing Play Core classes
# Flutter references Play Core classes that may not be included

# Don't warn about missing Play Core classes
-dontwarn com.google.android.play.core.**

# Keep Flutter deferred components classes even if Play Core is missing
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.app.FlutterPlayStoreSplitApplication { *; }

# Ignore missing classes errors for Play Core
-ignorewarnings
