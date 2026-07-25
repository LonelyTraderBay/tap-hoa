import org.gradle.api.GradleException
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningPropertiesFile = rootProject.file("key.properties")
val releaseSigningProperties = Properties().apply {
    if (releaseSigningPropertiesFile.exists()) {
        releaseSigningPropertiesFile.inputStream().use { load(it) }
    }
}

val releaseSigningPropertyNames = listOf("storePassword", "keyPassword", "keyAlias", "storeFile")
val releaseStoreFile = releaseSigningProperties.getProperty("storeFile")
    ?.takeUnless { it.isBlank() }
    ?.let { rootProject.file(it) }

gradle.taskGraph.whenReady { taskGraph ->
    val hasReleaseTask = taskGraph.allTasks.any { it.project == project && it.name.lowercase().contains("release") }

    if (hasReleaseTask) {
        if (!releaseSigningPropertiesFile.exists()) {
            throw GradleException(
                "Missing Android release signing file: ${releaseSigningPropertiesFile.path}. " +
                    "Copy key.properties.example to key.properties and set local keystore values.",
            )
        }

        val missingProperties = releaseSigningPropertyNames.filter {
            releaseSigningProperties.getProperty(it).isNullOrBlank()
        }

        if (missingProperties.isNotEmpty()) {
            throw GradleException(
                "Missing Android release signing properties in ${releaseSigningPropertiesFile.path}: " +
                    missingProperties.joinToString(", ") + ".",
            )
        }

        if (releaseStoreFile == null || !releaseStoreFile.exists()) {
            throw GradleException(
                "Android release keystore not found at '${releaseStoreFile?.path}'. " +
                    "Check storeFile in ${releaseSigningPropertiesFile.path}.",
            )
        }
    }
}

android {
    namespace = "vn.taphoa.pos_app"
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
        applicationId = "vn.taphoa.pos_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseSigningPropertiesFile.exists()) {
                keyAlias = releaseSigningProperties.getProperty("keyAlias")
                keyPassword = releaseSigningProperties.getProperty("keyPassword")
                storeFile = releaseStoreFile
                storePassword = releaseSigningProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
