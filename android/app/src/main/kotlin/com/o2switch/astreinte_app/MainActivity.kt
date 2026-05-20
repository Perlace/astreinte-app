package com.o2switch.astreinte_app

import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.provider.Settings
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val channel = "com.o2switch.astreinte/dnd"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            when (call.method) {
                "hasPermission" -> result.success(nm.isNotificationPolicyAccessGranted)

                "requestPermission" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
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

                "getInstalledApps" -> {
                    try {
                        val pm = packageManager
                        val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
                            .filter { pm.getLaunchIntentForPackage(it.packageName) != null }
                            .map { appInfo ->
                                val name = pm.getApplicationLabel(appInfo).toString()
                                val icon = try {
                                    drawableToBase64(pm.getApplicationIcon(appInfo.packageName))
                                } catch (_: Exception) { null }
                                mapOf("package" to appInfo.packageName, "name" to name, "icon" to icon)
                            }
                        result.success(apps)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "hasNotificationListenerPermission" -> {
                    val enabled = Settings.Secure.getString(
                        contentResolver,
                        "enabled_notification_listeners"
                    ) ?: ""
                    val component = ComponentName(this, NotificationFilterService::class.java).flattenToString()
                    result.success(enabled.contains(component))
                }

                "requestNotificationListenerPermission" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }

                "updateAllowedApps" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    val prefs = getSharedPreferences(NotificationFilterService.PREFS, Context.MODE_PRIVATE)
                    prefs.edit()
                        .putStringSet(NotificationFilterService.KEY_ALLOWED_APPS, packages.toSet())
                        .putBoolean(NotificationFilterService.KEY_ALL_APPS, packages.isEmpty())
                        .apply()
                    result.success(true)
                }

                "setNotificationFilterActive" -> {
                    val active = call.argument<Boolean>("active") ?: false
                    val prefs = getSharedPreferences(NotificationFilterService.PREFS, Context.MODE_PRIVATE)
                    prefs.edit().putBoolean(NotificationFilterService.KEY_ACTIVE, active).apply()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun drawableToBase64(drawable: Drawable): String {
        val bitmap = if (drawable is BitmapDrawable) {
            drawable.bitmap
        } else {
            val bmp = Bitmap.createBitmap(drawable.intrinsicWidth.coerceAtLeast(1), drawable.intrinsicHeight.coerceAtLeast(1), Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bmp
        }
        val scaled = Bitmap.createScaledBitmap(bitmap, 96, 96, true)
        val out = ByteArrayOutputStream()
        scaled.compress(Bitmap.CompressFormat.PNG, 85, out)
        return Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
    }
}
