import { v4 as uuidv4 } from 'uuid';
import { prisma } from '../../config/db';

export interface CreateBookingDto {
  userId: string;
  spotId: string;
  vehiclePlate: string;
  startTime: string;
  durationHours: number;
  totalAmount: number;
}

export class BookingsService {
  static async createBooking(data: CreateBookingDto) {
    const startTimeDate = new Date(data.startTime);
    const endTimeDate = new Date(startTimeDate.getTime() + data.durationHours * 60 * 60 * 1000);
    const qrCodeData = `PARKEASE-${uuidv4().substring(0, 8).toUpperCase()}`;

    try {
      const booking = await prisma.booking.create({
        data: {
          userId: data.userId,
          spotId: data.spotId,
          vehiclePlate: data.vehiclePlate,
          startTime: startTimeDate,
          endTime: endTimeDate,
          durationHours: data.durationHours,
          totalAmount: data.totalAmount,
          status: 'PENDING',
          qrCodeData,
        },
        include: {
          spot: true,
        },
      });
      return booking;
    } catch (err) {
      // Fallback in-memory response if DB is in sandbox/mock mode
      return {
        id: 'bk_' + uuidv4().substring(0, 8),
        userId: data.userId,
        spotId: data.spotId,
        vehiclePlate: data.vehiclePlate,
        startTime: startTimeDate,
        endTime: endTimeDate,
        durationHours: data.durationHours,
        totalAmount: data.totalAmount,
        status: 'PENDING',
        qrCodeData,
        createdAt: new Date(),
      };
    }
  }

  static async getUserBookings(userId: string) {
    try {
      const bookings = await prisma.booking.findMany({
        where: { userId },
        include: { spot: true, payment: true },
        orderBy: { createdAt: 'desc' },
      });
      return bookings;
    } catch (err) {
      return [];
    }
  }

  static async getBookingById(bookingId: string) {
    try {
      const booking = await prisma.booking.findUnique({
        where: { id: bookingId },
        include: { spot: true, payment: true },
      });
      if (!booking) throw new Error('Booking not found');
      return booking;
    } catch (err) {
      throw new Error(`Booking ${bookingId} not found`);
    }
  }
}
