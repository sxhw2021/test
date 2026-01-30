package io.github.proify.saltadapter

import com.highcapable.yukihookapi.hook.log.YLog
import org.json.JSONArray
import org.json.JSONObject

class LyricInterceptor(private val provider: SaltLyricProvider) {
    
    private var parsedLyrics: List<ParsedLyricLine> = emptyList()
    private var currentLineIndex = 0
    
    data class ParsedLyricLine(
        val timestamp: Long,
        val text: String,
        val translation: String? = null,
        val words: List<LyricWordTiming>? = null
    )
    
    data class LyricWordTiming(
        val text: String,
        val startTime: Long,
        val duration: Long
    )
    
    fun interceptLrcFormat(lrcContent: String) {
        parsedLyrics = parseLrc(lrcContent)
        currentLineIndex = 0
        YLog.info("Parsed ${parsedLyrics.size} lines from LRC format")
    }
    
    fun interceptEnhancedFormat(jsonContent: String) {
        try {
            val json = JSONObject(jsonContent)
            val lines = json.optJSONArray("lines") ?: JSONArray()
            
            parsedLyrics = (0 until lines.length()).map { i ->
                val line = lines.getJSONObject(i)
                ParsedLyricLine(
                    timestamp = line.optLong("timestamp", 0),
                    text = line.optString("text", ""),
                    translation = line.optString("translation", null)?.takeIf { it.isNotBlank() },
                    words = parseWords(line.optJSONArray("words"))
                )
            }
            
            currentLineIndex = 0
            YLog.info("Parsed ${parsedLyrics.size} lines from enhanced format")
        } catch (e: Exception) {
            YLog.error("Failed to parse enhanced lyric format: ${e.message}")
        }
    }
    
    private fun parseLrc(lrcContent: String): List<ParsedLyricLine> {
        val lines = mutableListOf<ParsedLyricLine>()
        // Match patterns like [00:12.34] or [00:12.345]
        val pattern = "\\[(\\d{2}):(\\d{2})\\.(\\d{2,3})\\](.*)".toRegex()
        
        lrcContent.lines().forEach { line ->
            val match = pattern.find(line)
            if (match != null) {
                try {
                    val minutes = match.groupValues[1].toLong()
                    val seconds = match.groupValues[2].toLong()
                    val millisStr = match.groupValues[3]
                    val millis = if (millisStr.length == 2) {
                        millisStr.toLong() * 10
                    } else {
                        millisStr.toLong()
                    }
                    val text = match.groupValues[4].trim()
                    
                    if (text.isNotBlank()) {
                        val timestamp = (minutes * 60 + seconds) * 1000 + millis
                        lines.add(ParsedLyricLine(timestamp, text))
                    }
                } catch (e: NumberFormatException) {
                    YLog.debug("Failed to parse LRC line: $line")
                }
            }
        }
        
        return lines.sortedBy { it.timestamp }
    }
    
    private fun parseWords(wordsArray: JSONArray?): List<LyricWordTiming>? {
        if (wordsArray == null || wordsArray.length() == 0) return null
        
        return try {
            (0 until wordsArray.length()).map { i ->
                val word = wordsArray.getJSONObject(i)
                LyricWordTiming(
                    text = word.optString("text", ""),
                    startTime = word.optLong("start", 0),
                    duration = word.optLong("duration", 0)
                )
            }
        } catch (e: Exception) {
            YLog.debug("Failed to parse words: ${e.message}")
            null
        }
    }
    
    fun updateCurrentPosition(position: Long): ParsedLyricLine? {
        val currentLine = parsedLyrics.lastOrNull { it.timestamp <= position }
        
        // Update index for next search optimization
        currentLine?.let { line ->
            val index = parsedLyrics.indexOf(line)
            if (index >= 0) {
                currentLineIndex = index
            }
        }
        
        return currentLine
    }
    
    fun getNextLine(position: Long): ParsedLyricLine? {
        return parsedLyrics.firstOrNull { it.timestamp > position }
    }
    
    fun hasTranslation(): Boolean {
        return parsedLyrics.any { it.translation != null }
    }
    
    fun isSyllableLyric(): Boolean {
        return parsedLyrics.any { it.words != null && it.words.isNotEmpty() }
    }
}
