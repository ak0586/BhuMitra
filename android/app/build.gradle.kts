import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val envProps = Properties()
val envFile = rootProject.file("../.env")
if (envFile.exists()) {
    envFile.inputStream().use { envProps.load(it) }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    implementation("com.google.firebase:firebase-auth")
}

android {
    namespace = "app.ankit.bhumitra"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.ankit.bhumitra"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["adMobAppId"] = envProps["ADMOB_APP_ID_ANDROID"] as String? ?: envProps["app_id"] as String? ?: "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        create("release") {
            val keystoreFile = envProps["storeFile"] as String?
            if (keystoreFile != null) {
                storeFile = file(keystoreFile)
                storePassword = envProps["storePassword"] as String
                keyAlias = envProps["keyAlias"] as String
                keyPassword = envProps["keyPassword"] as String
            } else {
                 val keyProps = Properties()
                 val keyPropsFile = rootProject.file("key.properties")
                 if (keyPropsFile.exists()) {
                     keyPropsFile.inputStream().use { keyProps.load(it) }
                     
                     val storeFileVal = keyProps["storeFile"] as? String
                     val storePasswordVal = keyProps["storePassword"] as? String
                     val keyAliasVal = keyProps["keyAlias"] as? String
                     val keyPasswordVal = keyProps["keyPassword"] as? String

                     if (storeFileVal == null || storePasswordVal == null || keyAliasVal == null || keyPasswordVal == null) {
                         throw GradleException("key.properties found but missing required keys: storeFile, storePassword, keyAlias, or keyPassword.")
                     }

                     storeFile = file(storeFileVal)
                     storePassword = storePasswordVal
                     keyAlias = keyAliasVal
                     keyPassword = keyPasswordVal
                 } else {
                     println("Warning: key.properties not found. Release build might fail signing.")
                 }
            }
        }
    }

    buildTypes {
        release {
            // Enable code shrinking, obfuscation, and optimization
            // Temporarily disabled for testing - Re-enable for Prod if desired
            isMinifyEnabled = false
            isShrinkResources = false
            /*
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            */
            signingConfig = signingConfigs.getByName("release")
        }
    }
    
    // Split APKs by ABI for smaller individual APK sizes
    // Temporarily disabled for testing
    /*
    splits {
        abi {
            isEnabled = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = false
        }
    }
    */
}

flutter {
    source = "../.."
}
