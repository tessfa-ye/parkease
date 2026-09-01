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
