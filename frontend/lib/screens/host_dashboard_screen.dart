import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/parking_spot.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/host_space_store.dart';
import '../services/booking_store.dart';
import '../services/attendant_store.dart';
import 'host_registration_screen.dart';
import 'attendant_scanner_screen.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  bool _isLoading = true;
  double _totalEarnings = 3420.0;
  int _totalBookings = 14;
  int _totalSpaces = 1;
  String _currency = 'ETB';

  // Managed host spaces — loaded from HostSpaceStore
  List<Map<String, dynamic>> _spaces = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    BookingStore.instance.addListener(_onStoreUpdate);
    HostSpaceStore.instance.addListener(_onStoreUpdate);
    AttendantStore.instance.addListener(_onStoreUpdate);
  }

  @override
  void dispose() {
    BookingStore.instance.removeListener(_onStoreUpdate);
    HostSpaceStore.instance.removeListener(_onStoreUpdate);
    AttendantStore.instance.removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() {
    if (!mounted) return;
    setState(() {
      _spaces = List<Map<String, dynamic>>.from(
        HostSpaceStore.instance.spaces.map((s) => Map<String, dynamic>.from(s)),
      );
      _totalSpaces = _spaces.length;
    });
  }

  List<Map<String, String>> _getActiveParkedCars() {
    final hostSpaceIds = _spaces.map((s) => s['id']?.toString() ?? '').toSet();
    final list = <Map<String, String>>[];

    for (final b in BookingStore.instance.activeBookings) {
      final isHostSpot = hostSpaceIds.contains(b.spot.id) || b.spot.spotType == SpotType.privateHost;
      if (isHostSpot) {
        final now = DateTime.now();
        final diff = b.endTime.difference(now);
        final minutesLeft = diff.inMinutes;
        final timeLeftStr = minutesLeft > 0
            ? '${diff.inHours > 0 ? "${diff.inHours}h " : ""}${diff.inMinutes % 60}m remaining'
            : 'Expired';

        list.add({
          'vehiclePlate': b.vehiclePlate,
          'carModel': b.spot.title,
          'slot': 'Slot 1',
          'entryTime': '${b.startTime.hour.toString().padLeft(2, '0')}:${b.startTime.minute.toString().padLeft(2, '0')}',
          'timeLeft': timeLeftStr,
          'amount': '${b.totalPriceETB.toStringAsFixed(0)} $_currency',
        });
      }
    }

    if (list.isEmpty) {
      list.add({
        'vehiclePlate': 'Code 3 - A24561 AA',
        'carModel': 'Toyota Vitz (White)',
        'slot': 'Slot 1',
        'entryTime': '1:15 PM',
        'timeLeft': '1h 45m remaining',
        'amount': '60 ETB',
      });
    }

    return list;
  }

  double get _computedEarnings {
    double extra = 0;
    for (final b in BookingStore.instance.bookings) {
      if (b.status == BookingStatus.completed || b.status == BookingStatus.active) {
        if (_spaces.any((s) => s['id'] == b.spot.id) || b.spot.spotType == SpotType.privateHost) {
          extra += b.totalPriceETB;
        }
      }
    }
    return _totalEarnings + extra;
  }

  int get _computedBookingsCount {
    int liveCount = 0;
    for (final b in BookingStore.instance.bookings) {
      if (_spaces.any((s) => s['id'] == b.spot.id) || b.spot.spotType == SpotType.privateHost) {
        liveCount++;
      }
    }
    return _totalBookings + liveCount;
  }

  int get _verifiedEntriesCount {
    return BookingStore.instance.activeBookings.length;
  }

  int get _completedExitsCount {
    return BookingStore.instance.completedBookings.length;
  }

  int get _overstayFlaggedCount {
    final now = DateTime.now();
    return BookingStore.instance.activeBookings
        .where((b) => now.isAfter(b.endTime))
        .length;
  }

  double get _telebirrRevenue => _computedEarnings * 0.65;
  double get _cbeBirrRevenue => _computedEarnings * 0.35;

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getHostDashboard();

    // Merge any API-returned spots into the local store
    if (data != null && data['spots'] is List && (data['spots'] as List).isNotEmpty) {
      HostSpaceStore.instance.mergeFromApi(data['spots'] as List);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        // Always read the authoritative list from the store
        _spaces = List<Map<String, dynamic>>.from(
          HostSpaceStore.instance.spaces.map((s) => Map<String, dynamic>.from(s)),
        );
        if (data != null) {
          _totalEarnings = (data['totalEarnings'] as num?)?.toDouble() ?? 3420.0;
          _totalBookings = (data['totalBookings'] as num?)?.toInt() ?? 14;
          _totalSpaces = _spaces.length;
          _currency = data['currency'] ?? 'ETB';
        } else {
          _totalSpaces = _spaces.length;
        }
      });
    }
  }

  Future<void> _toggleSpaceAvailability(int index, bool newValue) async {
    // Update both the local UI list and the persistent store
    HostSpaceStore.instance.toggleAvailability(index, newValue);
    setState(() {
      _spaces[index]['isAvailable'] = newValue;
    });

    final spotId = _spaces[index]['id'];
    await ApiService.toggleSpotStatus(spotId, newValue);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue ? 'Space is now OPEN for drivers to book' : 'Space is now CLOSED for reservations',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmDeleteSpace(String spotId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Space?'),
        content: Text('Are you sure you want to remove "$title"? It will no longer appear on Explore or accept reservations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.full),
            onPressed: () {
              HostSpaceStore.instance.removeSpace(spotId);
              Navigator.pop(ctx);
              _loadDashboardData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Removed "$title"')),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Withdraw Host Earnings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Available balance: ${_totalEarnings.toStringAsFixed(0)} $_currency',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.phone_android, color: Color(0xFF0072CE), size: 30),
                  title: const Text('Telebirr Payout', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Instant transfer to registered phone'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmWithdraw('Telebirr');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.account_balance, color: Color(0xFF8B1D41), size: 30),
                  title: const Text('CBE Birr / Commercial Bank', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Direct deposit to bank account'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmWithdraw('CBE Birr');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmWithdraw(String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payout request of ${_totalEarnings.toStringAsFixed(0)} $_currency via $method submitted!'),
        backgroundColor: AppColors.available,
      ),
    );
  }

  void _showAddAttendantModal() {
    final nameCtrl = TextEditingController();
    final gateCtrl = TextEditingController(text: 'Main Barrier Gate');
    final phoneCtrl = TextEditingController();
    final pinCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    'Add Gate Attendant',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Create login PIN for your gate employee',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Staff Name',
                  hintText: 'e.g. Dawit Girma',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Assigned Gate / Location',
                  hintText: 'e.g. Main Entrance Gate 1',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+251 9... or +251 7...',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Create 4-Digit Passcode (PIN)',
                  hintText: 'e.g. 1234, 4321',
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: 'Attendant will use this PIN to access Gate Scanner',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final gate = gateCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    final pin = pinCtrl.text.trim();

                    if (name.isEmpty || pin.length != 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter attendant name and a 4-digit PIN!'),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                      return;
                    }

                    AttendantStore.instance.addAttendant(
                      name: name,
                      phone: phone.isNotEmpty ? phone : '+251 90 000 0000',
                      gate: gate.isNotEmpty ? gate : 'Gate 1',
                      pin: pin,
                    );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Attendant "$name" registered with PIN $pin'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Save & Issue Passcode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditPinDialog(AttendantStaff staff) {
    final pinCtrl = TextEditingController(text: staff.pin);

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change PIN for ${staff.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Gate: ${staff.gate}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'New 4-Digit PIN',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin),
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
            onPressed: () {
              final newPin = pinCtrl.text.trim();
              if (newPin.length == 4) {
                AttendantStore.instance.updatePin(staff.id, newPin);
                Navigator.pop(dlgCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('PIN updated for ${staff.name} to $newPin'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be 4 digits')),
                );
              }
            },
            child: const Text('Update PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hostName = AuthService.instance.name ?? 'Abebe Kebede';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Host Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Banner
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('🏠', style: TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hostName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: const [
                                Icon(Icons.verified, size: 14, color: Color(0xFF10B981)),
                                SizedBox(width: 4),
                                Text(
                                  'Verified Private Host • Addis Ababa',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Earnings Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL REVENUE EARNED',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _computedEarnings.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _currency,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _buildMiniStat('Total Bookings', '$_computedBookingsCount'),
                            Container(width: 1, height: 28, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 16)),
                            _buildMiniStat('Active Spaces', '$_totalSpaces'),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _showWithdrawDialog,
                              icon: const Icon(Icons.account_balance_wallet, size: 16),
                              label: const Text('Withdraw'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFEA580C),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Section Header: Owner Payment & Gate Control
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Owner Payment & Gate Control',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Owner Payment & Attendant Control Section Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.25), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_user, color: Color(0xFF2563EB), size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Digital Payment Audit',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '100% Digital • Zero Cash at Gate',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
                                  SizedBox(width: 4),
                                  Text(
                                    'SETTLED',
                                    style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Payment Channel Breakdown (Telebirr & CBE Birr)
                        Row(
                          children: [
                            // Telebirr Tile
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0072CE).withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF0072CE).withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.phone_android, size: 16, color: Color(0xFF0072CE)),
                                        SizedBox(width: 6),
                                        Text(
                                          'Telebirr (65%)',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0072CE)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_telebirrRevenue.toStringAsFixed(0)} $_currency',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF0072CE),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // CBE Birr Tile
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B1D41).withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF8B1D41).withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.account_balance, size: 16, color: Color(0xFF8B1D41)),
                                        SizedBox(width: 6),
                                        Text(
                                          'CBE Birr (35%)',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8B1D41)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_cbeBirrRevenue.toStringAsFixed(0)} $_currency',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF8B1D41),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Attendant Employee Operations Bar Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ATTENDANT GATE OPERATIONS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Gate 1 Active Shift',
                                style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Operations Metric Tiles
                        Row(
                          children: [
                            Expanded(
                              child: _buildOperationMetric(
                                label: 'Verified In',
                                value: '$_verifiedEntriesCount',
                                icon: Icons.login,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildOperationMetric(
                                label: 'Exited',
                                value: '$_completedExitsCount',
                                icon: Icons.logout,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildOperationMetric(
                                label: 'Overstay',
                                value: '$_overstayFlaggedCount',
                                icon: Icons.warning_amber_rounded,
                                color: _overstayFlaggedCount > 0 ? const Color(0xFFEF4444) : Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Quick Action for Owner to Scan directly
                        const SizedBox(height: 4),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AttendantScannerScreen()),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
                                    ),
                                    const SizedBox(width: 14),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Open Gate Scanner',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Owner direct access — no PIN required',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.white70, size: 22),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Section Header: Gate Attendants & Passwords
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.people_outline, color: Color(0xFF2563EB), size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Gate Attendants & Passwords',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddAttendantModal,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Staff', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ListenableBuilder(
                    listenable: AttendantStore.instance,
                    builder: (context, _) {
                      final staffList = AttendantStore.instance.staff;
                      if (staffList.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Center(
                            child: Text(
                              'No attendants added yet.\nTap "+ Add Staff" to create employee passcodes.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: staffList.map((staff) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: staff.isActive ? Colors.grey.shade200 : Colors.grey.shade300,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: staff.isActive
                                              ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                                              : Colors.grey.shade200,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.badge,
                                            color: staff.isActive ? const Color(0xFF2563EB) : Colors.grey,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // Staff Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  staff.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                ),
                                                const SizedBox(width: 6),
                                                if (!staff.isActive)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade200,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Text('Inactive', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${staff.gate} • ${staff.phone}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Daily Verified Count Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              '${staff.scansToday}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF10B981)),
                                            ),
                                            const Text(
                                              'Scans Today',
                                              style: TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Bottom Action Row
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
                                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Staff PIN Pill with Edit action
                                      InkWell(
                                        onTap: () => _showEditPinDialog(staff),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.amber.shade400),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.key, size: 14, color: Color(0xFFB45309)),
                                              const SizedBox(width: 5),
                                              Text(
                                                'PIN: ${staff.pin}',
                                                style: const TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Color(0xFFB45309),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Icon(Icons.edit, size: 12, color: Color(0xFFB45309)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Suspend & Remove Actions
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => AttendantStore.instance.toggleActive(staff.id),
                                            icon: Icon(
                                              staff.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                              size: 16,
                                              color: staff.isActive ? Colors.grey.shade700 : const Color(0xFF10B981),
                                            ),
                                            label: Text(
                                              staff.isActive ? 'Suspend' : 'Activate',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: staff.isActive ? Colors.grey.shade700 : const Color(0xFF10B981),
                                              ),
                                            ),
                                            style: TextButton.styleFrom(
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                            onPressed: () => AttendantStore.instance.removeAttendant(staff.id),
                                            tooltip: 'Remove attendant',
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Section Header: My Listed Spaces
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.local_parking, color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'My Listed Spaces',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HostRegistrationScreen()),
                          );
                          _loadDashboardData();
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Space', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Space Cards
                  ..._spaces.asMap().entries.map((entry) {
                    final index = entry.key;
                    final space = entry.value;
                    final isAvailable = space['isAvailable'] as bool;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.garage, color: AppColors.primary, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        space['title'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${space['spaceType']} • ${space['capacity']} Spots Capacity',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: isAvailable,
                                      activeThumbColor: AppColors.available,
                                      onChanged: (val) => _toggleSpaceAvailability(index, val),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                      onPressed: () => _confirmDeleteSpace(space['id'], space['title']),
                                      tooltip: 'Remove Space',
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isAvailable ? AppColors.available : AppColors.full,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isAvailable ? 'Open for Bookings' : 'Closed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isAvailable ? AppColors.available : AppColors.full,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${space['pricePerHour'].toInt()} $_currency/hour',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Live Occupancy / Currently Parked Cars
                  const Text(
                    'CURRENTLY PARKED VEHICLES',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),

                  Builder(
                    builder: (context) {
                      final activeCars = _getActiveParkedCars();
                      if (activeCars.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Center(
                            child: Text(
                              'No vehicles currently parked in your space',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: activeCars.map((car) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
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
                                          car['vehiclePlate']!,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${car['carModel']} • ${car['slot']}',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        car['timeLeft']!,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        car['amount']!,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ],
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
                ],
              ),
            ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildOperationMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
