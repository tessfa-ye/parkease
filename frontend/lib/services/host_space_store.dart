import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parking_spot.dart';
import 'auth_service.dart';

/// Persistent and reactive store for host-listed parking spaces.
/// Persists spaces to local device storage across Hot Restarts and app restarts,
/// and exposes them live to both the Host Dashboard and the Explore Spots map.
class HostSpaceStore extends ChangeNotifier {
  HostSpaceStore._();
  static final HostSpaceStore instance = HostSpaceStore._();

  static const String _keySpaces = 'user_host_spaces_cache_v2';

  static const Map<String, dynamic> _defaultSpace = {
    'id': 'host_spot_1',
    'title': 'Home Driveway & Garage',
    'address': 'Bole Sub-City, Wereda 03, Addis Ababa',
    'city': 'Addis Ababa',
    'spaceType': 'Driveway',
    'capacity': 2,
    'pricePerHour': 30.0,
    'isAvailable': true,
    'occupied': 1,
    'latitude': 9.0150,
    'longitude': 38.7640,
    'imageUrl': 'https://images.unsplash.com/photo-1572120360610-d971b9d7767c?w=600',
    'hostName': 'Abebe K.',
  };

  final List<Map<String, dynamic>> _spaces = [
    Map<String, dynamic>.from(_defaultSpace),
  ];

  bool _isInitialized = false;

  List<Map<String, dynamic>> get spaces => List.unmodifiable(_spaces);

  /// Load and restore stored spaces from SharedPreferences
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_keySpaces);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        _spaces.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _spaces.add(Map<String, dynamic>.from(item));
          }
        }
        if (_spaces.isEmpty) {
          _spaces.add(Map<String, dynamic>.from(_defaultSpace));
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Add a newly submitted space to the store and persist immediately
  void addSpace({
    required String spaceType,
    required int capacity,
    String? dimensions,
    required double pricePerHour,
    String? address,
    List<String>? availableDays,
    String? payoutMethod,
    String? payoutAccount,
    double? latitude,
    double? longitude,
  }) {
    final id = 'host_spot_${DateTime.now().millisecondsSinceEpoch}';
    final count = _spaces.length;

    // Distribute coordinates across central Addis Ababa (Bole, Kazanchis, Piassa)
    final lat = latitude ?? (9.0150 + (count * 0.007) * (count.isOdd ? 1 : -1));
    final lng = longitude ?? (38.7640 + (count * 0.006) * (count % 2 == 0 ? 1 : -1));

    String imageUrl;
    switch (spaceType.toLowerCase()) {
      case 'garage':
        imageUrl = 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=600';
        break;
      case 'covered lot':
        imageUrl = 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=600';
        break;
      case 'open lot':
        imageUrl = 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=600';
        break;
      case 'underground':
        imageUrl = 'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=600';
        break;
      default:
        imageUrl = 'https://images.unsplash.com/photo-1572120360610-d971b9d7767c?w=600';
    }

    _spaces.insert(0, {
      'id': id,
      'title': '$spaceType Parking Space',
      'address': address ?? 'Bole, Addis Ababa',
      'city': 'Addis Ababa',
      'spaceType': spaceType,
      'capacity': capacity,
      'dimensions': dimensions,
      'pricePerHour': pricePerHour,
      'isAvailable': true,
      'occupied': 0,
      'availableDays': availableDays,
      'payoutMethod': payoutMethod,
      'payoutAccount': payoutAccount,
      'latitude': lat,
      'longitude': lng,
      'imageUrl': imageUrl,
      'hostName': AuthService.instance.name ?? 'Abebe K.',
    });

    _saveToDisk();
    notifyListeners();
  }

  /// Remove a space by ID
  void removeSpace(String id) {
    _spaces.removeWhere((s) => s['id'] == id);
    if (_spaces.isEmpty) {
      _spaces.add(Map<String, dynamic>.from(_defaultSpace));
    }
    _saveToDisk();
    notifyListeners();
  }

  /// Converts host-managed spaces to explore-compatible ParkingSpot objects
  List<ParkingSpot> toParkingSpots() {
    final spots = <ParkingSpot>[];
    for (int i = 0; i < _spaces.length; i++) {
      final s = _spaces[i];
      final isAvail = s['isAvailable'] as bool? ?? true;
      final capacity = (s['capacity'] as num?)?.toInt() ?? 1;
      final occupied = (s['occupied'] as num?)?.toInt() ?? 0;
      final availableSpots = isAvail ? (capacity - occupied).clamp(0, capacity) : 0;
      final price = (s['pricePerHour'] as num?)?.toDouble() ?? 30.0;
      final lat = (s['latitude'] as num?)?.toDouble() ?? 9.0150;
      final lng = (s['longitude'] as num?)?.toDouble() ?? 38.7640;

      spots.add(
        ParkingSpot(
          id: s['id'] ?? 'host_spot_$i',
          title: s['title'] ?? '${s['spaceType']} Parking Space',
          address: s['address'] ?? 'Addis Ababa',
          city: s['city'] ?? 'Addis Ababa',
          countryCode: 'ET',
          latitude: lat,
          longitude: lng,
          pricePerHour: price,
          distanceKm: 0.3 + (i * 0.2),
          totalSpots: capacity,
          availableSpots: availableSpots,
          rating: 5.0,
          reviewCount: 0,
          spotType: SpotType.privateHost,
          status: !isAvail || availableSpots == 0
              ? SpotStatus.full
              : (availableSpots <= 1 ? SpotStatus.fillingFast : SpotStatus.available),
          amenities: const ['Gated', 'Covered', 'Host On-site', 'Telebirr Pay'],
          imageUrl: s['imageUrl'] ?? 'https://images.unsplash.com/photo-1572120360610-d971b9d7767c?w=600',
          hostName: s['hostName'] ?? AuthService.instance.name ?? 'Abebe K.',
          hostPhotoUrl: 'https://i.pravatar.cc/100?img=12',
          hostRating: 5.0,
        ),
      );
    }
    return spots;
  }

  /// Merge API-returned spots into the local store (avoids duplicates by id)
  void mergeFromApi(List<dynamic> apiSpots) {
    bool added = false;
    for (final spot in apiSpots) {
      if (spot is Map<String, dynamic>) {
        final id = spot['id'];
        if (id != null && !_spaces.any((s) => s['id'] == id)) {
          _spaces.add({
            'id': id,
            'title': spot['title'] ?? '${spot['spaceType'] ?? 'Parking'} Space',
            'address': spot['address'] ?? 'Addis Ababa',
            'city': spot['city'] ?? 'Addis Ababa',
            'spaceType': spot['spaceType'] ?? 'Open Lot',
            'capacity': spot['capacity'] ?? 1,
            'pricePerHour': (spot['pricePerHour'] as num?)?.toDouble() ?? 25.0,
            'isAvailable': spot['isAvailable'] ?? (spot['status'] == 'AVAILABLE'),
            'occupied': spot['occupied'] ?? 0,
            'latitude': (spot['latitude'] as num?)?.toDouble() ?? 9.0150,
            'longitude': (spot['longitude'] as num?)?.toDouble() ?? 38.7640,
            'imageUrl': spot['imageUrl'] ?? 'https://images.unsplash.com/photo-1572120360610-d971b9d7767c?w=600',
            'hostName': spot['hostName'] ?? AuthService.instance.name ?? 'Abebe K.',
          });
          added = true;
        }
      }
    }
    if (added) {
      _saveToDisk();
      notifyListeners();
    }
  }

  /// Toggle a space's availability by index
  void toggleAvailability(int index, bool isAvailable) {
    if (index >= 0 && index < _spaces.length) {
      _spaces[index]['isAvailable'] = isAvailable;
      _saveToDisk();
      notifyListeners();
    }
  }

  /// Record an incoming booking on a host space, incrementing occupied count
  void recordBooking(String spotId) {
    final index = _spaces.indexWhere((s) => s['id'] == spotId);
    if (index != -1) {
      final cap = (_spaces[index]['capacity'] as num?)?.toInt() ?? 1;
      final occ = (_spaces[index]['occupied'] as num?)?.toInt() ?? 0;
      if (occ < cap) {
        _spaces[index]['occupied'] = occ + 1;
      }
      _saveToDisk();
      notifyListeners();
    }
  }

  /// Release a booking on a host space, decrementing occupied count
  void releaseBooking(String spotId) {
    final index = _spaces.indexWhere((s) => s['id'] == spotId);
    if (index != -1) {
      final occ = (_spaces[index]['occupied'] as num?)?.toInt() ?? 0;
      if (occ > 0) {
        _spaces[index]['occupied'] = occ - 1;
      }
      _saveToDisk();
      notifyListeners();
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySpaces, jsonEncode(_spaces));
    } catch (_) {}
  }
}
