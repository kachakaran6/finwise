import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.finwise.appilcation"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.finwise.appilcation"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = System.getenv("KEYSTORE_FILE") ?: keystoreProperties.getProperty("storeFile")
            val storePass = System.getenv("KEYSTORE_PASSWORD") ?: keystoreProperties.getProperty("storePassword")
            val keyAliasStr = System.getenv("KEY_ALIAS") ?: keystoreProperties.getProperty("keyAlias")
            val keyPass = System.getenv("KEY_PASSWORD") ?: keystoreProperties.getProperty("keyPassword")

            if (!storeFilePath.isNullOrEmpty() && !storePass.isNullOrEmpty() && !keyAliasStr.isNullOrEmpty() && !keyPass.isNullOrEmpty()) {
                val resolvedFile = when {
                    File(storeFilePath).isAbsolute -> File(storeFilePath)
                    rootProject.file(storeFilePath).exists() -> rootProject.file(storeFilePath)
                    project.file(storeFilePath).exists() -> project.file(storeFilePath)
                    else -> rootProject.file(storeFilePath)
                }
                if (resolvedFile.exists()) {
                    storeFile = resolvedFile
                    storePassword = storePass
                    keyAlias = keyAliasStr
                    keyPassword = keyPass
                }
            }
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")
            if (releaseSigning.storeFile != null && releaseSigning.storeFile!!.exists()) {
                signingConfig = releaseSigning
            } else {
                throw GradleException("Production release build requires valid signing credentials. Ensure android/key.properties or environment variables (KEYSTORE_FILE, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD) are configured.")
            }
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
