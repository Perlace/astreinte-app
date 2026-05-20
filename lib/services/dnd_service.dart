import 'package:flutter/services.dart';

class DndService {
  static const _channel = MethodChannel('com.o2switch.astreinte/dnd');

  // Modes Android : 0=normal, 1=silence, 2=priority, 3=alarms_only
  static Future<bool> setDndMode(int mode) async {
    try {
      final result = await _channel.invokeMethod('setDndMode', {'mode': mode});
      return result == true;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod('hasPermission');
      return result == true;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } on PlatformException catch (_) {}
  }

  static Future<int> getCurrentMode() async {
    try {
      final result = await _channel.invokeMethod('getCurrentMode');
      return result as int;
    } on PlatformException catch (_) {
      return 0;
    }
  }

  static int modeFromString(String mode) {
    switch (mode) {
      case 'silence': return 1;
      case 'allow_priority': return 2;
      case 'allow_all': return 0;
      default: return 0;
    }
  }

  static String modeLabel(String mode) {
    switch (mode) {
      case 'silence': return 'Silence total';
      case 'allow_priority': return 'Prioritaires uniquement';
      case 'allow_all': return 'Tout autoriser';
      default: return 'Normal';
    }
  }
}
