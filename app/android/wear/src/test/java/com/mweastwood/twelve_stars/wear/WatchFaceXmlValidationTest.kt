package com.mweastwood.twelve_stars.wear

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory

class WatchFaceXmlValidationTest {
    private fun locateWatchFaceFile(): File {
        val candidates = listOf(
            File("src/main/res/raw/watchface.xml"),
            File("wear/src/main/res/raw/watchface.xml"),
            File("app/android/wear/src/main/res/raw/watchface.xml"),
        )
        return candidates.firstOrNull { it.exists() }
            ?: error("Could not locate watchface.xml from ${File(".").absolutePath}")
    }

    @Test
    fun watchFaceXmlIsWellFormedAndHasTwelveStarsAndComplications() {
        val file = locateWatchFaceFile()
        val doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file)
        val root = doc.documentElement

        assertEquals("WatchFace", root.tagName)
        assertEquals("450", root.getAttribute("width"))
        assertEquals("450", root.getAttribute("height"))
        assertEquals("CIRCLE", root.getAttribute("clipShape"))

        val colorOptions = doc.getElementsByTagName("ColorOption")
        assertEquals(5, colorOptions.length)

        val partImages = doc.getElementsByTagName("PartImage")
        assertEquals(12, partImages.length)

        val complications = doc.getElementsByTagName("ComplicationSlot")
        assertEquals(2, complications.length)

        val clocks = doc.getElementsByTagName("DigitalClock")
        assertTrue(clocks.length >= 1)
    }
}
