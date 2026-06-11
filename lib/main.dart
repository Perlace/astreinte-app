import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'models/schedule.dart';
import 'services/schedule_service.dart';
import 'screens/home_screen.dart';
import 'screens/schedule_form_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/vpn_screen.dart';

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
    GoRoute(path: '/', builder: (_, __) => const MainShell(tab: 0)),
    GoRoute(path: '/vpn', builder: (_, __) => const MainShell(tab: 1)),
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

class MainShell extends StatefulWidget {
  final int tab;
  const MainShell({super.key, required this.tab});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.tab;
  }

  final _screens = const [HomeScreen(), VpnScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3D5C),
        title: Text(
          _currentIndex == 0 ? '🔔 AstreinteApp' : '🔐 Accès VPN',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              onPressed: () => context.push('/settings'),
            ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0B3D5C),
        indicatorColor: const Color(0xFF2dd4bf).withOpacity(0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.notifications_active, color: Color(0xFF2dd4bf)),
            label: 'Astreinte',
          ),
          NavigationDestination(
            icon: Icon(Icons.vpn_lock_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.vpn_lock, color: Color(0xFF2dd4bf)),
            label: 'VPN',
          ),
        ],
      ),
    );
  }
}
