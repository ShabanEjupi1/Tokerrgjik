import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. key.properties and the .jks are gitignored and live only on
// the build machine; without them a release build falls back to the debug key,
// which produces an APK Android will refuse to install over a properly signed
// one. Keep the keystore backed up: lose it and this app can never be updated.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    namespace = "com.ejupishaban.tokerrgjik"
    compileSdk = 36  // Required by sqflite_android-2.4.2+2 which uses BAKLAVA (Android 36)
    ndkVersion = "27.0.12077973"  // Fixed: Use highest NDK version required by plugins

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

    signingConfigs {
        create("release") {
            if (keystoreProperties.getProperty("storeFile") != null) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystoreProperties.getProperty("storeFile") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Temporarily disable minification to fix Play Core issue
            // Re-enable after fixing Play Core dependencies
            isMinifyEnabled = false
            isShrinkResources = false
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
        debug {
            // Disable minification for debug builds
            isMinifyEnabled = false
        }
    }
    
    // Fix for Play Core missing classes in R8
    buildFeatures {
        buildConfig = true
    }
    
    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring for flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Google Play Core for deferred components
    implementation("com.google.android.play:core:1.10.3")
}

// Suppress deprecation warnings from third-party dependencies
tasks.withType<JavaCompile> {
    options.compilerArgs.addAll(listOf("-Xlint:-deprecation", "-Xlint:-unchecked"))
}
