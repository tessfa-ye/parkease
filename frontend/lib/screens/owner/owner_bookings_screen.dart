import 'package:flutter/material.dart';

/// Owner's bookings/reservations screen
class OwnerBookingsScreen extends StatelessWidget {
  const OwnerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _bookingCard(
            'John Doe',
            'AA-1234',
            'Home Garage - Slot 1',
            'Today • 2 hours',
            100,
            true,
          ),
          const SizedBox(height: 12),
          _bookingCard(
            'Jane Smith',
            'AA-5678',
            'Parking Lot - Slot 5',
            'Today • 4 hours',
            200,
            true,
          ),
          const SizedBox(height: 12),
          _bookingCard(
            'Mike Johnson',
            'AA-9012',
            'Office Parking - Slot 3',
            'Tomorrow • 8 hours',
            400,
            false,
          ),
          const SizedBox(height: 12),
          _bookingCard(
            'Sarah Wilson',
            'AA-3456',
            'Home Garage - Slot 2',
            'Yesterday • 6 hours',
            300,
            false,
          ),
        ],
      ),
    );
  }

  Widget _bookingCard(
    String name,
    String plate,
    String location,
    String timing,
    int amount,
    bool isActive,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.blue[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Completed',
                    style: TextStyle(
                      color: isActive ? Colors.blue : Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              location,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timing,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '$amount Br',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
