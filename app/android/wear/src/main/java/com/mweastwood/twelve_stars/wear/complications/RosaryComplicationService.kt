package com.mweastwood.twelve_stars.wear.complications

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.MonochromaticImage
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService
import com.mweastwood.twelve_stars.wear.MainActivity
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
            tapAction = createRosaryPendingIntent(this),
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

    companion object {
        private const val REQUEST_CODE_OPEN_ROSARY = 1

        fun createRosaryPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(MainActivity.EXTRA_OPEN_ROSARY, true)
            }
            return PendingIntent.getActivity(
                context,
                REQUEST_CODE_OPEN_ROSARY,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
