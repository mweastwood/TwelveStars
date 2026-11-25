package com.mweastwood.twelve_stars.wear.tiles

import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.DeviceParametersBuilders
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.material.Chip
import androidx.wear.protolayout.material.layouts.PrimaryLayout
import androidx.wear.tiles.RequestBuilders
import com.mweastwood.twelve_stars.wear.MainActivity
import com.mweastwood.twelve_stars.wear.data.LiturgicalColor
import com.mweastwood.twelve_stars.wear.data.LiturgicalDayInfo
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.time.LocalDate

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class LiturgicalTileServiceTest {

    private fun createTileRequest(): RequestBuilders.TileRequest {
        val deviceParams = DeviceParametersBuilders.DeviceParameters.Builder()
            .setScreenWidthDp(227)
            .setScreenHeightDp(227)
            .setScreenDensity(2.0f)
            .build()
        return RequestBuilders.TileRequest.Builder()
            .setDeviceConfiguration(deviceParams)
            .build()
    }

    private fun findLaunchActions(element: LayoutElementBuilders.LayoutElement?): List<ActionBuilders.LaunchAction> {
        if (element == null) return emptyList()
        val found = mutableListOf<ActionBuilders.LaunchAction>()

        fun inspectElement(node: LayoutElementBuilders.LayoutElement?) {
            if (node == null) return

            val primaryLayout = PrimaryLayout.fromLayoutElement(node)
            if (primaryLayout != null) {
                inspectElement(primaryLayout.primaryLabelTextContent)
                inspectElement(primaryLayout.content)
                inspectElement(primaryLayout.primaryChipContent)
                return
            }

            val chip = Chip.fromLayoutElement(node)
            if (chip != null) {
                val action = chip.clickable.onClick
                if (action is ActionBuilders.LaunchAction) {
                    found.add(action)
                }
                return
            }

            when (node) {
                is LayoutElementBuilders.Box -> {
                    val action = node.modifiers?.clickable?.onClick
                    if (action is ActionBuilders.LaunchAction) {
                        found.add(action)
                    }
                    node.contents.forEach { inspectElement(it) }
                }

                is LayoutElementBuilders.Column -> {
                    val action = node.modifiers?.clickable?.onClick
                    if (action is ActionBuilders.LaunchAction) {
                        found.add(action)
                    }
                    node.contents.forEach { inspectElement(it) }
                }

                is LayoutElementBuilders.Row -> {
                    val action = node.modifiers?.clickable?.onClick
                    if (action is ActionBuilders.LaunchAction) {
                        found.add(action)
                    }
                    node.contents.forEach { inspectElement(it) }
                }
            }
        }

        inspectElement(element)
        return found
    }

    @Test
    fun buildLiturgicalTile_withValidDayInfo_populatesMetadataTimelineAndLaunchAction() {
        val context = RuntimeEnvironment.getApplication()
        val today = LocalDate.of(2026, 12, 25)
        val dayInfo = LiturgicalDayInfo(
            date = today,
            season = "christmas",
            seasonName = "Christmas",
            color = LiturgicalColor.WHITE,
            colorName = "White/Gold",
            feastName = "The Nativity of the Lord",
            weekName = "Christmas",
            sundayCycle = "A",
            weekdayCycle = "II",
            rosaryMystery = "sorrowful",
        )

        val tile = LiturgicalTileService.buildLiturgicalTile(
            context = context,
            requestParams = createTileRequest(),
            dayInfo = dayInfo,
            today = today,
        )

        assertEquals(LiturgicalTileService.RESOURCES_VERSION, tile.resourcesVersion)
        assertEquals(LiturgicalTileService.FRESHNESS_INTERVAL_MILLIS, tile.freshnessIntervalMillis)

        val timeline = tile.tileTimeline
        assertNotNull(timeline)
        assertEquals(1, timeline!!.timelineEntries.size)

        val root = timeline.timelineEntries.single().layout?.root
        assertNotNull(root)

        val launchActions = findLaunchActions(root)
        assertEquals(1, launchActions.size)
        val activity = launchActions.single().androidActivity
        assertNotNull(activity)
        assertEquals(context.packageName, activity!!.packageName)
        assertEquals(MainActivity::class.java.name, activity.className)

        val openRosaryExtra = activity.keyToExtraMapping[MainActivity.EXTRA_OPEN_ROSARY]
        assertTrue(openRosaryExtra is ActionBuilders.AndroidBooleanExtra)
        assertTrue((openRosaryExtra as ActionBuilders.AndroidBooleanExtra).value)
    }

    @Test
    fun buildLiturgicalTile_withNullDayInfo_fallsBackGracefully() {
        val context = RuntimeEnvironment.getApplication()
        val today = LocalDate.of(2026, 11, 25)

        val tile = LiturgicalTileService.buildLiturgicalTile(
            context = context,
            requestParams = createTileRequest(),
            dayInfo = null,
            today = today,
        )

        assertEquals(LiturgicalTileService.RESOURCES_VERSION, tile.resourcesVersion)
        assertEquals(LiturgicalTileService.FRESHNESS_INTERVAL_MILLIS, tile.freshnessIntervalMillis)

        val timeline = tile.tileTimeline
        assertNotNull(timeline)
        assertEquals(1, timeline!!.timelineEntries.size)

        val root = timeline.timelineEntries.single().layout?.root
        assertNotNull(root)

        val launchActions = findLaunchActions(root)
        assertEquals(1, launchActions.size)
        val activity = launchActions.single().androidActivity
        assertNotNull(activity)
        assertEquals(MainActivity::class.java.name, activity!!.className)
        val openRosaryExtra = activity.keyToExtraMapping[MainActivity.EXTRA_OPEN_ROSARY]
        assertTrue(openRosaryExtra is ActionBuilders.AndroidBooleanExtra)
        assertTrue((openRosaryExtra as ActionBuilders.AndroidBooleanExtra).value)
    }
}
