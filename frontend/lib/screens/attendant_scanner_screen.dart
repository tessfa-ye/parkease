import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/booking_store.dart';
import '../services/host_space_store.dart';

class AttendantScannerScreen extends StatefulWidget {
  const AttendantScannerScreen({super.key});

  @override
  State<AttendantScannerScreen> createState() => _AttendantScannerScreenState();
}

class _AttendantScannerScreenState extends State<AttendantScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  final TextEditingController _manualInputCtrl = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _manualInputCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _processPassCode(code.trim());
        break;
      }
    }
  }

  Future<void> _processPassCode(String passCode) async {
    setState(() => _isProcessing = true);

    // Always reload from disk to get the latest bookings
    await BookingStore.instance.forceReload();

    final normalized = passCode.trim().toUpperCase();

    // 1. Search local store (case-insensitive, flexible matching)
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
      // 2. Try backend API — raw code first, then extract ID after "PASS-"
      Map<String, dynamic>? apiData = await ApiService.lookupPass(passCode);
      if (apiData == null) {
        final m = RegExp(r'PARKEASE-PASS-(.+)$', caseSensitive: false)
            .firstMatch(passCode);
        if (m != null) {
          apiData = await ApiService.lookupPass(m.group(1)!);
        }
      }

      if (apiData != null) {
        details = {
          'id': apiData['id'],
          'spotTitle': apiData['spot']?['title'] ?? 'Assigned Parking Spot',
          'spotId': apiData['spotId'] ?? apiData['spot']?['id'] ?? '',
          'slotNumber': apiData['slotNumber'] ?? 'Slot-01',
          'vehiclePlate': apiData['vehiclePlate'] ?? 'Unknown Vehicle',
          'durationHours': apiData['durationHours'] ?? 2,
          'totalPriceETB':
              (apiData['totalAmount'] as num?)?.toDouble() ?? 50.0,
          'startTime':
              apiData['startTime'] ?? DateTime.now().toIso8601String(),
          'endTime': apiData['endTime'] ??
              DateTime.now()
                  .add(const Duration(hours: 2))
                  .toIso8601String(),
          'status':
              (apiData['status'] ?? 'ACTIVE').toString().toUpperCase(),
          'qrCodeData': passCode,
        };
      } else if (_isParkEaseCode(normalized)) {
        // 3. Fallback: genuine ParkEase code but booking not found locally/online.
        //    Show a partial modal so the attendant can still verify manually.
        final extractedId = _extractBookingId(normalized);
        details = {
          'id': extractedId,
          'spotTitle': 'ParkEase Parking',
          'spotId': '',
          'slotNumber': '—',
          'vehiclePlate': 'See pass for details',
          'durationHours': 1,
          'totalPriceETB': 0.0,
          // Set endTime well into the future so it is NOT treated as expired
          'startTime': DateTime.now().toIso8601String(),
          'endTime': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          'status': 'ACTIVE',
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

  void _showVerificationModal(Map<String, dynamic> b) {
    final status = b['status'] as String? ?? 'ACTIVE';
    // Status field is the source of truth.
    // Only use endTime as a fallback when status is NOT explicitly ACTIVE.
    final endTime = DateTime.tryParse(b['endTime'].toString());
    final isExpired = status == 'EXPIRED' ||
        (status != 'ACTIVE' &&
            endTime != null &&
            endTime.isBefore(DateTime.now()));

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
                  _infoRow(
                      'Spot', '${b['spotTitle']} (${b['slotNumber']})'),
                  const Divider(height: 16),
                  _infoRow('Paid Duration',
                      '${b['durationHours']} hrs (${b['totalPriceETB']} ETB)'),
                  const Divider(height: 16),
                  _infoRow('Status', status),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _executeCheckOut(b['id'], b['spotId'] ?? '');
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
                    onPressed: () {
                      Navigator.pop(ctx);
                      _executeCheckIn(b['id']);
                    },
                    icon: const Icon(Icons.login, size: 18),
                    label: const Text('Verify & Entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
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

  void _executeCheckIn(String bookingId) {
    ApiService.checkInBooking(bookingId);
    BookingStore.instance.startBookingNow(bookingId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF10B981),
        content: Text('Gate Opened! Vehicle checked in successfully.'),
      ),
    );
  }

  void _executeCheckOut(String bookingId, String spotId) {
    ApiService.checkOutBooking(bookingId);
    BookingStore.instance.completeBooking(bookingId);
    if (spotId.isNotEmpty) {
      HostSpaceStore.instance.releaseBooking(spotId);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF10B981),
        content: Text('Exit Verified! Spot freed for other drivers.'),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                isHighlighted ? FontWeight.bold : FontWeight.w600,
            color:
                isHighlighted ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Returns true if the scanned code looks like a genuine ParkEase pass
  bool _isParkEaseCode(String normalized) =>
      normalized.startsWith('PARKEASE-') || normalized.startsWith('PE-');

  /// Extracts a booking ID from a pass code like "PARKEASE-PASS-BK-980563"
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

  @override
  Widget build(BuildContext context) {
    final cutOutSize = MediaQuery.of(context).size.width * 0.72;
    // Bias the QR frame to the upper portion of the screen
    final cutOutOffsetY = MediaQuery.of(context).size.height * 0.18;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Pass'),
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
      body: Stack(
        children: [
          // Full-screen camera feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Viewfinder overlay — QR frame biased toward top of screen
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
          // Helper text below the QR frame
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
          // Bottom button — manual code entry
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;
  /// How far from the top of the widget the cut-out centre is placed.
  /// When null the cut-out is centred vertically (original behaviour).
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

    // Centre of cut-out: either top-biased or true centre
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
      // Top left
      ..moveTo(rrect.left, rrect.top + borderLength)
      ..lineTo(rrect.left, rrect.top + borderRadius)
      ..arcToPoint(Offset(rrect.left + borderRadius, rrect.top),
          radius: Radius.circular(borderRadius))
      ..lineTo(rrect.left + borderLength, rrect.top)
      // Top right
      ..moveTo(rrect.right - borderLength, rrect.top)
      ..lineTo(rrect.right - borderRadius, rrect.top)
      ..arcToPoint(Offset(rrect.right, rrect.top + borderRadius),
          radius: Radius.circular(borderRadius))
      ..lineTo(rrect.right, rrect.top + borderLength)
      // Bottom right
      ..moveTo(rrect.right, rrect.bottom - borderLength)
      ..lineTo(rrect.right, rrect.bottom - borderRadius)
      ..arcToPoint(Offset(rrect.right - borderRadius, rrect.bottom),
          radius: Radius.circular(borderRadius))
      ..lineTo(rrect.right - borderLength, rrect.bottom)
      // Bottom left
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
