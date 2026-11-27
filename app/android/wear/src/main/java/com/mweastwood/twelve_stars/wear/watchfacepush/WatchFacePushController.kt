package com.mweastwood.twelve_stars.wear.watchfacepush

import android.content.Context
import android.os.ParcelFileDescriptor
import androidx.wear.watchfacepush.WatchFacePushManager
import androidx.wear.watchfacepush.WatchFacePushManagerFactory
import com.mweastwood.twelve_stars.wear.R
import com.mweastwood.twelve_stars.wear.data.LiturgicalColor
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

sealed interface WatchFacePushOutcome {
    data object Activated : WatchFacePushOutcome
    data object AlreadyActive : WatchFacePushOutcome
    data class InstalledPickInGallery(val detail: String? = null) : WatchFacePushOutcome
    data class Failed(val reason: String) : WatchFacePushOutcome
}

/**
 * Coordinates installing, updating, and activating the bundled Twelve Stars
 * Watch Face Format APK via Wear OS 6+ Watch Face Push, defaulting the watch face
 * theme to the current liturgical color.
 */
class WatchFacePushController(
    private val managerProvider: () -> WatchFacePushManager,
    private val isSupportedCheck: () -> Boolean,
    private val validationTokenProvider: (LiturgicalColor) -> String,
    private val openApkFd: (LiturgicalColor) -> Pair<ParcelFileDescriptor, () -> Unit>,
) {
    constructor(context: Context) : this(
        managerProvider = {
            WatchFacePushManagerFactory.createWatchFacePushManager(context.applicationContext)
        },
        isSupportedCheck = {
            runCatching { WatchFacePushManagerFactory.isSupported() }.getOrDefault(false)
        },
        validationTokenProvider = { color ->
            context.applicationContext.getString(tokenResForColor(color))
        },
        openApkFd = { color ->
            val appContext = context.applicationContext
            val assetName = assetNameForColor(color)
            val tempFile = File.createTempFile("twelve_stars_wf_", ".apk", appContext.cacheDir)
            try {
                appContext.assets.open(assetName).use { input ->
                    tempFile.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
                val pfd = ParcelFileDescriptor.open(tempFile, ParcelFileDescriptor.MODE_READ_ONLY)
                pfd to {
                    runCatching { pfd.close() }
                    tempFile.delete()
                }
            } catch (e: Exception) {
                tempFile.delete()
                throw e
            }
        },
    )

    fun isSupported(): Boolean = isSupportedCheck()

    suspend fun isBundledWatchFaceActive(): Boolean = withContext(Dispatchers.IO) {
        if (!isSupported()) return@withContext false
        try {
            val manager = managerProvider()
            val details = manager.listWatchFaces().installedWatchFaceDetails.firstOrNull()
                ?: return@withContext false
            manager.isWatchFaceActive(details.packageName)
        } catch (e: CancellationException) {
            throw e
        } catch (_: Exception) {
            false
        }
    }

    suspend fun installOrUpdateWatchFace(
        color: LiturgicalColor = LiturgicalColor.GREEN,
    ): WatchFacePushManager.WatchFaceDetails =
        withContext(Dispatchers.IO) {
            val manager = managerProvider()
            val token = validationTokenProvider(color)
            require(token.isNotBlank()) { "Watch face validation token is blank" }

            val response = manager.listWatchFaces()
            val existing = response.installedWatchFaceDetails.firstOrNull()
            val (pfd, cleanup) = openApkFd(color)
            try {
                when {
                    existing != null -> manager.updateWatchFace(existing.slotId, pfd, token)
                    response.remainingSlotCount > 0 -> manager.addWatchFace(pfd, token)
                    else -> throw IllegalStateException("No Watch Face Push slots available")
                }
            } finally {
                cleanup()
            }
        }

    suspend fun syncColorIfInstalled(color: LiturgicalColor): Boolean =
        withContext(Dispatchers.IO) {
            if (!isSupported()) return@withContext false
            try {
                val manager = managerProvider()
                val existing = manager.listWatchFaces().installedWatchFaceDetails.firstOrNull()
                    ?: return@withContext false
                val token = validationTokenProvider(color)
                if (token.isBlank()) return@withContext false
                val (pfd, cleanup) = openApkFd(color)
                try {
                    manager.updateWatchFace(existing.slotId, pfd, token)
                    true
                } finally {
                    cleanup()
                }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                false
            }
        }

    suspend fun installAndActivate(
        canSetActive: Boolean,
        color: LiturgicalColor = LiturgicalColor.GREEN,
    ): WatchFacePushOutcome =
        withContext(Dispatchers.IO) {
            if (!isSupported()) {
                return@withContext WatchFacePushOutcome.Failed("Requires Wear OS 6+")
            }
            try {
                val manager = managerProvider()
                val details = installOrUpdateWatchFace(color)
                if (manager.isWatchFaceActive(details.packageName)) {
                    return@withContext WatchFacePushOutcome.AlreadyActive
                }
                if (!canSetActive) {
                    return@withContext WatchFacePushOutcome.InstalledPickInGallery("Permission denied")
                }
                try {
                    manager.setWatchFaceAsActive(details.slotId)
                    WatchFacePushOutcome.Activated
                } catch (e: WatchFacePushManager.SetWatchFaceAsActiveException) {
                    // System limits automatic activation; the watch face is installed in the gallery.
                    WatchFacePushOutcome.InstalledPickInGallery("Set active code ${e.errorCode}")
                } catch (_: SecurityException) {
                    WatchFacePushOutcome.InstalledPickInGallery("Set active permission")
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: WatchFacePushManager.AddWatchFaceException) {
                WatchFacePushOutcome.Failed("Add error ${e.errorCode}")
            } catch (e: WatchFacePushManager.UpdateWatchFaceException) {
                WatchFacePushOutcome.Failed("Update error ${e.errorCode}")
            } catch (e: Exception) {
                WatchFacePushOutcome.Failed(e.message ?: "Unable to install watch face")
            }
        }

    companion object {
        const val DEFAULT_WATCHFACE_ASSET = "default_watchface.apk"
        const val PERMISSION_SET_ACTIVE =
            "com.google.wear.permission.SET_PUSHED_WATCH_FACE_AS_ACTIVE"

        fun themeKeyForColor(color: LiturgicalColor): String = when (color) {
            LiturgicalColor.GREEN -> "green"
            LiturgicalColor.PURPLE, LiturgicalColor.ROSE -> "purple"
            LiturgicalColor.RED -> "red"
            LiturgicalColor.WHITE -> "white"
        }

        fun assetNameForColor(color: LiturgicalColor): String =
            "watchface_${themeKeyForColor(color)}.apk"

        fun tokenResForColor(color: LiturgicalColor): Int = when (color) {
            LiturgicalColor.GREEN -> R.string.wf_token_green
            LiturgicalColor.PURPLE, LiturgicalColor.ROSE -> R.string.wf_token_purple
            LiturgicalColor.RED -> R.string.wf_token_red
            LiturgicalColor.WHITE -> R.string.wf_token_white
        }
    }
}
