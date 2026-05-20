import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import '../services/dnd_service.dart';
import '../services/app_service.dart';
import 'app_picker_screen.dart';

class ScheduleFormScreen extends StatefulWidget {
  final String? scheduleId;
  const ScheduleFormScreen({super.key, this.scheduleId});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _labelController = TextEditingController();
  List<int> _selectedDays = [];
  TimeOfDay _startTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 5, minute: 0);
  String _mode = 'allow_priority';
  bool _active = true;
  List<String> _allowedApps = [];

  static const _dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const _modes = ['allow_priority', 'silence', 'allow_all'];

  @override
  void initState() {
    super.initState();
    if (widget.scheduleId != null) {
      final s = ScheduleService.box.get(widget.scheduleId);
      if (s != null) {
        _labelController.text = s.label;
        _selectedDays = List.from(s.days);
        _startTime = TimeOfDay(hour: s.startHour, minute: s.startMinute);
        _endTime = TimeOfDay(hour: s.endHour, minute: s.endMinute);
        _mode = s.mode;
        _active = s.active;
        _allowedApps = List.from(s.allowedApps);
      }
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF2dd4bf)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_labelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donnez un nom au planning')),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins un jour')),
      );
      return;
    }

    final schedule = Schedule(
      id: widget.scheduleId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      label: _labelController.text,
      days: _selectedDays,
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      mode: _mode,
      active: _active,
      allowedApps: _allowedApps,
    );
    await ScheduleService.save(schedule);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.scheduleId != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3D5C),
        title: Text(isEdit ? 'Modifier le planning' : 'Nouveau planning',
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(onPressed: _save, child: const Text('Sauver', style: TextStyle(color: Color(0xFF2dd4bf), fontWeight: FontWeight.bold))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Nom
          _Section(title: 'Nom du planning', child: TextField(
            controller: _labelController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Ex: Astreinte nuit semaine'),
          )),

          const SizedBox(height: 24),

          // Jours
          _Section(
            title: 'Jours actifs',
            child: Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                final selected = _selectedDays.contains(i);
                return FilterChip(
                  label: Text(_dayNames[i]),
                  selected: selected,
                  onSelected: (val) => setState(() {
                    if (val) _selectedDays.add(i);
                    else _selectedDays.remove(i);
                  }),
                  selectedColor: const Color(0xFF0d9488),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.white60),
                  backgroundColor: const Color(0xFF162840),
                  side: BorderSide(color: selected ? const Color(0xFF2dd4bf) : const Color(0xFF1e3a52)),
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          // Horaires
          _Section(
            title: 'Plage horaire',
            child: Row(
              children: [
                Expanded(child: _TimeButton(
                  label: 'Début',
                  time: _startTime,
                  onTap: () => _pickTime(true),
                )),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, color: Colors.white38),
                ),
                Expanded(child: _TimeButton(
                  label: 'Fin',
                  time: _endTime,
                  onTap: () => _pickTime(false),
                )),
              ],
            ),
          ),

          const SizedBox(height: 4),
          const Text(
            '⚠ Si la fin est avant le début, la plage chevauche minuit (ex: 23h → 5h)',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),

          const SizedBox(height: 24),

          // Mode DND
          _Section(
            title: 'Mode de notification',
            child: Column(
              children: _modes.map((m) => RadioListTile<String>(
                value: m,
                groupValue: _mode,
                onChanged: (v) => setState(() => _mode = v!),
                title: Text(DndService.modeLabel(m), style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text(_modeDescription(m), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                activeColor: const Color(0xFF2dd4bf),
                contentPadding: EdgeInsets.zero,
              )).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Apps autorisées (filtrage par app via NotificationListenerService)
          _Section(
            title: 'Apps autorisées',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _allowedApps.isEmpty
                      ? 'Toutes les apps (aucun filtre)'
                      : '${_allowedApps.length} app(s) sélectionnée(s)',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Nécessite la permission "Accès aux notifications"',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<List<String>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppPickerScreen(selectedPackages: _allowedApps),
                      ),
                    );
                    if (result != null) setState(() => _allowedApps = result);
                  },
                  icon: const Icon(Icons.apps, color: Color(0xFF2dd4bf), size: 18),
                  label: const Text('Choisir les apps', style: TextStyle(color: Color(0xFF2dd4bf))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2dd4bf)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                if (_allowedApps.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _allowedApps = []),
                    child: const Text('Tout réinitialiser', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Actif
          _Section(
            title: 'Statut',
            child: SwitchListTile(
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: Text(_active ? 'Activé' : 'Désactivé',
                  style: const TextStyle(color: Colors.white)),
              activeColor: const Color(0xFF2dd4bf),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  String _modeDescription(String mode) {
    switch (mode) {
      case 'silence': return 'Aucune notification ne passe';
      case 'allow_priority': return 'Seuls les contacts/apps prioritaires sonnent';
      case 'allow_all': return 'Toutes les notifs passent normalement';
      default: return '';
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38),
    filled: true,
    fillColor: const Color(0xFF162840),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1e3a52))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1e3a52))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2dd4bf))),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(color: Color(0xFF2dd4bf), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 10),
      child,
    ],
  );
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeButton({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF162840),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1e3a52)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}
