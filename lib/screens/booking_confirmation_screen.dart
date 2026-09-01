import 'package:flutter/material.dart';
import '../models/parking_spot.dart';
import '../theme/app_theme.dart';
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
  String _selectedVehicle = 'Code 3 - A24561 AA (Toyota Vitz)';
  String _selectedPaymentMethod = 'Telebirr / Mobile Wallet';

  final List<String> _vehicles = [
    'Code 3 - A24561 AA (Toyota Vitz)',
    'Code 3 - B98765 AA (Hyundai Tucson)',
    'Code 2 - C11223 AA (Suzuki Dzire)',
    'Standard Sedan (ABC-1234)',
  ];

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.spot.pricePerHour * widget.durationHours;
    final serviceFee = widget.spot.countryCode == 'ET' ? 10.00 : 1.50;
    final tax = widget.spot.countryCode == 'ET' ? 5.00 : 0.75;
    final grandTotal = subtotal + serviceFee + tax;
    final currency = widget.spot.currencySymbol;

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
                          ),
                          const SizedBox(height: 4),
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
                    const Divider(height: 24),
                    _buildRowDetail('Duration', '${widget.durationHours} Hours'),
                    const Divider(height: 24),
                    _buildRowDetail('End Time', 'Today, ${TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: widget.durationHours))).format(context)}'),
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
              initialValue: _selectedVehicle,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
              items: _vehicles.map((v) {
                return DropdownMenuItem(value: v, child: Text(v));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedVehicle = val);
              },
            ),

            const SizedBox(height: 24),

            // Payment Options
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption('Telebirr / Mobile Wallet', Icons.phone_android),
            _buildPaymentOption('CBE Birr / Bank Transfer', Icons.account_balance),
            _buildPaymentOption('Credit / Debit Card (Chapa / Stripe)', Icons.credit_card),
            _buildPaymentOption('Apple Pay / Google Pay', Icons.payment),

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
                    _buildRowDetail('Parking Fee (${widget.durationHours} hrs)', '$currency ${subtotal.toStringAsFixed(0)}'),
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        spot: widget.spot,
                        durationHours: widget.durationHours,
                        totalPriceETB: grandTotal,
                        vehiclePlate: _selectedVehicle,
                      ),
                    ),
                  );
                },
                child: Text('Pay $currency ${grandTotal.toStringAsFixed(0)} & Reserve'),
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
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
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
