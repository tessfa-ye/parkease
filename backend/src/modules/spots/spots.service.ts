import { prisma } from '../../config/db';

export interface SpotQueryParams {
  lat?: number;
  lng?: number;
  radiusKm?: number;
  spotType?: string;
  amenity?: string;
  search?: string;
}

// Initial seed / fallback sample spots matching our Flutter model
const fallbackSpots = [
  {
    id: '1',
    title: 'Bole Medhanealem Parking',
    address: 'Bole Road, Medhanealem',
    city: 'Addis Ababa',
    countryCode: 'ET',
    latitude: 9.0105,
    longitude: 38.7614,
    pricePerHour: 50,
    totalSpots: 120,
    availableSpots: 45,
    rating: 4.8,
    reviewCount: 312,
    spotType: 'COMMERCIAL',
    status: 'AVAILABLE',
    amenities: ['Security', 'Covered', 'CCTV', 'Telebirr Pay'],
    imageUrl: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=600',
  },
  {
    id: '2',
    title: 'Kazanchis Business Garage',
    address: 'Kazanchis, near UNECA',
    city: 'Addis Ababa',
    countryCode: 'ET',
    latitude: 9.0227,
    longitude: 38.7469,
    pricePerHour: 40,
    totalSpots: 80,
    availableSpots: 8,
    rating: 4.3,
    reviewCount: 187,
    spotType: 'GOVERNMENT',
    status: 'FILLING_FAST',
    amenities: ['Security', 'CCTV', 'Telebirr Pay'],
    imageUrl: 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=600',
  },
  {
    id: '3',
    title: 'Meskel Square Underground',
    address: 'Meskel Square Hub',
    city: 'Addis Ababa',
    countryCode: 'ET',
    latitude: 9.0094,
    longitude: 38.7612,
    pricePerHour: 60,
    totalSpots: 200,
    availableSpots: 0,
    rating: 4.6,
    reviewCount: 521,
    spotType: 'GOVERNMENT',
    status: 'FULL',
    amenities: ['Security', 'Covered', 'CCTV', 'EV Charging'],
    imageUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=600',
  },
  {
    id: '4',
    title: "Abebe's Home Driveway",
    address: 'Bole Sub-City, Wereda 03',
    city: 'Addis Ababa',
    countryCode: 'ET',
    latitude: 9.0150,
    longitude: 38.7640,
    pricePerHour: 30,
    totalSpots: 2,
    availableSpots: 2,
    rating: 4.9,
    reviewCount: 23,
    spotType: 'PRIVATE_HOST',
    status: 'AVAILABLE',
    amenities: ['Covered', 'Gated'],
    imageUrl: 'https://images.unsplash.com/photo-1572120360610-d971b9d7767c?w=600',
    hostName: 'Abebe K.',
    hostPhotoUrl: 'https://i.pravatar.cc/100?img=12',
    hostRating: 4.9,
  },
  {
    id: '5',
    title: 'Piassa City Center Lot',
    address: 'Churchill Avenue, Piassa',
    city: 'Addis Ababa',
    countryCode: 'ET',
    latitude: 9.0350,
    longitude: 38.7469,
    pricePerHour: 35,
    totalSpots: 60,
    availableSpots: 22,
    rating: 4.1,
    reviewCount: 98,
    spotType: 'GOVERNMENT',
    status: 'AVAILABLE',
    amenities: ['Security', 'Open Air'],
    imageUrl: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=600',
  },
];

/**
 * Calculates distance in Kilometers between two coordinates using Haversine formula
 */
function calculateDistanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371; // Radius of the Earth in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Number((R * c).toFixed(2));
}

export class SpotsService {
  static async getSpots(query: SpotQueryParams) {
    let spots: any[] = [];

    try {
      spots = await prisma.parkingSpot.findMany({
        include: { host: { select: { name: true, phone: true } } },
      });
    } catch (err) {
      // Use fallback if DB not populated yet
      spots = fallbackSpots;
    }

    if (spots.length === 0) {
      spots = fallbackSpots;
    }

    // Apply distance calculations if user coordinates provided
    let results = spots.map((spot) => {
      const distanceKm =
        query.lat && query.lng
          ? calculateDistanceKm(query.lat, query.lng, spot.latitude, spot.longitude)
          : 1.0;
      return {
        ...spot,
        distanceKm,
      };
    });

    // Filter by spotType
    if (query.spotType && query.spotType.toLowerCase() !== 'all') {
      const targetType = query.spotType.toUpperCase();
      results = results.filter((s) => s.spotType === targetType);
    }

    // Filter by amenity
    if (query.amenity) {
      results = results.filter((s) =>
        s.amenities && s.amenities.some((a: string) => a.toLowerCase().includes(query.amenity!.toLowerCase()))
      );
    }

    // Filter by search text
    if (query.search) {
      const q = query.search.toLowerCase();
      results = results.filter(
        (s) => s.title.toLowerCase().includes(q) || s.address.toLowerCase().includes(q)
      );
    }

    // Filter by radius if provided
    if (query.radiusKm) {
      results = results.filter((s) => s.distanceKm <= query.radiusKm!);
    }

    // Sort by nearest first
    results.sort((a, b) => a.distanceKm - b.distanceKm);

    return results;
  }

  static async getSpotById(id: string) {
    try {
      const spot = await prisma.parkingSpot.findUnique({
        where: { id },
        include: { host: true },
      });
      if (spot) return spot;
    } catch (err) {
      // Fallback
    }

    const fallback = fallbackSpots.find((s) => s.id === id);
    if (!fallback) {
      throw new Error(`Parking spot with ID ${id} not found`);
    }
    return fallback;
  }
}
