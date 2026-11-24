package com.mweastwood.twelve_stars.wear.data

import org.json.JSONObject
import java.io.InputStream
import java.time.LocalDate
import java.time.format.DateTimeFormatter

enum class LiturgicalColor(val hexArgb: Long) {
    GREEN(0xFF2E7D32),
    PURPLE(0xFF6A1B9A),
    WHITE(0xFFC68A00),
    RED(0xFFC62828),
    ROSE(0xFFD81B60);

    companion object {
        fun fromJsonKey(key: String?): LiturgicalColor {
            return when (key?.lowercase()) {
                "green" -> GREEN
                "purple" -> PURPLE
                "white" -> WHITE
                "red" -> RED
                "rose" -> ROSE
                else -> GREEN
            }
        }
    }
}

data class LiturgicalDayInfo(
    val date: LocalDate,
    val season: String,
    val seasonName: String,
    val color: LiturgicalColor,
    val colorName: String,
    val feastName: String?,
    val weekName: String,
    val sundayCycle: String,
    val weekdayCycle: String,
    val rosaryMystery: String,
) {
    val displayTitle: String
        get() = feastName?.takeIf { it.isNotBlank() } ?: weekName
}

class LiturgicalRepository(
    private val daysByIsoDate: Map<String, LiturgicalDayInfo>,
) {
    fun dayForDate(date: LocalDate): LiturgicalDayInfo? {
        return daysByIsoDate[date.format(DateTimeFormatter.ISO_LOCAL_DATE)]
    }

    val size: Int
        get() = daysByIsoDate.size

    companion object {
        fun loadFromStream(input: InputStream): LiturgicalRepository {
            val rawText = input.bufferedReader(Charsets.UTF_8).use { it.readText() }
            return loadFromJson(rawText)
        }

        fun loadFromJson(rawJson: String): LiturgicalRepository {
            val root = JSONObject(rawJson)
            val daysObj = root.optJSONObject("days") ?: return LiturgicalRepository(emptyMap())
            val map = HashMap<String, LiturgicalDayInfo>(daysObj.length())

            val keys = daysObj.keys()
            while (keys.hasNext()) {
                val dateKey = keys.next()
                val item = daysObj.optJSONObject(dateKey) ?: continue
                val parsedDate = runCatching {
                    LocalDate.parse(dateKey, DateTimeFormatter.ISO_LOCAL_DATE)
                }.getOrNull() ?: continue

                map[dateKey] = LiturgicalDayInfo(
                    date = parsedDate,
                    season = item.optString("season", "ordinaryTime"),
                    seasonName = item.optString("seasonName", "Ordinary Time"),
                    color = LiturgicalColor.fromJsonKey(item.optString("color")),
                    colorName = item.optString("colorName", "Green"),
                    feastName = if (item.has("name") && !item.isNull("name")) {
                        item.optString("name")
                    } else {
                        null
                    },
                    weekName = item.optString("weekName", ""),
                    sundayCycle = item.optString("sundayCycle", "A"),
                    weekdayCycle = item.optString("weekdayCycle", "I"),
                    rosaryMystery = item.optString("rosaryMystery", "joyful"),
                )
            }

            return LiturgicalRepository(map)
        }
    }
}
