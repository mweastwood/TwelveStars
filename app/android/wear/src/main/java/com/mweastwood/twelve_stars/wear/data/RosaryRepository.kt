package com.mweastwood.twelve_stars.wear.data

import org.json.JSONObject
import java.io.InputStream
import java.time.DayOfWeek
import java.time.LocalDate

enum class RosaryLanguage(val jsonKey: String, val label: String) {
    ENGLISH("english", "EN"),
    LATIN("latin", "LA"),
}

data class RosaryDecade(
    val number: Int,
    val title: String,
    val description: String,
)

data class RosaryMysterySet(
    val key: String,
    val title: String,
    val days: String,
    val decades: List<RosaryDecade>,
)

data class RosaryPrayerTranslation(
    val title: String,
    val text: String,
)

data class RosaryPrayer(
    val id: String,
    val defaultTitle: String,
    val hasAmen: Boolean,
    val translations: Map<String, RosaryPrayerTranslation>,
) {
    fun textFor(language: RosaryLanguage): String {
        return translations[language.jsonKey]?.text?.takeIf { it.isNotBlank() }
            ?: translations[RosaryLanguage.ENGLISH.jsonKey]?.text?.takeIf { it.isNotBlank() }
            ?: ""
    }

    fun titleFor(language: RosaryLanguage): String {
        return translations[language.jsonKey]?.title?.takeIf { it.isNotBlank() }
            ?: defaultTitle
    }
}

data class WearRosaryStep(
    val index: Int,
    val title: String,
    val subtitle: String?,
    val prayerId: String,
    val secondaryPrayerId: String? = null,
    val tertiaryPrayerId: String? = null,
    val decadeNumber: Int? = null,
    val beadInDecade: Int? = null,
    val mysteryTitle: String? = null,
)

class RosaryRepository(
    val mysteries: Map<String, RosaryMysterySet>,
    val prayers: Map<String, RosaryPrayer>,
) {
    fun mysteryForKey(key: String?): RosaryMysterySet? {
        val normalized = key?.lowercase() ?: return mysteries["joyful"]
        return mysteries[normalized] ?: mysteries["joyful"]
    }

    fun generateSteps(mysteryKey: String): List<WearRosaryStep> {
        val mystery = mysteryForKey(mysteryKey)
        val decades = mystery?.decades ?: emptyList()
        val steps = ArrayList<WearRosaryStep>(67)

        fun addStep(
            title: String,
            subtitle: String? = null,
            prayerId: String,
            secondaryPrayerId: String? = null,
            tertiaryPrayerId: String? = null,
            decadeNumber: Int? = null,
            beadInDecade: Int? = null,
            mysteryTitle: String? = null,
        ) {
            steps.add(
                WearRosaryStep(
                    index = steps.size,
                    title = title,
                    subtitle = subtitle,
                    prayerId = prayerId,
                    secondaryPrayerId = secondaryPrayerId,
                    tertiaryPrayerId = tertiaryPrayerId,
                    decadeNumber = decadeNumber,
                    beadInDecade = beadInDecade,
                    mysteryTitle = mysteryTitle,
                ),
            )
        }

        addStep(
            title = "Opening Prayers",
            subtitle = "Sign of the Cross & Creed",
            prayerId = "sign_of_the_cross",
            secondaryPrayerId = "apostles_creed",
        )
        addStep(title = "Our Father", subtitle = "Opening", prayerId = "our_father")
        for (i in 1..3) {
            addStep(title = "Hail Mary ($i/3)", subtitle = "Faith, Hope & Charity", prayerId = "hail_mary")
        }
        addStep(title = "Glory Be", subtitle = "Opening", prayerId = "glory_be")

        for (decadeIdx in 0 until 5) {
            val decade = decades.getOrNull(decadeIdx)
            val decadeNum = decade?.number ?: (decadeIdx + 1)
            val mysteryTitle = decade?.title ?: "Mystery $decadeNum"

            addStep(
                title = "Our Father",
                subtitle = "Decade $decadeNum",
                prayerId = "our_father",
                decadeNumber = decadeNum,
                mysteryTitle = mysteryTitle,
            )
            for (bead in 1..10) {
                addStep(
                    title = "Hail Mary ($bead/10)",
                    subtitle = "Decade $decadeNum",
                    prayerId = "hail_mary",
                    decadeNumber = decadeNum,
                    beadInDecade = bead,
                    mysteryTitle = mysteryTitle,
                )
            }
            addStep(
                title = "Glory Be & Fatima",
                subtitle = "Decade $decadeNum",
                prayerId = "glory_be",
                secondaryPrayerId = "fatima_prayer",
                decadeNumber = decadeNum,
                mysteryTitle = mysteryTitle,
            )
        }

        addStep(
            title = "Closing Prayers",
            subtitle = "Hail, Holy Queen",
            prayerId = "hail_holy_queen",
            secondaryPrayerId = "final_prayer_rosary",
            tertiaryPrayerId = "sign_of_the_cross",
        )

        return steps
    }

    fun combinedPrayerText(step: WearRosaryStep, language: RosaryLanguage): String {
        val parts = listOfNotNull(
            prayers[step.prayerId]?.textFor(language)?.takeIf { it.isNotBlank() },
            step.secondaryPrayerId?.let { prayers[it]?.textFor(language)?.takeIf { t -> t.isNotBlank() } },
            step.tertiaryPrayerId?.let { prayers[it]?.textFor(language)?.takeIf { t -> t.isNotBlank() } },
        )
        return parts.joinToString("\n\n")
    }

    companion object {
        fun defaultMysteryKeyForDate(date: LocalDate): String {
            return when (date.dayOfWeek) {
                DayOfWeek.MONDAY, DayOfWeek.SATURDAY -> "joyful"
                DayOfWeek.TUESDAY, DayOfWeek.FRIDAY -> "sorrowful"
                DayOfWeek.THURSDAY -> "luminous"
                else -> "glorious"
            }
        }

        fun loadFromStream(input: InputStream): RosaryRepository {
            val raw = input.bufferedReader(Charsets.UTF_8).use { it.readText() }
            return loadFromJson(raw)
        }

        fun loadFromJson(rawJson: String): RosaryRepository {
            val root = JSONObject(rawJson)
            val mysteriesObj = root.optJSONObject("mysteries") ?: JSONObject()
            val mysteriesMap = LinkedHashMap<String, RosaryMysterySet>()
            val mysteryKeys = mysteriesObj.keys()
            while (mysteryKeys.hasNext()) {
                val key = mysteryKeys.next()
                val mObj = mysteriesObj.optJSONObject(key) ?: continue
                val decadesArr = mObj.optJSONArray("decades")
                val decades = buildList {
                    if (decadesArr != null) {
                        for (i in 0 until decadesArr.length()) {
                            val d = decadesArr.optJSONObject(i) ?: continue
                            add(
                                RosaryDecade(
                                    number = d.optInt("number", i + 1),
                                    title = d.optString("title", ""),
                                    description = d.optString("description", ""),
                                ),
                            )
                        }
                    }
                }
                mysteriesMap[key] = RosaryMysterySet(
                    key = key,
                    title = mObj.optString("title", key),
                    days = mObj.optString("days", ""),
                    decades = decades,
                )
            }

            val prayersObj = root.optJSONObject("prayers") ?: JSONObject()
            val prayersMap = LinkedHashMap<String, RosaryPrayer>()
            val prayerKeys = prayersObj.keys()
            while (prayerKeys.hasNext()) {
                val id = prayerKeys.next()
                val pObj = prayersObj.optJSONObject(id) ?: continue
                val transObj = pObj.optJSONObject("translations") ?: JSONObject()
                val transMap = LinkedHashMap<String, RosaryPrayerTranslation>()
                val langKeys = transObj.keys()
                while (langKeys.hasNext()) {
                    val lang = langKeys.next()
                    val tObj = transObj.optJSONObject(lang) ?: continue
                    transMap[lang] = RosaryPrayerTranslation(
                        title = tObj.optString("title", ""),
                        text = tObj.optString("text", ""),
                    )
                }
                prayersMap[id] = RosaryPrayer(
                    id = id,
                    defaultTitle = pObj.optString("defaultTitle", id),
                    hasAmen = pObj.optBoolean("hasAmen", false),
                    translations = transMap,
                )
            }

            return RosaryRepository(mysteriesMap, prayersMap)
        }
    }
}
