package com.example.sante

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.ComponentActivity

class AlarmActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
        )

        val id = intent.getIntExtra("id", 0)
        val titre = intent.getStringExtra("titre") ?: "MediRemind"
        val message = intent.getStringExtra("message") ?: "Il est temps de prendre votre medicament"

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 64, 48, 64)
            setBackgroundColor(Color.parseColor("#12304A"))
        }

        val titleView = TextView(this).apply {
            text = titre
            textSize = 24f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
        }

        val messageView = TextView(this).apply {
            text = message
            textSize = 16f
            setTextColor(Color.parseColor("#DDEBFF"))
            gravity = Gravity.CENTER
        }

        val stopButton = Button(this).apply {
            text = "Arreter l alarme"
            setOnClickListener {
                stopAlarm(id)
                finish()
            }
        }

        val openButton = Button(this).apply {
            text = "Ouvrir l application"
            setOnClickListener {
                stopAlarm(id)
                packageManager.getLaunchIntentForPackage(packageName)?.let { launchIntent ->
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    startActivity(launchIntent)
                }
                finish()
            }
        }

        layout.addView(titleView)
        layout.addView(messageView)
        layout.addView(stopButton)
        layout.addView(openButton)

        setContentView(layout)
    }

    private fun stopAlarm(id: Int) {
        AlarmSoundPlayer.stop()
        stopService(Intent(this, AlarmForegroundService::class.java))
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(id)
        sendBroadcast(Intent(this, StopAlarmReceiver::class.java).apply {
            putExtra("id", id)
        })
    }
}
