import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import '../config/vpn_config.dart';


class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> {
  bool _unlocked = false;
  final _codeController = TextEditingController();
  bool _codeError = false;

  VpnStage _stage = VpnStage.disconnected;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initWg();
  }

  Future<void> _initWg() async {
    await WireGuardFlutter.instance.initialize(interfaceName: 'wg0');
    WireGuardFlutter.instance.vpnStageSnapshot.listen((stage) {
      if (mounted) setState(() => _stage = stage);
    });
    setState(() => _initializing = false);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _checkCode() {
    if (_codeController.text.trim() == vpnAccessCode) {
      setState(() {
        _unlocked = true;
        _codeError = false;
      });
    } else {
      setState(() => _codeError = true);
      _codeController.clear();
    }
  }

  Future<void> _toggle() async {
    if (_stage == VpnStage.connected) {
      await WireGuardFlutter.instance.stopVpn();
    } else {
      await WireGuardFlutter.instance.startVpn(
        serverAddress: '51.159.165.27',
        wgQuickConfig: wgConfigAndroid,
        providerBundleIdentifier: 'com.o2switch.astreinte_app',
      );
    }
  }

  Future<void> _exportConfig(String config, String filename, String subject) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(config);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/plain')],
      subject: subject,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) return _buildLock();
    return _buildVpn();
  }

  Widget _buildLock() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Color(0xFF2dd4bf)),
            const SizedBox(height: 24),
            const Text(
              'Accès VPN',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Entrez le code pour continuer',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              obscureText: true,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, letterSpacing: 4, fontSize: 20),
              textAlign: TextAlign.center,
              onSubmitted: (_) => _checkCode(),
              decoration: InputDecoration(
                errorText: _codeError ? 'Code incorrect' : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1e3a52)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2dd4bf)),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
                filled: true,
                fillColor: const Color(0xFF0F2035),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _checkCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B3D5C),
                  foregroundColor: const Color(0xFF2dd4bf),
                  side: const BorderSide(color: Color(0xFF2dd4bf)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Accéder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVpn() {
    final connected = _stage == VpnStage.connected;
    final connecting = _stage == VpnStage.connecting || _stage == VpnStage.authenticating;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? const Color(0xFF0D2E1A) : const Color(0xFF0F2035),
              border: Border.all(
                color: connected ? const Color(0xFF2dd4bf) : const Color(0xFF1e3a52),
                width: 2.5,
              ),
              boxShadow: connected
                  ? [BoxShadow(color: const Color(0xFF2dd4bf).withOpacity(0.3), blurRadius: 30, spreadRadius: 5)]
                  : [],
            ),
            child: Icon(
              Icons.vpn_lock,
              size: 64,
              color: connected ? const Color(0xFF2dd4bf) : Colors.white24,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            connected ? 'VPN Connecté' : connecting ? 'Connexion...' : 'VPN Déconnecté',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: connected ? const Color(0xFF2dd4bf) : Colors.white54,
            ),
          ),
          if (connected) ...[
            const SizedBox(height: 8),
            const Text(
              'IP sortante : 51.159.165.27',
              style: TextStyle(color: Colors.white38, fontSize: 13, fontFamily: 'monospace'),
            ),
          ],
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_initializing || connecting) ? null : _toggle,
              style: ElevatedButton.styleFrom(
                backgroundColor: connected ? const Color(0xFF2d1515) : const Color(0xFF0B3D5C),
                foregroundColor: connected ? Colors.redAccent : const Color(0xFF2dd4bf),
                side: BorderSide(color: connected ? Colors.redAccent : const Color(0xFF2dd4bf)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: connecting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2dd4bf)),
                    )
                  : Text(
                      connected ? 'Déconnecter' : 'Connecter',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 40),
          const Divider(color: Color(0xFF1e3a52)),
          const SizedBox(height: 24),
          Row(
            children: const [
              Icon(Icons.computer, color: Colors.white38, size: 18),
              SizedBox(width: 8),
              Text('Accès depuis Windows', style: TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _exportConfig(wgConfigWindows, 'llm-mcflex-windows.conf', 'Config WireGuard Windows'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Color(0xFF1e3a52)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.computer, size: 20),
              label: const Text('Exporter config Windows (.conf)'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _exportConfig(wgConfigLinux, 'llm-mcflex-linux.conf', 'Config WireGuard Linux'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Color(0xFF1e3a52)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.terminal, size: 20),
              label: const Text('Exporter config Linux (.conf)'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Importer dans WireGuard pour accéder à llm.mcflex.fr',
            style: TextStyle(color: Colors.white24, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
