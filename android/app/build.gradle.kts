plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "cn.aiaud.camera"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "cn.aiaud.camera"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }


    // 🌟 新增：配置 Release 签名配置
    signingConfigs {
        create("release") {
            keyAlias = "WTAPP123456"
            keyPassword = "WTAPP123456"
            storeFile = file("../WTAPP123456.keystore")
            storePassword = "WTAPP123456"
        }
    }


    buildTypes {

        debug {
            // 调试模式（flutter run）也使用 release 证书签名
            signingConfig = signingConfigs.getByName("release")
        }

        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")

            // 🌟 1. 开启原生的 Java/Kotlin 代码混淆 (R8)
            isMinifyEnabled = true

            // 🌟 2. 开启无用资源移除（进一步缩小 APK 体积）
            isShrinkResources = true

            // 🌟 3. 指定混淆规则配置文件
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
