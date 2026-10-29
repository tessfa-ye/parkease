import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/parking_spot.dart';
import '../models/booking.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/booking_store.dart';
import '../services/vehicle_store.dart';
import '../services/host_space_store.dart';
import '../services/payment_verification_service.dart';
import 'payment_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final ParkingSpot spot;
  final int durationHours;

  const BookingConfirmationScreen({
    super.key,
    required this.spot,
    this.durationHours = 2,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  late int _durationHours;
  late String _selectedVehicle;
  String _selectedPaymentMethod = 'Telebirr (via Chapa)';
  bool _isProcessing = false;
  String _processingLabel = 'Opening Chapa Checkout...';

  DateTime _startTime = DateTime.now();
  int _arrivalOffsetMinutes = 0; // 0 for "Now", 15, 30, or -1 for Custom

  DateTime get _effectiveEndTime => _startTime.add(Duration(hours: _durationHours));

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final timeStr = TimeOfDay.fromDateTime(dt).format(context);
    return isToday ? 'Today, $timeStr' : '${dt.month}/${dt.day}, $timeStr';
  }

  void _setArrivalOffset(int minutes) {
    setState(() {
      _arrivalOffsetMinutes = minutes;
      if (minutes == 0) {
        _startTime = DateTime.now();
      } else {
        _startTime = DateTime.now().add(Duration(minutes: minutes));
      }
    });
  }

  Future<void> _pickCustomStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
      helpText: 'Estimated Arrival Time',
    );
    if (picked != null) {
      final nowDt = DateTime.now();
      var selectedDt = DateTime(nowDt.year, nowDt.month, nowDt.day, picked.hour, picked.minute);
      if (selectedDt.isBefore(nowDt.subtract(const Duration(minutes: 5)))) {
        selectedDt = selectedDt.add(const Duration(days: 1));
      }
      setState(() {
        _arrivalOffsetMinutes = -1;
        _startTime = selectedDt;
      });
    }
  }

  Widget _buildArrivalChip({required String label, required int offset}) {
    final isSel = _arrivalOffsetMinutes == offset;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setArrivalOffset(offset),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSel ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // Lifecycle listener to detect when user returns from browser
  AppLifecycleListener? _lifecycleListener;
  bool _chapaLaunched = false;
  String? _pendingTxRef;
  String? _pendingBookingId;
  String? _pendingQrCodeData;
  double? _pendingGrandTotal;
  Booking? _pendingBooking;

  @override
  void initState() {
    super.initState();
    _durationHours = widget.durationHours > 0 ? widget.durationHours : 2;

    final availableVehicles = VehicleStore.instance.vehicleDisplayNames;
    if (availableVehicles.isNotEmpty) {
      _selectedVehicle = availableVehicles.first;
    } else {
      _selectedVehicle = 'Code 3 - A24561 AA (Toyota Vitz)';
    }

    VehicleStore.instance.addListener(_onVehicleStoreChanged);

    // Set up lifecycle listener to detect app returning from browser
    _lifecycleListener = AppLifecycleListener(
      onResume: _onAppResumed,
    );
  }

  @override
  void dispose() {
    VehicleStore.instance.removeListener(_onVehicleStoreChanged);
    _lifecycleListener?.dispose();
    super.dispose();
  }

  void _onVehicleStoreChanged() {
    if (!mounted) return;
    final available = VehicleStore.instance.vehicleDisplayNames;
    if (available.isNotEmpty && !available.contains(_selectedVehicle)) {
      setState(() {
        _selectedVehicle = available.first;
      });
    }
  }

  /// Called when the app resumes focus (user returns from Chapa browser page)
  Future<void> _onAppResumed() async {
    if (!_chapaLaunched || _pendingTxRef == null) return;
    _chapaLaunched = false;

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _processingLabel = 'Verifying payment…';
    });

    // Poll backend to verify payment
    final result = await PaymentVerificationService.verify(_pendingTxRef!);

    if (!mounted) return;

    if (result.isSuccess) {
      _navigateToSuccess(qrCode: result.qrCodeData);
    } else {
      setState(() => _isProcessing = false);
      _showPaymentError(result.status);
    }
  }

  void _navigateToSuccess({String? qrCode}) {
    if (_pendingBooking == null || _pendingGrandTotal == null) return;
    final booking = _pendingBooking!;
    final confirmedBooking = Booking(
      id: booking.id,
      spot: booking.spot,
      startTime: booking.startTime,
      endTime: booking.endTime,
      durationHours: booking.durationHours,
      totalPriceETB: booking.totalPriceETB,
      slotNumber: booking.slotNumber,
      vehiclePlate: booking.vehiclePlate,
      status: BookingStatus.active,
      qrCodeData: qrCode ?? booking.qrCodeData,
      txRef: _pendingTxRef,
    );
    BookingStore.instance.addBooking(confirmedBooking);
    HostSpaceStore.instance.recordBooking(widget.spot.id);

    setState(() => _isProcessing = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          spot: widget.spot,
          durationHours: _durationHours,
          totalPriceETB: _pendingGrandTotal!,
          vehiclePlate: _selectedVehicle,
          bookingId: _pendingBookingId,
          qrCodeData: qrCode ?? _pendingQrCodeData,
          txRef: _pendingTxRef,
          paymentMethod: _selectedPaymentMethod,
        ),
      ),
    );
  }

  void _showPaymentError(PaymentVerificationStatus status) {
    final message = status == PaymentVerificationStatus.timeout
        ? 'Could not confirm your payment. Please check your Chapa transaction history or try again.'
        : 'Payment was not completed. You can retry with Test Card Payment, or confirm directly in sandbox mode.';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Payment Status'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_pendingTxRef != null) {
                _relaunchChapa();
              }
            },
            child: const Text('Retry Payment'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              _navigateToSuccess(qrCode: _pendingQrCodeData);
            },
            icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            label: const Text('Confirm (Sandbox)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _relaunchChapa() async {
    if (_pendingTxRef == null || _pendingGrandTotal == null) return;
    setState(() {
      _isProcessing = true;
      _processingLabel = 'Reopening Chapa Checkout...';
    });

    final paymentInit = await ApiService.initializePayment(
      bookingId: _pendingBookingId ?? _pendingTxRef!,
      amount: _pendingGrandTotal!,
      phone: AuthService.instance.phone,
      name: AuthService.instance.name,
    );

    final checkoutUrl = paymentInit?['checkoutUrl'];
    setState(() => _isProcessing = false);

    if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          _chapaLaunched = true;
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }
  }

  Future<void> _handlePayAndReserve(double grandTotal) async {
    setState(() {
      _isProcessing = true;
      _processingLabel = 'Creating your reservation…';
    });

    final startTime = _startTime;

    // 1. Create booking on backend (status stays PENDING until payment verified)
    final booking = await ApiService.createBooking(
      spotId: widget.spot.id,
      vehiclePlate: _selectedVehicle,
      startTime: startTime,
      durationHours: _durationHours.toDouble(),
      totalAmount: grandTotal,
    );

    final bookingId = booking?['id'] ?? 'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final qrCodeData = booking?['qrCodeData'] ?? 'PARKEASE-PASS-$bookingId';
    final slotNumber = '${widget.spot.city.split(" ").first}-Slot-${(widget.spot.availableSpots % 25) + 1}';

    // 2. Hold booking info in pending state — NOT committed to BookingStore yet
    _pendingBookingId = bookingId;
    _pendingQrCodeData = qrCodeData;
    _pendingGrandTotal = grandTotal;
    _pendingBooking = Booking(
      id: bookingId,
      spot: widget.spot,
      startTime: startTime,
      endTime: startTime.add(Duration(hours: _durationHours)),
      durationHours: _durationHours,
      totalPriceETB: grandTotal,
      slotNumber: slotNumber,
      vehiclePlate: _selectedVehicle,
      status: BookingStatus.active,
      qrCodeData: qrCodeData,
    );

    // 3. Initialize Chapa Checkout
    setState(() => _processingLabel = 'Opening Chapa Checkout...');
    final paymentInit = await ApiService.initializePayment(
      bookingId: bookingId,
      amount: grandTotal,
      phone: AuthService.instance.phone,
      name: AuthService.instance.name,
    );

    final checkoutUrl = paymentInit?['checkoutUrl'];
    _pendingTxRef = paymentInit?['txRef'] ?? 'PE-TX-${DateTime.now().millisecondsSinceEpoch}';

    // 4. Launch Chapa checkout in external browser
    bool launched = false;
    if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          _chapaLaunched = true;
          launched = true;
          setState(() => _processingLabel = 'Waiting for payment…');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    // 5. If URL could not be launched (emulator/sandbox), auto-verify immediately
    if (!launched) {
      _chapaLaunched = false;
      setState(() => _processingLabel = 'Verifying payment…');
      final result = await PaymentVerificationService.verify(_pendingTxRef!);
      if (!mounted) return;

      setState(() => _isProcessing = false);

      if (result.isSuccess) {
        _navigateToSuccess(qrCode: result.qrCodeData);
      } else {
        setState(() => _isProcessing = false);
        _showPaymentError(result.status);
      }
      return;
    }

    // Keep spinner visible while waiting for app to resume from browser
    // _onAppResumed() will handle the rest when user comes back
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.spot.pricePerHour * _durationHours;
    final serviceFee = widget.spot.countryCode == 'ET' ? 10.00 : 1.50;
    final tax = widget.spot.countryCode == 'ET' ? 5.00 : 0.75;
    final grandTotal = subtotal + serviceFee + tax;
    final currency = widget.spot.currencySymbol;
    final vehicles = VehicleStore.instance.vehicleDisplayNames.isNotEmpty
        ? VehicleStore.instance.vehicleDisplayNames
        : ['Code 3 - A24561 AA (Toyota Vitz)'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Booking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Spot Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.primaryContainer,
                        image: DecorationImage(
                          image: NetworkImage(widget.spot.imageUrl),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.spot.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.spot.address,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Reservation Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reservation Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                TextButton.icon(
                  onPressed: _pickCustomStartTime,
                  icon: const Icon(Icons.schedule, size: 16),
                  label: const Text('Custom Time', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Quick arrival chips: Now, +15m, +30m, Pick Time
            Row(
              children: [
                _buildArrivalChip(label: 'Now', offset: 0),
                const SizedBox(width: 8),
                _buildArrivalChip(label: '+15 min', offset: 15),
                const SizedBox(width: 8),
                _buildArrivalChip(label: '+30 min', offset: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: _pickCustomStartTime,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _arrivalOffsetMinutes == -1
                            ? AppColors.primary
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _arrivalOffsetMinutes == -1
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _arrivalOffsetMinutes == -1
                            ? TimeOfDay.fromDateTime(_startTime).format(context)
                            : 'Pick Time',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _arrivalOffsetMinutes == -1
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRowDetail('Start Time (Arrival)', _formatDateTime(_startTime)),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Duration',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18, color: AppColors.primary),
                                onPressed: _durationHours > 1
                                    ? () => setState(() => _durationHours--)
                                    : null,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '$_durationHours hrs',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                                onPressed: _durationHours < 24
                                    ? () => setState(() => _durationHours++)
                                    : null,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildRowDetail(
                      'End Time',
                      _formatDateTime(_effectiveEndTime),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Vehicle Selector
            const Text(
              'Select Vehicle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: vehicles.contains(_selectedVehicle) ? _selectedVehicle : vehicles.first,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
              items: vehicles.map((v) {
                return DropdownMenuItem(
                  value: v,
                  child: Text(
                    v,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedVehicle = val);
              },
            ),

            const SizedBox(height: 24),

            // Payment Options
            const Text(
              'Payment Method (Chapa Gateway)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption('Telebirr (via Chapa)', Icons.phone_android),
            _buildPaymentOption('CBE Birr (via Chapa)', Icons.account_balance),
            _buildPaymentOption('Credit / Debit Card', Icons.credit_card),

            const SizedBox(height: 24),

            // Price Breakdown Card
            Text(
              'Payment Breakdown ($currency)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRowDetail('Parking Fee ($_durationHours hrs)', '$currency ${subtotal.toStringAsFixed(0)}'),
                    const SizedBox(height: 8),
                    _buildRowDetail('Service Fee', '$currency ${serviceFee.toStringAsFixed(0)}'),
                    const SizedBox(height: 8),
                    _buildRowDetail('City Tax', '$currency ${tax.toStringAsFixed(0)}'),
                    const Divider(height: 24),
                    _buildRowDetail('Total Amount', '$currency ${grandTotal.toStringAsFixed(0)}', isBold: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _handlePayAndReserve(grandTotal),
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(_processingLabel),
                        ],
                      )
                    : Text('Pay $currency ${grandTotal.toStringAsFixed(0)} & Reserve'),
              ),
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _isProcessing = false),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => _navigateToSuccess(qrCode: _pendingQrCodeData),
                    icon: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                    label: const Text('Confirm (Sandbox)', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRowDetail(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isBold ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
