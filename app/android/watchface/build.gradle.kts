import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
}

android {
    namespace = "com.mweastwood.twelve_stars.watchface"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.mweastwood.twelve_stars.watchfacepush.twelve_stars"
        minSdk = 33
        targetSdk = 35
        versionCode = (project.findProperty("watchfaceVersionCode") as String?)?.toIntOrNull() ?: 1
        versionName = (project.findProperty("watchfaceVersionName") as String?) ?: "1.0.0"
    }

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    packaging {
        resources {
            excludes += listOf(
                "META-INF/*.version",
                "META-INF/androidx.*",
                "kotlin-tooling-metadata.json",
                "DebugProbesKt.bin",
            )
        }
    }

    flavorDimensions += "env"

    productFlavors {
        create("dev") {
            dimension = "env"
            applicationId = "com.mweastwood.twelve_stars.dev.watchfacepush.twelve_stars"
            resValue("string", "watchface_app_name", "Twelve Stars Watch Face (Dev)")
        }
        create("prod") {
            dimension = "env"
            applicationId = "com.mweastwood.twelve_stars.watchfacepush.twelve_stars"
            resValue("string", "watchface_app_name", "Twelve Stars Watch Face")
        }
    }

    signingConfigs {
        create("release") {
            val storeFileEnv = System.getenv("ANDROID_KEYSTORE_PATH")
            if (storeFileEnv != null) {
                val envFile = File(storeFileEnv)
                storeFile = when {
                    envFile.isAbsolute -> envFile
                    rootProject.file("app/$storeFileEnv").exists() -> rootProject.file("app/$storeFileEnv")
                    else -> rootProject.file(storeFileEnv)
                }
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
                    ?: System.getenv("ANDROID_KEYSTORE_PASSWORD")
            } else {
                val keystorePropertiesFile = rootProject.file("key.properties")
                if (keystorePropertiesFile.exists()) {
                    val properties = Properties().apply {
                        load(keystorePropertiesFile.inputStream())
                    }
                    val propStoreFile = properties.getProperty("storeFile")
                    storeFile = if (File(propStoreFile).isAbsolute) {
                        File(propStoreFile)
                    } else {
                        rootProject.file(propStoreFile)
                    }
                    storePassword = properties.getProperty("storePassword")
                    keyAlias = properties.getProperty("keyAlias")
                    keyPassword = properties.getProperty("keyPassword")
                } else {
                    val debugConfig = signingConfigs.getByName("debug")
                    storeFile = debugConfig.storeFile
                    storePassword = debugConfig.storePassword
                    keyAlias = debugConfig.keyAlias
                    keyPassword = debugConfig.keyPassword
                }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = false
            vcsInfo {
                include = false
            }
        }
    }
}

configurations.configureEach {
    exclude(group = "org.jetbrains.kotlin")
}
