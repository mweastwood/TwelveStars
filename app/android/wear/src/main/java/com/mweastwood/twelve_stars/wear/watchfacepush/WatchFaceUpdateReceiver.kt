package com.mweastwood.twelve_stars.wear.watchfacepush

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout

/**
 * Keeps the pushed Twelve Stars watch face up to date whenever the Wear OS app is upgraded.
 */
class WatchFaceUpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) return
        val controller = WatchFacePushController(context)
        if (!controller.isSupported()) return

        val pendingResult = goAsync()
        CoroutineScope(SupervisorJob() + Dispatchers.IO).launch {
            try {
                withTimeout(UPDATE_TIMEOUT_MS) {
                    controller.installOrUpdateWatchFace()
                }
            } catch (_: Exception) {
                // Best-effort update; users can also update/activate from the main screen.
            } finally {
                pendingResult.finish()
            }
        }
    }

    companion object {
        private const val UPDATE_TIMEOUT_MS = 8_000L
    }
}
