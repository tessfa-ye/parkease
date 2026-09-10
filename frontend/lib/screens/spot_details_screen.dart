import 'package:flutter/material.dart';
import '../models/parking_spot.dart';
import '../theme/app_theme.dart';
import 'booking_confirmation_screen.dart';
import '../services/map_launcher_service.dart';

class SpotDetailsScreen extends StatelessWidget {
  final ParkingSpot spot;
  const SpotDetailsScreen({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero Photo Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    spot.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryContainer,
                      child: const Icon(Icons.local_parking, size: 80, color: AppColors.primary),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Spot Type Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spot.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  '${spot.address}, ${spot.city}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Spot type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: spot.spotTypeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: spot.spotTypeColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          spot.spotType == SpotType.privateHost ? '🏠 ${spot.spotTypeLabel}' : '🅿️ ${spot.spotTypeLabel}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: spot.spotTypeColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Private Host Card (only for private hosts)
                  if (spot.spotType == SpotType.privateHost && spot.hostName != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: spot.hostPhotoUrl != null
                                ? NetworkImage(spot.hostPhotoUrl!)
                                : null,
                            child: spot.hostPhotoUrl == null
                                ? Text(spot.hostName![0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEA580C)))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      spot.hostName!,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified, size: 14, color: Color(0xFFEA580C)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Private Space Host • ⭐ ${spot.hostRating?.toStringAsFixed(1) ?? '5.0'}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Info Tiles (Price, Available, Rating, Distance)
                  Row(
                    children: [
                      Expanded(child: _infoTile(Icons.payments_outlined, spot.formattedPrice, 'Hourly Rate')),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _infoTile(
                          Icons.local_parking,
                          '${spot.availableSpots}/${spot.totalSpots}',
                          'Available',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _infoTile(Icons.star_rounded, '${spot.rating} (${spot.reviewCount})', 'Rating')),
                      const SizedBox(width: 10),
                      Expanded(child: _infoTile(Icons.near_me_outlined, spot.formattedDistance, 'Distance')),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Status Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: spot.statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 10, color: spot.statusColor),
                          const SizedBox(width: 8),
                          Text(
                            spot.statusLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: spot.statusColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Amenities
                  const Text(
                    'Amenities',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: spot.amenities.map((a) => _amenityChip(a)).toList(),
                  ),

                  const SizedBox(height: 100), // Bottom padding for reserve button
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky Action Buttons (Directions + Reserve)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => MapLauncherService.showDirectionsModal(
                    context,
                    latitude: spot.latitude,
                    longitude: spot.longitude,
                    title: spot.title,
                    address: spot.address,
                  ),
                  icon: const Icon(Icons.directions, color: AppColors.primary),
                  label: const Text('Directions'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: spot.status == SpotStatus.full
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingConfirmationScreen(spot: spot),
                              ),
                            ),
                    child: Text(
                      spot.status == SpotStatus.full ? 'Spot Full' : 'Reserve Now',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _amenityChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryContainer),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_amenityIcon(label), size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  IconData _amenityIcon(String label) {
    switch (label.toLowerCase()) {
      case 'ev charging': return Icons.ev_station;
      case 'covered': return Icons.roofing;
      case 'security': return Icons.security;
      case 'cctv': return Icons.videocam;
      case 'telebirr pay': return Icons.phone_android;
      case 'gated': return Icons.lock;
      case 'open air': return Icons.wb_sunny;
      default: return Icons.check_circle_outline;
    }
  }
}
