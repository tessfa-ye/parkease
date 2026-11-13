import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// QR code scanner and check-in interface for attendants
class AttendantCheckinScreen extends StatefulWidget {
  const AttendantCheckinScreen({super.key});

  @override
  State<AttendantCheckinScreen> createState() => _AttendantCheckinScreenState();
}

class _AttendantCheckinScreenState extends State<AttendantCheckinScreen> {
  final TextEditingController _qrController = TextEditingController();

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Check-in'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // QR Scanner placeholder
          Card(
            elevation: 2,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_2,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Point camera at QR code',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Manual entry option
          Text(
            'Or enter manually',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _qrController,
            decoration: InputDecoration(
              hintText: 'Enter pass code or booking ID',
              prefixIcon: const Icon(Icons.receipt),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Submit button
          ElevatedButton(
            onPressed: () => _handleCheckin(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Confirm Check-in'),
          ),
          const SizedBox(height: 20),

          // Recent check-ins
          const Text(
            'Recent Check-ins',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _checkinItem('AA-1234', 'Slot 12', '2 min ago', true),
          _checkinItem('AA-5678', 'Slot 18', '5 min ago', true),
          _checkinItem('AA-9012', 'Slot 05', '12 min ago', true),
        ],
      ),
    );
  }

  void _handleCheckin() {
    final passCode = _qrController.text;
    if (passCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a pass code')),
      );
      return;
    }

    // TODO: Call backend API to check-in vehicle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checked in: $passCode')),
    );
    _qrController.clear();
  }

  Widget _checkinItem(String plate, String slot, String time, bool success) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: success ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              success ? Icons.check : Icons.close,
              color: success ? Colors.green : Colors.red,
            ),
          ),
          title: Text(plate),
          subtitle: Text('$slot • $time'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        ),
      ),
    );
  }
}
