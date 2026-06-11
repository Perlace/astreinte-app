import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/vpn_service.dart';

class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _resultData;
  String? _errorMessage;
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _generate(bool isVPN) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showSnack('Entrez votre code à 6 chiffres', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resultData = null;
    });

    try {
      final result = isVPN
          ? await VpnService.generateVPN(code)
          : await VpnService.generateNoIP(code);
      setState(() {
        _resultData = result;
        _isLoading = false;
      });
      _startCountdown(result['expires_at']);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startCountdown(String expiryTime) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final expiry = DateTime.parse(expiryTime);
      final diff = expiry.difference(DateTime.now());
      setState(() {
        _timeLeft = diff.isNegative ? Duration.zero : diff;
      });
      if (diff.isNegative) {
        timer.cancel();
        setState(() => _resultData = null);
      }
    });
  }

  Future<void> _downloadVPN() async {
    if (_resultData == null) return;
    try {
      final filename = _resultData!['download_url'].split('/').last;
      final content = await VpnService.downloadVPN(filename);
      await Clipboard.setData(ClipboardData(text: content));
      _showSnack('Config VPN copiée dans le presse-papier !');
    } catch (e) {
      _showSnack('Erreur: $e', isError: true);
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('Copié !');
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF2dd4bf),
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF0B3D5C),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF2dd4bf),
            labelColor: const Color(0xFF2dd4bf),
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.vpn_lock), text: 'VPN'),
              Tab(icon: Icon(Icons.cloud), text: 'No-IP'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTab(isVPN: true),
              _buildTab(isVPN: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab({required bool isVPN}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          TextField(
            controller: _codeController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Code sécurité (6 chiffres)',
              labelStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.lock, color: Color(0xFF2dd4bf)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1e3a52)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1e3a52)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2dd4bf)),
              ),
              counterStyle: const TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _generate(isVPN),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B3D5C),
                foregroundColor: const Color(0xFF2dd4bf),
                side: const BorderSide(color: Color(0xFF2dd4bf)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2dd4bf)))
                  : Icon(isVPN ? Icons.download : Icons.cloud_download),
              label: Text(isVPN ? 'Générer le fichier VPN' : 'Générer tunnel No-IP'),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2d1515),
                border: Border.all(color: Colors.redAccent),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent))),
                ],
              ),
            ),
          ],
          if (_resultData != null && ((_resultData!['type'] == 'vpn') == isVPN)) ...[
            const SizedBox(height: 20),
            _buildResult(isVPN: isVPN),
          ],
        ],
      ),
    );
  }

  Widget _buildResult({required bool isVPN}) {
    final color = isVPN ? const Color(0xFF2dd4bf) : Colors.blueAccent;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2035),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: color),
              const SizedBox(width: 10),
              Text(
                isVPN ? 'VPN Généré !' : 'No-IP Activé !',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isVPN) ...[
            _infoRow('IP VPN :', _resultData!['vpn_ip']),
            _infoRow('IP whitelist :', _resultData!['whitelist_ip']),
          ] else ...[
            _infoRow('IP réelle :', _resultData!['real_ip']),
            _infoRow('IP whitelist :', _resultData!['whitelist_ip']),
          ],
          _infoRow(
            'Expire à :',
            DateFormat('HH:mm:ss').format(DateTime.parse(_resultData!['expires_at'])),
          ),
          const SizedBox(height: 8),
          Text(
            'Expire dans : ${_formatDuration(_timeLeft)}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (isVPN) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadVPN,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B3D5C),
                      foregroundColor: const Color(0xFF2dd4bf),
                    ),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Copier config'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copy(
                    isVPN ? _resultData!['vpn_ip'] : _resultData!['real_ip'],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3D5C),
                    foregroundColor: color,
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copier IP'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14),
          ),
        ],
      ),
    );
  }
}
