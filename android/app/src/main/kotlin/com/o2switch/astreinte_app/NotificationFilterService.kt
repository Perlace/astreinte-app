package com.o2switch.astreinte_app

import android.content.SharedPreferences
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class NotificationFilterService : NotificationListenerService() {

    companion object {
        const val PREFS = "astreinte_prefs"
        const val KEY_ACTIVE = "filter_active"
        const val KEY_ALLOWED_APPS = "allowed_apps"
        const val KEY_ALL_APPS = "all_apps_allowed"
    }

    private fun prefs(): SharedPreferences =
        applicationContext.getSharedPreferences(PREFS, MODE_PRIVATE)

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val p = prefs()
        if (!p.getBoolean(KEY_ACTIVE, false)) return
        if (p.getBoolean(KEY_ALL_APPS, true)) return

        val allowedSet = p.getStringSet(KEY_ALLOWED_APPS, emptySet()) ?: emptySet()
        if (allowedSet.isNotEmpty() && !allowedSet.contains(sbn.packageName)) {
            try { cancelNotification(sbn.key) } catch (_: Exception) {}
        }
    }
}
