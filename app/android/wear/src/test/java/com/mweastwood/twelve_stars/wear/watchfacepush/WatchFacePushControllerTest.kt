package com.mweastwood.twelve_stars.wear.watchfacepush

import android.os.ParcelFileDescriptor
import androidx.wear.watchfacepush.WatchFacePushManager
import com.mweastwood.twelve_stars.wear.data.LiturgicalColor
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class WatchFacePushControllerTest {
    private class FakeWatchFacePushManager(
        var installed: MutableList<WatchFacePushManager.WatchFaceDetails> = mutableListOf(),
        var remainingSlots: Int = 1,
        var activePackageName: String? = null,
        var failAdd: Boolean = false,
        var failSetActiveWithSecurityException: Boolean = false,
    ) : WatchFacePushManager {
        var addCalls = 0
        var updateCalls = 0
        var setActiveCalls = 0
        var lastToken: String? = null
        var lastUpdatedSlotId: String? = null

        override suspend fun listWatchFaces(): WatchFacePushManager.ListWatchFacesResponse =
            WatchFacePushManager.ListWatchFacesResponse(installed.toList(), remainingSlots)

        override suspend fun removeWatchFace(slotId: String) {
            installed.removeAll { it.slotId == slotId }
            remainingSlots++
        }

        override suspend fun addWatchFace(
            apkFd: ParcelFileDescriptor,
            validationToken: String,
        ): WatchFacePushManager.WatchFaceDetails {
            addCalls++
            lastToken = validationToken
            if (failAdd) throw IllegalStateException("Simulated add failure")
            val details = WatchFacePushManager.WatchFaceDetails(
                slotId = "slot-1",
                versionCode = 1L,
                packageName = "com.mweastwood.twelve_stars.watchfacepush.twelve_stars",
                getMetaDataFunc = { emptyList() },
            )
            installed.add(details)
            remainingSlots = (remainingSlots - 1).coerceAtLeast(0)
            return details
        }

        override suspend fun updateWatchFace(
            slotId: String,
            apkFd: ParcelFileDescriptor,
            validationToken: String,
        ): WatchFacePushManager.WatchFaceDetails {
            updateCalls++
            lastToken = validationToken
            lastUpdatedSlotId = slotId
            val updated = WatchFacePushManager.WatchFaceDetails(
                slotId = slotId,
                versionCode = 2L,
                packageName = "com.mweastwood.twelve_stars.watchfacepush.twelve_stars",
                getMetaDataFunc = { emptyList() },
            )
            installed.removeAll { it.slotId == slotId }
            installed.add(updated)
            return updated
        }

        override suspend fun isWatchFaceActive(watchfacePackageName: String): Boolean =
            activePackageName == watchfacePackageName

        override suspend fun setWatchFaceAsActive(slotId: String) {
            setActiveCalls++
            if (failSetActiveWithSecurityException) {
                throw SecurityException("Missing SET_PUSHED_WATCH_FACE_AS_ACTIVE")
            }
            activePackageName = installed.firstOrNull { it.slotId == slotId }?.packageName
        }
    }

    private fun openTempFd(onCleanup: () -> Unit): Pair<ParcelFileDescriptor, () -> Unit> {
        val temp = File.createTempFile("wf_test_", ".apk")
        temp.writeBytes(byteArrayOf(1, 2, 3))
        val pfd = ParcelFileDescriptor.open(temp, ParcelFileDescriptor.MODE_READ_ONLY)
        return pfd to {
            runCatching { pfd.close() }
            temp.delete()
            onCleanup()
        }
    }

    @Test
    fun installAndActivate_addsNewWatchFaceWithRequestedColorAndActivates() = runBlocking {
        val manager = FakeWatchFacePushManager()
        var cleanedUp = false
        var openedColor: LiturgicalColor? = null
        val controller = WatchFacePushController(
            managerProvider = { manager },
            isSupportedCheck = { true },
            validationTokenProvider = { color -> "token-${color.name.lowercase()}" },
            openApkFd = { color ->
                openedColor = color
                openTempFd { cleanedUp = true }
            },
        )

        val outcome = controller.installAndActivate(
            canSetActive = true,
            color = LiturgicalColor.PURPLE,
        )

        assertEquals(WatchFacePushOutcome.Activated, outcome)
        assertEquals(LiturgicalColor.PURPLE, openedColor)
        assertEquals(1, manager.addCalls)
        assertEquals(0, manager.updateCalls)
        assertEquals(1, manager.setActiveCalls)
        assertEquals("token-purple", manager.lastToken)
        assertTrue(cleanedUp)
        assertTrue(controller.isBundledWatchFaceActive())
    }

    @Test
    fun installAndActivate_updatesExistingSlotAndSkipsActivationWhenAlreadyActive() = runBlocking {
        val pkg = "com.mweastwood.twelve_stars.watchfacepush.twelve_stars"
        val existing = WatchFacePushManager.WatchFaceDetails(
            slotId = "slot-existing",
            versionCode = 1L,
            packageName = pkg,
            getMetaDataFunc = { emptyList() },
        )
        val manager = FakeWatchFacePushManager(
            installed = mutableListOf(existing),
            remainingSlots = 0,
            activePackageName = pkg,
        )
        val controller = WatchFacePushController(
            managerProvider = { manager },
            isSupportedCheck = { true },
            validationTokenProvider = { "token-v2" },
            openApkFd = { openTempFd {} },
        )

        val outcome = controller.installAndActivate(canSetActive = true)

        assertEquals(WatchFacePushOutcome.AlreadyActive, outcome)
        assertEquals(0, manager.addCalls)
        assertEquals(1, manager.updateCalls)
        assertEquals("slot-existing", manager.lastUpdatedSlotId)
        assertEquals(0, manager.setActiveCalls)
    }

    @Test
    fun syncColorIfInstalled_updatesExistingSlotWithNewColor() = runBlocking {
        val existing = WatchFacePushManager.WatchFaceDetails(
            slotId = "slot-1",
            versionCode = 1L,
            packageName = "com.mweastwood.twelve_stars.watchfacepush.twelve_stars",
            getMetaDataFunc = { emptyList() },
        )
        val manager = FakeWatchFacePushManager(
            installed = mutableListOf(existing),
            remainingSlots = 0,
        )
        val controller = WatchFacePushController(
            managerProvider = { manager },
            isSupportedCheck = { true },
            validationTokenProvider = { color -> "token-${color.name.lowercase()}" },
            openApkFd = { openTempFd {} },
        )

        assertTrue(controller.syncColorIfInstalled(LiturgicalColor.RED))
        assertEquals(1, manager.updateCalls)
        assertEquals("token-red", manager.lastToken)
    }

    @Test
    fun themeKeyAndAssetName_mapAllLiturgicalColors() {
        assertEquals("watchface_green.apk", WatchFacePushController.assetNameForColor(LiturgicalColor.GREEN))
        assertEquals("watchface_purple.apk", WatchFacePushController.assetNameForColor(LiturgicalColor.PURPLE))
        assertEquals("watchface_purple.apk", WatchFacePushController.assetNameForColor(LiturgicalColor.ROSE))
        assertEquals("watchface_red.apk", WatchFacePushController.assetNameForColor(LiturgicalColor.RED))
        assertEquals("watchface_white.apk", WatchFacePushController.assetNameForColor(LiturgicalColor.WHITE))
    }

    @Test
    fun installAndActivate_installsToGalleryWhenPermissionNotGranted() = runBlocking {
        val manager = FakeWatchFacePushManager()
        val controller = WatchFacePushController(
            managerProvider = { manager },
            isSupportedCheck = { true },
            validationTokenProvider = { "token-1" },
            openApkFd = { openTempFd {} },
        )

        val outcome = controller.installAndActivate(canSetActive = false)

        assertTrue(outcome is WatchFacePushOutcome.InstalledPickInGallery)
        assertEquals(1, manager.addCalls)
        assertEquals(0, manager.setActiveCalls)
    }

    @Test
    fun installAndActivate_fallsBackToGalleryOnSecurityException() = runBlocking {
        val manager = FakeWatchFacePushManager(failSetActiveWithSecurityException = true)
        val controller = WatchFacePushController(
            managerProvider = { manager },
            isSupportedCheck = { true },
            validationTokenProvider = { "token-1" },
            openApkFd = { openTempFd {} },
        )

        val outcome = controller.installAndActivate(canSetActive = true)

        assertTrue(outcome is WatchFacePushOutcome.InstalledPickInGallery)
        assertEquals(1, manager.addCalls)
        assertEquals(1, manager.setActiveCalls)
    }

    @Test
    fun installAndActivate_failsWhenNoSlotsAvailable() = runBlocking {
        val manager = FakeWatchFacePushManager(remainingSlots = 0)
        var cleanedUp = false
        val controller = WatchFacePushController(
            managerProvider = { manager },
            isSupportedCheck = { true },
            validationTokenProvider = { "token-1" },
            openApkFd = { openTempFd { cleanedUp = true } },
        )

        val outcome = controller.installAndActivate(canSetActive = true)

        assertTrue(outcome is WatchFacePushOutcome.Failed)
        assertTrue(cleanedUp)
        assertEquals(0, manager.addCalls)
    }

    @Test
    fun installAndActivate_failsWhenValidationTokenIsBlank() = runBlocking {
        val manager = FakeWatchFacePushManager()
        val controller = WatchFacePushController(
            managerProvider = { manager },
            isSupportedCheck = { true },
            validationTokenProvider = { "   " },
            openApkFd = { openTempFd {} },
        )

        val outcome = controller.installAndActivate(canSetActive = true)

        assertTrue(outcome is WatchFacePushOutcome.Failed)
        assertEquals(0, manager.addCalls)
    }

    @Test
    fun installAndActivate_returnsFailedAndCleansUpWhenAddThrows() = runBlocking {
        val manager = FakeWatchFacePushManager(failAdd = true)
        var cleanedUp = false
        val controller = WatchFacePushController(
            managerProvider = { manager },
            isSupportedCheck = { true },
            validationTokenProvider = { "token-1" },
            openApkFd = { openTempFd { cleanedUp = true } },
        )

        val outcome = controller.installAndActivate(canSetActive = true)

        assertTrue(outcome is WatchFacePushOutcome.Failed)
        assertTrue(cleanedUp)
    }

    @Test
    fun isSupportedFalse_returnsFailedAndNotActive() = runBlocking {
        val manager = FakeWatchFacePushManager()
        val controller = WatchFacePushController(
            managerProvider = { manager },
            isSupportedCheck = { false },
            validationTokenProvider = { "token-1" },
            openApkFd = { openTempFd {} },
        )

        assertFalse(controller.isBundledWatchFaceActive())
        assertTrue(controller.installAndActivate(canSetActive = true) is WatchFacePushOutcome.Failed)
        assertEquals(0, manager.addCalls)
    }
}
