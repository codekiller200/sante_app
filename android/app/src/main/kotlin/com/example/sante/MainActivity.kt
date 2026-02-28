package com.example.sante

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.AlarmClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.sante/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "programmerAlarme" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val titre = call.argument<String>("titre") ?: "Rappel"
                    val message = call.argument<String>("message") ?: ""
                    val heure = call.argument<Int>("heure") ?: 8
                    val minute = call.argument<Int>("minute") ?: 0
                    
                    val success = programmerAlarme(id, titre, message, heure, minute)
                    result.success(success)
                }
                "annulerAlarme" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val success = annulerAlarme(id)
                    result.success(success)
                }
                "verifierAutorisation" -> {
                    val hasPermission = verifierAutorisation()
                    result.success(hasPermission)
                }
                "ouvrirAppAlarme" -> {
                    ouvrirAppAlarme()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun programmerAlarme(id: Int, titre: String, message: String, heure: Int, minute: Int): Boolean {
        return try {
            // Ouvrir l'app Horloge native avec les paramètres pré-remplis
            val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                putExtra(AlarmClock.EXTRA_HOUR, heure)
                putExtra(AlarmClock.EXTRA_MINUTES, minute)
                putExtra(AlarmClock.EXTRA_MESSAGE, "$titre - $message")
                putExtra(AlarmClock.EXTRA_VIBRATE, true)
            }
            
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else {
                // Fallback: utiliser AlarmManager directement
                programmerAlarmeDirect(id, titre, message, heure, minute)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun programmerAlarmeDirect(id: Int, titre: String, message: String, heure: Int, minute: Int): Boolean {
        return try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(this, AlarmReceiver::class.java).apply {
                putExtra("titre", titre)
                putExtra("message", message)
                putExtra("id", id)
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            val calendar = java.util.Calendar.getInstance().apply {
                set(java.util.Calendar.HOUR_OF_DAY, heure)
                set(java.util.Calendar.MINUTE, minute)
                set(java.util.Calendar.SECOND, 0)
                
                // Si l'heure est passée, mettre à demain
                if (timeInMillis <= System.currentTimeMillis()) {
                    add(java.util.Calendar.DAY_OF_YEAR, 1)
                }
            }
            
            // Répéter quotidiennement
            alarmManager.setRepeating(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                AlarmManager.INTERVAL_DAY,
                pendingIntent
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
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            alarmManager.cancel(pendingIntent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun verifierAutorisation(): Boolean {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    private fun ouvrirAppAlarme() {
        try {
            val intent = Intent(AlarmClock.ACTION_SHOW_ALARMS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}

// BroadcastReceiver pour gérer les alarmes
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val titre = intent.getStringExtra("titre") ?: "Rappel médicament"
        val message = intent.getStringExtra("message") ?: "Il est temps de prendre votre médicament"
        
        // Ici on pourrait déclencher une notification
        // La notification principale sera gérée par flutter_local_notifications
    }
}
