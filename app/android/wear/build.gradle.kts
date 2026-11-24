import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "com.mweastwood.twelve_stars.wear"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }

    defaultConfig {
        applicationId = "com.mweastwood.twelve_stars"
        minSdk = 30
        targetSdk = 35
        versionCode = (project.findProperty("wearVersionCode") as String?)?.toIntOrNull() ?: 100000001
        versionName = (project.findProperty("wearVersionName") as String?) ?: "1.0.0"
    }

    flavorDimensions += "env"

    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "TwelveStars (Dev)")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "TwelveStars")
        }
    }

    signingConfigs {
        create("release") {
            val storeFileEnv = System.getenv("ANDROID_KEYSTORE_PATH")
            if (storeFileEnv != null) {
                val envFile = File(storeFileEnv)
                storeFile = if (envFile.isAbsolute) {
                    envFile
                } else {
                    val appRelative = rootProject.file("app/$storeFileEnv")
                    if (appRelative.exists()) appRelative else rootProject.file(storeFileEnv)
                }
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
                    ?: System.getenv("ANDROID_KEYSTORE_PASSWORD")
            } else {
                val keystorePropertiesFile = rootProject.file("key.properties")
                if (keystorePropertiesFile.exists()) {
                    val properties = Properties().apply {
                        keystorePropertiesFile.inputStream().use { load(it) }
                    }
                    val storeFileProp = properties.getProperty("storeFile")
                    if (!storeFileProp.isNullOrBlank()) {
                        val propFile = File(storeFileProp)
                        storeFile = if (propFile.isAbsolute) propFile else rootProject.file(storeFileProp)
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
            isShrinkResources = true
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

val wearRawDir = layout.projectDirectory.dir("src/main/res/raw").asFile
val liturgicalJsonFile = File(wearRawDir, "liturgical_calendar.json")
val rosaryJsonFile = File(wearRawDir, "rosary_data.json")
val flutterAppDir = rootProject.projectDir.parentFile

val generateWearData by tasks.registering {
    val calendarOut = liturgicalJsonFile
    val rosaryOut = rosaryJsonFile
    val appDir = flutterAppDir

    onlyIf {
        !calendarOut.exists() || !rosaryOut.exists()
    }

    doLast {
        fun runDart(vararg args: String) {
            val command = listOf("dart") + args
            val process = try {
                ProcessBuilder(command)
                    .directory(appDir)
                    .inheritIO()
                    .start()
            } catch (e: java.io.IOException) {
                throw GradleException(
                    "Failed to execute 'dart' to generate Wear OS data. Ensure Dart/Flutter is installed and 'dart' is on PATH.",
                    e
                )
            }
            val exitCode = process.waitFor()
            if (exitCode != 0) {
                throw GradleException(
                    "Command '${command.joinToString(" ")}' in ${appDir.absolutePath} failed with exit code $exitCode."
                )
            }
        }

        val prayersJson = File(appDir, "assets/prayers.json")
        if (!prayersJson.exists()) {
            runDart("run", "bin/assemble_db.dart")
        }
        runDart("run", "bin/assemble_wear_data.dart", "--out-dir=android/wear/src/main/res/raw")
    }
}

tasks.matching { it.name == "preBuild" }.configureEach {
    dependsOn(generateWearData)
}

dependencies {
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation(platform("androidx.compose:compose-bom:2025.02.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.wear.compose:compose-material:1.4.1")
    implementation("androidx.wear.compose:compose-foundation:1.4.1")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20250107")
}
