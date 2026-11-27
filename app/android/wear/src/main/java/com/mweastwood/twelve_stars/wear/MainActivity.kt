package com.mweastwood.twelve_stars.wear

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.wear.compose.material.ChipDefaults
import androidx.wear.compose.material.CompactChip
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import com.mweastwood.twelve_stars.wear.data.GospelReading
import com.mweastwood.twelve_stars.wear.data.GospelRepository
import com.mweastwood.twelve_stars.wear.data.LiturgicalColor
import com.mweastwood.twelve_stars.wear.data.LiturgicalDayInfo
import com.mweastwood.twelve_stars.wear.data.LiturgicalRepository
import com.mweastwood.twelve_stars.wear.data.RosaryRepository
import com.mweastwood.twelve_stars.wear.ui.WearGospelScreen
import com.mweastwood.twelve_stars.wear.ui.WearRosaryScreen
import com.mweastwood.twelve_stars.wear.watchfacepush.WatchFacePushController
import com.mweastwood.twelve_stars.wear.watchfacepush.WatchFacePushOutcome
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import java.time.LocalDate

class MainActivity : ComponentActivity() {
    private var liturgicalRepository: LiturgicalRepository? = null
    private var rosaryRepository: RosaryRepository? = null
    private var gospelRepository: GospelRepository? = null
    private lateinit var watchFacePushController: WatchFacePushController
    private var currentDate: LocalDate? = null
    private var refreshStatusJob: Job? = null
    private var todayInfoState by mutableStateOf<LiturgicalDayInfo?>(null)
    private var todayGospelState by mutableStateOf<GospelReading?>(null)
    private var showRosaryState by mutableStateOf(false)
    private var showGospelState by mutableStateOf(false)
    private var watchFaceSupportedState by mutableStateOf(false)
    private var watchFaceBusyState by mutableStateOf(false)
    private var watchFaceActiveState by mutableStateOf(false)
    private var watchFaceButtonLabelState by mutableStateOf(LABEL_SET_WATCH_FACE)
    private var watchFaceStatusDetailState by mutableStateOf<String?>(null)

    private val setActivePermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted ->
        runWatchFaceInstall(canSetActive = granted)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        watchFacePushController = WatchFacePushController(this)
        watchFaceSupportedState = watchFacePushController.isSupported()
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
        gospelRepository = runCatching {
            resources.openRawResource(R.raw.gospel_data).use { stream ->
                GospelRepository.loadFromStream(stream)
            }
        }.getOrNull()
        refreshTodayIfNeeded()
        if (savedInstanceState != null) {
            showRosaryState = savedInstanceState.getBoolean(STATE_SHOW_ROSARY, false)
            showGospelState = savedInstanceState.getBoolean(STATE_SHOW_GOSPEL, false)
        } else {
            applyLaunchIntent(intent)
        }

        setContent {
            BackHandler(enabled = showRosaryState || showGospelState) {
                showRosaryState = false
                showGospelState = false
            }
            MaterialTheme {
                val dayInfo = todayInfoState
                val accentColor = Color((dayInfo?.color ?: LiturgicalColor.GREEN).hexArgb)
                val repo = rosaryRepository
                val gospel = todayGospelState
                when {
                    showRosaryState && repo != null -> {
                        val mysteryKey = dayInfo?.rosaryMystery?.takeIf { it.isNotBlank() }
                            ?: RosaryRepository.defaultMysteryKeyForDate(LocalDate.now())
                        WearRosaryScreen(
                            repository = repo,
                            mysteryKey = mysteryKey,
                            accentColor = accentColor,
                            onBack = { showRosaryState = false },
                        )
                    }
                    showGospelState && gospel != null -> {
                        WearGospelScreen(
                            reading = gospel,
                            accentColor = accentColor,
                            onBack = { showGospelState = false },
                        )
                    }
                    else -> {
                        WearTodayScreen(
                            dayInfo = dayInfo,
                            onPrayRosary = if (repo != null) {
                                {
                                    showGospelState = false
                                    showRosaryState = true
                                }
                            } else {
                                null
                            },
                            gospelCitation = gospel?.shortCitation,
                            onReadGospel = if (gospel != null) {
                                {
                                    showRosaryState = false
                                    showGospelState = true
                                }
                            } else {
                                null
                            },
                            watchFaceButtonLabel = if (watchFaceSupportedState) {
                                watchFaceButtonLabelState
                            } else {
                                null
                            },
                            watchFaceStatusDetail = if (watchFaceSupportedState) {
                                watchFaceStatusDetailState
                            } else {
                                null
                            },
                            onSetWatchFace = if (
                                watchFaceSupportedState && !watchFaceBusyState && !watchFaceActiveState
                            ) {
                                { onSetWatchFaceClicked() }
                            } else {
                                null
                            },
                        )
                    }
                }
            }
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putBoolean(STATE_SHOW_ROSARY, showRosaryState)
        outState.putBoolean(STATE_SHOW_GOSPEL, showGospelState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        applyLaunchIntent(intent)
    }

    private fun applyLaunchIntent(intent: Intent?) {
        when {
            intent?.getBooleanExtra(EXTRA_OPEN_GOSPEL, false) == true -> {
                showRosaryState = false
                showGospelState = true
            }
            intent?.getBooleanExtra(EXTRA_OPEN_ROSARY, false) == true -> {
                showGospelState = false
                showRosaryState = true
            }
        }
    }

    override fun onResume() {
        super.onResume()
        refreshTodayIfNeeded()
        refreshWatchFaceStatus()
    }

    private fun refreshTodayIfNeeded() {
        val today = LocalDate.now()
        if (today != currentDate) {
            currentDate = today
            val dayInfo = liturgicalRepository?.dayForDate(today)
            todayInfoState = dayInfo
            todayGospelState = gospelRepository?.readingForKey(dayInfo?.lectionaryKey)
        }
    }

    private fun currentLiturgicalColor(): LiturgicalColor =
        todayInfoState?.color ?: LiturgicalColor.GREEN

    private fun refreshWatchFaceStatus() {
        if (!watchFaceSupportedState || watchFaceBusyState) return
        refreshStatusJob?.cancel()
        refreshStatusJob = lifecycleScope.launch {
            val todayColor = currentLiturgicalColor()
            val todayThemeKey = WatchFacePushController.themeKeyForColor(todayColor)
            val prefs = getSharedPreferences(PREFS_WATCHFACE, MODE_PRIVATE)
            if (prefs.getString(KEY_LAST_THEME, null) != todayThemeKey) {
                if (watchFacePushController.syncColorIfInstalled(todayColor)) {
                    prefs.edit().putString(KEY_LAST_THEME, todayThemeKey).apply()
                }
            }
            val active = watchFacePushController.isBundledWatchFaceActive()
            if (!watchFaceBusyState) {
                watchFaceActiveState = active
                watchFaceButtonLabelState = if (active) LABEL_WATCH_FACE_ACTIVE else LABEL_SET_WATCH_FACE
                if (active) {
                    watchFaceStatusDetailState = null
                }
            }
        }
    }

    private fun onSetWatchFaceClicked() {
        if (watchFaceBusyState || watchFaceActiveState) return
        val hasPermission = ContextCompat.checkSelfPermission(
            this,
            WatchFacePushController.PERMISSION_SET_ACTIVE,
        ) == PackageManager.PERMISSION_GRANTED
        if (hasPermission) {
            runWatchFaceInstall(canSetActive = true)
        } else {
            setActivePermissionLauncher.launch(WatchFacePushController.PERMISSION_SET_ACTIVE)
        }
    }

    private fun runWatchFaceInstall(canSetActive: Boolean) {
        refreshStatusJob?.cancel()
        watchFaceBusyState = true
        watchFaceButtonLabelState = LABEL_SETTING_WATCH_FACE
        watchFaceStatusDetailState = null
        val todayColor = currentLiturgicalColor()
        lifecycleScope.launch {
            try {
                when (
                    val outcome = watchFacePushController.installAndActivate(
                        canSetActive = canSetActive,
                        color = todayColor,
                    )
                ) {
                    WatchFacePushOutcome.Activated,
                    WatchFacePushOutcome.AlreadyActive,
                    -> {
                        getSharedPreferences(PREFS_WATCHFACE, MODE_PRIVATE)
                            .edit()
                            .putString(KEY_LAST_THEME, WatchFacePushController.themeKeyForColor(todayColor))
                            .apply()
                        watchFaceActiveState = true
                        watchFaceButtonLabelState = LABEL_WATCH_FACE_ACTIVE
                        watchFaceStatusDetailState = null
                    }
                    is WatchFacePushOutcome.InstalledPickInGallery -> {
                        getSharedPreferences(PREFS_WATCHFACE, MODE_PRIVATE)
                            .edit()
                            .putString(KEY_LAST_THEME, WatchFacePushController.themeKeyForColor(todayColor))
                            .apply()
                        watchFaceActiveState = false
                        watchFaceButtonLabelState = LABEL_ADDED_TO_PICKER
                        watchFaceStatusDetailState = outcome.detail
                    }
                    is WatchFacePushOutcome.Failed -> {
                        watchFaceActiveState = false
                        watchFaceButtonLabelState = LABEL_RETRY_WATCH_FACE
                        watchFaceStatusDetailState = outcome.reason
                    }
                }
            } finally {
                watchFaceBusyState = false
            }
        }
    }

    companion object {
        const val EXTRA_OPEN_ROSARY = "extra_open_rosary"
        const val EXTRA_OPEN_GOSPEL = "extra_open_gospel"
        private const val STATE_SHOW_ROSARY = "state_show_rosary"
        private const val STATE_SHOW_GOSPEL = "state_show_gospel"
        private const val PREFS_WATCHFACE = "twelve_stars_watchface_push"
        private const val KEY_LAST_THEME = "last_pushed_liturgical_theme"
        private const val LABEL_SET_WATCH_FACE = "Set Watch Face"
        private const val LABEL_SETTING_WATCH_FACE = "Setting..."
        private const val LABEL_WATCH_FACE_ACTIVE = "Watch Face Active"
        private const val LABEL_ADDED_TO_PICKER = "Added to Picker"
        private const val LABEL_RETRY_WATCH_FACE = "Retry Watch Face"
    }
}

@Composable
fun WearTodayScreen(
    dayInfo: LiturgicalDayInfo?,
    onPrayRosary: (() -> Unit)? = null,
    gospelCitation: String? = null,
    onReadGospel: (() -> Unit)? = null,
    watchFaceButtonLabel: String? = null,
    watchFaceStatusDetail: String? = null,
    onSetWatchFace: (() -> Unit)? = null,
) {
    val accentColor = Color((dayInfo?.color ?: LiturgicalColor.GREEN).hexArgb)
    val readableAccent = lerp(accentColor, Color.White, 0.35f)
    val title = dayInfo?.displayTitle ?: "Twelve Stars"
    val season = dayInfo?.seasonName ?: "Daily Prayer"
    val mysteryLabel = dayInfo?.rosaryMystery
        ?.takeIf { it.isNotBlank() }
        ?.replaceFirstChar { it.uppercase() }
    val hasExtraChips = onReadGospel != null || watchFaceButtonLabel != null
    val bottomPadding = if (hasExtraChips) 24.dp else 14.dp

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .verticalScroll(rememberScrollState())
            .padding(start = 24.dp, end = 24.dp, top = 14.dp, bottom = bottomPadding),
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
            color = readableAccent,
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
        if (onReadGospel != null) {
            Spacer(modifier = Modifier.height(2.dp))
            CompactChip(
                onClick = onReadGospel,
                label = {
                    Text(
                        text = gospelCitation?.let { "Gospel: $it" } ?: "Read Gospel",
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                },
                colors = ChipDefaults.secondaryChipColors(
                    backgroundColor = Color(0xFF1F2937),
                    contentColor = Color.White,
                ),
            )
        }
        if (watchFaceButtonLabel != null) {
            Spacer(modifier = Modifier.height(2.dp))
            CompactChip(
                onClick = { onSetWatchFace?.invoke() },
                enabled = onSetWatchFace != null,
                label = {
                    Text(
                        text = watchFaceButtonLabel,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                },
                colors = ChipDefaults.secondaryChipColors(
                    backgroundColor = Color(0xFF1F2937),
                    contentColor = Color.White,
                ),
            )
            if (!watchFaceStatusDetail.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = watchFaceStatusDetail,
                    style = MaterialTheme.typography.caption3,
                    color = Color(0xFFB0BEC5),
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}
