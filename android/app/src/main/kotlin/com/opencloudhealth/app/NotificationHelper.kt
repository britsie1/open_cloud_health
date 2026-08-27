package com.opencloudhealth.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

object NotificationHelper {
    const val CHANNEL_ID = "medical_emergency_critical_channel"
    const val CHANNEL_NAME = "Critical Medical Info"
    const val NOTIFICATION_ID = 999

    fun showNotification(context: Context, title: String, body: String, dataJson: String = "") {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Displays critical medical info for first responders on the lock screen"
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(channel)
        }

        // Target Activity (Emergency Display)
        val intent = Intent(context, EmergencyActivity::class.java)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(context, NOTIFICATION_ID, intent, flags)

        // Delete intent (Triggered when user dismisses/swipes away the notification)
        val deleteIntent = Intent(context, NotificationDismissReceiver::class.java).apply {
            putExtra("title", title)
            putExtra("body", body)
        }
        val deletePendingIntent = PendingIntent.getBroadcast(
            context,
            NOTIFICATION_ID + 1,
            deleteIntent,
            flags
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setOngoing(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(pendingIntent)
            .setDeleteIntent(deletePendingIntent)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setColor(0xFFB71C1C.toInt())
            .build()

        manager.notify(NOTIFICATION_ID, notification)

        // Cache in Device Protected Storage for Direct Boot (Pre-unlock reboot state)
        try {
            val dpContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                context.createDeviceProtectedStorageContext()
            } else {
                context
            }
            dpContext.getSharedPreferences("emergency_cache", Context.MODE_PRIVATE)
                .edit()
                .putString("title", title)
                .putString("body", body)
                .putString("data_json", dataJson)
                .putBoolean("isEnabled", true)
                .apply()
        } catch (e: Exception) {
            // Ignore storage cache errors
        }
    }

    fun cancelNotification(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(NOTIFICATION_ID)

        try {
            val dpContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                context.createDeviceProtectedStorageContext()
            } else {
                context
            }
            dpContext.getSharedPreferences("emergency_cache", Context.MODE_PRIVATE)
                .edit()
                .putBoolean("isEnabled", false)
                .apply()
        } catch (e: Exception) {
            // Ignore storage cache errors
        }
    }
}
