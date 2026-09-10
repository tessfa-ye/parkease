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
  }

  @override
  void dispose() {
    VehicleStore.instance.removeListener(_onVehicleStoreChanged);
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

  Future<void> _handlePayAndReserve(double grandTotal) async {
    setState(() => _isProcessing = true);

    final startTime = DateTime.now();

    // 1. Create booking on backend
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

    // 2. Persist booking to live client store so it instantly reflects in TripHistoryScreen
    final newBooking = Booking(
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
    BookingStore.instance.addBooking(newBooking);

    // 3. Update host space occupancy if it is a host space
    HostSpaceStore.instance.recordBooking(widget.spot.id);

    // 4. Initialize Chapa Checkout
    final paymentInit = await ApiService.initializePayment(
      bookingId: bookingId,
      amount: grandTotal,
      phone: AuthService.instance.phone,
      name: AuthService.instance.name,
    );

    final checkoutUrl = paymentInit?['checkoutUrl'];
    final txRef = paymentInit?['txRef'] ?? 'PE-TX-${DateTime.now().millisecondsSinceEpoch}';

    // 5. Launch Chapa checkout if available
    if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        // Fallback for mock sandbox URLs
      }
    }

    setState(() => _isProcessing = false);

    if (!mounted) return;

    // 6. Navigate to Digital Pass confirmation screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          spot: widget.spot,
          durationHours: _durationHours,
          totalPriceETB: grandTotal,
          vehiclePlate: _selectedVehicle,
          bookingId: bookingId,
          qrCodeData: qrCodeData,
          txRef: txRef,
          paymentMethod: _selectedPaymentMethod,
        ),
      ),
    );
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
            const Text(
              'Reservation Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRowDetail('Start Time', 'Today, ${TimeOfDay.now().format(context)}'),
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
                      'Today, ${TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: _durationHours))).format(context)}',
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
              initialValue: vehicles.contains(_selectedVehicle) ? _selectedVehicle : vehicles.first,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
              items: vehicles.map((v) {
                return DropdownMenuItem(value: v, child: Text(v));
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
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Opening Chapa Checkout...'),
                        ],
                      )
                    : Text('Pay $currency ${grandTotal.toStringAsFixed(0)} & Reserve'),
              ),
            ),
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
