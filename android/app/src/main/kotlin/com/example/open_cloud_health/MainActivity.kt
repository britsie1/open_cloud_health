package com.example.open_cloud_health

import android.app.KeyguardManager
import android.content.Context
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.example.open_cloud_health/security"

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
    }
}
