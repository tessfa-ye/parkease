import 'dart:async';
import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../theme/app_theme.dart';
import '../services/booking_store.dart';
import '../services/api_service.dart';
import '../services/map_launcher_service.dart';
import '../services/host_space_store.dart';
import '../screens/payment_screen.dart';

class ActiveParkingSessionCard extends StatefulWidget {
  final Booking booking;
  const ActiveParkingSessionCard({super.key, required this.booking});

  @override
  State<ActiveParkingSessionCard> createState() => _ActiveParkingSessionCardState();
}

class _ActiveParkingSessionCardState extends State<ActiveParkingSessionCard> {
  Timer? _timer;
  late Booking _booking;
  late Duration _remaining;
  bool _isUpcoming = false;
  Duration _remainingUntilStart = Duration.zero;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _calculateRemaining();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant ActiveParkingSessionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.endTime != widget.booking.endTime ||
        oldWidget.booking.startTime != widget.booking.startTime) {
      _booking = widget.booking;
      _calculateRemaining();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    _isUpcoming = now.isBefore(_booking.startTime);
    if (_isUpcoming) {
      _remainingUntilStart = _booking.startTime.difference(now);
      _remaining = _booking.endTime.difference(_booking.startTime);
    } else {
      _remainingUntilStart = Duration.zero;
      final diff = _booking.endTime.difference(now);
      _remaining = diff.isNegative ? Duration.zero : diff;
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}h : ${minutes.toString().padLeft(2, '0')}m : ${seconds.toString().padLeft(2, '0')}s';
  }

  Color get _statusColor {
    if (_isUpcoming) return const Color(0xFF6366F1); // Indigo for Scheduled
    if (_remaining == Duration.zero) return const Color(0xFFEF4444); // Expired
    if (_remaining.inMinutes <= 15) return const Color(0xFFF59E0B); // Amber warning
    return const Color(0xFF10B981); // Healthy green
  }

  void _openPassScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          spot: _booking.spot,
          durationHours: _booking.durationHours,
          totalPriceETB: _booking.totalPriceETB,
          vehiclePlate: _booking.vehiclePlate,
          bookingId: _booking.id,
          qrCodeData: _booking.qrCodeData,
          txRef: _booking.txRef,
        ),
      ),
    );
  }

  void _confirmCheckOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 10),
            Text('Check Out of Spot?'),
          ],
        ),
        content: Text(
          'Are you leaving ${_booking.spot.title}? This will complete your parking session and free the spot for other drivers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              BookingStore.instance.completeBooking(_booking.id);
              HostSpaceStore.instance.releaseBooking(_booking.spot.id);
              ApiService.checkOutBooking(_booking.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF10B981),
                  content: Text('👋 Session completed! Saved to your Bookings history.'),
                ),
              );
            },
            child: const Text('Confirm Check Out'),
          ),
        ],
      ),
    );
  }

  void _showExtendModal(BuildContext context) {
    int selectedHours = 1;
    final hourlyRate = widget.booking.spot.pricePerHour;
    bool isExtending = false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final totalCost = hourlyRate * selectedHours;
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.more_time, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Extend Parking Session',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${widget.booking.spot.title} • ${widget.booking.slotNumber}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Choose Extension Time:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [1, 2, 3].map((hours) {
                    final isSel = selectedHours == hours;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedHours = hours),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel ? AppColors.primary : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '+$hours hr${hours > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(hourlyRate * hours).toInt()} ETB',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSel ? Colors.white.withValues(alpha: 0.9) : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isExtending
                        ? null
                        : () async {
                            setModalState(() => isExtending = true);
                            await ApiService.extendBooking(
                              bookingId: widget.booking.id,
                              additionalHours: selectedHours,
                              additionalAmount: totalCost,
                            );
                            BookingStore.instance.extendBooking(
                              widget.booking.id,
                              selectedHours,
                              totalCost,
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF10B981),
                                  content: Text(
                                    '🎉 Session extended by $selectedHours hour(s)! New end time updated.',
                                  ),
                                ),
                              );
                            }
                          },
                    child: isExtending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text('Pay $totalCost ETB & Extend'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining == Duration.zero;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _statusColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.booking.spot.title} • ${widget.booking.slotNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Compact Digital QR Pass button
              InkWell(
                onTap: _openPassScreen,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.qr_code_2, size: 14, color: AppColors.primary),
                      SizedBox(width: 3),
                      Text(
                        'Pass',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isUpcoming ? 'SCHEDULED' : (isExpired ? 'EXPIRED' : 'ACTIVE'),
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (widget.booking.vehiclePlate.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.directions_car_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.booking.vehiclePlate,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isUpcoming
                      ? Icons.schedule
                      : (isExpired ? Icons.timer_off_outlined : Icons.timer_outlined),
                  size: 16,
                  color: _statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _isUpcoming
                      ? 'Starts in ${_formatDuration(_remainingUntilStart)}'
                      : (isExpired ? 'Parking Time Expired' : _formatDuration(_remaining)),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Exactly 2 primary action buttons per state:
          Row(
            children: [
              if (_isUpcoming) ...[
                // 1. Directions to spot
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => MapLauncherService.showDirectionsModal(
                      context,
                      latitude: widget.booking.spot.latitude,
                      longitude: widget.booking.spot.longitude,
                      title: widget.booking.spot.title,
                      address: widget.booking.spot.address,
                    ),
                    icon: const Icon(Icons.navigation_outlined, size: 16, color: Color(0xFF10B981)),
                    label: const Text('Directions', style: TextStyle(fontSize: 12, color: Color(0xFF10B981))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 2. Start session early
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final now = DateTime.now();
                      setState(() {
                        _booking = _booking.copyWith(
                          startTime: now,
                          endTime: now.add(Duration(hours: _booking.durationHours)),
                        );
                        _calculateRemaining();
                      });
                      BookingStore.instance.startBookingNow(_booking.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF10B981),
                          content: Text('🚗 Parking session started! Your timer is now active.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Start Now', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ] else if (isExpired) ...[
                // 1. Extend Time
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showExtendModal(context),
                    icon: const Icon(Icons.more_time, size: 16, color: AppColors.primary),
                    label: const Text('Extend Time', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 2. Check out & leave
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmCheckOut(context),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Check Out', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ] else ...[
                // ACTIVE:
                // 1. Find Car (walking directions)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => MapLauncherService.showDirectionsModal(
                      context,
                      latitude: widget.booking.spot.latitude,
                      longitude: widget.booking.spot.longitude,
                      title: widget.booking.spot.title,
                      address: widget.booking.spot.address,
                    ),
                    icon: const Icon(Icons.directions_walk, size: 16, color: Color(0xFF10B981)),
                    label: const Text('Find Car', style: TextStyle(fontSize: 12, color: Color(0xFF10B981))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 2. Extend Time
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showExtendModal(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Extend', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
