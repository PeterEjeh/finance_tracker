plugins {
    id("com.android.application")
    id("com.google.gms.google-services")  // Firebase plugin
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.finance_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    // Workaround for flutter_native_timezone namespace issue
    sourceSets["main"].manifest.srcFile("src/main/AndroidManifest.xml")

    compileOptions {
        // Enable core library desugaring for Java 8+ APIs used by dependencies
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.example.finance_tracker"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.1"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.android.gms:play-services-auth:20.7.0") // Google Sign-In
    implementation("androidx.multidex:multidex:2.0.1") // If multidex is needed
    // Core library desugaring for Java 8+ APIs required by flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}

// After assembleRelease, copy the produced APK to a friendly filename
val renameReleaseApk by tasks.registering {
    doLast {
        val possiblePaths = listOf(
            "$buildDir/outputs/flutter-apk",
            "$buildDir/outputs/apk/release",
            "$buildDir/outputs/apk"
        )

        val apkFile = possiblePaths
            .map { file(it) }
            .filter { it.exists() }
            .flatMap { it.listFiles()?.toList() ?: emptyList() }
            .firstOrNull { it.extension == "apk" }

        if (apkFile != null) {
            val dest = file(apkFile.parentFile.resolve("Finance Tracker.apk"))
            apkFile.copyTo(dest, overwrite = true)
            println("Renamed APK: ${apkFile.name} -> ${dest.name}")
        } else {
            println("No APK found to rename in expected output directories.")
        }
    }
}

// Ensure the rename runs after assembleRelease when that task exists
tasks.matching { it.name == "assembleRelease" }.configureEach {
    finalizedBy(renameReleaseApk)
}
