package com.mweastwood.twelve_stars.wear.data

import org.json.JSONObject
import java.io.InputStream

data class GospelVerse(
    val chapter: Int,
    val number: Int,
    val text: String,
)

data class GospelReading(
    val citation: String,
    val shortCitation: String,
    val bookName: String,
    val verses: List<GospelVerse>,
)

class GospelRepository(
    private val readingsByKey: Map<String, GospelReading>,
) {
    fun readingForKey(lectionaryKey: String?): GospelReading? {
        if (lectionaryKey.isNullOrBlank()) return null
        return readingsByKey[lectionaryKey]
    }

    val size: Int
        get() = readingsByKey.size

    companion object {
        fun loadFromStream(input: InputStream): GospelRepository {
            val rawText = input.bufferedReader(Charsets.UTF_8).use { it.readText() }
            return loadFromJson(rawText)
        }

        fun loadFromJson(rawJson: String): GospelRepository {
            val root = JSONObject(rawJson)
            val readingsObj = root.optJSONObject("readings") ?: return GospelRepository(emptyMap())
            val map = HashMap<String, GospelReading>(readingsObj.length())

            val keys = readingsObj.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                val item = readingsObj.optJSONObject(key) ?: continue
                val versesArray = item.optJSONArray("verses") ?: continue
                val verses = ArrayList<GospelVerse>(versesArray.length())
                for (i in 0 until versesArray.length()) {
                    val vObj = versesArray.optJSONObject(i) ?: continue
                    val text = vObj.optString("text", "")
                    if (text.isNotEmpty()) {
                        verses.add(
                            GospelVerse(
                                chapter = vObj.optInt("chapter", 1),
                                number = vObj.optInt("number", i + 1),
                                text = text,
                            ),
                        )
                    }
                }
                if (verses.isNotEmpty()) {
                    val citation = item.optString("citation", "")
                    val shortCitation = item.optString("shortCitation", citation)
                    map[key] = GospelReading(
                        citation = citation,
                        shortCitation = shortCitation,
                        bookName = item.optString("bookName", ""),
                        verses = verses,
                    )
                }
            }
            return GospelRepository(map)
        }
    }
}
