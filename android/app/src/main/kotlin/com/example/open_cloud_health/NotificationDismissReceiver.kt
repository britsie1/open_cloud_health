package com.example.open_cloud_health

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
            val dbFile = context.getDatabasePath("opencloudhealth.db")
            if (dbFile.exists()) {
                var db: SQLiteDatabase? = null
                try {
                    db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
                    val settingsCursor = db.rawQuery("SELECT * FROM lock_screen_settings WHERE isEnabled = 'true' LIMIT 1", null)
                    val isStillEnabled = settingsCursor.moveToFirst()
                    settingsCursor.close()
                    
                    if (isStillEnabled) {
                        NotificationHelper.showNotification(context, title, body)
                    }
                } catch (e: Exception) {
                    Log.e("NotificationDismiss", "Error checking settings: ${e.localizedMessage}")
                } finally {
                    db?.close()
                }
            }
        }
    }
}
