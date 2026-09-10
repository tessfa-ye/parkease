import 'parking_spot.dart';

enum BookingStatus { active, completed, cancelled }

class Booking {
  final String id;
  final ParkingSpot spot;
  final DateTime startTime;
  final DateTime endTime;
  final int durationHours;
  final double totalPriceETB;
  final String slotNumber;
  final String qrCodeData;
  final String vehiclePlate;
  final BookingStatus status;

  const Booking({
    required this.id,
    required this.spot,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.totalPriceETB,
    required this.slotNumber,
    required this.qrCodeData,
    required this.vehiclePlate,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    BookingStatus status = BookingStatus.active;
    final statusStr = (json['status'] ?? '').toString().toUpperCase();
    if (statusStr.contains('CANCEL')) {
      status = BookingStatus.cancelled;
    } else if (statusStr.contains('COMPLETE')) {
      status = BookingStatus.completed;
    } else {
      status = BookingStatus.active;
    }

    ParkingSpot spot;
    if (json['spot'] != null && json['spot'] is Map<String, dynamic>) {
      spot = ParkingSpot.fromJson(json['spot']);
    } else {
      spot = ParkingSpot.sampleSpots.firstWhere(
        (s) => s.id == json['spotId']?.toString(),
        orElse: () => ParkingSpot.sampleSpots[0],
      );
    }

    final start = json['startTime'] != null ? DateTime.tryParse(json['startTime'].toString()) ?? DateTime.now() : DateTime.now();
    final duration = (json['durationHours'] as num?)?.toInt() ?? 2;
    final end = json['endTime'] != null ? DateTime.tryParse(json['endTime'].toString()) ?? start.add(Duration(hours: duration)) : start.add(Duration(hours: duration));

    return Booking(
      id: json['id']?.toString() ?? 'BK-${DateTime.now().millisecondsSinceEpoch}',
      spot: spot,
      startTime: start,
      endTime: end,
      durationHours: duration,
      totalPriceETB: (json['totalAmount'] as num?)?.toDouble() ?? (json['totalPriceETB'] as num?)?.toDouble() ?? 50.0,
      slotNumber: json['slotNumber'] ?? 'Slot-01',
      qrCodeData: json['qrCodeData'] ?? 'PARKEASE-PASS-${json['id']}',
      vehiclePlate: json['vehiclePlate'] ?? 'Code 3 - A24561 AA',
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spot': spot.toJson(),
      'spotId': spot.id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationHours': durationHours,
      'totalAmount': totalPriceETB,
      'slotNumber': slotNumber,
      'qrCodeData': qrCodeData,
      'vehiclePlate': vehiclePlate,
      'status': status.name.toUpperCase(),
    };
  }

  Booking copyWith({
    BookingStatus? status,
    DateTime? endTime,
  }) {
    return Booking(
      id: id,
      spot: spot,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      durationHours: durationHours,
      totalPriceETB: totalPriceETB,
      slotNumber: slotNumber,
      qrCodeData: qrCodeData,
      vehiclePlate: vehiclePlate,
      status: status ?? this.status,
    );
  }

  static List<Booking> get sampleBookings => [
    Booking(
      id: 'BK-AA-8842',
      spot: ParkingSpot.sampleSpots[0],
      startTime: DateTime.now().subtract(const Duration(minutes: 45)),
      endTime: DateTime.now().add(const Duration(hours: 2, minutes: 15)),
      durationHours: 3,
      totalPriceETB: 150.00,
      slotNumber: 'Bole-14',
      qrCodeData: 'PARKEASE-AA-BK8842-BOLE14',
      vehiclePlate: 'Code 3 - A24561 AA (Toyota Vitz)',
      status: BookingStatus.active,
    ),
    Booking(
      id: 'BK-AA-7721',
      spot: ParkingSpot.sampleSpots[1],
      startTime: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      endTime: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      durationHours: 2,
      totalPriceETB: 80.00,
      slotNumber: 'Kaz-09',
      qrCodeData: 'PARKEASE-AA-BK7721-KAZ09',
      vehiclePlate: 'Code 3 - A24561 AA (Toyota Vitz)',
      status: BookingStatus.completed,
    ),
    Booking(
      id: 'BK-AA-6104',
      spot: ParkingSpot.sampleSpots[2],
      startTime: DateTime.now().subtract(const Duration(days: 5, hours: 3)),
      endTime: DateTime.now().subtract(const Duration(days: 5, hours: 1)),
      durationHours: 2,
      totalPriceETB: 120.00,
      slotNumber: 'Msk-22',
      qrCodeData: 'PARKEASE-AA-BK6104-MSK22',
      vehiclePlate: 'Code 3 - A24561 AA (Toyota Vitz)',
      status: BookingStatus.completed,
    ),
  ];
}
