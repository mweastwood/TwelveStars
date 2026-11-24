package com.mweastwood.twelve_stars.wear.complications

import com.mweastwood.twelve_stars.wear.data.LiturgicalColor
import com.mweastwood.twelve_stars.wear.data.LiturgicalDayInfo
import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.LocalDate

class LiturgicalComplicationFormatterTest {
    @Test
    fun formatsFeastDayAndOrdinaryDay() {
        val christmas = LiturgicalDayInfo(
            date = LocalDate.of(2026, 12, 25),
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

        assertEquals("Christmas", LiturgicalComplicationFormatter.formatSeasonTitle(christmas))
        assertEquals("The Nativity of the Lord", LiturgicalComplicationFormatter.formatDayText(christmas))
        assertEquals("Sorrowful", LiturgicalComplicationFormatter.formatRosaryMystery(christmas, christmas.date))
    }

    @Test
    fun fallsBackGracefullyWhenDayInfoIsNull() {
        val monday = LocalDate.of(2026, 11, 23)
        val thursday = LocalDate.of(2026, 11, 26)
        val sunday = LocalDate.of(2026, 11, 22)

        assertEquals("Twelve Stars", LiturgicalComplicationFormatter.formatSeasonTitle(null))
        assertEquals("Daily Prayer", LiturgicalComplicationFormatter.formatDayText(null))
        assertEquals("Joyful", LiturgicalComplicationFormatter.formatRosaryMystery(null, monday))
        assertEquals("Luminous", LiturgicalComplicationFormatter.formatRosaryMystery(null, thursday))
        assertEquals("Glorious", LiturgicalComplicationFormatter.formatRosaryMystery(null, sunday))
    }
}
