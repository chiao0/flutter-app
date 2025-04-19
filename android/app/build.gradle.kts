plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // 🔹 新增firebase
}

dependencies {
    // Firebase BoM（你已加了這行，沒問題）
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))

    // Firebase Analytics（保留）
    implementation("com.google.firebase:firebase-analytics")

    // ✅ 新增 Firebase Auth
    implementation("com.google.firebase:firebase-auth")

    // 如果你未來有使用 Firebase Firestore、Storage 等也可加上
    // implementation("com.google.firebase:firebase-firestore")
    // implementation("com.google.firebase:firebase-storage")
    implementation("com.google.android.gms:play-services-fitness:21.1.0")
    implementation("com.google.android.gms:play-services-auth:20.4.0")
}

android {
    namespace = "com.example.health_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"  // 修改此行

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.health_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdkVersion(26)

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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