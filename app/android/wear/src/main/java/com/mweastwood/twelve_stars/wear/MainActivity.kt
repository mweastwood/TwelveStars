package com.mweastwood.twelve_stars.wear

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
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import com.mweastwood.twelve_stars.wear.data.LiturgicalColor
import com.mweastwood.twelve_stars.wear.data.LiturgicalDayInfo
import com.mweastwood.twelve_stars.wear.data.LiturgicalRepository
import java.time.LocalDate

class MainActivity : ComponentActivity() {
    private var loadedDate: LocalDate? = null
    private var todayInfo by mutableStateOf<LiturgicalDayInfo?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        refreshTodayInfo()

        setContent {
            MaterialTheme {
                WearTodayScreen(dayInfo = todayInfo)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        refreshTodayInfo()
    }

    private fun refreshTodayInfo() {
        val today = LocalDate.now()
        if (loadedDate == today && todayInfo != null) {
            return
        }
        loadedDate = today
        todayInfo = runCatching {
            resources.openRawResource(R.raw.liturgical_calendar).use { stream ->
                LiturgicalRepository.loadFromStream(stream).dayForDate(today)
            }
        }.getOrNull()
    }
}

@Composable
fun WearTodayScreen(dayInfo: LiturgicalDayInfo?) {
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
            .padding(horizontal = 24.dp, vertical = 28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Box(
            modifier = Modifier
                .size(12.dp)
                .background(accentColor, CircleShape),
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = season,
            style = MaterialTheme.typography.caption2,
            color = accentColor,
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.title3,
            color = Color.White,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        if (mysteryLabel != null) {
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = "$mysteryLabel Mysteries",
                style = MaterialTheme.typography.caption1,
                color = Color(0xFFB0BEC5),
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}
