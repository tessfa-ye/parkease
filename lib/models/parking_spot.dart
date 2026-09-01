import 'package:flutter/material.dart';

enum SpotStatus { available, fillingFast, full }

class ParkingSpot {
  final String id;
  final String title;
  final String address;
  final double distanceKm;
  final double rating;
  final double pricePerHourETB;
  final SpotStatus status;
  final int totalSlots;
  final int availableSlots;
  final List<String> amenities;
  final String imageUrl;

  const ParkingSpot({
    required this.id,
    required this.title,
    required this.address,
    required this.distanceKm,
    required this.rating,
    required this.pricePerHourETB,
    required this.status,
    required this.totalSlots,
    required this.availableSlots,
    required this.amenities,
    required this.imageUrl,
  });

  String get statusLabel {
    switch (status) {
      case SpotStatus.available:
        return 'AVAILABLE';
      case SpotStatus.fillingFast:
        return 'FILLING FAST';
      case SpotStatus.full:
        return 'FULL';
    }
  }

  Color get statusColor {
    switch (status) {
      case SpotStatus.available:
        return const Color(0xFF10B981);
      case SpotStatus.fillingFast:
        return const Color(0xFFF59E0B);
      case SpotStatus.full:
        return const Color(0xFF374151);
    }
  }

  static List<ParkingSpot> get sampleSpots => [
    const ParkingSpot(
      id: 'spot_bole',
      title: 'Bole Medhanealem Mall Parking',
      address: 'Bole Road, Next to Medhanealem Church, Addis Ababa',
      distanceKm: 0.5,
      rating: 4.8,
      pricePerHourETB: 50.00,
      status: SpotStatus.available,
      totalSlots: 150,
      availableSlots: 42,
      amenities: ['EV Charging', '24/7 Security', 'Covered', 'Telebirr Pay'],
      imageUrl: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a',
    ),
    const ParkingSpot(
      id: 'spot_kazanchis',
      title: 'Kazanchis Business District Garage',
      address: 'Kazanchis, Near UNECA & Interlux Hotel, Addis Ababa',
      distanceKm: 1.2,
      rating: 4.6,
      pricePerHourETB: 40.00,
      status: SpotStatus.fillingFast,
      totalSlots: 100,
      availableSlots: 8,
      amenities: ['CCTV Security', 'CBE Birr Accepted', 'Valet Service'],
      imageUrl: 'https://images.unsplash.com/photo-1590674899484-d5640e854abe',
    ),
    const ParkingSpot(
      id: 'spot_meskel',
      title: 'Meskel Square Underground Parking',
      address: 'Meskel Square Hub, Exhibition Center Area, Addis Ababa',
      distanceKm: 2.1,
      rating: 4.9,
      pricePerHourETB: 60.00,
      status: SpotStatus.available,
      totalSlots: 300,
      availableSlots: 115,
      amenities: ['Covered', 'Direct LRT Access', 'EV Charger', '24/7 Security'],
      imageUrl: 'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98',
    ),
    const ParkingSpot(
      id: 'spot_piassa',
      title: 'Piassa City Center Parking Lot',
      address: 'Churchill Avenue, Near Eliana Hotel, Piassa, Addis Ababa',
      distanceKm: 3.4,
      rating: 4.3,
      pricePerHourETB: 35.00,
      status: SpotStatus.full,
      totalSlots: 80,
      availableSlots: 0,
      amenities: ['Central City Access', 'CCTV Security'],
      imageUrl: 'https://images.unsplash.com/photo-1517524008697-84bbe3c3fd98',
    ),
  ];
}
