import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/dnd_service.dart';
import '../services/app_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasPermission = false;
  bool _hasNotifListenerPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final p = await DndService.hasPermission();
    final n = await AppService.hasNotificationListenerPermission();
    if (mounted) setState(() { _hasPermission = p; _hasNotifListenerPermission = n; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3D5C),
        title: const Text('Paramètres', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Android
          if (Platform.isAndroid) ...[
            _SectionHeader('Android — Ne pas déranger'),
            _SettingsTile(
              icon: Icons.do_not_disturb,
              title: 'Permission DND',
              subtitle: _hasPermission ? 'Accordée ✓' : 'Non accordée — requis pour le contrôle auto',
              trailing: _hasPermission
                  ? const Icon(Icons.check_circle, color: Color(0xFF2dd4bf))
                  : ElevatedButton(
                      onPressed: () async {
                        await DndService.requestPermission();
                        await Future.delayed(const Duration(seconds: 1));
                        _checkPermissions();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0d9488)),
                      child: const Text('Autoriser'),
                    ),
            ),
            const SizedBox(height: 16),
            _SettingsTile(
              icon: Icons.notifications_active,
              title: 'Accès aux notifications',
              subtitle: _hasNotifListenerPermission
                  ? 'Accordé ✓ — filtrage par app actif'
                  : 'Non accordé — nécessaire pour filtrer par app',
              trailing: _hasNotifListenerPermission
                  ? const Icon(Icons.check_circle, color: Color(0xFF2dd4bf))
                  : ElevatedButton(
                      onPressed: () async {
                        await AppService.requestNotificationListenerPermission();
                        await Future.delayed(const Duration(seconds: 1));
                        _checkPermissions();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0d9488)),
                      child: const Text('Autoriser'),
                    ),
            ),
            const SizedBox(height: 24),
          ],

          // Section iOS
          if (Platform.isIOS) ...[
            _SectionHeader('iOS — Focus Modes'),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Sur iOS, le contrôle automatique des notifications passe par les "Modes de concentration" (Focus Modes) natifs d\'Apple.\n\nCréez un mode "Astreinte" dans Réglages → Concentration, puis configurez une automatisation dans l\'app Raccourcis pour l\'activer/désactiver selon vos horaires.',
                style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.6),
              ),
            ),
            _SettingsTile(
              icon: Icons.open_in_new,
              title: 'Ouvrir Réglages → Concentration',
              subtitle: 'Configurer les Focus Modes iOS',
              onTap: () => launchUrl(Uri.parse('App-prefs:Focus')),
            ),
            _SettingsTile(
              icon: Icons.shortcut,
              title: 'Ouvrir l\'app Raccourcis',
              subtitle: 'Créer une automatisation horaire',
              onTap: () => launchUrl(Uri.parse('shortcuts://')),
            ),
            const SizedBox(height: 24),
          ],

          // À propos
          _SectionHeader('À propos'),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'AstreinteApp',
            subtitle: 'v1.1.0 — o2switch internal tool',
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(
      color: Color(0xFF2dd4bf), fontSize: 12,
      fontWeight: FontWeight.w700, letterSpacing: 1,
    )),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon, required this.title, required this.subtitle,
    this.trailing, this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF0F2035),
      border: Border.all(color: const Color(0xFF1e3a52)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: ListTile(
      leading: Icon(icon, color: const Color(0xFF2dd4bf)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: trailing,
      onTap: onTap,
    ),
  );
}
