package com.mweastwood.twelve_stars.wear.complications

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.LongTextComplicationData
import androidx.wear.watchface.complications.data.MonochromaticImage
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService
import com.mweastwood.twelve_stars.wear.MainActivity
import com.mweastwood.twelve_stars.wear.R
import com.mweastwood.twelve_stars.wear.data.LiturgicalDayInfo
import com.mweastwood.twelve_stars.wear.data.LiturgicalRepository
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

internal object LiturgicalComplicationFormatter {
    private val shortDateFormatter = DateTimeFormatter.ofPattern("EEE, MMM d", Locale.US)

    fun formatDateTitle(date: LocalDate): String {
        return date.format(shortDateFormatter)
    }

    fun formatSeasonTitle(dayInfo: LiturgicalDayInfo?): String {
        return dayInfo?.seasonName?.takeIf { it.isNotBlank() } ?: "Twelve Stars"
    }

    fun formatDayText(dayInfo: LiturgicalDayInfo?): String {
        return dayInfo?.displayTitle?.takeIf { it.isNotBlank() } ?: "Daily Prayer"
    }

    fun formatRosaryMystery(dayInfo: LiturgicalDayInfo?, date: LocalDate): String {
        val raw = dayInfo?.rosaryMystery?.takeIf { it.isNotBlank() }
            ?: when (date.dayOfWeek) {
                java.time.DayOfWeek.MONDAY, java.time.DayOfWeek.SATURDAY -> "joyful"
                java.time.DayOfWeek.TUESDAY, java.time.DayOfWeek.FRIDAY -> "sorrowful"
                java.time.DayOfWeek.THURSDAY -> "luminous"
                else -> "glorious"
            }
        return raw.replaceFirstChar { it.uppercase() }
    }
}

class LiturgicalComplicationService : SuspendingComplicationDataSourceService() {
    override fun getPreviewData(type: ComplicationType): ComplicationData? {
        return buildComplicationData(
            type = type,
            title = "Sun, Nov 29",
            text = "1st Sunday of Advent",
            tapAction = null,
        )
    }

    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData? {
        val today = LocalDate.now()
        val dayInfo = runCatching {
            resources.openRawResource(R.raw.liturgical_calendar).use { stream ->
                LiturgicalRepository.loadFromStream(stream).dayForDate(today)
            }
        }.getOrNull()

        return buildComplicationData(
            type = request.complicationType,
            title = LiturgicalComplicationFormatter.formatDateTitle(today),
            text = LiturgicalComplicationFormatter.formatDayText(dayInfo),
            tapAction = createLaunchPendingIntent(this),
        )
    }

    private fun buildComplicationData(
        type: ComplicationType,
        title: String,
        text: String,
        tapAction: PendingIntent?,
    ): ComplicationData? {
        val icon = MonochromaticImage.Builder(
            Icon.createWithResource(this, R.drawable.ic_liturgical_cross),
        ).build()

        return when (type) {
            ComplicationType.SHORT_TEXT -> ShortTextComplicationData.Builder(
                text = PlainComplicationText.Builder(text).build(),
                contentDescription = PlainComplicationText.Builder("$title: $text").build(),
            )
                .setTitle(PlainComplicationText.Builder(title).build())
                .setMonochromaticImage(icon)
                .setTapAction(tapAction)
                .build()

            ComplicationType.LONG_TEXT -> LongTextComplicationData.Builder(
                text = PlainComplicationText.Builder(text).build(),
                contentDescription = PlainComplicationText.Builder("$title: $text").build(),
            )
                .setTitle(PlainComplicationText.Builder(title).build())
                .setMonochromaticImage(icon)
                .setTapAction(tapAction)
                .build()

            else -> null
        }
    }

    companion object {
        fun createLaunchPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        fun componentName(context: Context): ComponentName {
            return ComponentName(context, LiturgicalComplicationService::class.java)
        }
    }
}
