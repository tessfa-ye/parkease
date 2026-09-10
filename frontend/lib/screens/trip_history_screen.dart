import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../theme/app_theme.dart';
import '../services/booking_store.dart';
import '../services/api_service.dart';
import '../services/map_launcher_service.dart';
import 'payment_screen.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    BookingStore.instance.addListener(_onBookingsChanged);
    BookingStore.instance.init();
    _refreshBookings();
  }

  @override
  void dispose() {
    BookingStore.instance.removeListener(_onBookingsChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onBookingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshBookings() async {
    setState(() => _isRefreshing = true);
    await ApiService.getMyBookings();
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _showCancelDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Reservation?'),
        content: Text('Are you sure you want to cancel your reservation for "${booking.spot.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.full),
            onPressed: () {
              Navigator.pop(ctx);
              ApiService.cancelBooking(booking.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reservation cancelled successfully')),
              );
            },
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final timeStr = '${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today, $timeStr';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day} • $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final activeList = BookingStore.instance.activeBookings;
    final completedList = BookingStore.instance.completedBookings;
    final cancelledList = BookingStore.instance.cancelledBookings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: _refreshBookings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Active (${activeList.length})'),
            Tab(text: 'Completed (${completedList.length})'),
            Tab(text: 'Cancelled (${cancelledList.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingList(activeList, isActive: true),
          _buildBookingList(completedList),
          _buildBookingList(cancelledList, isCancelled: true),
        ],
      ),
    );
  }

  Widget _buildBookingList(List<Booking> list, {bool isActive = false, bool isCancelled = false}) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshBookings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildEmptyState(
              isActive
                  ? 'No active bookings right now.\nReserve a spot on the map!'
                  : isCancelled
                      ? 'No cancelled bookings.'
                      : 'No completed trips yet.',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final booking = list[index];
          final color = booking.status == BookingStatus.active
              ? AppColors.available
              : booking.status == BookingStatus.completed
                  ? AppColors.primary
                  : AppColors.full;

          final label = booking.status == BookingStatus.active
              ? 'ACTIVE'
              : booking.status == BookingStatus.completed
                  ? 'COMPLETED'
                  : 'CANCELLED';

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.local_parking, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.spot.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_formatDate(booking.startTime)} • ${booking.durationHours}h',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '${booking.totalPriceETB.toStringAsFixed(0)} ETB',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.directions_car, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        booking.vehiclePlate,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      const Icon(Icons.pin_drop, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        booking.slotNumber,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (isActive) ...[
                            TextButton.icon(
                              onPressed: () => MapLauncherService.showDirectionsModal(
                                context,
                                latitude: booking.spot.latitude,
                                longitude: booking.spot.longitude,
                                title: booking.spot.title,
                                address: booking.spot.address,
                              ),
                              icon: const Icon(Icons.directions, size: 16, color: Color(0xFF10B981)),
                              label: const Text('Directions', style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                            TextButton(
                              onPressed: () => _showCancelDialog(booking),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.full, fontSize: 13)),
                            ),
                          ],
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentScreen(
                                    spot: booking.spot,
                                    durationHours: booking.durationHours,
                                    totalPriceETB: booking.totalPriceETB,
                                    vehiclePlate: booking.vehiclePlate,
                                    bookingId: booking.id,
                                    qrCodeData: booking.qrCodeData,
                                    txRef: 'REF-${booking.id}',
                                    paymentMethod: 'Telebirr / Chapa',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code, size: 16, color: AppColors.primary),
                            label: const Text('View Pass', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
