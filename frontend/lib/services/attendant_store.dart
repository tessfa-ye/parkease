import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendantStaff {
  final String id;
  final String name;
  final String phone;
  final String gate;
  final String pin;
  final int scansToday;
  final bool isActive;
  final DateTime createdAt;

  const AttendantStaff({
    required this.id,
    required this.name,
    required this.phone,
    required this.gate,
    required this.pin,
    this.scansToday = 0,
    this.isActive = true,
    required this.createdAt,
  });

  AttendantStaff copyWith({
    String? name,
    String? phone,
    String? gate,
    String? pin,
    int? scansToday,
    bool? isActive,
  }) {
    return AttendantStaff(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      gate: gate ?? this.gate,
      pin: pin ?? this.pin,
      scansToday: scansToday ?? this.scansToday,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'gate': gate,
        'pin': pin,
        'scansToday': scansToday,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AttendantStaff.fromJson(Map<String, dynamic> json) {
    return AttendantStaff(
      id: json['id'] ?? 'att_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] ?? 'Gate Attendant',
      phone: json['phone'] ?? '+251 90 000 0000',
      gate: json['gate'] ?? 'Gate 1',
      pin: json['pin'] ?? '1234',
      scansToday: (json['scansToday'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AttendantStore extends ChangeNotifier {
  static final AttendantStore instance = AttendantStore._();
  AttendantStore._();

  static const String _keyStaff = 'attendant_staff_cache';

  final List<AttendantStaff> _staff = [
    AttendantStaff(
      id: 'att_1',
      name: 'Dawit Girma',
      phone: '+251 92 345 6789',
      gate: 'Main Entry Gate 1',
      pin: '1234',
      scansToday: 8,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    AttendantStaff(
      id: 'att_2',
      name: 'Selamawit Tadesse',
      phone: '+251 91 876 5432',
      gate: 'Rear Exit Gate 2',
      pin: '5678',
      scansToday: 5,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  bool _isInitialized = false;

  List<AttendantStaff> get staff => List.unmodifiable(_staff);
  List<AttendantStaff> get activeStaff => _staff.where((s) => s.isActive).toList();

  int get totalStaffScansToday =>
      _staff.fold(0, (sum, s) => sum + s.scansToday);

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_keyStaff);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        _staff.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _staff.add(AttendantStaff.fromJson(item));
          }
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Check if the PIN matches any active attendant OR the master owner PIN (9999)
  bool validatePin(String enteredPin) {
    if (enteredPin == '9999') return true; // Owner master PIN always unlocks!
    return _staff.any((s) => s.isActive && s.pin == enteredPin);
  }

  /// Get the attendant who matches the PIN, if any
  AttendantStaff? getAttendantByPin(String pin) {
    try {
      return _staff.firstWhere((s) => s.isActive && s.pin == pin);
    } catch (_) {
      return null;
    }
  }

  /// Add a new attendant with custom PIN created by the owner
  void addAttendant({
    required String name,
    required String phone,
    required String gate,
    required String pin,
  }) {
    final newStaff = AttendantStaff(
      id: 'att_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      gate: gate,
      pin: pin,
      scansToday: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );
    _staff.insert(0, newStaff);
    _saveToDisk();
    notifyListeners();
  }

  /// Change/reset an attendant's passcode
  void updatePin(String staffId, String newPin) {
    final idx = _staff.indexWhere((s) => s.id == staffId);
    if (idx >= 0) {
      _staff[idx] = _staff[idx].copyWith(pin: newPin);
      _saveToDisk();
      notifyListeners();
    }
  }

  /// Increment scan count when an attendant verifies a car pass
  void recordScan(String staffId) {
    final idx = _staff.indexWhere((s) => s.id == staffId);
    if (idx >= 0) {
      _staff[idx] = _staff[idx].copyWith(scansToday: _staff[idx].scansToday + 1);
      _saveToDisk();
      notifyListeners();
    }
  }

  /// Toggle active status
  void toggleActive(String staffId) {
    final idx = _staff.indexWhere((s) => s.id == staffId);
    if (idx >= 0) {
      _staff[idx] = _staff[idx].copyWith(isActive: !_staff[idx].isActive);
      _saveToDisk();
      notifyListeners();
    }
  }

  /// Remove an attendant
  void removeAttendant(String staffId) {
    _staff.removeWhere((s) => s.id == staffId);
    _saveToDisk();
    notifyListeners();
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _staff.map((s) => s.toJson()).toList();
      await prefs.setString(_keyStaff, jsonEncode(jsonList));
    } catch (_) {}
  }
}

