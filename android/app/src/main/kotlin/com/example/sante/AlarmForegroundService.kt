package com.example.sante

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class AlarmForegroundService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val id = intent?.getIntExtra(EXTRA_ID, 0) ?: 0
        val titre = intent?.getStringExtra(EXTRA_TITRE) ?: "MediRemind"
        val message =
            intent?.getStringExtra(EXTRA_MESSAGE) ?: "Il est temps de prendre votre medicament"
        val soundType = intent?.getStringExtra(EXTRA_SOUND_TYPE) ?: "alarm"

        creerCanaux()
        AlarmSoundPlayer.play(applicationContext, soundType)

        val notification = buildNotification(id, titre, message)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(id, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(id, notification)
        }

        return START_STICKY
    }

    override fun onDestroy() {
        AlarmSoundPlayer.stop()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }

    private fun buildNotification(id: Int, titre: String, message: String) =
        NotificationCompat.Builder(this, CHANNEL_RAPPELS)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(titre)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(false)
            .setContentIntent(buildOpenPendingIntent(id, titre, message))
            .setVibrate(longArrayOf(0, 500, 200, 500))
            .setFullScreenIntent(buildOpenPendingIntent(id, titre, message), true)
            .addAction(android.R.drawable.ic_delete, "Arreter", buildStopPendingIntent(id))
            .addAction(android.R.drawable.ic_input_add, "Pris", buildOpenPendingIntent(id, titre, message))
            .setOngoing(true)
            .build()

    private fun buildOpenPendingIntent(id: Int, titre: String, message: String): PendingIntent {
        val alarmScreenIntent = Intent(this, AlarmActivity::class.java).apply {
            putExtra(EXTRA_ID, id)
            putExtra(EXTRA_TITRE, titre)
            putExtra(EXTRA_MESSAGE, message)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        return PendingIntent.getActivity(
            this,
            id,
            alarmScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun buildStopPendingIntent(id: Int): PendingIntent {
        val stopIntent = Intent(this, StopAlarmReceiver::class.java).apply {
            putExtra(EXTRA_ID, id)
        }
        return PendingIntent.getBroadcast(
            this,
            id + 99999,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun creerCanaux() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val nm = getSystemService(NotificationManager::class.java)
        val sonnerie = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        val audioAttr = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val canalAlarme = NotificationChannel(
            CHANNEL_RAPPELS,
            "Rappels medicaments",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Notifications de prise de medicaments"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 500, 200, 500)
            enableLights(true)
            setSound(sonnerie, audioAttr)
            setBypassDnd(true)
        }

        nm.createNotificationChannel(canalAlarme)
    }

    companion object {
        private const val CHANNEL_RAPPELS = "mediremind_rappels"
        const val EXTRA_ID = "id"
        const val EXTRA_TITRE = "titre"
        const val EXTRA_MESSAGE = "message"
        const val EXTRA_SOUND_TYPE = "soundType"
    }
}
