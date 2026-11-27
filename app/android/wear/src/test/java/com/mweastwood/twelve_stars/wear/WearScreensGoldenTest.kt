package com.mweastwood.twelve_stars.wear

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.MaterialTheme
import com.github.takahirom.roborazzi.captureRoboImage
import com.mweastwood.twelve_stars.wear.data.GospelReading
import com.mweastwood.twelve_stars.wear.data.GospelVerse
import com.mweastwood.twelve_stars.wear.data.LiturgicalColor
import com.mweastwood.twelve_stars.wear.data.LiturgicalDayInfo
import com.mweastwood.twelve_stars.wear.data.RosaryDecade
import com.mweastwood.twelve_stars.wear.data.RosaryMysterySet
import com.mweastwood.twelve_stars.wear.data.RosaryPrayer
import com.mweastwood.twelve_stars.wear.data.RosaryPrayerTranslation
import com.mweastwood.twelve_stars.wear.data.RosaryRepository
import com.mweastwood.twelve_stars.wear.ui.WearGospelScreen
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

    @Composable
    private fun RoundWatchPreviewFrame(
        diameter: Dp,
        content: @Composable () -> Unit,
    ) {
        MaterialTheme {
            Box(
                modifier = Modifier
                    .size(diameter)
                    .clip(CircleShape),
            ) {
                content()
            }
        }
    }

    @Test
    @Config(sdk = [34], qualifiers = "w192dp-h192dp-notlong-round-hdpi")
    fun wearTodayScreen_smallRound_christmas() {
        composeRule.setContent {
            RoundWatchPreviewFrame(diameter = 192.dp) {
                WearTodayScreen(dayInfo = christmasDay, onPrayRosary = {})
            }
        }
        composeRule.onRoot().captureRoboImage("src/test/snapshots/wear_today_small_round_christmas.png")
    }

    @Test
    @Config(sdk = [34], qualifiers = "w227dp-h227dp-notlong-round-xhdpi")
    fun wearTodayScreen_largeRound_advent() {
        composeRule.setContent {
            RoundWatchPreviewFrame(diameter = 227.dp) {
                WearTodayScreen(dayInfo = adventDay, onPrayRosary = {})
            }
        }
        composeRule.onRoot().captureRoboImage("src/test/snapshots/wear_today_large_round_advent.png")
    }

    @Test
    @Config(sdk = [34], qualifiers = "w227dp-h227dp-notlong-round-xhdpi")
    fun wearTodayScreen_largeRound_advent_withWatchFaceChip() {
        composeRule.setContent {
            RoundWatchPreviewFrame(diameter = 227.dp) {
                WearTodayScreen(
                    dayInfo = adventDay,
                    onPrayRosary = {},
                    watchFaceButtonLabel = "Set Watch Face",
                    onSetWatchFace = {},
                )
            }
        }
        composeRule.onRoot()
            .captureRoboImage("src/test/snapshots/wear_today_large_round_advent_watchface.png")
    }

    @Test
    @Config(sdk = [34], qualifiers = "w192dp-h192dp-notlong-round-hdpi")
    fun wearRosaryScreen_smallRound_firstDecadeBead() {
        composeRule.setContent {
            RoundWatchPreviewFrame(diameter = 192.dp) {
                WearRosaryScreen(
                    repository = sampleRosaryRepo,
                    mysteryKey = "joyful",
                    accentColor = Color(0xFF1E3A8A),
                    initialStepIndex = 9,
                    onBack = {},
                )
            }
        }
        composeRule.onRoot().captureRoboImage("src/test/snapshots/wear_rosary_small_round_decade.png")
    }

    @Test
    @Config(sdk = [34], qualifiers = "w227dp-h227dp-notlong-round-xhdpi")
    fun wearRosaryScreen_largeRound_firstDecadeBead() {
        composeRule.setContent {
            RoundWatchPreviewFrame(diameter = 227.dp) {
                WearRosaryScreen(
                    repository = sampleRosaryRepo,
                    mysteryKey = "joyful",
                    accentColor = Color(0xFF1E3A8A),
                    initialStepIndex = 9,
                    onBack = {},
                )
            }
        }
        composeRule.onRoot().captureRoboImage("src/test/snapshots/wear_rosary_large_round_decade.png")
    }

    @Test
    @Config(sdk = [34], qualifiers = "w227dp-h227dp-notlong-round-xhdpi")
    fun wearGospelScreen_largeRound() {
        val sampleReading = GospelReading(
            citation = "Matthew 5:1-3",
            shortCitation = "Mt 5:1-3",
            bookName = "Matthew",
            verses = listOf(
                GospelVerse(5, 1, "Then, seeing the crowds, he ascended the mountain, and when he had sat down, his disciples drew near to him,"),
                GospelVerse(5, 2, "and opening his mouth, he taught them, saying:"),
                GospelVerse(5, 3, "Blessed are the poor in spirit, for theirs is the kingdom of heaven."),
            ),
        )
        composeRule.setContent {
            RoundWatchPreviewFrame(diameter = 227.dp) {
                WearGospelScreen(
                    reading = sampleReading,
                    accentColor = Color(LiturgicalColor.PURPLE.hexArgb),
                    onBack = {},
                )
            }
        }
        composeRule.onRoot().captureRoboImage("src/test/snapshots/wear_gospel_large_round.png")
    }
}
