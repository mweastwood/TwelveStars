package com.mweastwood.twelve_stars.wear.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class GospelRepositoryTest {
    @Test
    fun loadFromJson_parsesGospelReadingsAndVerses() {
        val json = """
            {
              "schemaVersion": 1,
              "readings": {
                "feast_all_saints": {
                  "citation": "Matthew 5:1-12a",
                  "shortCitation": "Mt 5:1-12",
                  "bookName": "Matthew",
                  "verses": [
                    {"chapter": 5, "number": 1, "text": "Seeing the crowds, he went up the mountain."},
                    {"chapter": 5, "number": 3, "text": "Blessed are the poor in spirit."}
                  ]
                }
              }
            }
        """.trimIndent()

        val repo = GospelRepository.loadFromJson(json)
        assertEquals(1, repo.size)

        val reading = repo.readingForKey("feast_all_saints")
        assertNotNull(reading)
        assertEquals("Matthew 5:1-12a", reading?.citation)
        assertEquals("Mt 5:1-12", reading?.shortCitation)
        assertEquals(2, reading?.verses?.size)
        assertEquals(3, reading?.verses?.get(1)?.number)

        assertNull(repo.readingForKey("unknown_key"))
        assertNull(repo.readingForKey(""))
        assertNull(repo.readingForKey(null))
    }
}
