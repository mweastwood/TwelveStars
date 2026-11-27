package com.mweastwood.twelve_stars.wear.watchfacepush

import android.content.Context
import android.os.ParcelFileDescriptor
import androidx.wear.watchfacepush.WatchFacePushManager
import androidx.wear.watchfacepush.WatchFacePushManagerFactory
import com.mweastwood.twelve_stars.wear.R
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

sealed interface WatchFacePushOutcome {
    data object Activated : WatchFacePushOutcome
    data object AlreadyActive : WatchFacePushOutcome
    data object InstalledPickInGallery : WatchFacePushOutcome
    data class Failed(val reason: String) : WatchFacePushOutcome
}

/**
 * Coordinates installing, updating, and activating the bundled Twelve Stars
 * Watch Face Format APK via Wear OS 6+ Watch Face Push.
 */
class WatchFacePushController(
    private val managerProvider: () -> WatchFacePushManager,
    private val isSupportedCheck: () -> Boolean,
    private val validationTokenProvider: () -> String,
    private val openApkFd: () -> Pair<ParcelFileDescriptor, () -> Unit>,
) {
    constructor(context: Context) : this(
        managerProvider = {
            WatchFacePushManagerFactory.createWatchFacePushManager(context.applicationContext)
        },
        isSupportedCheck = {
            runCatching { WatchFacePushManagerFactory.isSupported() }.getOrDefault(false)
        },
        validationTokenProvider = {
            context.applicationContext.getString(R.string.default_wf_token)
        },
        openApkFd = {
            val appContext = context.applicationContext
            val tempFile = File.createTempFile("twelve_stars_wf_", ".apk", appContext.cacheDir)
            appContext.assets.open(DEFAULT_WATCHFACE_ASSET).use { input ->
                tempFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            val pfd = ParcelFileDescriptor.open(tempFile, ParcelFileDescriptor.MODE_READ_ONLY)
            pfd to {
                runCatching { pfd.close() }
                tempFile.delete()
            }
        },
    )

    fun isSupported(): Boolean = isSupportedCheck()

    suspend fun isBundledWatchFaceActive(): Boolean = withContext(Dispatchers.IO) {
        if (!isSupported()) return@withContext false
        runCatching {
            val manager = managerProvider()
            val details = manager.listWatchFaces().installedWatchFaceDetails.firstOrNull()
                ?: return@runCatching false
            manager.isWatchFaceActive(details.packageName)
        }.getOrDefault(false)
    }

    suspend fun installOrUpdateWatchFace(): WatchFacePushManager.WatchFaceDetails =
        withContext(Dispatchers.IO) {
            val manager = managerProvider()
            val token = validationTokenProvider()
            require(token.isNotBlank()) { "Default watch face validation token is blank" }

            val response = manager.listWatchFaces()
            val existing = response.installedWatchFaceDetails.firstOrNull()
            val (pfd, cleanup) = openApkFd()
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

    suspend fun installAndActivate(canSetActive: Boolean): WatchFacePushOutcome =
        withContext(Dispatchers.IO) {
            if (!isSupported()) {
                return@withContext WatchFacePushOutcome.Failed("Requires Wear OS 6+")
            }
            try {
                val manager = managerProvider()
                val details = installOrUpdateWatchFace()
                if (manager.isWatchFaceActive(details.packageName)) {
                    return@withContext WatchFacePushOutcome.AlreadyActive
                }
                if (!canSetActive) {
                    return@withContext WatchFacePushOutcome.InstalledPickInGallery
                }
                try {
                    manager.setWatchFaceAsActive(details.slotId)
                    WatchFacePushOutcome.Activated
                } catch (_: WatchFacePushManager.SetWatchFaceAsActiveException) {
                    // System limits automatic activation; the watch face is installed in the gallery.
                    WatchFacePushOutcome.InstalledPickInGallery
                }
            } catch (e: Exception) {
                WatchFacePushOutcome.Failed(e.message ?: "Unable to install watch face")
            }
        }

    companion object {
        const val DEFAULT_WATCHFACE_ASSET = "default_watchface.apk"
        const val PERMISSION_SET_ACTIVE =
            "com.google.wear.permission.SET_PUSHED_WATCH_FACE_AS_ACTIVE"
    }
}
