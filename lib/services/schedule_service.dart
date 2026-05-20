import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import '../models/schedule.dart';
import 'dnd_service.dart';

const taskName = 'checkSchedule';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Hive.initFlutter();
    Hive.registerAdapter(ScheduleAdapter());
    final box = await Hive.openBox<Schedule>('schedules');

    final activeSchedules = box.values.where((s) => s.active && s.isActiveNow()).toList();

    if (activeSchedules.isNotEmpty) {
      final mode = DndService.modeFromString(activeSchedules.first.mode);
      await DndService.setDndMode(mode);
    } else {
      await DndService.setDndMode(0); // Retour mode normal
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
