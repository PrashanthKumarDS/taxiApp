import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropsFile = rootProject.file("local.properties")
if (localPropsFile.exists()) {
    localPropsFile.inputStream().use { localProperties.load(it) }
}
fun readGoogleServicesApiKey(file: File): String? {
    if (!file.exists()) return null
    val m = Regex(""""current_key"\s*:\s*"([^"]+)"""").find(file.readText())
    return m?.groupValues?.getOrNull(1)
}

val googleServicesJson = file("google-services.json")
val mapsKeyFromProperties =
    localProperties.getProperty("GOOGLE_MAPS_API_KEY")?.takeIf { it.isNotBlank() }
val mapsKeyFromFirebaseJson = readGoogleServicesApiKey(googleServicesJson)
val googleMapsApiKeyAndroid =
    mapsKeyFromProperties ?: mapsKeyFromFirebaseJson ?: "YOUR_ANDROID_MAPS_KEY"

android {
    namespace = "com.mytowncabs.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.mytowncabs.app"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKeyAndroid
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

dependencies {
    // Align native Firebase libraries (FlutterFire plugins still supply most artifacts).
    implementation(platform("com.google.firebase:firebase-bom:34.11.0"))
    implementation("com.google.firebase:firebase-analytics")
}
