import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VehicleItem {
  final String id;
  final String plate;
  final String model;
  final String color;

  const VehicleItem({
    required this.id,
    required this.plate,
    required this.model,
    this.color = 'White',
  });

  String get displayName => '$plate ($model)';

  factory VehicleItem.fromJson(Map<String, dynamic> json) {
    return VehicleItem(
      id: json['id'] ?? 'veh_${DateTime.now().millisecondsSinceEpoch}',
      plate: json['plate'] ?? 'Code 3 - A24561 AA',
      model: json['model'] ?? 'Toyota Vitz',
      color: json['color'] ?? 'White',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'plate': plate,
    'model': model,
    'color': color,
  };
}

/// Reactive store for driver's registered vehicles.
/// Persisted locally and shared between Profile and Booking Confirmation screens.
class VehicleStore extends ChangeNotifier {
  VehicleStore._();
  static final VehicleStore instance = VehicleStore._();

  static const String _keyVehicles = 'user_vehicles_cache';

  final List<VehicleItem> _vehicles = [
    const VehicleItem(
      id: 'veh_1',
      plate: 'Code 3 - A24561 AA',
      model: 'Toyota Vitz',
      color: 'White',
    ),
    const VehicleItem(
      id: 'veh_2',
      plate: 'Code 3 - B98765 AA',
      model: 'Hyundai Tucson',
      color: 'Silver',
    ),
  ];

  bool _isInitialized = false;

  List<VehicleItem> get vehicles => List.unmodifiable(_vehicles);

  List<String> get vehicleDisplayNames =>
      _vehicles.map((v) => v.displayName).toList();

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_keyVehicles);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        _vehicles.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _vehicles.add(VehicleItem.fromJson(item));
          }
        }
        if (_vehicles.isEmpty) {
          _vehicles.add(
            const VehicleItem(
              id: 'veh_1',
              plate: 'Code 3 - A24561 AA',
              model: 'Toyota Vitz',
              color: 'White',
            ),
          );
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void addVehicle({
    required String plate,
    required String model,
    String color = 'White',
  }) {
    final newItem = VehicleItem(
      id: 'veh_${DateTime.now().millisecondsSinceEpoch}',
      plate: plate.trim(),
      model: model.trim(),
      color: color.trim().isEmpty ? 'White' : color.trim(),
    );
    _vehicles.add(newItem);
    _saveToDisk();
    notifyListeners();
  }

  void removeVehicle(String id) {
    _vehicles.removeWhere((v) => v.id == id);
    _saveToDisk();
    notifyListeners();
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _vehicles.map((v) => v.toJson()).toList();
      await prefs.setString(_keyVehicles, jsonEncode(jsonList));
    } catch (_) {}
  }
}
