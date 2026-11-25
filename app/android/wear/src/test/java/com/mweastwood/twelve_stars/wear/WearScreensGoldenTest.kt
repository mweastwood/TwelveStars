package com.mweastwood.twelve_stars.wear

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onRoot
import androidx.wear.compose.material.MaterialTheme
import com.github.takahirom.roborazzi.captureRoboImage
import com.mweastwood.twelve_stars.wear.data.LiturgicalColor
import com.mweastwood.twelve_stars.wear.data.LiturgicalDayInfo
import com.mweastwood.twelve_stars.wear.data.RosaryDecade
import com.mweastwood.twelve_stars.wear.data.RosaryMysterySet
import com.mweastwood.twelve_stars.wear.data.RosaryPrayer
import com.mweastwood.twelve_stars.wear.data.RosaryPrayerTranslation
import com.mweastwood.twelve_stars.wear.data.RosaryRepository
import com.mweastwood.twelve_stars.wear.ui.WearRosaryScreen
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.time.LocalDate

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class WearScreensGoldenTest {
    @get:Rule
    val composeRule = createComposeRule()

    private val christmasDay = LiturgicalDayInfo(
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

    private val adventDay = LiturgicalDayInfo(
        date = LocalDate.of(2026, 11, 29),
        season = "advent",
        seasonName = "Advent",
        color = LiturgicalColor.PURPLE,
        colorName = "Violet",
        feastName = null,
        weekName = "1st Sunday of Advent",
        sundayCycle = "A",
        weekdayCycle = "I",
        rosaryMystery = "glorious",
    )

    private val sampleRosaryRepo = RosaryRepository(
        mysteries = mapOf(
            "joyful" to RosaryMysterySet(
                key = "joyful",
                title = "Joyful Mysteries",
                days = "Mondays & Saturdays",
                decades = listOf(
                    RosaryDecade(1, "The Annunciation", "Angel Gabriel appears to Mary."),
                    RosaryDecade(2, "The Visitation", "Mary visits Elizabeth."),
                    RosaryDecade(3, "The Nativity", "Jesus is born in Bethlehem."),
                    RosaryDecade(4, "The Presentation", "Jesus is presented in the Temple."),
                    RosaryDecade(5, "The Finding in the Temple", "Jesus is found in the Temple."),
                ),
            ),
        ),
        prayers = mapOf(
            "hail_mary" to RosaryPrayer(
                id = "hail_mary",
                defaultTitle = "Hail Mary",
                hasAmen = true,
                translations = mapOf(
                    "english" to RosaryPrayerTranslation(
                        title = "Hail Mary",
                        text = "Hail Mary, full of grace, the Lord is with thee.",
                    ),
                ),
            ),
        ),
    )

    @Test
    @Config(sdk = [34], qualifiers = "w192dp-h192dp-notlong-round-hdpi")
    fun wearTodayScreen_smallRound_christmas() {
        composeRule.setContent {
            MaterialTheme {
                WearTodayScreen(dayInfo = christmasDay, onPrayRosary = {})
            }
        }
        composeRule.onRoot().captureRoboImage("src/test/snapshots/wear_today_small_round_christmas.png")
    }

    @Test
    @Config(sdk = [34], qualifiers = "w227dp-h227dp-notlong-round-xhdpi")
    fun wearTodayScreen_largeRound_advent() {
        composeRule.setContent {
            MaterialTheme {
                WearTodayScreen(dayInfo = adventDay, onPrayRosary = {})
            }
        }
        composeRule.onRoot().captureRoboImage("src/test/snapshots/wear_today_large_round_advent.png")
    }

    @Test
    @Config(sdk = [34], qualifiers = "w227dp-h227dp-notlong-round-xhdpi")
    fun wearRosaryScreen_largeRound_firstDecadeBead() {
        composeRule.setContent {
            MaterialTheme {
                WearRosaryScreen(
                    repository = sampleRosaryRepo,
                    mysteryKey = "joyful",
                    accentColor = Color(0xFF1E3A8A),
                    initialStepIndex = 10,
                    onBack = {},
                )
            }
        }
        composeRule.onRoot().captureRoboImage("src/test/snapshots/wear_rosary_large_round_decade.png")
    }
}
