import 'package:flutter/material.dart';

/// Activity log showing check-ins, check-outs, and lot events
class AttendantActivityScreen extends StatelessWidget {
  const AttendantActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _activityItem(
            'Check-in',
            'AA-1234',
            'Slot 12',
            '14:30',
            Icons.login,
            Colors.green,
          ),
          _activityItem(
            'Check-out',
            'AA-5678',
            'Slot 18',
            '14:25',
            Icons.logout,
            Colors.red,
          ),
          _activityItem(
            'Check-in',
            'AA-9012',
            'Slot 05',
            '14:15',
            Icons.login,
            Colors.green,
          ),
          _activityItem(
            'Check-out',
            'AA-3456',
            'Slot 22',
            '14:05',
            Icons.logout,
            Colors.red,
          ),
          _activityItem(
            'Check-in',
            'AA-7890',
            'Slot 08',
            '13:50',
            Icons.login,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _activityItem(
    String action,
    String plate,
    String slot,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(plate),
          subtitle: Text('$slot • $time'),
          trailing: Text(
            action,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
