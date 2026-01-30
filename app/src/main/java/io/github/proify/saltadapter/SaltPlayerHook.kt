package io.github.proify.saltadapter

import android.content.Context
import com.highcapable.yukihookapi.hook.entity.YukiBaseHooker
import com.highcapable.yukihookapi.hook.factory.method
import com.highcapable.yukihookapi.hook.log.YLog
import com.highcapable.yukihookapi.hook.type.java.StringClass
import com.highcapable.yukihookapi.hook.type.java.LongType

class SaltPlayerHook : YukiBaseHooker() {

    private var lyricProvider: SaltLyricProvider? = null
    private var lyricInterceptor: LyricInterceptor? = null
    private var playbackMonitor: PlaybackMonitor? = null

    override fun onHook() {
        YLog.info("SaltPlayer Hook initialized for package: $packageName")
        
        if (packageName != "com.salt.music") {
            YLog.info("Skipping non-target package: $packageName")
            return
        }

        try {
            // Initialize components
            lyricProvider = SaltLyricProvider(appContext)
            lyricInterceptor = LyricInterceptor(lyricProvider!!)
            playbackMonitor = PlaybackMonitor(appContext, lyricProvider!!)
            
            // Register with Lyricon
            lyricProvider?.register()
            
            // Start monitoring
            playbackMonitor?.startMonitoring()
            
            // Hook various lyric methods
            hookLyricView()
            hookLyricController()
            hookMediaController()
            hookNotification()
            
            YLog.info("SaltPlayer hooks installed successfully")
        } catch (e: Exception) {
            YLog.error("Failed to initialize hooks: ${e.message}")
        }
    }

    private fun hookLyricView() {
        // Attempt to hook common lyric view classes
        val possibleClasses = listOf(
            "com.salt.music.ui.lyric.LyricView",
            "com.salt.music.lyric.LyricView",
            "com.salt.music.view.LyricTextView",
            "com.salt.music.widget.LyricView"
        )
        
        possibleClasses.forEach { className ->
            try {
                findClass(className).apply {
                    method {
                        name = "setLyric"
                        param(StringClass)
                    }.hook {
                        before {
                            val lyric = args[0] as? String ?: return@before
                            lyricProvider?.onLyricUpdate(lyric, System.currentTimeMillis())
                            YLog.debug("Intercepted lyric: $lyric")
                        }
                    }
                    
                    method {
                        name = "updateLyric"
                        param(StringClass, LongType)
                    }.hook {
                        before {
                            val lyric = args[0] as? String ?: return@before
                            val timestamp = args[1] as? Long ?: 0L
                            lyricProvider?.onLyricUpdate(lyric, timestamp)
                        }
                    }
                }
                YLog.info("Hooked lyric class: $className")
            } catch (e: Exception) {
                YLog.debug("Class not found: $className")
            }
        }
    }

    private fun hookLyricController() {
        val possibleControllers = listOf(
            "com.salt.music.player.LyricController",
            "com.salt.music.lyric.LyricController",
            "com.salt.music.service.LyricManager"
        )
        
        possibleControllers.forEach { className ->
            try {
                findClass(className).apply {
                    method {
                        name = "setCurrentLyric"
                    }.hook {
                        before {
                            val lyric = args[0] as? String ?: return@before
                            lyricProvider?.onLyricUpdate(lyric, System.currentTimeMillis())
                        }
                    }
                    
                    method {
                        name = "onLyricUpdate"
                    }.hook {
                        before {
                            val lyric = args[0] as? String ?: return@before
                            lyricProvider?.onLyricUpdate(lyric, System.currentTimeMillis())
                        }
                    }
                }
            } catch (e: Exception) {
                YLog.debug("Controller class not found: $className")
            }
        }
    }

    private fun hookMediaController() {
        try {
            findClass("com.salt.music.player.MediaController").apply {
                method {
                    name = "setPlaybackState"
                }.hook {
                    before {
                        val isPlaying = args[0] as? Boolean ?: false
                        lyricProvider?.onPlaybackStateChanged(isPlaying)
                    }
                }
                
                method {
                    name = "seekTo"
                }.hook {
                    before {
                        val position = args[0] as? Long ?: 0L
                        lyricProvider?.onPositionChanged(position)
                    }
                }
            }
        } catch (e: Exception) {
            YLog.debug("MediaController not found")
        }
    }

    private fun hookNotification() {
        // Hook notification updates for metadata extraction
        try {
            findClass("android.app.NotificationManager").apply {
                method {
                    name = "notify"
                }.hook {
                    before {
                        val notification = args[1] as? android.app.Notification
                        notification?.let { notif ->
                            extractLyricFromNotification(notif)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            YLog.debug("Could not hook NotificationManager")
        }
    }

    private fun extractLyricFromNotification(notification: android.app.Notification) {
        try {
            val extras = notification.extras
            val title = extras.getString(android.app.Notification.EXTRA_TITLE) ?: ""
            val text = extras.getCharSequence(android.app.Notification.EXTRA_TEXT)?.toString() ?: ""
            val subText = extras.getCharSequence(android.app.Notification.EXTRA_SUB_TEXT)?.toString() ?: ""
            
            // Check if this is Salt Player's notification
            if (title.isNotEmpty() && (text.contains("歌词") || subText.contains("歌词"))) {
                lyricProvider?.onLyricUpdate(text, System.currentTimeMillis())
            }
        } catch (e: Exception) {
            YLog.debug("Failed to extract from notification: ${e.message}")
        }
    }
}
