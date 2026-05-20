import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/app_service.dart';

class AppPickerScreen extends StatefulWidget {
  final List<String> selectedPackages;
  const AppPickerScreen({super.key, required this.selectedPackages});

  @override
  State<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends State<AppPickerScreen> {
  List<InstalledApp> _apps = [];
  List<InstalledApp> _filtered = [];
  late Set<String> _selected;
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedPackages);
    _load();
  }

  Future<void> _load() async {
    final apps = await AppService.getInstalledApps();
    if (mounted) {
      setState(() {
        _apps = apps;
        _filtered = apps;
        _loading = false;
      });
    }
  }

  void _filter(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _apps
          : _apps.where((a) => a.appName.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3D5C),
        title: const Text('Apps autorisées', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selected.toList()),
            child: const Text('OK', style: TextStyle(color: Color(0xFF2dd4bf), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0d2e1a),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF2dd4bf), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selected.isEmpty
                        ? 'Toutes les apps sont autorisées (aucune sélection)'
                        : '${_selected.length} app(s) autorisée(s) — les autres seront silencieuses',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Recherche
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: _filter,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher une app...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white38),
                        onPressed: () { _search.clear(); _filter(''); },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF162840),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Boutons tout/rien
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () => setState(() => _selected = _apps.map((a) => a.packageName).toSet()),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1e3a52))),
                  child: const Text('Tout cocher', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => setState(() => _selected.clear()),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1e3a52))),
                  child: const Text('Tout décocher', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Liste
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2dd4bf)))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final app = _filtered[i];
                      final selected = _selected.contains(app.packageName);
                      return ListTile(
                        leading: app.iconBase64 != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(base64Decode(app.iconBase64!), width: 40, height: 40, fit: BoxFit.cover),
                              )
                            : Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: const Color(0xFF162840), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.android, color: Colors.white38),
                              ),
                        title: Text(app.appName, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(app.packageName, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        trailing: Checkbox(
                          value: selected,
                          onChanged: (v) => setState(() {
                            if (v == true) _selected.add(app.packageName);
                            else _selected.remove(app.packageName);
                          }),
                          activeColor: const Color(0xFF2dd4bf),
                          checkColor: Colors.black,
                          side: const BorderSide(color: Colors.white38),
                        ),
                        onTap: () => setState(() {
                          if (selected) _selected.remove(app.packageName);
                          else _selected.add(app.packageName);
                        }),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
