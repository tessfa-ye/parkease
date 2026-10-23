import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Override this if testing on a real physical device with LAN IP e.g. "http://192.168.1.100:5000/api"
  static String? _customBaseUrl;

  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url;
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }

    try {
      if (Platform.isAndroid) {
        // Physical device connected via USB uses ADB reverse port forwarding (adb reverse tcp:5000 tcp:5000).
        // This allows `localhost:5000` on the phone to connect directly to the PC backend!
        // For Wi-Fi debugging without USB, set _customBaseUrl or use LAN IP e.g. "http://172.20.47.19:5000/api".
        return 'http://localhost:5000/api';
      }
    } catch (_) {}

    // Windows / macOS / iOS Simulator default
    return 'http://localhost:5000/api';
  }

  // Endpoints
  static String get authOtpSend => '$baseUrl/auth/otp/send';
  static String get authOtpVerify => '$baseUrl/auth/otp/verify';
  static String get spots => '$baseUrl/spots';
  static String get bookings => '$baseUrl/bookings';
  static String get paymentsInitialize => '$baseUrl/payments/initialize';
  static String get hostsApply => '$baseUrl/hosts/apply';
  static String get hostsDashboard => '$baseUrl/hosts/dashboard';
}
