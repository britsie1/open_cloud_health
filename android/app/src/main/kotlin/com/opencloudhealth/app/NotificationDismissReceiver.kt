package com.opencloudhealth.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.util.Log

class NotificationDismissReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("NotificationDismiss", "Notification dismissed. Re-posting if enabled.")
        
        val title = intent.getStringExtra("title") ?: ""
        val body = intent.getStringExtra("body") ?: ""
        
        if (title.isNotEmpty() && body.isNotEmpty()) {
            val dpContext = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                context.createDeviceProtectedStorageContext()
            } else {
                context
            }
            val prefs = dpContext.getSharedPreferences("emergency_cache", Context.MODE_PRIVATE)
            val isEnabledInCache = prefs.getBoolean("isEnabled", true)
            if (isEnabledInCache) {
                NotificationHelper.showNotification(context, title, body)
            }
        }
    }
}
