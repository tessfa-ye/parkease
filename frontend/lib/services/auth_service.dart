import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();
  AuthService._();

  static const String _keyToken = 'auth_token';
  static const String _keyPhone = 'auth_phone';
  static const String _keyName = 'auth_name';
  static const String _keyRole = 'auth_role';

  String? _token;
  String? _phone;
  String? _name;
  String? _role;

  String? get token => _token;
  String? get phone => _phone;
  String? get name => _name;
  String? get role => _role;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);
    _phone = prefs.getString(_keyPhone);
    _name = prefs.getString(_keyName);
    _role = prefs.getString(_keyRole);
    notifyListeners();
  }

  /// Request OTP for a phone number
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.authOtpSend),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone}),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['data']?['message'] ?? 'OTP sent',
          'debugOtp': data['data']?['debugOtp'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to send OTP',
      };
    } catch (e) {
      // Offline fallback for seamless testing
      return {
        'success': true,
        'message': 'Sandbox Mode: Use OTP 123456',
        'debugOtp': '123456',
      };
    }
  }

  /// Verify OTP and save JWT token
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
    String? name,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.authOtpVerify),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': phone,
              'otp': otp,
              if (name != null && name.isNotEmpty) 'name': name,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']?['token'];
        final user = data['data']?['user'];

        await _saveSession(
          token: token,
          phone: user?['phone'] ?? phone,
          name: user?['name'] ?? name ?? 'ParkEase Driver',
          role: user?['role'] ?? 'USER',
        );

        return {'success': true, 'user': user};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Invalid OTP code',
      };
    } catch (e) {
      // Sandbox fallback if server is unreachable
      if (otp == '123456') {
        await _saveSession(
          token: 'sandbox_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          phone: phone,
          name: name ?? 'ParkEase Driver',
          role: 'USER',
        );
        return {'success': true, 'sandbox': true};
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  Future<void> _saveSession({
    required String token,
    required String phone,
    required String name,
    required String role,
  }) async {
    _token = token;
    _phone = phone;
    _name = name;
    _role = role;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyRole, role);

    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _phone = null;
    _name = null;
    _role = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyName);
    await prefs.remove(_keyRole);

    notifyListeners();
  }
}
