import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.bps.pendeza"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.bps.pendeza"
        minSdk = 24
        targetSdk = 36

        // Hardcoded for the first Google Play Store release
        // versionCode must start at 1 and increase with every update
        // versionName is the visible version string (can be any format you prefer)
        versionCode = 4
        versionName = "1.3"

        multiDexEnabled = true
    }

    compileOptions {
        // Core Library Desugaring is needed for Java 17 features on older Androids
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            // Ensure this path is correct on your machine
            storeFile = file("D:/A.Projects/pendeza/release-key.jks")
            storePassword = "@Watakubali2"
            keyAlias = "releasekey"
            keyPassword = "@Watakubali2"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
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

dependencies {
    // Required for Java 17 support
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("androidx.multidex:multidex:2.0.1")

    // Firebase
    implementation(platform("com.google.firebase:firebase-bom:34.8.0"))
    implementation("com.google.firebase:firebase-analytics")
}

// FIX: Configuration for Kotlin compiler moved outside the android block
kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}