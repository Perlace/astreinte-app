import 'package:flutter/material.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';

const _wgConfig = '''[Interface]
PrivateKey = 2DqS6t2IVLSE4155QG2Gbmnv7uw49F7IPJm2qNl4eko=
Address = 10.0.0.2/24
DNS = 8.8.8.8

[Peer]
PublicKey = +iB4pASiK+m8kQXPMxevKObTesE/Ya4ENpEbTtaALlg=
Endpoint = 51.159.165.27:51820
AllowedIPs = 51.159.165.27/32
PersistentKeepalive = 25
''';

class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> {
  VpnStage _stage = VpnStage.disconnected;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await WireGuardFlutter.instance.initialize(interfaceName: 'wg0');
    WireGuardFlutter.instance.vpnStageSnapshot.listen((stage) {
      if (mounted) setState(() => _stage = stage);
    });
    setState(() => _initializing = false);
  }

  Future<void> _toggle() async {
    if (_stage == VpnStage.connected) {
      await WireGuardFlutter.instance.stopVpn();
    } else {
      await WireGuardFlutter.instance.startVpn(
        serverAddress: '51.159.165.27',
        wgQuickConfig: _wgConfig,
        providerBundleIdentifier: 'com.o2switch.astreinte_app',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = _stage == VpnStage.connected;
    final connecting = _stage == VpnStage.connecting || _stage == VpnStage.authenticating;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: connected
                    ? const Color(0xFF0D2E1A)
                    : const Color(0xFF0F2035),
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
              connected
                  ? 'VPN Connecté'
                  : connecting
                      ? 'Connexion...'
                      : 'VPN Déconnecté',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: connected ? const Color(0xFF2dd4bf) : Colors.white54,
                letterSpacing: 0.5,
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
                  side: BorderSide(
                    color: connected ? Colors.redAccent : const Color(0xFF2dd4bf),
                  ),
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
          ],
        ),
      ),
    );
  }
}
