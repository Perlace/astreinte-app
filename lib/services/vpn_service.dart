import 'package:http/http.dart' as http;
import 'dart:convert';

class VpnService {
  static const String baseUrl = 'http://utqd1640.pvc.o2switch.net:5000';

  static Future<Map<String, dynamic>> generateVPN(String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/generate-vpn'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw error['error'] ?? 'Erreur inconnue';
    }
  }

  static Future<Map<String, dynamic>> generateNoIP(String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/generate-noip'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw error['error'] ?? 'Erreur inconnue';
    }
  }

  static Future<String> downloadVPN(String filename) async {
    final response = await http.get(
      Uri.parse('$baseUrl/download/$filename'),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw 'Téléchargement échoué';
    }
  }
}
