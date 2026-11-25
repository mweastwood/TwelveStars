package com.mweastwood.twelve_stars.wear.complications

import android.app.PendingIntent
import android.graphics.drawable.Icon
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.MonochromaticImage
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService
import com.mweastwood.twelve_stars.wear.R
import com.mweastwood.twelve_stars.wear.data.LiturgicalRepository
import java.time.LocalDate

class RosaryComplicationService : SuspendingComplicationDataSourceService() {
    override fun getPreviewData(type: ComplicationType): ComplicationData? {
        return buildComplicationData(
            type = type,
            mystery = "Joyful",
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

        val mystery = LiturgicalComplicationFormatter.formatRosaryMystery(dayInfo, today)
        return buildComplicationData(
            type = request.complicationType,
            mystery = mystery,
            tapAction = LiturgicalComplicationService.createLaunchPendingIntent(this),
        )
    }

    private fun buildComplicationData(
        type: ComplicationType,
        mystery: String,
        tapAction: PendingIntent?,
    ): ComplicationData? {
        if (type != ComplicationType.SHORT_TEXT) return null

        val icon = MonochromaticImage.Builder(
            Icon.createWithResource(this, R.drawable.ic_rosary_bead),
        ).build()

        return ShortTextComplicationData.Builder(
            text = PlainComplicationText.Builder(mystery).build(),
            contentDescription = PlainComplicationText.Builder("Rosary: $mystery Mysteries").build(),
        )
            .setTitle(PlainComplicationText.Builder("Rosary").build())
            .setMonochromaticImage(icon)
            .setTapAction(tapAction)
            .build()
    }
}
