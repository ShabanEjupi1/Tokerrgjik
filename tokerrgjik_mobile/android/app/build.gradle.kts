plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ejupishaban.tokerrgjik"
    compileSdk = 36  // Required by sqflite_android-2.4.2+2 which uses BAKLAVA (Android 36)
    ndkVersion = flutter.ndkVersion  // Use Flutter's recommended NDK version

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17  // Updated from 11 to 17
        targetCompatibility = JavaVersion.VERSION_17  // Updated from 11 to 17
        // Enable core library desugaring for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()  // Updated from 11 to 17
        languageVersion = "1.9"  // Set Kotlin language version for Sentry compatibility
    }

    defaultConfig {
        // Unique Application ID for Tokerrgjik
        applicationId = "com.ejupishaban.tokerrgjik"
        // Application configuration
        minSdk = 24  // Android 7.0 and above
        targetSdk = 34  // Stable Android version for CI
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring for flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

// Suppress deprecation warnings from third-party dependencies
tasks.withType<JavaCompile> {
    options.compilerArgs.addAll(listOf("-Xlint:-deprecation", "-Xlint:-unchecked"))
}
