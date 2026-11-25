package com.mweastwood.twelve_stars.wear

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.ChipDefaults
import androidx.wear.compose.material.CompactChip
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import com.mweastwood.twelve_stars.wear.data.LiturgicalColor
import com.mweastwood.twelve_stars.wear.data.LiturgicalDayInfo
import com.mweastwood.twelve_stars.wear.data.LiturgicalRepository
import com.mweastwood.twelve_stars.wear.data.RosaryRepository
import com.mweastwood.twelve_stars.wear.ui.WearRosaryScreen
import java.time.LocalDate

class MainActivity : ComponentActivity() {
    private var liturgicalRepository: LiturgicalRepository? = null
    private var rosaryRepository: RosaryRepository? = null
    private var currentDate: LocalDate? = null
    private var todayInfoState by mutableStateOf<LiturgicalDayInfo?>(null)
    private var showRosaryState by mutableStateOf(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        liturgicalRepository = runCatching {
            resources.openRawResource(R.raw.liturgical_calendar).use { stream ->
                LiturgicalRepository.loadFromStream(stream)
            }
        }.getOrNull()
        rosaryRepository = runCatching {
            resources.openRawResource(R.raw.rosary_data).use { stream ->
                RosaryRepository.loadFromStream(stream)
            }
        }.getOrNull()
        refreshTodayIfNeeded()
        if (intent?.getBooleanExtra(EXTRA_OPEN_ROSARY, false) == true) {
            showRosaryState = true
        }

        setContent {
            MaterialTheme {
                val dayInfo = todayInfoState
                val accentColor = Color((dayInfo?.color ?: LiturgicalColor.GREEN).hexArgb)
                val repo = rosaryRepository
                if (showRosaryState && repo != null) {
                    val mysteryKey = dayInfo?.rosaryMystery?.takeIf { it.isNotBlank() }
                        ?: RosaryRepository.defaultMysteryKeyForDate(LocalDate.now())
                    WearRosaryScreen(
                        repository = repo,
                        mysteryKey = mysteryKey,
                        accentColor = accentColor,
                        onBack = { showRosaryState = false },
                    )
                } else {
                    WearTodayScreen(
                        dayInfo = dayInfo,
                        onPrayRosary = if (repo != null) {
                            { showRosaryState = true }
                        } else {
                            null
                        },
                    )
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(EXTRA_OPEN_ROSARY, false)) {
            showRosaryState = true
        }
    }

    override fun onResume() {
        super.onResume()
        refreshTodayIfNeeded()
    }

    private fun refreshTodayIfNeeded() {
        val today = LocalDate.now()
        if (today != currentDate) {
            currentDate = today
            todayInfoState = liturgicalRepository?.dayForDate(today)
        }
    }

    companion object {
        const val EXTRA_OPEN_ROSARY = "extra_open_rosary"
    }
}

@Composable
fun WearTodayScreen(
    dayInfo: LiturgicalDayInfo?,
    onPrayRosary: (() -> Unit)? = null,
) {
    val accentColor = Color((dayInfo?.color ?: LiturgicalColor.GREEN).hexArgb)
    val title = dayInfo?.displayTitle ?: "Twelve Stars"
    val season = dayInfo?.seasonName ?: "Daily Prayer"
    val mysteryLabel = dayInfo?.rosaryMystery
        ?.takeIf { it.isNotBlank() }
        ?.replaceFirstChar { it.uppercase() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp, vertical = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Box(
            modifier = Modifier
                .size(10.dp)
                .background(accentColor, CircleShape),
        )
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = season,
            style = MaterialTheme.typography.caption2,
            color = accentColor,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Spacer(modifier = Modifier.height(2.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.title3,
            color = Color.White,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        if (mysteryLabel != null) {
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "$mysteryLabel Mysteries",
                style = MaterialTheme.typography.caption2,
                color = Color(0xFFB0BEC5),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        if (onPrayRosary != null) {
            Spacer(modifier = Modifier.height(6.dp))
            CompactChip(
                onClick = onPrayRosary,
                label = {
                    Text(
                        text = "Pray Rosary",
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                },
                colors = ChipDefaults.primaryChipColors(
                    backgroundColor = accentColor,
                    contentColor = Color.White,
                ),
            )
        }
    }
}
