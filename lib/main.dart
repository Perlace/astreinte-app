import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'models/schedule.dart';
import 'services/schedule_service.dart';
import 'screens/home_screen.dart';
import 'screens/schedule_form_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ScheduleAdapter());
  await Hive.openBox<Schedule>('schedules');
  await ScheduleService.init();
  runApp(const AstreinteApp());
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/schedule/new', builder: (_, __) => const ScheduleFormScreen()),
    GoRoute(
      path: '/schedule/edit/:id',
      builder: (_, state) => ScheduleFormScreen(scheduleId: state.pathParameters['id']),
    ),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);

class AstreinteApp extends StatelessWidget {
  const AstreinteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AstreinteApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B3D5C),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      routerConfig: _router,
    );
  }
}
