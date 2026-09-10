import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/parking_spot.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/host_space_store.dart';
import '../services/booking_store.dart';
import 'host_registration_screen.dart';

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
  }

  @override
  void dispose() {
    BookingStore.instance.removeListener(_onStoreUpdate);
    HostSpaceStore.instance.removeListener(_onStoreUpdate);
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

                  const SizedBox(height: 28),

                  // My Spaces Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MY LISTED SPACES',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HostRegistrationScreen()),
                          );
                          // Refresh after returning from registration
                          _loadDashboardData();
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Space'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

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
}
