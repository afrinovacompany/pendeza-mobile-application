// Root-level build.gradle.kts for Pendeza
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // STRICTLY PRESERVED: Your Firebase Google Services version
        classpath("com.google.gms:google-services:4.4.4")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ STANDARDIZED: Flutter-required build directory mapping
rootProject.layout.buildDirectory.value(rootProject.layout.projectDirectory.dir("../build"))

subprojects {
    // Ensure submodules (like :app) also follow this path
    project.layout.buildDirectory.value(rootProject.layout.buildDirectory.dir(project.name))
}

subprojects {
    // This ensures the app module is evaluated correctly by Flutter tools
    project.evaluationDependsOn(":app")
}

// Force desugar library version across all subprojects (Preserved your 2.1.5)
subprojects {
    project.configurations.all {
        resolutionStrategy {
            force("com.android.tools:desugar_jdk_libs:2.1.5")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}