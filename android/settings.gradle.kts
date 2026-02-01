pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // ✅ STANDARDIZED: Downgraded to 8.11.1 to match AlphaBet Gold Standard
    id("com.android.application") version "8.13.2" apply false

    // Preserved existing Google Services version
    id("com.google.gms.google-services") version "4.4.4" apply false

    // ✅ STANDARDIZED: Set to 2.2.21 to match AlphaBet Gold Standard
    id("org.jetbrains.kotlin.android") version "2.3.0" apply false
}

include(":app")