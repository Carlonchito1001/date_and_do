import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Lee android/key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.finatech.date_and_doing"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.finatech.date_and_doing"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ Firma release con tu keystore (no debug)
    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"]?.toString()

            // storeFile (desde android/key.properties)
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = rootProject.file(storeFilePath)
            }

            storePassword = keystoreProperties["storePassword"]?.toString()
            keyAlias = keystoreProperties["keyAlias"]?.toString()
            keyPassword = keystoreProperties["keyPassword"]?.toString()
        }
    }

    buildTypes {
        release {
            // ✅ usa release signing
            signingConfig = signingConfigs.getByName("release")

            // Opcional:
            // isMinifyEnabled = true
            // isShrinkResources = true
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
        debug {
            // se queda con debug signing default
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 🔥 Necesario para Java 8+ (requerido por flutter_local_notifications)
    add("coreLibraryDesugaring", "com.android.tools:desugar_jdk_libs:2.1.4")

    // 🔥 Firebase BOM
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))

    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

    // 🔥 Firebase Messaging (para recibir notificaciones)
    implementation("com.google.firebase:firebase-messaging")

    // AndroidX essentials
    implementation("androidx.core:core-ktx:1.10.1")
}
