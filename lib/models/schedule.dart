import 'package:hive/hive.dart';

part 'schedule.g.dart';

@HiveType(typeId: 0)
class Schedule extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String label; // ex: "Astreinte semaine"

  @HiveField(2)
  List<int> days; // 0=lundi ... 6=dimanche

  @HiveField(3)
  int startHour;

  @HiveField(4)
  int startMinute;

  @HiveField(5)
  int endHour;

  @HiveField(6)
  int endMinute;

  @HiveField(7)
  bool active;

  @HiveField(8)
  String mode; // 'silence' | 'allow_priority' | 'allow_all'

  Schedule({
    required this.id,
    required this.label,
    required this.days,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.active = true,
    this.mode = 'allow_priority',
  });

  bool isActiveNow() {
    final now = DateTime.now();
    final weekday = now.weekday - 1; // 0=lundi
    if (!days.contains(weekday)) return false;

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    if (endMinutes < startMinutes) {
      // Plage qui chevauche minuit (ex: 23h → 5h)
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }

  String get timeRange {
    final start = '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
    final end = '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
    return '$start → $end';
  }

  String get daysLabel {
    const names = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days.map((d) => names[d]).join(', ');
  }
}
