import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import '../models/schedule.dart';
import 'dnd_service.dart';
import 'app_service.dart';

const taskName = 'checkSchedule';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Hive.initFlutter();
    Hive.registerAdapter(ScheduleAdapter());
    final box = await Hive.openBox<Schedule>('schedules');

    final activeSchedules = box.values.where((s) => s.active && s.isActiveNow()).toList();

    if (activeSchedules.isNotEmpty) {
      final schedule = activeSchedules.first;
      final mode = DndService.modeFromString(schedule.mode);
      await DndService.setDndMode(mode);
      await AppService.updateAllowedApps(schedule.allowedApps);
      await AppService.setNotificationFilterActive(true);
    } else {
      await DndService.setDndMode(0);
      await AppService.setNotificationFilterActive(false);
    }

    return Future.value(true);
  });
}

class ScheduleService {
  static Future<void> init() async {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    // Vérifie toutes les 15 minutes
    Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }

  static Box<Schedule> get box => Hive.box<Schedule>('schedules');

  static List<Schedule> getAll() => box.values.toList();

  static Future<void> save(Schedule schedule) async {
    await box.put(schedule.id, schedule);
  }

  static Future<void> delete(String id) async {
    await box.delete(id);
  }

  static Schedule? getActiveNow() {
    try {
      return box.values.firstWhere((s) => s.active && s.isActiveNow());
    } catch (_) {
      return null;
    }
  }
}
