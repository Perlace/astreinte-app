import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/dnd_service.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = schedule.active && schedule.isActiveNow();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2035),
        border: Border.all(
          color: isActive ? const Color(0xFF2dd4bf) : const Color(0xFF1e3a52),
          width: isActive ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isActive ? const Color(0xFF0d9488) : const Color(0xFF162840),
          child: Icon(
            isActive ? Icons.notifications_active : Icons.notifications_none,
            color: isActive ? Colors.white : Colors.white38,
            size: 20,
          ),
        ),
        title: Text(
          schedule.label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(schedule.timeRange, style: const TextStyle(color: Color(0xFF2dd4bf), fontSize: 13)),
            Text(schedule.daysLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            Text(DndService.modeLabel(schedule.mode), style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: schedule.active,
              onChanged: onToggle,
              activeColor: const Color(0xFF2dd4bf),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white38),
              color: const Color(0xFF162840),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF0F2035),
                      title: const Text('Supprimer ?', style: TextStyle(color: Colors.white)),
                      content: Text('Supprimer "${schedule.label}" ?', style: const TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                        TextButton(
                          onPressed: () { Navigator.pop(context); onDelete(); },
                          child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Modifier', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.redAccent))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
