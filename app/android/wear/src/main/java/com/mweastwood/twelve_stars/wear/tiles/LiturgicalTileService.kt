package com.mweastwood.twelve_stars.wear.tiles

import android.content.Context
import androidx.concurrent.futures.CallbackToFutureAdapter
import androidx.core.graphics.ColorUtils
import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.protolayout.material.Chip
import androidx.wear.protolayout.material.ChipColors
import androidx.wear.protolayout.material.Colors
import androidx.wear.protolayout.material.Text
import androidx.wear.protolayout.material.Typography
import androidx.wear.protolayout.material.layouts.PrimaryLayout
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.ListenableFuture
import com.mweastwood.twelve_stars.wear.MainActivity
import com.mweastwood.twelve_stars.wear.R
import com.mweastwood.twelve_stars.wear.complications.LiturgicalComplicationFormatter
import com.mweastwood.twelve_stars.wear.data.LiturgicalColor
import com.mweastwood.twelve_stars.wear.data.LiturgicalDayInfo
import com.mweastwood.twelve_stars.wear.data.LiturgicalRepository
import java.time.LocalDate
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class LiturgicalTileService : TileService() {
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()

    @Volatile
    private var cachedRepository: LiturgicalRepository? = null

    private fun getOrLoadRepository(): LiturgicalRepository? {
        cachedRepository?.let { return it }
        val loaded = runCatching {
            resources.openRawResource(R.raw.liturgical_calendar).use { stream ->
                LiturgicalRepository.loadFromStream(stream)
            }
        }.getOrNull()
        if (loaded != null) {
            cachedRepository = loaded
        }
        return loaded
    }

    override fun onTileRequest(requestParams: RequestBuilders.TileRequest): ListenableFuture<TileBuilders.Tile> {
        return CallbackToFutureAdapter.getFuture { completer ->
            executor.execute {
                try {
                    val today = LocalDate.now()
                    val dayInfo = getOrLoadRepository()?.dayForDate(today)
                    completer.set(buildLiturgicalTile(this, requestParams, dayInfo, today))
                } catch (e: Throwable) {
                    completer.setException(e)
                }
            }
            "LiturgicalTileService.onTileRequest"
        }
    }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> {
        return CallbackToFutureAdapter.getFuture { completer ->
            completer.set(
                ResourceBuilders.Resources.Builder()
                    .setVersion(RESOURCES_VERSION)
                    .build(),
            )
        }
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }

    companion object {
        internal const val RESOURCES_VERSION = "1"
        internal const val FRESHNESS_INTERVAL_MILLIS = 6 * 60 * 60 * 1000L
        private const val ACTION_ID_PRAY_ROSARY = "pray_rosary"

        internal fun buildLiturgicalTile(
            context: Context,
            requestParams: RequestBuilders.TileRequest,
            dayInfo: LiturgicalDayInfo?,
            today: LocalDate,
        ): TileBuilders.Tile {
            val accentArgb = (dayInfo?.color ?: LiturgicalColor.GREEN).hexArgb.toInt()
            val readableAccentArgb = ColorUtils.blendARGB(accentArgb, 0xFFFFFFFF.toInt(), 0.35f)
            val seasonTitle = LiturgicalComplicationFormatter.formatSeasonTitle(dayInfo)
            val dayText = LiturgicalComplicationFormatter.formatDayText(dayInfo)
            val mystery = LiturgicalComplicationFormatter.formatRosaryMystery(dayInfo, today)

            val launchRosaryAction = ActionBuilders.LaunchAction.Builder()
                .setAndroidActivity(
                    ActionBuilders.AndroidActivity.Builder()
                        .setPackageName(context.packageName)
                        .setClassName(MainActivity::class.java.name)
                        .addKeyToExtraMapping(
                            MainActivity.EXTRA_OPEN_ROSARY,
                            ActionBuilders.AndroidBooleanExtra.Builder().setValue(true).build(),
                        )
                        .build(),
                )
                .build()

            val clickable = ModifiersBuilders.Clickable.Builder()
                .setId(ACTION_ID_PRAY_ROSARY)
                .setOnClick(launchRosaryAction)
                .build()

            val contentColumn = LayoutElementBuilders.Column.Builder()
                .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
                .addContent(
                    Text.Builder(context, dayText)
                        .setTypography(Typography.TYPOGRAPHY_TITLE3)
                        .setColor(argb(0xFFFFFFFF.toInt()))
                        .setMaxLines(2)
                        .build(),
                )
                .addContent(
                    LayoutElementBuilders.Spacer.Builder()
                        .setHeight(dp(4f))
                        .build(),
                )
                .addContent(
                    Text.Builder(context, "$mystery Mysteries")
                        .setTypography(Typography.TYPOGRAPHY_CAPTION1)
                        .setColor(argb(0xFFB0BEC5.toInt()))
                        .setMaxLines(1)
                        .build(),
                )
                .build()

            val primaryChip = Chip.Builder(context, clickable, requestParams.deviceConfiguration)
                .setPrimaryLabelContent("Pray Rosary")
                .setChipColors(ChipColors.primaryChipColors(Colors(accentArgb, 0xFFFFFFFF.toInt(), 0xFF000000.toInt(), 0xFFFFFFFF.toInt())))
                .build()

            val layout = PrimaryLayout.Builder(requestParams.deviceConfiguration)
                .setPrimaryLabelTextContent(
                    Text.Builder(context, seasonTitle)
                        .setTypography(Typography.TYPOGRAPHY_CAPTION1)
                        .setColor(argb(readableAccentArgb))
                        .setMaxLines(1)
                        .build(),
                )
                .setContent(contentColumn)
                .setPrimaryChipContent(primaryChip)
                .build()

            val timeline = TimelineBuilders.Timeline.Builder()
                .addTimelineEntry(
                    TimelineBuilders.TimelineEntry.Builder()
                        .setLayout(
                            LayoutElementBuilders.Layout.Builder()
                                .setRoot(layout)
                                .build(),
                        )
                        .build(),
                )
                .build()

            return TileBuilders.Tile.Builder()
                .setResourcesVersion(RESOURCES_VERSION)
                .setFreshnessIntervalMillis(FRESHNESS_INTERVAL_MILLIS)
                .setTileTimeline(timeline)
                .build()
        }
    }
}
