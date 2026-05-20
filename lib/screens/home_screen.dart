import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import '../services/dnd_service.dart';
import '../widgets/schedule_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Schedule? _activeSchedule;
  int _dndMode = 0;
  late Timer _timer;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final active = ScheduleService.getActiveNow();
    final mode = await DndService.getCurrentMode();
    final perm = await DndService.hasPermission();
    if (mounted) {
      setState(() {
        _activeSchedule = active;
        _dndMode = mode;
        _hasPermission = perm;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedules = ScheduleService.getAll();
    final isOnCall = _activeSchedule != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3D5C),
        title: const Text('🔔 AstreinteApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statut actuel
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isOnCall ? const Color(0xFF0D2E1A) : const Color(0xFF0F2035),
              border: Border.all(color: isOnCall ? const Color(0xFF2dd4bf) : const Color(0xFF1e3a52), width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  isOnCall ? Icons.notifications_active : Icons.notifications_off,
                  size: 48,
                  color: isOnCall ? const Color(0xFF2dd4bf) : Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  isOnCall ? 'ASTREINTE EN COURS' : 'Pas d\'astreinte',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isOnCall ? const Color(0xFF2dd4bf) : Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                if (isOnCall && _activeSchedule != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _activeSchedule!.label,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    _activeSchedule!.timeRange,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                _DndStatusBadge(mode: _dndMode),
              ],
            ),
          ),

          // Alerte permission manquante
          if (!_hasPermission)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2d1515),
                border: Border.all(color: Colors.redAccent),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Permission "Ne pas déranger" manquante',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await DndService.requestPermission();
                      _refresh();
                    },
                    child: const Text('Autoriser'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Liste des plannings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Plannings', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: () => context.push('/schedule/new').then((_) => _refresh()),
                  icon: const Icon(Icons.add, color: Color(0xFF2dd4bf)),
                  label: const Text('Ajouter', style: TextStyle(color: Color(0xFF2dd4bf))),
                ),
              ],
            ),
          ),

          Expanded(
            child: schedules.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 48, color: Colors.white24),
                        SizedBox(height: 12),
                        Text('Aucun planning configuré', style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: schedules.length,
                    itemBuilder: (_, i) => ScheduleCard(
                      schedule: schedules[i],
                      onEdit: () => context.push('/schedule/edit/${schedules[i].id}').then((_) => _refresh()),
                      onDelete: () async {
                        await ScheduleService.delete(schedules[i].id);
                        _refresh();
                      },
                      onToggle: (val) async {
                        schedules[i].active = val;
                        await ScheduleService.save(schedules[i]);
                        _refresh();
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DndStatusBadge extends StatelessWidget {
  final int mode;
  const _DndStatusBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final labels = {0: 'Mode normal', 1: 'Silence total', 2: 'Prioritaires seulement', 3: 'Alarmes seulement'};
    final colors = {0: Colors.grey, 1: Colors.redAccent, 2: const Color(0xFF2dd4bf), 3: Colors.orange};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (colors[mode] ?? Colors.grey).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (colors[mode] ?? Colors.grey).withOpacity(0.5)),
      ),
      child: Text(
        labels[mode] ?? 'Inconnu',
        style: TextStyle(color: colors[mode] ?? Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
