import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing:
// - android/key.properties present (storeFile, storePassword, keyAlias,
//   keyPassword): sign with that key. GitHub releases write it from the
//   repository secrets; the key itself is never committed.
// - MELODY_UNSIGNED=1: leave the APK unsigned; F-Droid signs it itself.
// - otherwise: this machine's own debug key, for local testing only.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use(::load)
}
val unsignedRelease = System.getenv("MELODY_UNSIGNED") == "1"
val tailscaleAar = file("libs/tsbridge.aar")

android {
    namespace = "io.github.engineer948.melody"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.engineer948.melody"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyProperties.isNotEmpty()) {
            create("release") {
                storeFile = rootProject.file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = when {
                unsignedRelease -> null
                keyProperties.isNotEmpty() -> signingConfigs.getByName("release")
                else -> signingConfigs.getByName("debug")
            }
        }
    }

    // The built-in Tailscale node (native/tailscale, built with
    // tool/build_tailscale.sh) is only compiled in when its library exists;
    // otherwise a stub hides the feature.
    sourceSets {
        getByName("main") {
            java.srcDir(if (tailscaleAar.exists()) "src/tailscale/kotlin" else "src/notailscale/kotlin")
        }
    }

    // Native libraries are stored compressed: much smaller APK downloads
    // (the Tailscale library is ~20 MB per CPU uncompressed); Android
    // unpacks them once at install time.
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    // Google's encrypted dependency report is not wanted in F-Droid builds.
    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
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

dependencies {
    if (tailscaleAar.exists()) {
        implementation(files(tailscaleAar))
    }
}
