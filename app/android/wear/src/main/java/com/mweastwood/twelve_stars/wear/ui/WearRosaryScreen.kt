package com.mweastwood.twelve_stars.wear.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.ButtonDefaults
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import com.mweastwood.twelve_stars.wear.data.RosaryLanguage
import com.mweastwood.twelve_stars.wear.data.RosaryRepository
import com.mweastwood.twelve_stars.wear.data.WearRosaryStep

@Composable
fun WearRosaryScreen(
    repository: RosaryRepository,
    mysteryKey: String,
    accentColor: Color,
    initialStepIndex: Int = 0,
    onBack: () -> Unit,
) {
    val steps = remember(repository, mysteryKey) {
        repository.generateSteps(mysteryKey)
    }
    var stepIndex by remember(steps) {
        mutableIntStateOf(initialStepIndex.coerceIn(0, (steps.size - 1).coerceAtLeast(0)))
    }
    var language by remember { mutableStateOf(RosaryLanguage.ENGLISH) }
    val scrollState = rememberScrollState()
    val haptics = LocalHapticFeedback.current

    LaunchedEffect(stepIndex) {
        scrollState.scrollTo(0)
    }

    val step = steps.getOrNull(stepIndex)
    val mysterySet = repository.mysteryForKey(mysteryKey)
    val prayerText = if (step != null) {
        repository.combinedPrayerText(step, language)
    } else {
        ""
    }

    fun advanceStep() {
        if (stepIndex < steps.lastIndex) {
            val next = steps[stepIndex + 1]
            val isDecadeBoundary = next.decadeNumber != step?.decadeNumber
            haptics.performHapticFeedback(
                if (isDecadeBoundary) HapticFeedbackType.LongPress else HapticFeedbackType.TextHandleMove,
            )
            stepIndex += 1
        }
    }

    fun previousStep() {
        if (stepIndex > 0) {
            haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
            stepIndex -= 1
        } else {
            onBack()
        }
    }

    val readableAccent = remember(accentColor) {
        androidx.compose.ui.graphics.lerp(accentColor, Color.White, 0.35f)
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .padding(top = 14.dp, bottom = 14.dp, start = 20.dp, end = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "${stepIndex + 1}/${steps.size}",
                style = MaterialTheme.typography.caption2,
                color = readableAccent,
                fontWeight = FontWeight.Bold,
            )
            Text(
                text = language.label,
                style = MaterialTheme.typography.caption2,
                color = Color.White,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .background(Color(0xFF1E293B))
                    .clickable {
                        language = if (language == RosaryLanguage.ENGLISH) {
                            RosaryLanguage.LATIN
                        } else {
                            RosaryLanguage.ENGLISH
                        }
                    }
                    .padding(horizontal = 8.dp, vertical = 2.dp),
            )
        }

        if (step?.decadeNumber != null) {
            Spacer(modifier = Modifier.height(5.dp))
            DecadeBeadStrip(
                activeBead = step.beadInDecade,
                accentColor = readableAccent,
            )
        }

        Spacer(modifier = Modifier.height(4.dp))

        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .verticalScroll(scrollState),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text(
                text = step?.mysteryTitle ?: mysterySet?.title ?: "Holy Rosary",
                style = MaterialTheme.typography.caption2,
                color = Color(0xFF94A3B8),
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )

            Spacer(modifier = Modifier.height(2.dp))

            Text(
                text = step?.title ?: "Complete",
                style = MaterialTheme.typography.title3,
                color = Color.White,
                textAlign = TextAlign.Center,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )

            if (prayerText.isNotBlank()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = prayerText,
                    style = MaterialTheme.typography.caption1,
                    color = Color(0xFFE2E8F0),
                    textAlign = TextAlign.Center,
                )
            }
        }

        Spacer(modifier = Modifier.height(6.dp))

        Row(
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Button(
                onClick = { previousStep() },
                colors = ButtonDefaults.secondaryButtonColors(),
                modifier = Modifier.size(32.dp),
            ) {
                Text(text = "<", style = MaterialTheme.typography.button)
            }
            Spacer(modifier = Modifier.width(8.dp))
            Button(
                onClick = { advanceStep() },
                enabled = stepIndex < steps.lastIndex,
                colors = ButtonDefaults.buttonColors(backgroundColor = accentColor),
                modifier = Modifier.size(width = 64.dp, height = 32.dp),
            ) {
                Text(
                    text = if (stepIndex < steps.lastIndex) "Next" else "Amen",
                    style = MaterialTheme.typography.button,
                    color = Color.White,
                )
            }
        }
    }
}

@Composable
private fun DecadeBeadStrip(
    activeBead: Int?,
    accentColor: Color,
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        for (bead in 1..10) {
            val isActive = activeBead == bead
            val isCompleted = activeBead != null && bead < activeBead
            Box(
                modifier = Modifier
                    .size(if (isActive) 8.dp else 6.dp)
                    .background(
                        color = when {
                            isActive -> accentColor
                            isCompleted -> accentColor.copy(alpha = 0.5f)
                            else -> Color(0xFF334155)
                        },
                        shape = CircleShape,
                    ),
            )
        }
    }
}
