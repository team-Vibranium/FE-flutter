import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.aningcall"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.aningcall"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (project.hasProperty("key.properties")) {
                val keyPropertiesFile = rootProject.file("android/key.properties")
                if (keyPropertiesFile.exists()) {
                    val keyProperties = Properties()
                    keyProperties.load(FileInputStream(keyPropertiesFile))
                    storeFile = file(keyProperties["storeFile"] as String)
                    storePassword = keyProperties["storePassword"] as String
                    keyAlias = keyProperties["keyAlias"] as String
                    keyPassword = keyProperties["keyPassword"] as String
                }
            }
        }
    }

    // ✅ Kotlin DSL 문법으로 수정
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.24") // ✅ 직접 버전 입력
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
