import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static String _defaultIP() {
    try {
      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        return "127.0.0.1"; 
      }
    } catch (_) {}
    return "192.168.18.17"; 
  }

  static String apiIP = _defaultIP();

  static Future<void> loadPersistedIP() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIP = prefs.getString('backend_ip');
      if (savedIP != null && savedIP.trim().isNotEmpty) {
        apiIP = savedIP.trim();
      }
    } catch (_) {}
  }

  static Future<void> saveIP(String newIP) async {
    apiIP = newIP.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backend_ip', apiIP);
    } catch (_) {}
  }

  static String get baseUrl {
    final ip = apiIP.trim();
    if (ip.startsWith('http://') || ip.startsWith('https://')) {
      var base = ip;
      if (base.endsWith('/analyze')) {
        base = base.substring(0, base.length - 8);
      } else if (base.endsWith('/analyze/')) {
        base = base.substring(0, base.length - 9);
      }
      if (base.endsWith('/')) {
        base = base.substring(0, base.length - 1);
      }
      return base;
    }
    return "http://$ip:5000";
  }

  static String get apiUrl {
    return "$baseUrl/analyze";
  }
}
