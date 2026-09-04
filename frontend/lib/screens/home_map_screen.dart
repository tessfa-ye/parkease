import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/parking_spot.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import 'spot_details_screen.dart';

class HomeMapScreen extends StatefulWidget {
  final Function(ParkingSpot)? onSpotSelected;
  const HomeMapScreen({super.key, this.onSpotSelected});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final List<ParkingSpot> _spots = ParkingSpot.sampleSpots;
  final Set<Marker> _markers = {};
  ParkingSpot? _selectedSpot;
  String _activeFilterKey = 'all';
  bool _isLocating = false;

  // Default: Addis Ababa center (used until GPS loads)
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(9.0227, 38.7469),
    zoom: 14.5,
  );

  List<Map<String, String>> get _filterOptions => [
    {'key': 'all', 'label': AppStrings.all},
    {'key': 'commercial', 'label': AppStrings.commercial},
    {'key': 'government', 'label': AppStrings.government},
    {'key': 'private', 'label': AppStrings.privateHost},
    {'key': 'covered', 'label': AppStrings.covered},
    {'key': 'ev', 'label': AppStrings.ev},
  ];

  @override
  void initState() {
    super.initState();
    _buildMarkers();
    _goToCurrentLocation();
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15.0,
        ),
      );
    } catch (_) {
      // Keep default Addis Ababa view if location fails
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _buildMarkers() {
    _markers.clear();
    final filtered = _filteredSpots;
    for (final spot in filtered) {
      _markers.add(
        Marker(
          markerId: MarkerId(spot.id),
          position: LatLng(spot.latitude, spot.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            spot.status == SpotStatus.available
                ? BitmapDescriptor.hueGreen
                : spot.status == SpotStatus.fillingFast
                    ? BitmapDescriptor.hueYellow
                    : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: spot.title,
            snippet: '${spot.formattedPrice} • ${spot.statusLabel}',
          ),
          onTap: () => setState(() => _selectedSpot = spot),
        ),
      );
    }
    setState(() {});
  }

  List<ParkingSpot> get _filteredSpots {
    if (_activeFilterKey == 'all') return _spots;
    if (_activeFilterKey == 'commercial') {
      return _spots.where((s) => s.spotType == SpotType.commercial).toList();
    }
    if (_activeFilterKey == 'government') {
      return _spots.where((s) => s.spotType == SpotType.government).toList();
    }
    if (_activeFilterKey == 'private') {
      return _spots.where((s) => s.spotType == SpotType.privateHost).toList();
    }
    if (_activeFilterKey == 'covered') {
      return _spots.where((s) => s.amenities.contains('Covered')).toList();
    }
    if (_activeFilterKey == 'ev') {
      return _spots.where((s) => s.amenities.contains('EV Charging')).toList();
    }
    return _spots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: _defaultPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            markers: _markers,
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
            onTap: (_) => setState(() => _selectedSpot = null),
          ),

          // Top Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: AppStrings.searchParking,
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.tune, color: AppColors.primary, size: 20),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Filter chips row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((opt) {
                      final isActive = _activeFilterKey == opt['key'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _activeFilterKey = opt['key']!);
                            _buildMarkers();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              opt['label']!,
                              style: TextStyle(
                                color: isActive ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // My Location FAB
          Positioned(
            right: 16,
            bottom: _selectedSpot != null ? 320 : 170,
            child: FloatingActionButton.small(
              heroTag: 'location',
              backgroundColor: Colors.white,
              onPressed: _goToCurrentLocation,
              child: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),

          // Bottom Sheet: Nearby Spots List
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      children: [
                        Text(
                          _selectedSpot != null
                              ? AppStrings.availability
                              : '${AppStrings.nearbyParking} (${_filteredSpots.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedSpot != null)
                          GestureDetector(
                            onTap: () => setState(() => _selectedSpot = null),
                            child: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: _selectedSpot != null ? 200 : 180,
                    child: _selectedSpot != null
                        ? _buildSpotCard(_selectedSpot!, large: true)
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            scrollDirection: Axis.horizontal,
                            itemCount: _filteredSpots.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (_, i) => _buildSpotCard(_filteredSpots[i]),
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotCard(ParkingSpot spot, {bool large = false}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SpotDetailsScreen(spot: spot)),
      ),
      child: Container(
        width: large ? double.infinity : 220,
        margin: large ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) : EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    spot.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: spot.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    spot.statusLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: spot.statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: spot.spotTypeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    spot.spotType == SpotType.privateHost ? '🏠 ${spot.spotTypeLabel}' : '🅿️ ${spot.spotTypeLabel}',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: spot.spotTypeColor),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                const SizedBox(width: 2),
                Text(spot.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                const Icon(Icons.near_me, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Text(spot.formattedDistance, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                Text(
                  spot.formattedPrice,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
