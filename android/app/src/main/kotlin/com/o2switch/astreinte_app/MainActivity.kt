package com.o2switch.astreinte_app

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.o2switch.astreinte/dnd"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            when (call.method) {
                "hasPermission" -> result.success(nm.isNotificationPolicyAccessGranted)

                "requestPermission" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }

                "setDndMode" -> {
                    if (!nm.isNotificationPolicyAccessGranted) {
                        result.error("PERMISSION_DENIED", "DND permission not granted", null)
                        return@setMethodCallHandler
                    }
                    when (call.argument<Int>("mode")) {
                        0 -> nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                        1 -> nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
                        2 -> nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                        3 -> nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALARMS)
                    }
                    result.success(true)
                }

                "getCurrentMode" -> {
                    val mode = when (nm.currentInterruptionFilter) {
                        NotificationManager.INTERRUPTION_FILTER_NONE -> 1
                        NotificationManager.INTERRUPTION_FILTER_PRIORITY -> 2
                        NotificationManager.INTERRUPTION_FILTER_ALARMS -> 3
                        else -> 0
                    }
                    result.success(mode)
                }

                else -> result.notImplemented()
            }
        }
    }
}
