package com.mweastwood.twelve_stars.wear.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.input.rotary.onRotaryScrollEvent
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.ChipDefaults
import androidx.wear.compose.material.CompactChip
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import com.mweastwood.twelve_stars.wear.data.GospelReading
import kotlinx.coroutines.launch

@Composable
fun WearGospelScreen(
    reading: GospelReading,
    accentColor: Color,
    onBack: () -> Unit,
) {
    val readableAccent = lerp(accentColor, Color.White, 0.35f)
    val scrollState = rememberScrollState()
    val focusRequester = remember { FocusRequester() }
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(reading.citation) {
        scrollState.scrollTo(0)
        runCatching { focusRequester.requestFocus() }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .onRotaryScrollEvent { event ->
                coroutineScope.launch {
                    scrollState.scrollBy(event.verticalScrollPixels)
                }
                true
            }
            .focusRequester(focusRequester)
            .focusable()
            .verticalScroll(scrollState)
            .padding(start = 20.dp, end = 20.dp, top = 22.dp, bottom = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "Gospel",
            style = MaterialTheme.typography.caption2,
            color = readableAccent,
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.height(2.dp))
        Text(
            text = reading.citation,
            style = MaterialTheme.typography.title3,
            color = Color.White,
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.height(10.dp))

        val body = remember(reading) {
            buildAnnotatedString {
                reading.verses.forEachIndexed { index, verse ->
                    if (index > 0) append(" ")
                    withStyle(
                        SpanStyle(
                            color = readableAccent,
                            fontWeight = FontWeight.Bold,
                        ),
                    ) {
                        append("${verse.number} ")
                    }
                    append(verse.text)
                }
            }
        }

        Text(
            text = body,
            style = MaterialTheme.typography.body2,
            color = Color(0xFFE5E7EB),
            modifier = Modifier.fillMaxWidth(),
        )

        Spacer(modifier = Modifier.height(14.dp))
        CompactChip(
            onClick = onBack,
            label = { Text(text = "Done") },
            colors = ChipDefaults.secondaryChipColors(
                backgroundColor = Color(0xFF1F2937),
                contentColor = Color.White,
            ),
        )
    }
}
