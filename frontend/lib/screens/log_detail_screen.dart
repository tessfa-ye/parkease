import 'package:flutter/material.dart';
import '../services/attendant_store.dart';
import '../theme/app_theme.dart';

class LogDetailScreen extends StatelessWidget {
  final ScanLogEntry entry;

  const LogDetailScreen({Key? key, required this.entry}) : super(key: key);

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _shareLog(BuildContext context) {
    // Sharing placeholder – show a snack bar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing not configured.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEntry = entry.action == ScanAction.entry;
    final Color color = entry.wasOverstay
        ? const Color(0xFFEF4444)
        : isEntry
            ? const Color(0xFF10B981)
            : const Color(0xFF2563EB);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Log',
            onPressed: () => _shareLog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header badge
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEntry ? Icons.login_rounded : Icons.logout_rounded,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.vehiclePlate,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.spotTitle} • ${entry.slotNumber}',
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            // Details list
            _detailRow('Log ID', entry.id),
            _detailRow('Booking ID', entry.bookingId),
            _detailRow('Action', entry.action.name.toUpperCase()),
            _detailRow('Scanned At', _formatDateTime(entry.scannedAt)),
            _detailRow('Duration', '${entry.durationHours} hour(s)'),
            if (entry.wasOverstay) _detailRow('Overstay', 'Yes'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
