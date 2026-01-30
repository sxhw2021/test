package io.github.proify.saltadapter

import android.content.Context
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.os.Handler
import android.os.Looper
import com.highcapable.yukihookapi.hook.log.YLog

class PlaybackMonitor(
    private val context: Context,
    private val provider: SaltLyricProvider
) {
    private val handler = Handler(Looper.getMainLooper())
    private var isMonitoring = false
    private var lastPosition = 0L
    private var lastPlaybackState = false
    private var lastTitle = ""
    private var lastArtist = ""
    
    private val updateRunnable = object : Runnable {
        override fun run() {
            if (isMonitoring) {
                try {
                    checkMediaSession()
                } catch (e: Exception) {
                    YLog.error("Error in monitoring loop: ${e.message}")
                }
                handler.postDelayed(this, 500)
            }
        }
    }
    
    fun startMonitoring() {
        if (isMonitoring) return
        
        isMonitoring = true
        handler.post(updateRunnable)
        YLog.info("Playback monitoring started")
    }
    
    fun stopMonitoring() {
        isMonitoring = false
        handler.removeCallbacks(updateRunnable)
        YLog.info("Playback monitoring stopped")
    }
    
    private fun checkMediaSession() {
        try {
            val sessionManager = context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
            val controllers = sessionManager.getActiveSessions(null)
            
            val saltController = controllers.find { 
                it.packageName == "com.salt.music" 
            }
            
            saltController?.let { controller ->
                updateFromMediaController(controller)
            } ?: run {
                YLog.debug("Salt Player media session not found")
            }
        } catch (e: SecurityException) {
            YLog.error("Security exception accessing media sessions: ${e.message}")
        } catch (e: Exception) {
            YLog.error("Error checking media session: ${e.message}")
        }
    }
    
    private fun updateFromMediaController(controller: MediaController) {
        try {
            val metadata = controller.metadata
            val playbackState = controller.playbackState
            
            // Update metadata
            metadata?.let { meta ->
                val title = meta.getString(MediaMetadata.METADATA_KEY_TITLE) ?: ""
                val artist = meta.getString(MediaMetadata.METADATA_KEY_ARTIST) 
                    ?: meta.getString(MediaMetadata.METADATA_KEY_ALBUM_ARTIST) 
                    ?: ""
                val duration = meta.getLong(MediaMetadata.METADATA_KEY_DURATION)
                
                // Only update if song changed
                if (title != lastTitle || artist != lastArtist) {
                    provider.onSongChanged(title, artist, duration)
                    lastTitle = title
                    lastArtist = artist
                    YLog.info("New song detected: $title - $artist")
                }
            }
            
            // Update playback state
            playbackState?.let { state ->
                val isPlaying = state.state == android.media.session.PlaybackState.STATE_PLAYING
                val position = state.position
                
                if (isPlaying != lastPlaybackState) {
                    provider.onPlaybackStateChanged(isPlaying)
                    lastPlaybackState = isPlaying
                    YLog.info("Playback state changed: $isPlaying")
                }
                
                if (kotlin.math.abs(position - lastPosition) > 1000) {
                    provider.onPositionChanged(position)
                    lastPosition = position
                }
            }
        } catch (e: Exception) {
            YLog.error("Error updating from media controller: ${e.message}")
        }
    }
    
    fun isActive(): Boolean {
        return isMonitoring
    }
}
