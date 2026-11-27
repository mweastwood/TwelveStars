import java.io.File
import java.util.Properties
import org.gradle.api.DefaultTask
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.CacheableTask
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction

plugins {
    id("com.android.application")
}

@CacheableTask
abstract class GenerateThemedWatchFaceXmlTask : DefaultTask() {
    @get:InputFile
    @get:PathSensitive(PathSensitivity.NONE)
    abstract val templateXml: RegularFileProperty

    @get:Input
    abstract val autoColors: Property<String>

    @get:OutputDirectory
    abstract val resOutputDir: DirectoryProperty

    @TaskAction
    fun generate() {
        val rawDir = File(resOutputDir.get().asFile, "raw")
        rawDir.mkdirs()
        val template = templateXml.get().asFile.readText()
        val updated = template.replace(
            Regex("""(<ColorOption\s+id="liturgical_auto"[^>]*?colors=")[^"]+(")"""),
            "$1${autoColors.get()}$2",
        )
        File(rawDir, "watchface.xml").writeText(updated)
    }
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

    flavorDimensions += listOf("env", "theme")

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
        create("green") { dimension = "theme" }
        create("purple") { dimension = "theme" }
        create("red") { dimension = "theme" }
        create("white") { dimension = "theme" }
    }

    val hasReleaseSigning = System.getenv("ANDROID_KEYSTORE_PATH") != null ||
        rootProject.file("key.properties").exists()

    signingConfigs {
        if (hasReleaseSigning) {
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
                    val properties = Properties().apply {
                        keystorePropertiesFile.inputStream().use { load(it) }
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
                }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hasReleaseSigning) "release" else "debug")
            isMinifyEnabled = true
            isShrinkResources = false
            vcsInfo {
                include = false
            }
        }
    }
}

val liturgicalAutoColors = mapOf(
    "purple" to "#FF4A148C #FFD4AF37 #FFF3E5F5",
    "red" to "#FF8E0000 #FFD4AF37 #FFFFEBEE",
    "white" to "#FF3E2723 #FFFFD54F #FFFFF8E1",
)

androidComponents {
    onVariants { variant ->
        val theme = variant.productFlavors.firstOrNull { it.first == "theme" }?.second ?: return@onVariants
        val colors = liturgicalAutoColors[theme] ?: return@onVariants
        val variantCap = variant.name.replaceFirstChar { it.uppercase() }
        val genTask = tasks.register<GenerateThemedWatchFaceXmlTask>("generate${variantCap}WatchFaceXml") {
            templateXml.set(layout.projectDirectory.file("src/main/res/raw/watchface.xml"))
            autoColors.set(colors)
        }
        variant.sources.res?.addGeneratedSourceDirectory(
            genTask,
            GenerateThemedWatchFaceXmlTask::resOutputDir,
        )
    }
}

configurations.configureEach {
    exclude(group = "org.jetbrains.kotlin")
}
