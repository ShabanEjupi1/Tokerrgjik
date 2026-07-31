import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Nënshkrimi i lëshimit. `key.properties` dhe `.jks` janë të gitignore-uara dhe
// rrinë vetëm te makina që ndërton; pa to një ndërtim `release` bie prapa te
// çelësi i debug-ut, dhe Play-i e refuzon një AAB të tillë.
//
// !! Ruaje keystore-in diku tjetër. Nëse humbet, ky aplikacion NUK përditësohet
//    dot më kurrë: Android-i refuzon një paketë të nënshkruar me çelës tjetër.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    namespace = "com.ejupishaban.tokerrgjik"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.ejupishaban.tokerrgjik"
        minSdk = 24
        // 🚨 Play kërkon API 35 për çdo ngarkim të ri që nga 31 gushti 2025,
        // dhe **API 36 që nga 31 gushti 2026**. Me një numër më të ulët
        // ngarkimi refuzohet te dera, para se ta shohë njeri.
        // Ngritur 35 → 36 më 2026-07-31: testimi i mbyllur zgjat 14 ditë dhe
        // publikimi bie pas afatit, pra çdo AAB i ri duhet të jetë tashmë 36.
        // `compileSdk` ishte tashmë 36, ndaj s'kërkohet asgjë tjetër.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
            // Tani ka kuptim: aplikacioni nuk ka më Play Core, Stripe apo Sentry,
            // pra as klasat që e detyronin R8-ën të dorëzohej. Rregullat e
            // Flutter-it mjaftojnë.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
