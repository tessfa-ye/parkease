import 'package:flutter/material.dart';
import '../models/parking_spot.dart';
import '../theme/app_theme.dart';
import 'main_navigation_shell.dart';

class PaymentScreen extends StatelessWidget {
  final ParkingSpot spot;
  final int durationHours;
  final double totalPriceETB;
  final String vehiclePlate;

  const PaymentScreen({
    super.key,
    required this.spot,
    required this.durationHours,
    required this.totalPriceETB,
    required this.vehiclePlate,
  });

  @override
  Widget build(BuildContext context) {
    const slotNumber = 'Bole-14';

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
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.available,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Telebirr Payment Successful!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your Addis Ababa parking spot is confirmed.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),

              const SizedBox(height: 28),

              // Pass Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
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

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),

                      // Assigned Slot & Duration
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: const [
                              Text('ASSIGNED SLOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              SizedBox(height: 4),
                              Text(
                                slotNumber,
                                style: TextStyle(
                                  fontSize: 22,
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

                      const SizedBox(height: 24),

                      // QR Code Pass
                      Container(
                        width: 180,
                        height: 180,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.qr_code_2, size: 120, color: AppColors.textPrimary),
                            Text(
                              'PASS: BK-AA-8842',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        'Scan QR code at entry barrier in Addis Ababa',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),

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

              const SizedBox(height: 28),

              // Navigation Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
                      (route) => false,
                    );
                  },
                  child: const Text('Back to Home'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Download Telebirr Receipt'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
