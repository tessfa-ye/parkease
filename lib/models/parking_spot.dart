import 'package:flutter/material.dart';
import '../utils/locale_utils.dart';

/// Spot type — who owns/operates the parking space.
enum SpotType { government, commercial, privateHost }

/// Availability status of a parking spot.
enum SpotStatus { available, fillingFast, full }

class ParkingSpot {
  final String id;
  final String title;
  final String address;
  final String city;
  final String countryCode; // ISO 2-letter e.g. 'ET', 'US', 'KE'
  final double latitude;
  final double longitude;
  final double pricePerHour;
  final double distanceKm;
  final int totalSpots;
  final int availableSpots;
  final double rating;
  final int reviewCount;
  final SpotType spotType;
  final SpotStatus status;
  final List<String> amenities;
  final String imageUrl;

  // Private host fields (only for spotType == privateHost)
  final String? hostName;
  final String? hostPhotoUrl;
  final double? hostRating;

  const ParkingSpot({
    required this.id,
    required this.title,
    required this.address,
    required this.city,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.pricePerHour,
    required this.distanceKm,
    required this.totalSpots,
    required this.availableSpots,
    required this.rating,
    required this.reviewCount,
    required this.spotType,
    required this.status,
    required this.amenities,
    required this.imageUrl,
    this.hostName,
    this.hostPhotoUrl,
    this.hostRating,
  });

  String get currencySymbol => LocaleUtils.currencyDisplaySymbol(countryCode);
  String get distanceUnit => LocaleUtils.distanceUnit(countryCode);
  String get formattedPrice => '${LocaleUtils.currencyDisplaySymbol(countryCode)} ${pricePerHour.toInt()}/hr';
  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} $distanceUnit';

  Color get statusColor {
    switch (status) {
      case SpotStatus.available: return const Color(0xFF10B981);
      case SpotStatus.fillingFast: return const Color(0xFFF59E0B);
      case SpotStatus.full: return const Color(0xFFBA1A1A);
    }
  }

  String get statusLabel {
    switch (status) {
      case SpotStatus.available: return 'AVAILABLE';
      case SpotStatus.fillingFast: return 'FILLING FAST';
      case SpotStatus.full: return 'FULL';
    }
  }

  String get spotTypeLabel {
    switch (spotType) {
      case SpotType.government: return 'GOVERNMENT';
      case SpotType.commercial: return 'COMMERCIAL';
      case SpotType.privateHost: return 'PRIVATE HOST';
    }
  }

  Color get spotTypeColor {
    switch (spotType) {
      case SpotType.government: return const Color(0xFF2563EB);
      case SpotType.commercial: return const Color(0xFF7C3AED);
      case SpotType.privateHost: return const Color(0xFFEA580C);
    }
  }

  // Sample spots — globally aware (Ethiopia + Kenya + USA)
  static List<ParkingSpot> get sampleSpots => [
    const ParkingSpot(
      id: '1',
      title: 'Bole Medhanealem Parking',
      address: 'Bole Road, Medhanealem',
      city: 'Addis Ababa',
      countryCode: 'ET',
      latitude: 9.0105,
      longitude: 38.7614,
      pricePerHour: 50,
      distanceKm: 0.5,
      totalSpots: 120,
      availableSpots: 45,
      rating: 4.8,
      reviewCount: 312,
      spotType: SpotType.commercial,
      status: SpotStatus.available,
      amenities: ['Security', 'Covered', 'CCTV', 'Telebirr Pay'],
      imageUrl: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=600',
    ),
    const ParkingSpot(
      id: '2',
      title: 'Kazanchis Business Garage',
      address: 'Kazanchis, near UNECA',
      city: 'Addis Ababa',
      countryCode: 'ET',
      latitude: 9.0227,
      longitude: 38.7469,
      pricePerHour: 40,
      distanceKm: 1.2,
      totalSpots: 80,
      availableSpots: 8,
      rating: 4.3,
      reviewCount: 187,
      spotType: SpotType.government,
      status: SpotStatus.fillingFast,
      amenities: ['Security', 'CCTV', 'Telebirr Pay'],
      imageUrl: 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=600',
    ),
    const ParkingSpot(
      id: '3',
      title: 'Meskel Square Underground',
      address: 'Meskel Square Hub',
      city: 'Addis Ababa',
      countryCode: 'ET',
      latitude: 9.0094,
      longitude: 38.7612,
      pricePerHour: 60,
      distanceKm: 2.1,
      totalSpots: 200,
      availableSpots: 0,
      rating: 4.6,
      reviewCount: 521,
      spotType: SpotType.government,
      status: SpotStatus.full,
      amenities: ['Security', 'Covered', 'CCTV', 'EV Charging'],
      imageUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=600',
    ),
    ParkingSpot(
      id: '4',
      title: "Abebe's Home Driveway",
      address: 'Bole Sub-City, Wereda 03',
      city: 'Addis Ababa',
      countryCode: 'ET',
      latitude: 9.0150,
      longitude: 38.7640,
      pricePerHour: 30,
      distanceKm: 0.3,
      totalSpots: 2,
      availableSpots: 2,
      rating: 4.9,
      reviewCount: 23,
      spotType: SpotType.privateHost,
      status: SpotStatus.available,
      amenities: ['Covered', 'Gated'],
      imageUrl: 'https://images.unsplash.com/photo-1572120360610-d971b9d7767c?w=600',
      hostName: 'Abebe K.',
      hostPhotoUrl: 'https://i.pravatar.cc/100?img=12',
      hostRating: 4.9,
    ),
    const ParkingSpot(
      id: '5',
      title: 'Piassa City Center Lot',
      address: 'Churchill Avenue, Piassa',
      city: 'Addis Ababa',
      countryCode: 'ET',
      latitude: 9.0350,
      longitude: 38.7469,
      pricePerHour: 35,
      distanceKm: 3.4,
      totalSpots: 60,
      availableSpots: 22,
      rating: 4.1,
      reviewCount: 98,
      spotType: SpotType.government,
      status: SpotStatus.available,
      amenities: ['Security', 'Open Air'],
      imageUrl: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=600',
    ),
  ];
}
