package com.example.sante

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "com.example.sante/alarm"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        creerCanauxNotification()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "programmerAlarme" -> {
                        val id = call.argument<Int>("id") ?: 0
                        val titre = call.argument<String>("titre") ?: ""
                        val message = call.argument<String>("message") ?: ""
                        val heure = call.argument<Int>("heure") ?: 0
                        val minute = call.argument<Int>("minute") ?: 0
                        val soundType = call.argument<String>("soundType") ?: "alarm"
                        result.success(programmerAlarme(id, titre, message, heure, minute, soundType))
                    }
                    "programmerAlarmeTimestamp" -> {
                        val id = call.argument<Int>("id") ?: 0
                        val titre = call.argument<String>("titre") ?: ""
                        val message = call.argument<String>("message") ?: ""
                        val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                        val soundType = call.argument<String>("soundType") ?: "alarm"
                        result.success(programmerAlarmeTimestamp(id, titre, message, triggerAtMillis, soundType))
                    }
                    "annulerAlarme" -> {
                        val id = call.argument<Int>("id") ?: 0
                        result.success(annulerAlarme(id))
                    }
                    "annulerToutesAlarmes" -> result.success(true)
                    "stopActiveAlarm" -> result.success(stopActiveAlarm())
                    "verifierAutorisation" -> result.success(verifierAutorisation())
                    "ouvrirParametresAlarme" -> {
                        ouvrirParametresAlarme()
                        result.success(true)
                    }
                    "demanderIgnorerOptimisationsBatterie" ->
                        result.success(demanderIgnorerOptimisationsBatterie())
                    "ignoreOptimisationsBatterieActive" ->
                        result.success(ignoreOptimisationsBatterieActive())
                    "ouvrirParametresBatterie" ->
                        result.success(ouvrirParametresBatterie())
                    "ouvrirParametresArrierePlan" ->
                        result.success(ouvrirParametresArrierePlan())
                    else -> result.notImplemented()
                }
            }
    }

    private fun programmerAlarme(
        id: Int,
        titre: String,
        message: String,
        heure: Int,
        minute: Int,
        soundType: String,
    ): Boolean {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, heure)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (before(Calendar.getInstance())) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        return programmer(
            id = id,
            titre = titre,
            message = message,
            triggerAtMillis = calendar.timeInMillis,
            soundType = soundType,
            heure = heure,
            minute = minute,
        )
    }

    private fun programmerAlarmeTimestamp(
        id: Int,
        titre: String,
        message: String,
        triggerAtMillis: Long,
        soundType: String,
    ): Boolean {
        return programmer(
            id = id,
            titre = titre,
            message = message,
            triggerAtMillis = triggerAtMillis,
            soundType = soundType,
            heure = -1,
            minute = -1,
        )
    }

    private fun programmer(
        id: Int,
        titre: String,
        message: String,
        triggerAtMillis: Long,
        soundType: String,
        heure: Int,
        minute: Int,
    ): Boolean {
        return try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
                return false
            }

            val intent = Intent(this, AlarmReceiver::class.java).apply {
                putExtra("id", id)
                putExtra("titre", titre)
                putExtra("message", message)
                putExtra("heure", heure)
                putExtra("minute", minute)
                putExtra("soundType", soundType)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                this,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent,
            )
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun annulerAlarme(id: Int): Boolean {
        return try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, AlarmReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                id,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
            )
            pendingIntent?.let {
                alarmManager.cancel(it)
                it.cancel()
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun verifierAutorisation(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    private fun stopActiveAlarm(): Boolean {
        return try {
            AlarmSoundPlayer.stop()
            stopService(Intent(this, AlarmForegroundService::class.java))
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancelAll()
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun ouvrirParametresAlarme() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM))
        }
    }

    private fun demanderIgnorerOptimisationsBatterie(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }
        if (ignoreOptimisationsBatterieActive()) {
            return true
        }

        return lancerPremierIntentDisponible(
            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
            },
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
            appDetailsIntent(),
        )
    }

    private fun ignoreOptimisationsBatterieActive(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    private fun ouvrirParametresBatterie(): Boolean {
        return lancerPremierIntentDisponible(
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
            Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS),
            appDetailsIntent(),
        )
    }

    private fun ouvrirParametresArrierePlan(): Boolean {
        return lancerPremierIntentDisponible(
            appDetailsIntent(),
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
            Intent(Settings.ACTION_MANAGE_APPLICATIONS_SETTINGS),
            Intent(Settings.ACTION_APPLICATION_SETTINGS),
            Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS),
        )
    }

    private fun appDetailsIntent(): Intent {
        return Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
        }
    }

    private fun lancerPremierIntentDisponible(vararg intents: Intent): Boolean {
        intents.forEach { intent ->
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                return true
            }
        }
        return false
    }

    private fun creerCanauxNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            listOf(
                NotificationChannel(
                    "mediremind_rappels",
                    "Rappels médicaments",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "Notifications de prise de médicaments"
                    enableVibration(true)
                    enableLights(true)
                },
                NotificationChannel(
                    "mediremind_stock",
                    "Alertes de stock",
                    NotificationManager.IMPORTANCE_DEFAULT,
                ).apply {
                    description = "Alertes de renouvellement de médicaments"
                },
            ).forEach { nm.createNotificationChannel(it) }
        }
    }
}
