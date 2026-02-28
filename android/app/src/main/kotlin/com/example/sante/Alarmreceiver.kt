package com.example.sante

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import java.util.Calendar

class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val id      = intent.getIntExtra("id", 0)
        val titre   = intent.getStringExtra("titre") ?: "💊 MediRemind"
        val message = intent.getStringExtra("message") ?: "Il est l'heure de prendre votre médicament"
        val heure   = intent.getIntExtra("heure", -1)
        val minute  = intent.getIntExtra("minute", -1)

        // Créer le canal ici (MainActivity peut ne pas être lancée)
        creerCanaux(context)

        // Jouer la sonnerie d'alarme directement (bypass NPD)
        jouerSonnerie(context)

        // Afficher la notification plein écran
        afficherNotification(context, id, titre, message)

        // Reprogrammer pour demain à la même heure exacte
        if (heure >= 0 && minute >= 0) {
            reprogrammerDemain(context, intent, id, heure, minute)
        }
    }

    private fun creerCanaux(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val sonnerie = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            val audioAttr = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            // Canal alarme — importance MAX + bypass NPD
            val canalAlarme = NotificationChannel(
                "mediremind_rappels",
                "Rappels médicaments",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications de prise de médicaments"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500)
                enableLights(true)
                setSound(sonnerie, audioAttr)
                setBypassDnd(true)
            }

            // Canal stock (importance normale)
            val canalStock = NotificationChannel(
                "mediremind_stock",
                "Alertes de stock",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Alertes de renouvellement de médicaments"
            }

            nm.createNotificationChannel(canalAlarme)
            nm.createNotificationChannel(canalStock)
        }
    }

    // Jouer la sonnerie d'alarme système directement
    // Cela fonctionne même si le mode NPD est actif
    private fun jouerSonnerie(context: Context) {
        try {
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val ringtone: Ringtone = RingtoneManager.getRingtone(context, uri)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                ringtone.isLooping = false
            }
            ringtone.play()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun afficherNotification(
        context: Context, id: Int, titre: String, message: String
    ) {
        val ouvrirAppIntent = Intent().apply {
            setClassName(context.packageName, "${context.packageName}.MainActivity")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context, id, ouvrirAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val sonnerie = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)

        val notification = NotificationCompat.Builder(context, "mediremind_rappels")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(titre)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setSound(sonnerie)
            .setVibrate(longArrayOf(0, 500, 200, 500))
            .setFullScreenIntent(pendingIntent, true)
            .build()

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(id, notification)
    }

    private fun reprogrammerDemain(
        context: Context, intent: Intent, id: Int, heure: Int, minute: Int
    ) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (!alarmManager.canScheduleExactAlarms()) return
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context, id, intent,
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