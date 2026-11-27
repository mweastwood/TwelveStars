package com.mweastwood.twelve_stars.wear

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory

class WatchFaceXmlValidationTest {
    private fun locateWatchFaceFile(): File {
        val candidates = listOf(
            File("../watchface/src/main/res/raw/watchface.xml"),
            File("watchface/src/main/res/raw/watchface.xml"),
            File("app/android/watchface/src/main/res/raw/watchface.xml"),
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
        assertEquals(6, colorOptions.length)

        val partImages = doc.getElementsByTagName("PartImage")
        assertTrue(partImages.length >= 12)

        val complications = doc.getElementsByTagName("ComplicationSlot")
        assertEquals(3, complications.length)

        val analogClocks = doc.getElementsByTagName("AnalogClock")
        assertEquals(1, analogClocks.length)
        assertEquals(1, doc.getElementsByTagName("HourHand").length)
        assertEquals(1, doc.getElementsByTagName("MinuteHand").length)
        assertEquals(1, doc.getElementsByTagName("SecondHand").length)
    }
}
