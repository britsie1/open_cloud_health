package com.opencloudhealth.app

import android.app.KeyguardManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.opencloudhealth.app/security"
    private val NOTIFICATION_CHANNEL = "com.opencloudhealth.app/emergency_notification"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isDeviceSecure") {
                val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                result.success(keyguardManager.isKeyguardSecure)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "showNotification") {
                val title = call.argument<String>("title") ?: ""
                val body = call.argument<String>("body") ?: ""
                NotificationHelper.showNotification(this, title, body)
                result.success(null)
            } else if (call.method == "cancelNotification") {
                NotificationHelper.cancelNotification(this)
                result.success(null)
            } else if (call.method == "isChannelEnabled") {
                result.success(isEmergencyChannelEnabled())
            } else if (call.method == "openNotificationSettings") {
                openNotificationSettings()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isEmergencyChannelEnabled(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = manager.getNotificationChannel(NotificationHelper.CHANNEL_ID)
            if (channel != null) {
                return channel.importance != NotificationManager.IMPORTANCE_NONE && manager.areNotificationsEnabled()
            }
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager?
        return manager != null && manager.areNotificationsEnabled()
    }

    private fun openNotificationSettings() {
        val intent = Intent().apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                if (!manager.areNotificationsEnabled()) {
                    action = android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS
                    putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, packageName)
                } else {
                    action = android.provider.Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS
                    putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, packageName)
                    putExtra(android.provider.Settings.EXTRA_CHANNEL_ID, NotificationHelper.CHANNEL_ID)
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                action = "android.settings.APP_NOTIFICATION_SETTINGS"
                putExtra("app_package", packageName)
                putExtra("app_uid", applicationInfo.uid)
            } else {
                action = android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                data = Uri.parse("package:$packageName")
            }
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }
}

