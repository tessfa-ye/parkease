import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Multi-step host registration screen — allows users to list
/// their free parking space and earn money per booking.
class HostRegistrationScreen extends StatefulWidget {
  const HostRegistrationScreen({super.key});

  @override
  State<HostRegistrationScreen> createState() => _HostRegistrationScreenState();
}

class _HostRegistrationScreenState extends State<HostRegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1 — Location
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String _selectedCountry = 'Ethiopia';

  // Step 2 — Space Details
  String _spaceType = 'Driveway';
  int _capacity = 1;
  final _dimensionsController = TextEditingController(text: '5m x 2.5m');

  // Step 3 — Pricing & Availability
  final _priceController = TextEditingController(text: '30');
  final List<bool> _availableDays = List.filled(7, true);
  final _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Step 4 — Payout
  String _payoutMethod = 'Telebirr';
  final _payoutAccountController = TextEditingController();

  final List<String> _spaceTypes = ['Driveway', 'Garage', 'Open Lot', 'Covered Lot', 'Underground'];
  final List<String> _countries = [
    'Ethiopia', 'Kenya', 'Nigeria', 'South Africa', 'Ghana',
    'Uganda', 'Tanzania', 'Egypt', 'United States', 'United Kingdom', 'Other'
  ];
  final List<String> _payoutMethods = [
    'Telebirr', 'CBE Birr', 'M-Pesa', 'Bank Transfer', 'PayPal'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('List Your Parking Space'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1Location(),
          _buildStep2Details(),
          _buildStep3Pricing(),
          _buildStep4Payout(),
        ],
      ),
    );
  }

  Widget _buildStep(String title, String subtitle, Widget content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    '${_currentStep + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          content,
          const SizedBox(height: 32),
          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      setState(() => _currentStep--);
                    },
                    child: const Text('Back'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentStep < 3) {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      setState(() => _currentStep++);
                    } else {
                      _submitListing();
                    }
                  },
                  child: Text(_currentStep == 3 ? '🚀 Publish Listing' : 'Next →'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Location() {
    return _buildStep(
      'Your Location',
      'Where is your parking space?',
      Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedCountry,
            decoration: _inputDecoration('Country'),
            items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedCountry = v);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cityController,
            decoration: _inputDecoration('City / Town'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: _inputDecoration('Street Address / Landmark'),
          ),
          const SizedBox(height: 20),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_location_alt, size: 40, color: AppColors.primary),
                  SizedBox(height: 8),
                  Text('Tap to pin location on map', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Details() {
    return _buildStep(
      'Space Details',
      'Tell renters about your space',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Space Type', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _spaceTypes.map((type) {
              final selected = _spaceType == type;
              return GestureDetector(
                onTap: () => setState(() => _spaceType = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Number of Spaces', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                onPressed: () => setState(() { if (_capacity > 1) _capacity--; }),
              ),
              Container(
                width: 56,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$_capacity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                onPressed: () => setState(() => _capacity++),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dimensionsController,
            decoration: _inputDecoration('Dimensions (e.g. 5m x 2.5m)'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Pricing() {
    return _buildStep(
      'Pricing & Hours',
      'Set your hourly rate and availability',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Hourly Rate (in your local currency)'),
          ),
          const SizedBox(height: 8),
          const Text(
            '💡 Tip: Based on your area, we recommend 30–60 ETB/hr (or \$2–\$5/hr)',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          const Text('Available Days', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              return GestureDetector(
                onTap: () => setState(() => _availableDays[i] = !_availableDays[i]),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _availableDays[i] ? AppColors.primary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _availableDays[i] ? AppColors.primary : AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      _dayNames[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _availableDays[i] ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Payout() {
    return _buildStep(
      'Payout Details',
      'How would you like to receive your earnings?',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payout Method', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ..._payoutMethods.map((method) {
            final isSelected = _payoutMethod == method;
            return GestureDetector(
              onTap: () => setState(() => _payoutMethod = method),
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
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      method,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          TextField(
            controller: _payoutAccountController,
            decoration: _inputDecoration('Account Number / Phone / Email'),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.available.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.available.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.available, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Earnings are paid out within 24 hours of each completed booking. No fees for the first 3 months!',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submitListing() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.available),
            const SizedBox(height: 16),
            const Text('Listing Submitted!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Your parking space is under review. You\'ll be notified once it\'s live on ParkEase.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    filled: true,
    fillColor: Colors.white,
  );
}
