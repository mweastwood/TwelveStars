package com.mweastwood.twelve_stars.wear.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.LocalDate

class LiturgicalRepositoryTest {
    private val sampleJson = """
        {
          "schemaVersion": 1,
          "startYear": 2026,
          "endYear": 2026,
          "days": {
            "2026-12-25": {
              "season": "christmas",
              "seasonName": "Christmas",
              "color": "white",
              "colorName": "White/Gold",
              "name": "The Nativity of the Lord",
              "weekName": "Christmas",
              "sundayCycle": "A",
              "weekdayCycle": "II",
              "rosaryMystery": "sorrowful"
            },
            "2026-11-22": {
              "season": "ordinaryTime",
              "seasonName": "Ordinary Time",
              "color": "white",
              "colorName": "White/Gold",
              "weekName": "34th Sunday in Ordinary Time",
              "sundayCycle": "A",
              "weekdayCycle": "II",
              "rosaryMystery": "glorious"
            }
          }
        }
    """.trimIndent()

    @Test
    fun loadsDaysAndResolvesFeastAndFallbackTitle() {
        val repo = LiturgicalRepository.loadFromJson(sampleJson)
        assertEquals(2, repo.size)

        val christmas = repo.dayForDate(LocalDate.of(2026, 12, 25))!!
        assertEquals(LiturgicalColor.WHITE, christmas.color)
        assertEquals("The Nativity of the Lord", christmas.displayTitle)
        assertEquals("sorrowful", christmas.rosaryMystery)

        val sunday = repo.dayForDate(LocalDate.of(2026, 11, 22))!!
        assertNull(sunday.feastName)
        assertEquals("34th Sunday in Ordinary Time", sunday.displayTitle)
    }

    @Test
    fun returnsNullForMissingDate() {
        val repo = LiturgicalRepository.loadFromJson(sampleJson)
        assertNull(repo.dayForDate(LocalDate.of(2030, 1, 1)))
    }

    @Test
    fun mapsAllLiturgicalColors() {
        assertEquals(LiturgicalColor.GREEN, LiturgicalColor.fromJsonKey("green"))
        assertEquals(LiturgicalColor.PURPLE, LiturgicalColor.fromJsonKey("purple"))
        assertEquals(LiturgicalColor.WHITE, LiturgicalColor.fromJsonKey("white"))
        assertEquals(LiturgicalColor.RED, LiturgicalColor.fromJsonKey("red"))
        assertEquals(LiturgicalColor.ROSE, LiturgicalColor.fromJsonKey("rose"))
        assertEquals(LiturgicalColor.GREEN, LiturgicalColor.fromJsonKey(null))
    }
}
