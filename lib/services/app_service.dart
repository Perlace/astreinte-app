import 'package:flutter/services.dart';

class InstalledApp {
  final String packageName;
  final String appName;
  final String? iconBase64;

  InstalledApp({required this.packageName, required this.appName, this.iconBase64});
}

class AppService {
  static const _channel = MethodChannel('com.o2switch.astreinte/dnd');

  static Future<List<InstalledApp>> getInstalledApps() async {
    try {
      final List result = await _channel.invokeMethod('getInstalledApps');
      return result.map((a) => InstalledApp(
        packageName: a['package'] as String,
        appName: a['name'] as String,
        iconBase64: a['icon'] as String?,
      )).toList()
        ..sort((a, b) => a.appName.compareTo(b.appName));
    } on PlatformException {
      return [];
    }
  }

  static Future<bool> hasNotificationListenerPermission() async {
    try {
      final result = await _channel.invokeMethod('hasNotificationListenerPermission');
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> requestNotificationListenerPermission() async {
    try {
      await _channel.invokeMethod('requestNotificationListenerPermission');
    } on PlatformException catch (_) {}
  }

  static Future<void> updateAllowedApps(List<String> packages) async {
    try {
      await _channel.invokeMethod('updateAllowedApps', {'packages': packages});
    } on PlatformException catch (_) {}
  }

  static Future<void> setNotificationFilterActive(bool active) async {
    try {
      await _channel.invokeMethod('setNotificationFilterActive', {'active': active});
    } on PlatformException catch (_) {}
  }
}
