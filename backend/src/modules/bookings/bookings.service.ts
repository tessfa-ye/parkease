import { v4 as uuidv4 } from 'uuid';
import { prisma } from '../../config/db';
import { SpotsService } from '../spots/spots.service';

export interface CreateBookingDto {
  userId: string;
  spotId: string;
  vehiclePlate: string;
  startTime: string;
  durationHours: number;
  totalAmount: number;
}

// In-memory persistent bookings list for sandbox / fallback mode
const fallbackBookings: any[] = [
  {
    id: 'BK-AA-8842',
    userId: 'guest_user',
    spotId: '1',
    vehiclePlate: 'Code 3 - A24561 AA (Toyota Vitz)',
    startTime: new Date(Date.now() - 45 * 60 * 1000),
    endTime: new Date(Date.now() + 135 * 60 * 1000),
    durationHours: 3,
    totalAmount: 150.0,
    status: 'ACTIVE',
    qrCodeData: 'PARKEASE-AA-BK8842-BOLE14',
    slotNumber: 'Bole-14',
    createdAt: new Date(Date.now() - 45 * 60 * 1000),
    spot: {
      id: '1',
      title: 'Bole Medhanealem Parking',
      address: 'Bole Road, Medhanealem',
      city: 'Addis Ababa',
      pricePerHour: 50,
      imageUrl: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=600',
    },
  },
  {
    id: 'BK-AA-7721',
    userId: 'guest_user',
    spotId: '2',
    vehiclePlate: 'Code 3 - A24561 AA (Toyota Vitz)',
    startTime: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    endTime: new Date(Date.now() - (2 * 24 * 60 * 60 * 1000 - 2 * 60 * 60 * 1000)),
    durationHours: 2,
    totalAmount: 80.0,
    status: 'COMPLETED',
    qrCodeData: 'PARKEASE-AA-BK7721-KAZ09',
    slotNumber: 'Kaz-09',
    createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    spot: {
      id: '2',
      title: 'Kazanchis Business Garage',
      address: 'Kazanchis, near UNECA',
      city: 'Addis Ababa',
      pricePerHour: 40,
      imageUrl: 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=600',
    },
  },
  {
    id: 'BK-AA-6104',
    userId: 'guest_user',
    spotId: '3',
    vehiclePlate: 'Code 3 - A24561 AA (Toyota Vitz)',
    startTime: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    endTime: new Date(Date.now() - (5 * 24 * 60 * 60 * 1000 - 2 * 60 * 60 * 1000)),
    durationHours: 2,
    totalAmount: 120.0,
    status: 'COMPLETED',
    qrCodeData: 'PARKEASE-AA-BK6104-MSK22',
    slotNumber: 'Msk-22',
    createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    spot: {
      id: '3',
      title: 'Meskel Square Underground',
      address: 'Meskel Square Hub',
      city: 'Addis Ababa',
      pricePerHour: 60,
      imageUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=600',
    },
  },
];

export class BookingsService {
  static async createBooking(data: CreateBookingDto) {
    const startTimeDate = new Date(data.startTime);
    const endTimeDate = new Date(startTimeDate.getTime() + data.durationHours * 60 * 60 * 1000);
    const bookingId = 'BK-' + uuidv4().substring(0, 8).toUpperCase();
    const qrCodeData = `PARKEASE-PASS-${bookingId}`;

    let spotDetails: any = null;
    try {
      spotDetails = await SpotsService.getSpotById(data.spotId);
    } catch (_) {
      spotDetails = {
        id: data.spotId,
        title: 'Reserved Parking Space',
        address: 'Addis Ababa',
        city: 'Addis Ababa',
        pricePerHour: data.totalAmount / data.durationHours,
        imageUrl: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=600',
      };
    }

    const fallbackBooking = {
      id: bookingId,
      userId: data.userId,
      spotId: data.spotId,
      vehiclePlate: data.vehiclePlate,
      startTime: startTimeDate,
      endTime: endTimeDate,
      durationHours: data.durationHours,
      totalAmount: data.totalAmount,
      status: 'ACTIVE',
      qrCodeData,
      slotNumber: `Slot-${Math.floor(Math.random() * 20) + 1}`,
      createdAt: new Date(),
      spot: spotDetails,
    };

    // Save into in-memory fallback list immediately
    fallbackBookings.unshift(fallbackBooking);

    // Decrement available slots on the booked parking spot
    await SpotsService.decrementAvailableSpots(data.spotId);

    try {
      const booking = await prisma.booking.create({
        data: {
          id: bookingId,
          userId: data.userId,
          spotId: data.spotId,
          vehiclePlate: data.vehiclePlate,
          startTime: startTimeDate,
          endTime: endTimeDate,
          durationHours: data.durationHours,
          totalAmount: data.totalAmount,
          status: 'CONFIRMED',
          qrCodeData,
        },
        include: {
          spot: true,
        },
      });
      return booking;
    } catch (err) {
      return fallbackBooking;
    }
  }

  static async getUserBookings(userId: string) {
    await BookingsService.syncExpiredBookings();

    try {
      const bookings = await prisma.booking.findMany({
        where: { userId },
        include: { spot: true, payment: true },
        orderBy: { createdAt: 'desc' },
      });
      if (bookings.length > 0) return bookings;
    } catch (err) {
      // Fall through to fallback
    }

    // Return fallback in-memory list
    return fallbackBookings;
  }

  static async getBookingById(bookingId: string) {
    try {
      const booking = await prisma.booking.findUnique({
        where: { id: bookingId },
        include: { spot: true, payment: true },
      });
      if (booking) return booking;
    } catch (err) {
      // Fall through to fallback
    }

    const fallback = fallbackBookings.find((b) => b.id === bookingId);
    if (!fallback) {
      throw new Error(`Booking ${bookingId} not found`);
    }
    return fallback;
  }

  static async syncExpiredBookings() {
    const now = new Date();
    for (const b of fallbackBookings) {
      if ((b.status === 'ACTIVE' || b.status === 'CONFIRMED') && new Date(b.endTime) < now) {
        b.status = 'COMPLETED';
        await SpotsService.incrementAvailableSpots(b.spotId);
      }
    }
    try {
      const expired = await prisma.booking.findMany({
        where: {
          status: { in: ['CONFIRMED', 'ACTIVE'] },
          endTime: { lt: now },
        },
      });
      for (const eb of expired) {
        await prisma.booking.update({
          where: { id: eb.id },
          data: { status: 'COMPLETED' },
        });
        await SpotsService.incrementAvailableSpots(eb.spotId);
      }
    } catch (_) {}
  }

  static async cancelBooking(bookingId: string, userId: string) {
    let spotId = '';
    const index = fallbackBookings.findIndex((b) => b.id === bookingId);
    if (index >= 0) {
      fallbackBookings[index].status = 'CANCELLED';
      spotId = fallbackBookings[index].spotId;
    }

    try {
      const updated = await prisma.booking.update({
        where: { id: bookingId },
        data: { status: 'CANCELLED' },
      });
      if (updated.spotId) spotId = updated.spotId;
    } catch (_) {}

    if (spotId) {
      await SpotsService.incrementAvailableSpots(spotId);
    }

    if (index >= 0) {
      return fallbackBookings[index];
    }
    return { id: bookingId, status: 'CANCELLED' };
  }

  static async extendBooking(bookingId: string, additionalHours: number, additionalAmount: number) {
    let updatedBooking: any = null;
    const index = fallbackBookings.findIndex((b) => b.id === bookingId);
    if (index >= 0) {
      const current = fallbackBookings[index];
      const newEndTime = new Date(new Date(current.endTime).getTime() + additionalHours * 60 * 60 * 1000);
      current.endTime = newEndTime;
      current.durationHours = (current.durationHours || 1) + additionalHours;
      current.totalAmount = (current.totalAmount || 0) + additionalAmount;
      updatedBooking = current;
    }

    try {
      const current = await prisma.booking.findUnique({ where: { id: bookingId } });
      if (current) {
        const newEndTime = new Date(new Date(current.endTime).getTime() + additionalHours * 60 * 60 * 1000);
        updatedBooking = await prisma.booking.update({
          where: { id: bookingId },
          data: {
            endTime: newEndTime,
            durationHours: current.durationHours + additionalHours,
            totalAmount: current.totalAmount + additionalAmount,
          },
          include: { spot: true, payment: true },
        });
      }
    } catch (_) {}

    return updatedBooking || { id: bookingId, additionalHours, additionalAmount };
  }

  static async getBookingByPass(passCode: string) {
    try {
      const booking = await prisma.booking.findFirst({
        where: {
          OR: [{ qrCodeData: passCode }, { id: passCode }],
        },
        include: { spot: true, user: true },
      });
      if (booking) return booking;
    } catch (_) {}

    const fallback = fallbackBookings.find((b) => b.qrCodeData === passCode || b.id === passCode);
    if (fallback) return fallback;

    throw new Error('Pass code not recognized');
  }

  static async checkInBooking(bookingId: string) {
    const index = fallbackBookings.findIndex((b) => b.id === bookingId || b.qrCodeData === bookingId);
    if (index >= 0) {
      fallbackBookings[index].status = 'ACTIVE';
      fallbackBookings[index].checkedInAt = new Date();
      return fallbackBookings[index];
    }
    try {
      const updated = await prisma.booking.update({
        where: { id: bookingId },
        data: { status: 'ACTIVE' },
        include: { spot: true },
      });
      return updated;
    } catch (_) {}
    return { id: bookingId, status: 'ACTIVE' };
  }

  static async checkOutBooking(bookingId: string) {
    let spotId = '';
    const index = fallbackBookings.findIndex((b) => b.id === bookingId || b.qrCodeData === bookingId);
    if (index >= 0) {
      fallbackBookings[index].status = 'COMPLETED';
      fallbackBookings[index].checkedOutAt = new Date();
      spotId = fallbackBookings[index].spotId;
    }
    try {
      const updated = await prisma.booking.update({
        where: { id: bookingId },
        data: { status: 'COMPLETED' },
        include: { spot: true },
      });
      if (updated.spotId) spotId = updated.spotId;
    } catch (_) {}

    if (spotId) {
      await SpotsService.incrementAvailableSpots(spotId);
    }

    if (index >= 0) return fallbackBookings[index];
    return { id: bookingId, status: 'COMPLETED' };
  }
}
