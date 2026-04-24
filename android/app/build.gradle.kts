import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun readKeystoreProp(name: String): String? {
    val direct = keystoreProperties.getProperty(name)?.trim()
    if (!direct.isNullOrEmpty()) {
        return direct
    }
    val bomPrefixed = keystoreProperties.getProperty("\uFEFF$name")?.trim()
    if (!bomPrefixed.isNullOrEmpty()) {
        return bomPrefixed
    }
    return null
}

val storeFileValue = readKeystoreProp("storeFile")
val storePasswordValue = readKeystoreProp("storePassword")
val keyAliasValue = readKeystoreProp("keyAlias")
val keyPasswordValue = readKeystoreProp("keyPassword")
val releaseStoreFile = storeFileValue?.let { rootProject.file(it) }
val hasKeystoreConfig = keystorePropertiesFile.exists() &&
    !storePasswordValue.isNullOrEmpty() &&
    !keyAliasValue.isNullOrEmpty() &&
    !keyPasswordValue.isNullOrEmpty() &&
    releaseStoreFile?.exists() == true

android {
    namespace = "com.garkename.yetisportspinguthrow"
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
        applicationId = "com.garkename.yetisportspinguthrow"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasKeystoreConfig) {
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
                storeFile = releaseStoreFile
                storePassword = storePasswordValue
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasKeystoreConfig) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
