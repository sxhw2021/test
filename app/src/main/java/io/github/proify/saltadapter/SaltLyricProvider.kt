package io.github.proify.saltadapter

import android.content.Context
import io.github.proify.lyricon.bridge.provider.LyriconFactory
import io.github.proify.lyricon.bridge.provider.LyriconProvider
import io.github.proify.lyricon.bridge.provider.model.RichLyricLine
import io.github.proify.lyricon.bridge.provider.model.Song
import com.highcapable.yukihookapi.hook.log.YLog

class SaltLyricProvider(private val context: Context) {
    
    private var provider: LyriconProvider? = null
    private var currentSong: Song? = null
    private var isPlaying = false
    private var currentPosition = 0L
    private val lyricBuffer = mutableListOf<RichLyricLine>()
    private var lastLyricText = ""
    private var songStartTime = 0L
    
    fun register() {
        try {
            provider = LyriconFactory.createProvider(
                context = context,
                centralPackageName = "io.github.proify.lyricon"
            )
            
            provider?.register()
            YLog.info("Lyricon Provider registered successfully")
        } catch (e: Exception) {
            YLog.error("Failed to register Lyricon Provider: ${e.message}")
        }
    }
    
    fun onSongChanged(title: String, artist: String, duration: Long) {
        currentSong = Song(
            id = "${title}_${artist}_${System.currentTimeMillis()}",
            name = title,
            artist = artist,
            duration = duration,
            lyrics = emptyList()
        )
        
        try {
            provider?.player?.setSong(currentSong!!)
            YLog.info("Song changed: $title - $artist")
        } catch (e: Exception) {
            YLog.error("Failed to set song: ${e.message}")
        }
        
        lyricBuffer.clear()
        lastLyricText = ""
        songStartTime = System.currentTimeMillis()
    }
    
    fun onLyricUpdate(lyric: String, timestamp: Long) {
        if (lyric.isBlank() || lyric == lastLyricText) return
        
        lastLyricText = lyric
        
        // Create rich lyric line with timing
        val richLine = RichLyricLine(
            begin = timestamp - songStartTime,
            end = timestamp - songStartTime + 5000,
            text = lyric
        )
        
        lyricBuffer.add(richLine)
        
        // Update song with accumulated lyrics
        currentSong?.let { song ->
            try {
                val updatedSong = song.copy(lyrics = lyricBuffer.toList())
                provider?.player?.setSong(updatedSong)
            } catch (e: Exception) {
                YLog.debug("Failed to update song lyrics: ${e.message}")
            }
        }
        
        // Also send as simple text for immediate display
        try {
            provider?.player?.sendText(lyric)
            YLog.debug("Sent lyric: $lyric")
        } catch (e: Exception) {
            YLog.error("Failed to send lyric text: ${e.message}")
        }
    }
    
    fun onPlaybackStateChanged(playing: Boolean) {
        isPlaying = playing
        try {
            provider?.player?.setPlaybackState(playing)
            YLog.info("Playback state: $playing")
        } catch (e: Exception) {
            YLog.error("Failed to set playback state: ${e.message}")
        }
    }
    
    fun onPositionChanged(position: Long) {
        currentPosition = position
        try {
            provider?.player?.setPosition(position)
        } catch (e: Exception) {
            YLog.debug("Failed to set position: ${e.message}")
        }
    }
    
    fun sendLyricsWithTranslation(original: String, translation: String?) {
        val richLine = RichLyricLine(
            text = original,
            translation = translation,
            end = currentPosition + 5000
        )
        
        currentSong?.let { song ->
            try {
                val updatedLyrics = song.lyrics + richLine
                provider?.player?.setSong(
                    song.copy(lyrics = updatedLyrics)
                )
            } catch (e: Exception) {
                YLog.error("Failed to send translation: ${e.message}")
            }
        }
        
        // Send original text
        try {
            provider?.player?.sendText(original)
        } catch (e: Exception) {
            YLog.error("Failed to send original text: ${e.message}")
        }
        
        // Enable translation display if available
        translation?.let {
            try {
                provider?.player?.setDisplayTranslation(true)
            } catch (e: Exception) {
                YLog.debug("Failed to enable translation: ${e.message}")
            }
        }
    }
    
    fun disconnect() {
        provider = null
        YLog.info("Lyricon Provider disconnected")
    }
}
