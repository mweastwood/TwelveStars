import java.io.File
import java.util.Properties
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.CacheableTask
import org.gradle.api.tasks.Classpath
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

@CacheableTask
abstract class PrepareDefaultWatchFaceTask : DefaultTask() {
    @get:InputFile
    @get:PathSensitive(PathSensitivity.NONE)
    abstract val greenWatchFaceApk: RegularFileProperty

    @get:InputFile
    @get:PathSensitive(PathSensitivity.NONE)
    abstract val purpleWatchFaceApk: RegularFileProperty

    @get:InputFile
    @get:PathSensitive(PathSensitivity.NONE)
    abstract val redWatchFaceApk: RegularFileProperty

    @get:InputFile
    @get:PathSensitive(PathSensitivity.NONE)
    abstract val whiteWatchFaceApk: RegularFileProperty

    @get:Classpath
    abstract val validatorClasspath: ConfigurableFileCollection

    @get:Input
    abstract val callerPackageName: Property<String>

    @get:OutputDirectory
    abstract val assetsOutputDir: DirectoryProperty

    @get:OutputDirectory
    abstract val resOutputDir: DirectoryProperty

    @TaskAction
    fun prepare() {
        val validatorJar = validatorClasspath.files.firstOrNull {
            it.name.startsWith("validator-push-cli") && it.extension == "jar"
        } ?: throw GradleException("Could not resolve validator-push-cli jar from watchFaceValidator configuration")

        val javaBin = File(System.getProperty("java.home"), "bin/java").absolutePath
        val assetsDir = assetsOutputDir.get().asFile
        assetsDir.mkdirs()

        fun escapeXmlString(raw: String): String = raw
            .replace("\\", "\\\\")
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("'", "\\'")
            .replace("\"", "\\\"")
            .let { if (it.startsWith("@") || it.startsWith("?")) "\\$it" else it }

        fun validateAndCopy(apkFile: File, assetName: String): String {
            if (!apkFile.exists()) {
                throw GradleException("Watch face APK not found at ${apkFile.absolutePath}")
            }
            val command = listOf(
                javaBin,
                "-jar",
                validatorJar.absolutePath,
                "--apk_path=${apkFile.absolutePath}",
                "--package_name=${callerPackageName.get()}",
            )
            val process = ProcessBuilder(command)
                .redirectErrorStream(true)
                .start()
            val output = process.inputStream.bufferedReader().use { it.readText() }
            val exitCode = process.waitFor()

            val tokenMatch = Regex("""generated token:\s*(\S+)""").find(output)
            if (exitCode != 0 || !output.contains("Validation is successful") || tokenMatch == null) {
                throw GradleException(
                    "Watch Face Push validation failed for ${apkFile.name} (package=${callerPackageName.get()}, exitCode=$exitCode):\n$output",
                )
            }
            apkFile.copyTo(File(assetsDir, assetName), overwrite = true)
            return escapeXmlString(tokenMatch.groupValues[1])
        }

        val greenToken = validateAndCopy(greenWatchFaceApk.get().asFile, "watchface_green.apk")
        val purpleToken = validateAndCopy(purpleWatchFaceApk.get().asFile, "watchface_purple.apk")
        val redToken = validateAndCopy(redWatchFaceApk.get().asFile, "watchface_red.apk")
        val whiteToken = validateAndCopy(whiteWatchFaceApk.get().asFile, "watchface_white.apk")

        // Also provide default_watchface.apk for Wear OS 6+ automatic default watch face install.
        greenWatchFaceApk.get().asFile.copyTo(File(assetsDir, "default_watchface.apk"), overwrite = true)

        val valuesDir = File(resOutputDir.get().asFile, "values")
        valuesDir.mkdirs()
        File(valuesDir, "watchface_push_token.xml").writeText(
            """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="default_wf_token" translatable="false">$greenToken</string>
    <string name="wf_token_green" translatable="false">$greenToken</string>
    <string name="wf_token_purple" translatable="false">$purpleToken</string>
    <string name="wf_token_red" translatable="false">$redToken</string>
    <string name="wf_token_white" translatable="false">$whiteToken</string>
</resources>
""",
        )
    }
}

val watchFaceValidator by configurations.creating {
    isCanBeConsumed = false
    isCanBeResolved = true
}

android {
    namespace = "com.mweastwood.twelve_stars.wear"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                val isRecord = System.getProperty("roborazzi.test.record", "false").toBoolean()
                it.systemProperty("roborazzi.test.record", isRecord.toString())
                it.systemProperty(
                    "roborazzi.test.verify",
                    System.getProperty("roborazzi.test.verify", (!isRecord).toString()),
                )
                it.systemProperty(
                    "robolectric.dependency.repo.url",
                    "https://maven-central.storage-download.googleapis.com/maven2/",
                )
                it.systemProperty(
                    "robolectric.dependency.repo.id",
                    "maven-central-mirror",
                )
            }
        }
    }

    defaultConfig {
        applicationId = "com.mweastwood.twelve_stars"
        minSdk = 34
        targetSdk = 36
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

    val hasReleaseSigning = System.getenv("ANDROID_KEYSTORE_PATH") != null ||
        rootProject.file("key.properties").exists()

    signingConfigs {
        if (hasReleaseSigning) {
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
                }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hasReleaseSigning) "release" else "debug")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

androidComponents {
    onVariants { variant ->
        val envFlavor = variant.flavorName ?: "prod"
        val envCap = envFlavor.replaceFirstChar { it.uppercase() }
        val variantCap = variant.name.replaceFirstChar { it.uppercase() }
        val watchFaceProject = project(":watchface")

        fun themedApk(theme: String) = watchFaceProject.layout.buildDirectory.file(
            "outputs/apk/${envFlavor}${theme.replaceFirstChar { it.uppercase() }}/release/watchface-$envFlavor-$theme-release.apk",
        )

        val prepareTask = tasks.register<PrepareDefaultWatchFaceTask>("prepare${variantCap}DefaultWatchFace") {
            dependsOn(
                ":watchface:assemble${envCap}GreenRelease",
                ":watchface:assemble${envCap}PurpleRelease",
                ":watchface:assemble${envCap}RedRelease",
                ":watchface:assemble${envCap}WhiteRelease",
            )
            greenWatchFaceApk.set(themedApk("green"))
            purpleWatchFaceApk.set(themedApk("purple"))
            redWatchFaceApk.set(themedApk("red"))
            whiteWatchFaceApk.set(themedApk("white"))
            validatorClasspath.from(watchFaceValidator)
            callerPackageName.set(variant.applicationId)
        }

        variant.sources.assets?.addGeneratedSourceDirectory(
            prepareTask,
            PrepareDefaultWatchFaceTask::assetsOutputDir,
        )
        variant.sources.res?.addGeneratedSourceDirectory(
            prepareTask,
            PrepareDefaultWatchFaceTask::resOutputDir,
        )
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
val gospelJsonFile = File(wearRawDir, "gospel_data.json")
val flutterAppDir = rootProject.projectDir.parentFile

val generateWearData by tasks.registering {
    val calendarOut = liturgicalJsonFile
    val rosaryOut = rosaryJsonFile
    val gospelOut = gospelJsonFile
    val appDir = flutterAppDir

    onlyIf {
        !calendarOut.exists() || !rosaryOut.exists() || !gospelOut.exists()
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
    watchFaceValidator("com.google.android.wearable.watchface.validator:validator-push-cli:1.1.0-alpha01")

    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    implementation(platform("androidx.compose:compose-bom:2025.02.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.wear.compose:compose-material:1.4.1")
    implementation("androidx.wear.compose:compose-foundation:1.4.1")
    implementation("androidx.wear.watchface:watchface-complications-data-source-ktx:1.2.1")
    implementation("androidx.wear.watchfacepush:watchfacepush:1.0.0")
    implementation("androidx.wear.tiles:tiles:1.4.1")
    implementation("androidx.wear.protolayout:protolayout:1.2.1")
    implementation("androidx.wear.protolayout:protolayout-material:1.2.1")
    implementation("androidx.concurrent:concurrent-futures:1.2.0")

    debugImplementation("androidx.compose.ui:ui-test-manifest")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20250107")
    testImplementation("org.robolectric:robolectric:4.14.1")
    testImplementation(platform("androidx.compose:compose-bom:2025.02.00"))
    testImplementation("androidx.compose.ui:ui-test-junit4")
    testImplementation("io.github.takahirom.roborazzi:roborazzi:1.42.0")
    testImplementation("io.github.takahirom.roborazzi:roborazzi-compose:1.42.0")
    testImplementation("io.github.takahirom.roborazzi:roborazzi-junit-rule:1.42.0")
}
