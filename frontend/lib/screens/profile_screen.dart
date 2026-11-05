import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/vehicle_store.dart';
import '../services/attendant_store.dart';
import 'login_screen.dart';
import 'host_dashboard_screen.dart';
import 'attendant_scanner_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Color get _roleColor {
    if (AuthService.instance.isOwner) return const Color(0xFFEA580C);
    if (AuthService.instance.isAttendant) return const Color(0xFF2563EB);
    return const Color(0xFF10B981);
  }

  String get _roleDisplayName {
    if (AuthService.instance.isOwner) return '🏢 Garage Owner';
    if (AuthService.instance.isAttendant) return '🎟️ Gate Attendant';
    return '🚗 Driver Mode';
  }

  void _showRoleSwitchModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Switch User Role Mode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select the mode according to your role in ParkEase',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                _buildRoleOption(
                  roleKey: 'DRIVER',
                  title: '🚗 Driver Mode',
                  subtitle: 'Explore spots, book parking & use digital pass',
                  isActive: AuthService.instance.isDriver,
                  color: const Color(0xFF10B981),
                  onTap: () async {
                    await AuthService.instance.switchRole('DRIVER');
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 10),
                _buildRoleOption(
                  roleKey: 'ATTENDANT',
                  title: '🎟️ Gate Attendant Mode',
                  subtitle: 'Scan QR passes at gate & verify entry / exit',
                  isActive: AuthService.instance.isAttendant,
                  color: const Color(0xFF2563EB),
                  onTap: () async {
                    // If already owner, owner has instant attendant access without PIN!
                    if (AuthService.instance.isOwner) {
                      await AuthService.instance.switchRole('ATTENDANT');
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Owner Access: Switched to Gate Attendant Mode'),
                            backgroundColor: Color(0xFF2563EB),
                          ),
                        );
                      }
                    } else {
                      _promptRolePasscode(ctx, 'ATTENDANT', '1234', 'Use Staff PIN (default: 1234)');
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildRoleOption(
                  roleKey: 'OWNER',
                  title: '🏢 Garage Owner / Host Mode',
                  subtitle: 'Track digital revenue, monitor staff & withdraw',
                  isActive: AuthService.instance.isOwner,
                  color: const Color(0xFFEA580C),
                  onTap: () => _promptRolePasscode(ctx, 'OWNER', '9999', 'Owner Secret PIN: 9999'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _promptRolePasscode(BuildContext modalCtx, String targetRole, String expectedPin, String hint) {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Security Passcode ($targetRole)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter PIN code to unlock $targetRole access.\n($hint for testing)',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pinCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter 4-digit PIN',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = pinCtrl.text.trim();
              bool isValid = false;
              if (targetRole == 'ATTENDANT') {
                isValid = AttendantStore.instance.validatePin(pin);
              } else if (targetRole == 'OWNER') {
                isValid = (pin == '9999' || pin == expectedPin);
              }

              if (isValid) {
                await AuthService.instance.switchRole(targetRole);
                if (dlgCtx.mounted) Navigator.pop(dlgCtx);
                if (modalCtx.mounted) Navigator.pop(modalCtx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched to $targetRole Mode'),
                      backgroundColor: targetRole == 'OWNER' ? const Color(0xFFEA580C) : const Color(0xFF2563EB),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(targetRole == 'ATTENDANT'
                        ? 'Incorrect Staff PIN! Check with garage owner.'
                        : 'Incorrect Owner PIN! (Default: 9999)'),
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                );
              }
            },
            child: const Text('Unlock & Switch'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption({
    required String roleKey,
    required String title,
    required String subtitle,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: isActive ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isActive ? color : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isActive)
              Icon(Icons.check_circle, color: color, size: 22)
            else
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
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
                        '$phone • ${AuthService.instance.isOwner ? "🏢 Garage Owner" : (AuthService.instance.isAttendant ? "🎟️ Gate Attendant" : "🚗 Driver")}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 12),

                      // Role Mode Badge & Switch Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _roleColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _roleColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _roleDisplayName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _roleColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: _showRoleSwitchModal,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _roleColor.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.swap_horiz, size: 14, color: _roleColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Switch Role',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _roleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Role-based Conditional Sections
            ListenableBuilder(
              listenable: AuthService.instance,
              builder: (context, _) {
                final isAttendant = AuthService.instance.isAttendant;
                final isOwner = AuthService.instance.isOwner;

                if (isAttendant) {
                  // ATTENDANT VIEW
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Attendant Banner
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AttendantScannerScreen()),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Scan Driver Pass',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Verify QR to allow entry & exit',
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
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You are in Gate Attendant mode. Financial dashboards and withdrawals are hidden for security.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else if (isOwner) {
                  // OWNER / HOST VIEW
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Host Dashboard Banner
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
                                      'Track digital revenue & audit attendants',
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
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.verified_user, color: Color(0xFFEA580C), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You are in Garage Owner mode. Full access to digital earnings & attendant auditing enabled.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF9A3412)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // DRIVER VIEW (DEFAULT)
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // My Vehicles Section
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
                    ],
                  );
                }
              },
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
