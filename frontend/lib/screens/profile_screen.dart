import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/vehicle_store.dart';
import 'login_screen.dart';
import 'host_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showAddVehicleModal() {
    final plateCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final colorCtrl = TextEditingController(text: 'White');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Vehicle',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: modelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Model',
                  hintText: 'e.g. Toyota Corolla, Hyundai Tucson',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: plateCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'License Plate',
                  hintText: 'e.g. Code 3 - B98765 AA',
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  hintText: 'e.g. White, Silver, Black',
                  prefixIcon: Icon(Icons.color_lens_outlined),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final plate = plateCtrl.text.trim();
                    final model = modelCtrl.text.trim();
                    final color = colorCtrl.text.trim();

                    if (plate.isEmpty || model.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in vehicle model and plate number')),
                      );
                      return;
                    }

                    VehicleStore.instance.addVehicle(
                      plate: plate,
                      model: model,
                      color: color.isEmpty ? 'White' : color,
                    );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Vehicle $model ($plate) added!'),
                        backgroundColor: AppColors.available,
                      ),
                    );
                  },
                  child: const Text('Save Vehicle'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteVehicleConfirmation(VehicleItem vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Vehicle?'),
        content: Text('Are you sure you want to remove ${vehicle.model} (${vehicle.plate})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.full),
            onPressed: () {
              VehicleStore.instance.removeVehicle(vehicle.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Removed ${vehicle.model}')),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.myProfile),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header with Live User Info
            ListenableBuilder(
              listenable: AuthService.instance,
              builder: (context, _) {
                final name = AuthService.instance.name?.isNotEmpty == true
                    ? AuthService.instance.name!
                    : 'Abebe Kebede';
                final phone = AuthService.instance.phone?.isNotEmpty == true
                    ? AuthService.instance.phone!
                    : '+251 91 123 4567';

                return Center(
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuANbLPoxbNN7tdBBteNvawQUDhEyU53p6MMVDtGcP1r29ITA1VZF9WV4krMadh2xf0lx60cgFzLOvi3xQ2yOic2mrAqGbv0sX0rWaHd0sOWRjEWPpM4VwO_NZYhjrOzo9BLoZPFheWx18A988liI_vHdRyUYAPK01pYXDS8fz6mjnYpSFexJOb-OBLXjE-bUO3hETnlNXzRZwmeGuwXIMf0ViYHippt02CFsM1ya21hdkS2DblIVtQ',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$phone • Verified Driver',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // My Vehicles Section (Dynamically rendered from VehicleStore)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.myVehicles,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddVehicleModal,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Vehicle'),
                ),
              ],
            ),
            const SizedBox(height: 6),

            ListenableBuilder(
              listenable: VehicleStore.instance,
              builder: (context, _) {
                final vehicles = VehicleStore.instance.vehicles;
                if (vehicles.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'No vehicles added yet.\nTap "+ Add Vehicle" to register one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8)),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: vehicles.map((v) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.directions_car, color: AppColors.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.model,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${v.color} • ${v.plate}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                              onPressed: () => _showDeleteVehicleConfirmation(v),
                              tooltip: 'Remove vehicle',
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Host Dashboard & Earnings Banner
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HostDashboardScreen()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🏠', style: TextStyle(fontSize: 36)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Host Dashboard & Earnings',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Manage your space availability & withdraw earnings',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Settings List Section
            Text(
              AppStrings.settings,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildSettingTile(Icons.credit_card, 'Payment Methods (Telebirr & CBE)', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment gateway: Telebirr, CBE Birr & Card via Chapa')),
                    );
                  }),
                  const Divider(height: 1),
                  _buildSettingTile(Icons.notifications_outlined, AppStrings.notifications, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications enabled for parking pass updates')),
                    );
                  }),
                  const Divider(height: 1),
                  _buildSettingTile(Icons.help_outline, AppStrings.helpSupport, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ParkEase Support: support@parkease.et')),
                    );
                  }),
                  const Divider(height: 1),
                  _buildSettingTile(Icons.info_outline, AppStrings.aboutApp, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ParkEase v1.0.0 - Addis Ababa Smart Parking')),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await AuthService.instance.logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: AppColors.full),
                label: Text(AppStrings.signOut, style: const TextStyle(color: AppColors.full, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.full.withValues(alpha: 0.1),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}
