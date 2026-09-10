import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/parking_spot.dart';
import '../theme/app_theme.dart';
import '../services/map_launcher_service.dart';
import 'main_navigation_shell.dart';

class PaymentScreen extends StatelessWidget {
  final ParkingSpot spot;
  final int durationHours;
  final double totalPriceETB;
  final String vehiclePlate;
  final String? bookingId;
  final String? qrCodeData;
  final String? txRef;
  final String paymentMethod;

  const PaymentScreen({
    super.key,
    required this.spot,
    required this.durationHours,
    required this.totalPriceETB,
    required this.vehiclePlate,
    this.bookingId,
    this.qrCodeData,
    this.txRef,
    this.paymentMethod = 'Telebirr / Chapa',
  });

  @override
  Widget build(BuildContext context) {
    final passCode = qrCodeData ?? 'PARKEASE-PASS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final slotNumber = '${spot.city.split(" ").first}-Slot-${(spot.availableSpots % 25) + 1}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Parking Digital Pass'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Checkmark Badge
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColors.available,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 16),
              Text(
                '$paymentMethod Payment Confirmed!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Your parking space is reserved & digital pass is ready.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Pass Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    children: [
                      Text(
                        spot.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        spot.address,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 18),

                      // Assigned Slot & Duration
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('ASSIGNED SLOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                slotNumber,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 40, color: AppColors.border),
                          Column(
                            children: [
                              const Text('DURATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                '$durationHours Hours',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Dynamic Scannable QR Code Pass
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QrImageView(
                              data: passCode,
                              version: QrVersions.auto,
                              size: 160.0,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppColors.textPrimary,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              passCode,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: AppColors.textSecondary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      const Text(
                        'Scan QR code at entry barrier or show to parking attendant',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 14),

                      // Vehicle & Total Paid in ETB
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Vehicle:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Expanded(
                            child: Text(
                              vehiclePlate,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (txRef != null && txRef!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tx Ref:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            Text(
                              txRef!,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Paid:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          Text(
                            '${totalPriceETB.toStringAsFixed(0)} ETB',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Turn-by-Turn Navigation Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => MapLauncherService.showDirectionsModal(
                    context,
                    latitude: spot.latitude,
                    longitude: spot.longitude,
                    title: spot.title,
                    address: spot.address,
                  ),
                  icon: const Icon(Icons.navigation, color: Colors.white),
                  label: const Text('🚗 Start Driving Navigation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Navigation Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MainNavigationShell(initialIndex: 1),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.confirmation_number_outlined),
                  label: const Text('View in My Trips / Bookings'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
                      (route) => false,
                    );
                  },
                  child: const Text('Back to Explore Map'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Digital pass receipt saved to device!')),
                  );
                },
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Download PDF Receipt'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
