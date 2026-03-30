package com.example.sante

import android.content.Context
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build

object AlarmSoundPlayer {
    private var ringtone: Ringtone? = null

    fun play(context: Context, soundType: String) {
        stop()

        val uri = when (soundType) {
            "ringtone" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            "notification" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            else -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        } ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        ringtone = RingtoneManager.getRingtone(context.applicationContext, uri)?.apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                isLooping = true
            }
            play()
        }
    }

    fun stop() {
        ringtone?.let {
            if (it.isPlaying) {
                it.stop()
            }
        }
        ringtone = null
    }
}
