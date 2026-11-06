import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/booking_store.dart';
import '../services/host_space_store.dart';
import '../services/attendant_store.dart';

class AttendantScannerScreen extends StatefulWidget {
  const AttendantScannerScreen({super.key});

  @override
  State<AttendantScannerScreen> createState() => _AttendantScannerScreenState();
}

class _AttendantScannerScreenState extends State<AttendantScannerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  final TextEditingController _manualInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    AttendantStore.instance.addListener(_onLogUpdate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    _manualInputCtrl.dispose();
    AttendantStore.instance.removeListener(_onLogUpdate);
    super.dispose();
  }

  void _onLogUpdate() {
    if (mounted) setState(() {});
  }

  // ─── QR Detection ──────────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _processPassCode(code.trim());
        break;
      }
    }
  }

  Future<void> _processPassCode(String rawCode) async {
    setState(() => _isProcessing = true);

    await BookingStore.instance.forceReload();

    String passCode = rawCode.trim();
    DateTime? embeddedEndTime;
    String? embeddedSpot;
    String? embeddedSlot;
    String? embeddedPlate;
    int? embeddedDuration;
    double? embeddedPrice;

    if (passCode.contains('|')) {
      final parts = passCode.split('|');
      passCode = parts[0].trim();
      for (final part in parts.skip(1)) {
        final t = part.trim();
        if (t.startsWith('EXP:')) {
          final ms = int.tryParse(t.substring(4).trim());
          if (ms != null) embeddedEndTime = DateTime.fromMillisecondsSinceEpoch(ms);
        } else if (t.startsWith('SPOT:')) {
          embeddedSpot = t.substring(5).trim();
        } else if (t.startsWith('SLOT:')) {
          embeddedSlot = t.substring(5).trim();
        } else if (t.startsWith('PLATE:')) {
          embeddedPlate = t.substring(6).trim();
        } else if (t.startsWith('DUR:')) {
          embeddedDuration = int.tryParse(t.substring(4).trim());
        } else if (t.startsWith('PRICE:')) {
          embeddedPrice = double.tryParse(t.substring(6).trim());
        }
      }
    }

    final normalized = passCode.trim().toUpperCase();

    final localMatch = BookingStore.instance.bookings.where((b) {
      final qr = b.qrCodeData.toUpperCase();
      final id = b.id.toUpperCase();
      return qr == normalized ||
          id == normalized ||
          normalized.contains(id) ||
          qr.contains(normalized);
    });

    Map<String, dynamic>? details;

    if (localMatch.isNotEmpty) {
      final b = localMatch.first;
      details = {
        'id': b.id,
        'spotTitle': b.spot.title,
        'spotId': b.spot.id,
        'slotNumber': b.slotNumber,
        'vehiclePlate': b.vehiclePlate,
        'durationHours': b.durationHours,
        'totalPriceETB': b.totalPriceETB,
        'startTime': b.startTime.toIso8601String(),
        'endTime': b.endTime.toIso8601String(),
        'status': b.status.name.toUpperCase(),
        'qrCodeData': b.qrCodeData,
      };
    } else {
      Map<String, dynamic>? apiData = await ApiService.lookupPass(passCode);
      if (apiData == null) {
        final m = RegExp(r'PARKEASE-PASS-(.+)$', caseSensitive: false)
            .firstMatch(passCode);
        if (m != null) apiData = await ApiService.lookupPass(m.group(1)!);
      }

      if (apiData != null) {
        details = {
          'id': apiData['id'],
          'spotTitle': apiData['spot']?['title'] ?? 'Assigned Parking Spot',
          'spotId': apiData['spotId'] ?? apiData['spot']?['id'] ?? '',
          'slotNumber': apiData['slotNumber'] ?? 'Slot-01',
          'vehiclePlate': apiData['vehiclePlate'] ?? 'Unknown Vehicle',
          'durationHours': apiData['durationHours'] ?? 2,
          'totalPriceETB': (apiData['totalAmount'] as num?)?.toDouble() ?? 50.0,
          'startTime': apiData['startTime'] ?? DateTime.now().toIso8601String(),
          'endTime': apiData['endTime'] ??
              DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
          'status': (apiData['status'] ?? 'ACTIVE').toString().toUpperCase(),
          'qrCodeData': passCode,
        };
      } else if (_isParkEaseCode(normalized)) {
        final extractedId = _extractBookingId(normalized);
        final effectiveEnd =
            embeddedEndTime ?? DateTime.now().add(const Duration(hours: 24));
        final isEmbeddedExpired =
            embeddedEndTime != null && DateTime.now().isAfter(embeddedEndTime);
        details = {
          'id': extractedId,
          'spotTitle': embeddedSpot ?? 'ParkEase Parking',
          'spotId': '',
          'slotNumber': embeddedSlot ?? '—',
          'vehiclePlate': embeddedPlate ?? 'See pass for details',
          'durationHours': embeddedDuration ?? 1,
          'totalPriceETB': embeddedPrice ?? 0.0,
          'startTime': DateTime.now().toIso8601String(),
          'endTime': effectiveEnd.toIso8601String(),
          'status': isEmbeddedExpired ? 'EXPIRED' : 'ACTIVE',
          'qrCodeData': passCode,
        };
      }
    }

    if (!mounted) return;

    if (details != null) {
      _showVerificationModal(details);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text('Invalid or unrecognized pass: "$passCode"'),
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  // ─── Verification Modal ────────────────────────────────────────────────────

  void _showVerificationModal(Map<String, dynamic> b) {
    final status = b['status'] as String? ?? 'ACTIVE';
    final endTime = DateTime.tryParse(b['endTime'].toString());
    final now = DateTime.now();

    final bool isExpired = status == 'EXPIRED' ||
        (endTime != null &&
            now.isAfter(endTime) &&
            status != 'COMPLETED' &&
            status != 'CANCELLED');

    final displayStatus = isExpired ? 'EXPIRED' : status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                        : const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isExpired ? Icons.warning_amber_rounded : Icons.verified,
                    color: isExpired
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isExpired ? 'Session Expired' : 'Valid Parking Pass',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isExpired
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        'Booking ID: ${b['id']}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _infoRow('Vehicle Plate', b['vehiclePlate'] ?? '',
                      isHighlighted: true),
                  const Divider(height: 16),
                  _infoRow('Spot', '${b['spotTitle']} (${b['slotNumber']})'),
                  const Divider(height: 16),
                  _infoRow('Paid Duration',
                      '${b['durationHours']} hrs (${b['totalPriceETB']} ETB)'),
                  const Divider(height: 16),
                  _infoRow('Status', displayStatus, isHighlighted: isExpired),
                ],
              ),
            ),
            if (isExpired) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.error_outline,
                        color: Color(0xFFEF4444), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Parking time expired! Driver must extend time in app before entry can be verified.',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _executeCheckOut(b);
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Check Out (Exit)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isExpired
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _executeCheckIn(b);
                          },
                    icon: Icon(
                      isExpired ? Icons.block : Icons.login,
                      size: 18,
                    ),
                    label: Text(isExpired ? 'Extend Required' : 'Verify & Entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  // ─── Check In / Out (now log-aware) ────────────────────────────────────────

  void _executeCheckIn(Map<String, dynamic> b) {
    final bookingId = b['id'] as String? ?? '';
    ApiService.checkInBooking(bookingId);
    BookingStore.instance.startBookingNow(bookingId);

    AttendantStore.instance.addLogEntry(
      bookingId: bookingId,
      vehiclePlate: b['vehiclePlate'] as String? ?? 'Unknown',
      spotTitle: b['spotTitle'] as String? ?? 'Parking',
      slotNumber: b['slotNumber'] as String? ?? '—',
      action: ScanAction.entry,
      durationHours: (b['durationHours'] as num?)?.toInt() ?? 1,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF10B981),
        content: Text('Gate Opened! Vehicle checked in successfully.'),
      ),
    );
  }

  void _executeCheckOut(Map<String, dynamic> b) {
    final bookingId = b['id'] as String? ?? '';
    final spotId = b['spotId'] as String? ?? '';
    final endTime = DateTime.tryParse(b['endTime'].toString());
    final wasOverstay =
        endTime != null && DateTime.now().isAfter(endTime);

    ApiService.checkOutBooking(bookingId);
    BookingStore.instance.completeBooking(bookingId);
    if (spotId.isNotEmpty) {
      HostSpaceStore.instance.releaseBooking(spotId);
    }

    AttendantStore.instance.addLogEntry(
      bookingId: bookingId,
      vehiclePlate: b['vehiclePlate'] as String? ?? 'Unknown',
      spotTitle: b['spotTitle'] as String? ?? 'Parking',
      slotNumber: b['slotNumber'] as String? ?? '—',
      action: ScanAction.exit,
      wasOverstay: wasOverstay,
      durationHours: (b['durationHours'] as num?)?.toInt() ?? 1,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF10B981),
        content: Text('Exit Verified! Spot freed for other drivers.'),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _infoRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  bool _isParkEaseCode(String normalized) =>
      normalized.startsWith('PARKEASE-') || normalized.startsWith('PE-');

  String _extractBookingId(String normalized) {
    final m = RegExp(r'PARKEASE-PASS-(.+)$').firstMatch(normalized);
    return m?.group(1) ?? normalized;
  }

  void _showManualEntryDialog() {
    _manualInputCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Pass Code Manually'),
        content: TextField(
          controller: _manualInputCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. PARKEASE-PASS-BK-... or Booking ID',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _manualInputCtrl.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(ctx);
                _processPassCode(code);
              }
            },
            child: const Text('Lookup'),
          ),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final log = AttendantStore.instance.todayLog;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate Scanner'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            const Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scanner'),
            Tab(
              icon: Badge(
                isLabelVisible: log.isNotEmpty,
                label: Text('${log.length}'),
                child: const Icon(Icons.history_rounded),
              ),
              text: 'Shift Log',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Toggle Flash',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            tooltip: 'Flip Camera',
            onPressed: () => _controller.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: 'Type Code',
            onPressed: _showManualEntryDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        // Disable swipe on scanner tab so camera drag doesn't switch tabs
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildScannerTab(),
          _buildShiftLogTab(log),
        ],
      ),
    );
  }

  // ─── Scanner Tab ───────────────────────────────────────────────────────────

  Widget _buildScannerTab() {
    final cutOutSize = MediaQuery.of(context).size.width * 0.72;
    final cutOutOffsetY = MediaQuery.of(context).size.height * 0.18;

    return Stack(
      children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        Container(
          decoration: ShapeDecoration(
            shape: QrScannerOverlayShape(
              borderColor: AppColors.primary,
              borderRadius: 16,
              borderLength: 30,
              borderWidth: 6,
              cutOutSize: cutOutSize,
              cutOutOffsetY: cutOutOffsetY,
            ),
          ),
        ),
        Positioned(
          top: cutOutOffsetY + cutOutSize + 18,
          left: 24,
          right: 24,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Point camera at the driver QR code',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _showManualEntryDialog,
              icon: const Icon(Icons.keyboard),
              label: const Text('Enter Code Manually'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shift Log Tab ─────────────────────────────────────────────────────────

  Widget _buildShiftLogTab(List<ScanLogEntry> log) {
    final entries = AttendantStore.instance.todayEntries;
    final exits = AttendantStore.instance.todayExits;
    final overstays = AttendantStore.instance.todayOverstays;

    return Column(
      children: [
        // Summary strip
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _summaryChip('IN', entries, const Color(0xFF10B981)),
              const SizedBox(width: 10),
              _summaryChip('OUT', exits, const Color(0xFF2563EB)),
              const SizedBox(width: 10),
              _summaryChip('⚠ OVERSTAY', overstays, const Color(0xFFEF4444)),
              const Spacer(),
              Text(
                _todayLabel(),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Log list
        Expanded(
          child: log.isEmpty
              ? _emptyLog()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: log.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _logCard(log[i]),
                ),
        ),
      ],
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _logCard(ScanLogEntry entry) {
    final isEntry = entry.action == ScanAction.entry;
    final color = entry.wasOverstay
        ? const Color(0xFFEF4444)
        : isEntry
            ? const Color(0xFF10B981)
            : const Color(0xFF2563EB);

    final actionLabel = isEntry ? 'IN' : 'OUT';
    final timeStr =
        '${entry.scannedAt.hour.toString().padLeft(2, '0')}:${entry.scannedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Action badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isEntry ? Icons.login_rounded : Icons.logout_rounded,
                  color: color,
                  size: 18,
                ),
                Text(
                  actionLabel,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.vehiclePlate,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.spotTitle}  •  ${entry.slotNumber}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                if (entry.wasOverstay) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '⚠ Overstay exit',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
              Text(
                '${entry.durationHours}h booked',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyLog() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          const Text(
            'No scans yet today',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Scan a driver pass to start logging activity',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${now.day} ${months[now.month - 1]}';
  }
}

// ─── QR Overlay ───────────────────────────────────────────────────────────────

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;
  final double? cutOutOffsetY;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
    this.cutOutOffsetY,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final centreX = rect.left + width / 2;
    final centreY = cutOutOffsetY != null
        ? rect.top + cutOutOffsetY! + cutOutSize / 2
        : rect.top + height / 2;

    final cutOutRect = Rect.fromCenter(
      center: Offset(centreX, centreY),
      width: cutOutSize,
      height: cutOutSize,
    );

    canvas.saveLayer(rect, Paint());
    canvas.drawRect(rect, backgroundPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    final rrect =
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius));
    final path = Path()
      ..moveTo(rrect.left, rrect.top + borderLength)
      ..lineTo(rrect.left, rrect.top + borderRadius)
      ..arcToPoint(Offset(rrect.left + borderRadius, rrect.top),
          radius: Radius.circular(borderRadius))
      ..lineTo(rrect.left + borderLength, rrect.top)
      ..moveTo(rrect.right - borderLength, rrect.top)
      ..lineTo(rrect.right - borderRadius, rrect.top)
      ..arcToPoint(Offset(rrect.right, rrect.top + borderRadius),
          radius: Radius.circular(borderRadius))
      ..lineTo(rrect.right, rrect.top + borderLength)
      ..moveTo(rrect.right, rrect.bottom - borderLength)
      ..lineTo(rrect.right, rrect.bottom - borderRadius)
      ..arcToPoint(Offset(rrect.right - borderRadius, rrect.bottom),
          radius: Radius.circular(borderRadius))
      ..lineTo(rrect.right - borderLength, rrect.bottom)
      ..moveTo(rrect.left + borderLength, rrect.bottom)
      ..lineTo(rrect.left + borderRadius, rrect.bottom)
      ..arcToPoint(Offset(rrect.left, rrect.bottom - borderRadius),
          radius: Radius.circular(borderRadius))
      ..lineTo(rrect.left, rrect.bottom - borderLength);

    canvas.drawPath(path, boxPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
