package com.example.sante

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import java.util.Calendar

class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra("id", 0)
        val titre = intent.getStringExtra("titre") ?: "MediRemind"
        val message =
            intent.getStringExtra("message") ?: "Il est l'heure de prendre votre medicament"
        val heure = intent.getIntExtra("heure", -1)
        val minute = intent.getIntExtra("minute", -1)
        val soundType = intent.getStringExtra("soundType") ?: "alarm"

        creerCanaux(context)

        val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
            putExtra("id", id)
            putExtra("titre", titre)
            putExtra("message", message)
            putExtra("soundType", soundType)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        if (heure >= 0 && minute >= 0) {
            reprogrammerDemain(context, intent, id, heure, minute)
        }
    }

    private fun creerCanaux(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val sonnerie = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        val audioAttr = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val canalAlarme = NotificationChannel(
            "mediremind_rappels",
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

        val canalStock = NotificationChannel(
            "mediremind_stock",
            "Alertes de stock",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Alertes de renouvellement de medicaments"
        }

        nm.createNotificationChannel(canalAlarme)
        nm.createNotificationChannel(canalStock)
    }

    private fun reprogrammerDemain(
        context: Context,
        intent: Intent,
        id: Int,
        heure: Int,
        minute: Int,
    ) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
                return
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            val demain = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, heure)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                demain.timeInMillis,
                pendingIntent,
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
