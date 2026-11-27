package com.mweastwood.twelve_stars.wear.complications

import android.app.PendingIntent
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
import com.mweastwood.twelve_stars.wear.data.GospelRepository
import com.mweastwood.twelve_stars.wear.data.LiturgicalRepository
import java.time.LocalDate

class GospelComplicationService : SuspendingComplicationDataSourceService() {
    override fun getPreviewData(type: ComplicationType): ComplicationData? {
        return buildComplicationData(
            type = type,
            shortCitation = "Mt 5:1-12",
            fullCitation = "Matthew 5:1-12a",
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

        val reading = runCatching {
            resources.openRawResource(R.raw.gospel_data).use { stream ->
                GospelRepository.loadFromStream(stream).readingForKey(dayInfo?.lectionaryKey)
            }
        }.getOrNull()

        val shortCitation = reading?.shortCitation?.takeIf { it.isNotBlank() } ?: "Read"
        val fullCitation = reading?.citation?.takeIf { it.isNotBlank() } ?: "Today's Gospel"

        return buildComplicationData(
            type = request.complicationType,
            shortCitation = shortCitation,
            fullCitation = fullCitation,
            tapAction = createGospelPendingIntent(this),
        )
    }

    private fun buildComplicationData(
        type: ComplicationType,
        shortCitation: String,
        fullCitation: String,
        tapAction: PendingIntent?,
    ): ComplicationData? {
        val icon = MonochromaticImage.Builder(
            Icon.createWithResource(this, R.drawable.ic_gospel_book),
        ).build()

        return when (type) {
            ComplicationType.SHORT_TEXT -> ShortTextComplicationData.Builder(
                text = PlainComplicationText.Builder(shortCitation).build(),
                contentDescription = PlainComplicationText.Builder("Gospel: $fullCitation").build(),
            )
                .setTitle(PlainComplicationText.Builder("Gospel").build())
                .setMonochromaticImage(icon)
                .setTapAction(tapAction)
                .build()

            ComplicationType.LONG_TEXT -> LongTextComplicationData.Builder(
                text = PlainComplicationText.Builder(fullCitation).build(),
                contentDescription = PlainComplicationText.Builder("Gospel: $fullCitation").build(),
            )
                .setTitle(PlainComplicationText.Builder("Gospel").build())
                .setMonochromaticImage(icon)
                .setTapAction(tapAction)
                .build()

            else -> null
        }
    }

    companion object {
        private const val REQUEST_CODE_OPEN_GOSPEL = 2

        fun createGospelPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(MainActivity.EXTRA_OPEN_GOSPEL, true)
            }
            return PendingIntent.getActivity(
                context,
                REQUEST_CODE_OPEN_GOSPEL,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
