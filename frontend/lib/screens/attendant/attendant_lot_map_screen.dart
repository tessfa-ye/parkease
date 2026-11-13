import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Shows heatmap of parking lot spots with real-time occupancy
class AttendantLotMapScreen extends StatelessWidget {
  const AttendantLotMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lot Map'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Spot Heatmap',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Grid of spots
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _spotRow(['A', 'A', 'F', 'F', 'A']),
                  const SizedBox(height: 8),
                  _spotRow(['A', 'O', 'O', 'A', 'A']),
                  const SizedBox(height: 8),
                  _spotRow(['F', 'O', 'O', 'O', 'A']),
                  const SizedBox(height: 8),
                  _spotRow(['A', 'A', 'O', 'F', 'A']),
                  const SizedBox(height: 20),

                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _legendItem(Colors.green, 'Available'),
                      _legendItem(Colors.orange, 'Filling Fast'),
                      _legendItem(Colors.red, 'Occupied'),
                      _legendItem(Colors.grey, 'Maintenance'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _spotRow(List<String> statuses) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: statuses
          .map((status) => _spotBox(status))
          .toList(),
    );
  }

  Widget _spotBox(String status) {
    Color color;
    switch (status) {
      case 'A':
        color = Colors.green;
        break;
      case 'F':
        color = Colors.orange;
        break;
      case 'O':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          status,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
