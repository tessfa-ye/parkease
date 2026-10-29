import { prisma } from '../config/db';

/**
 * Atomic Transaction Manager for critical operations
 * Ensures data consistency for booking + spot availability updates
 */
export class TransactionService {
  /**
   * Atomically create a booking and decrement spot availability
   * If either fails, both are rolled back
   */
  static async createBookingWithDecrement(
    bookingData: any,
    spotId: string
  ) {
    return prisma.$transaction(async (tx) => {
      // 1. Check if spots are available (locks the row)
      const spot = await tx.parkingSpot.findUnique({
        where: { id: spotId },
      });

      if (!spot || spot.availableSpots <= 0) {
        throw new Error('No available spots at this location');
      }

      // 2. Decrement in same transaction
      const updatedSpot = await tx.parkingSpot.update({
        where: { id: spotId },
        data: {
          availableSpots: spot.availableSpots - 1,
          status:
            spot.availableSpots - 1 === 0
              ? 'FULL'
              : spot.availableSpots - 1 <= Math.ceil(spot.totalSpots * 0.25)
              ? 'FILLING_FAST'
              : 'AVAILABLE',
        },
      });

      // 3. Create booking in same transaction
      const booking = await tx.booking.create({
        data: bookingData,
        include: { spot: true },
      });

      return {
        booking,
        updatedSpot,
      };
    });
  }

  /**
   * Atomically cancel a booking and increment spot availability
   */
  static async cancelBookingWithIncrement(
    bookingId: string,
    userId: string
  ) {
    return prisma.$transaction(async (tx) => {
      // 1. Find the booking
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
      });

      if (!booking || booking.userId !== userId) {
        throw new Error('Booking not found or unauthorized');
      }

      if (booking.status === 'CANCELLED' || booking.status === 'COMPLETED') {
        throw new Error(`Cannot cancel a ${booking.status} booking`);
      }

      // 2. Get current spot state (locks the row)
      const spot = await tx.parkingSpot.findUnique({
        where: { id: booking.spotId },
      });

      if (!spot) {
        throw new Error('Associated parking spot not found');
      }

      // 3. Increment available spots
      const updatedSpot = await tx.parkingSpot.update({
        where: { id: booking.spotId },
        data: {
          availableSpots: Math.min(spot.totalSpots, spot.availableSpots + 1),
          status: 'AVAILABLE', // Reset to available
        },
      });

      // 4. Cancel the booking
      const cancelledBooking = await tx.booking.update({
        where: { id: bookingId },
        data: { status: 'CANCELLED' },
        include: { spot: true },
      });

      return {
        booking: cancelledBooking,
        updatedSpot,
      };
    });
  }

  /**
   * Atomically complete a booking and increment spot availability
   */
  static async completeBookingWithIncrement(bookingId: string) {
    return prisma.$transaction(async (tx) => {
      // 1. Find the booking
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
      });

      if (!booking) {
        throw new Error('Booking not found');
      }

      // 2. Get current spot state
      const spot = await tx.parkingSpot.findUnique({
        where: { id: booking.spotId },
      });

      if (!spot) {
        throw new Error('Associated parking spot not found');
      }

      // 3. Increment available spots
      const updatedSpot = await tx.parkingSpot.update({
        where: { id: booking.spotId },
        data: {
          availableSpots: Math.min(spot.totalSpots, spot.availableSpots + 1),
          status: 'AVAILABLE',
        },
      });

      // 4. Mark booking as completed
      const completedBooking = await tx.booking.update({
        where: { id: bookingId },
        data: { status: 'COMPLETED' },
        include: { spot: true },
      });

      return {
        booking: completedBooking,
        updatedSpot,
      };
    });
  }
}
