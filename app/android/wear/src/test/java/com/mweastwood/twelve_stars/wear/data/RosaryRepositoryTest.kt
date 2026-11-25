package com.mweastwood.twelve_stars.wear.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class RosaryRepositoryTest {
    private val sampleJson = """
        {
          "schemaVersion": 1,
          "mysteries": {
            "joyful": {
              "title": "Joyful Mysteries",
              "days": "Mondays & Saturdays",
              "decades": [
                {"number": 1, "title": "The Annunciation", "description": "Angel Gabriel"},
                {"number": 2, "title": "The Visitation", "description": "Mary visits Elizabeth"},
                {"number": 3, "title": "The Nativity", "description": "Jesus is born"},
                {"number": 4, "title": "The Presentation", "description": "Presented in the Temple"},
                {"number": 5, "title": "The Finding in the Temple", "description": "Found teaching"}
              ]
            }
          },
          "prayers": {
            "sign_of_the_cross": {
              "id": "sign_of_the_cross",
              "defaultTitle": "Sign of the Cross",
              "hasAmen": true,
              "translations": {
                "english": {"title": "Sign of the Cross", "text": "In the name of the Father..."},
                "latin": {"title": "Signum Crucis", "text": "In nomine Patris..."}
              }
            },
            "our_father": {
              "id": "our_father",
              "defaultTitle": "Our Father",
              "hasAmen": true,
              "translations": {
                "english": {"title": "Our Father", "text": "Our Father, who art in heaven..."},
                "latin": {"title": "Pater Noster", "text": "Pater noster, qui es in caelis..."}
              }
            },
            "hail_mary": {
              "id": "hail_mary",
              "defaultTitle": "Hail Mary",
              "hasAmen": true,
              "translations": {
                "english": {"title": "Hail Mary", "text": "Hail Mary, full of grace..."}
              }
            },
            "hail_holy_queen": {
              "id": "hail_holy_queen",
              "defaultTitle": "Hail, Holy Queen",
              "hasAmen": false,
              "translations": {
                "english": {"title": "Hail, Holy Queen", "text": "Hail, holy Queen, Mother of mercy..."}
              }
            },
            "final_prayer_rosary": {
              "id": "final_prayer_rosary",
              "defaultTitle": "Rosary Closing Prayer",
              "hasAmen": true,
              "translations": {
                "english": {"title": "Closing Prayer", "text": "O God, whose only begotten Son..."}
              }
            }
          }
        }
    """.trimIndent()

    @Test
    fun generates67StepsWithCorrectDecadeStructure() {
        val repo = RosaryRepository.loadFromJson(sampleJson)
        val steps = repo.generateSteps("joyful")

        assertEquals(67, steps.size)
        assertEquals("Opening Prayers", steps.first().title)
        assertEquals("Sign of the Cross & Creed", steps.first().subtitle)
        assertEquals("sign_of_the_cross", steps.first().prayerId)
        assertEquals("apostles_creed", steps.first().secondaryPrayerId)
        assertEquals("Closing Prayers", steps.last().title)
        assertEquals("The Annunciation", steps[6].mysteryTitle)
        assertEquals(1, steps[6].decadeNumber)
        assertEquals(1, steps[7].beadInDecade)
        assertEquals(10, steps[16].beadInDecade)
    }

    @Test
    fun resolvesEnglishLatinAndCombinedClosingText() {
        val repo = RosaryRepository.loadFromJson(sampleJson)
        val steps = repo.generateSteps("joyful")

        val openingTextEn = repo.combinedPrayerText(steps.first(), RosaryLanguage.ENGLISH)
        val openingTextLa = repo.combinedPrayerText(steps.first(), RosaryLanguage.LATIN)
        assertEquals("In the name of the Father...", openingTextEn)
        assertEquals("In nomine Patris...", openingTextLa)

        val closingText = repo.combinedPrayerText(steps.last(), RosaryLanguage.ENGLISH)
        assertTrue(closingText.contains("Hail, holy Queen"))
        assertTrue(closingText.contains("O God, whose only begotten Son"))
        assertTrue(closingText.contains("In the name of the Father"))
    }

    @Test
    fun fallsBackToEnglishWhenLatinTranslationIsMissingOrBlank() {
        val repo = RosaryRepository.loadFromJson(sampleJson)
        val missingLatinPrayer = repo.prayers.getValue("hail_mary")
        assertEquals("Hail Mary, full of grace...", missingLatinPrayer.textFor(RosaryLanguage.LATIN))

        val blankLatinPrayer = RosaryPrayer(
            id = "glory_be",
            defaultTitle = "Glory Be",
            hasAmen = true,
            translations = mapOf(
                "english" to RosaryPrayerTranslation(title = "Glory Be", text = "Glory be to the Father..."),
                "latin" to RosaryPrayerTranslation(title = "Gloria Patri", text = "   "),
            ),
        )
        assertEquals("Glory be to the Father...", blankLatinPrayer.textFor(RosaryLanguage.LATIN))
    }

    @Test
    fun mysteryForKeyFallsBackToJoyfulForUnknownOrNullKey() {
        val repo = RosaryRepository.loadFromJson(sampleJson)
        assertEquals("joyful", repo.mysteryForKey(null)?.key)
        assertEquals("joyful", repo.mysteryForKey("unknown_mystery")?.key)
        assertEquals("joyful", repo.mysteryForKey("JOYFUL")?.key)
    }

    @Test
    fun defaultMysteryKeyMatchesDayOfWeek() {
        assertEquals("joyful", RosaryRepository.defaultMysteryKeyForDate(LocalDate.of(2026, 11, 23))) // Monday
        assertEquals("sorrowful", RosaryRepository.defaultMysteryKeyForDate(LocalDate.of(2026, 11, 24))) // Tuesday
        assertEquals("glorious", RosaryRepository.defaultMysteryKeyForDate(LocalDate.of(2026, 11, 25))) // Wednesday
        assertEquals("luminous", RosaryRepository.defaultMysteryKeyForDate(LocalDate.of(2026, 11, 26))) // Thursday
        assertEquals("sorrowful", RosaryRepository.defaultMysteryKeyForDate(LocalDate.of(2026, 11, 27))) // Friday
        assertEquals("joyful", RosaryRepository.defaultMysteryKeyForDate(LocalDate.of(2026, 11, 28))) // Saturday
        assertEquals("glorious", RosaryRepository.defaultMysteryKeyForDate(LocalDate.of(2026, 11, 29))) // Sunday
    }
}
