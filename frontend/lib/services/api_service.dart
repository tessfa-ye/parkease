import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/parking_spot.dart';
import 'api_config.dart';
import 'auth_service.dart';

class ApiService {
  static Map<String, String> _getHeaders() {
    final token = AuthService.instance.token;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetches parking spots from the backend API with proximity & filters
  static Future<List<ParkingSpot>> getSpots({
    double? lat,
    double? lng,
    double? radiusKm,
    String? spotType,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();
    if (radiusKm != null) queryParams['radiusKm'] = radiusKm.toString();
    if (spotType != null && spotType != 'all') queryParams['spotType'] = spotType;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse(ApiConfig.spots).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http.get(uri, headers: _getHeaders()).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List).map((json) => ParkingSpot.fromJson(json)).toList();
        }
      }
    } catch (e) {
      // Graceful offline fallback
    }

    // Fallback to sample spots if backend is offline/unreachable
    return _filterFallbackSpots(spotType: spotType, search: search);
  }

  static List<ParkingSpot> _filterFallbackSpots({String? spotType, String? search}) {
    var spots = ParkingSpot.sampleSpots;
    if (spotType != null && spotType != 'all') {
      if (spotType == 'government') {
        spots = spots.where((s) => s.spotType == SpotType.government).toList();
      } else if (spotType == 'commercial') {
        spots = spots.where((s) => s.spotType == SpotType.commercial).toList();
      } else if (spotType == 'private') {
        spots = spots.where((s) => s.spotType == SpotType.privateHost).toList();
      }
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      spots = spots.where((s) => s.title.toLowerCase().contains(q) || s.address.toLowerCase().contains(q)).toList();
    }
    return spots;
  }

  /// Creates a booking on the backend
  static Future<Map<String, dynamic>?> createBooking({
    required String spotId,
    required String vehiclePlate,
    required DateTime startTime,
    required double durationHours,
    required double totalAmount,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.bookings),
            headers: _getHeaders(),
            body: jsonEncode({
              'spotId': spotId,
              'vehiclePlate': vehiclePlate,
              'startTime': startTime.toIso8601String(),
              'durationHours': durationHours,
              'totalAmount': totalAmount,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } catch (_) {}
    return null;
  }
}
