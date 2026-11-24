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

    @Test
    fun loadsFromStream() {
        val repo = sampleJson.byteInputStream(Charsets.UTF_8).use { stream ->
            LiturgicalRepository.loadFromStream(stream)
        }
        assertEquals(2, repo.size)
        val christmas = repo.dayForDate(LocalDate.of(2026, 12, 25))!!
        assertEquals("The Nativity of the Lord", christmas.displayTitle)
    }

    @Test
    fun fallsBackToWeekNameWhenNameIsBlankOrNull() {
        val json = """
            {
              "days": {
                "2026-03-01": {
                  "name": null,
                  "weekName": "2nd Sunday of Lent"
                },
                "2026-03-02": {
                  "name": "",
                  "weekName": "Monday of the 2nd Week of Lent"
                },
                "2026-03-03": {
                  "name": "   ",
                  "weekName": "Tuesday of the 2nd Week of Lent"
                }
              }
            }
        """.trimIndent()

        val repo = LiturgicalRepository.loadFromJson(json)
        assertEquals(3, repo.size)

        val nullName = repo.dayForDate(LocalDate.of(2026, 3, 1))!!
        assertNull(nullName.feastName)
        assertEquals("2nd Sunday of Lent", nullName.displayTitle)

        val emptyName = repo.dayForDate(LocalDate.of(2026, 3, 2))!!
        assertEquals("Monday of the 2nd Week of Lent", emptyName.displayTitle)

        val whitespaceName = repo.dayForDate(LocalDate.of(2026, 3, 3))!!
        assertEquals("Tuesday of the 2nd Week of Lent", whitespaceName.displayTitle)
    }

    @Test
    fun returnsEmptyRepositoryWhenDaysKeyIsMissing() {
        val repo = LiturgicalRepository.loadFromJson("""{"schemaVersion": 1}""")
        assertEquals(0, repo.size)
        assertNull(repo.dayForDate(LocalDate.of(2026, 12, 25)))
    }

    @Test
    fun skipsMalformedDateKeysAndLoadsValidEntries() {
        val json = """
            {
              "days": {
                "not-a-date": {
                  "weekName": "Invalid"
                },
                "2026-13-45": {
                  "weekName": "Invalid Month/Day"
                },
                "2026-05-01": {
                  "name": "St. Joseph the Worker",
                  "weekName": "Friday of the 4th Week of Easter"
                }
              }
            }
        """.trimIndent()

        val repo = LiturgicalRepository.loadFromJson(json)
        assertEquals(1, repo.size)
        assertEquals(
            "St. Joseph the Worker",
            repo.dayForDate(LocalDate.of(2026, 5, 1))?.displayTitle,
        )
    }
}
