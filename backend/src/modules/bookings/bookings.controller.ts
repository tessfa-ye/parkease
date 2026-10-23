import { Response, NextFunction } from 'express';
import { z } from 'zod';
import { BookingsService } from './bookings.service';
import { AuthRequest } from '../../middlewares/auth.middleware';

const createBookingSchema = z.object({
  spotId: z.string().min(1, 'Spot ID is required'),
  vehiclePlate: z.string().min(3, 'Vehicle plate number is required'),
  startTime: z.string().datetime().or(z.string().min(5)),
  durationHours: z.number().min(0.5).max(72),
  totalAmount: z.number().min(1),
});

export class BookingsController {
  static async createBooking(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const validated = createBookingSchema.parse(req.body);
      const userId = req.user?.userId || 'guest_user';

      const booking = await BookingsService.createBooking({
        ...validated,
        userId,
      });

      res.status(201).json({
        success: true,
        message: 'Booking created successfully',
        data: booking,
      });
    } catch (error) {
      next(error);
    }
  }

  static async getMyBookings(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.userId || 'guest_user';
      const bookings = await BookingsService.getUserBookings(userId);

      res.status(200).json({
        success: true,
        count: bookings.length,
        data: bookings,
      });
    } catch (error) {
      next(error);
    }
  }

  static async getBookingById(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const booking = await BookingsService.getBookingById(id);

      res.status(200).json({
        success: true,
        data: booking,
      });
    } catch (error) {
      next(error);
    }
  }

  static async cancelBooking(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const userId = req.user?.userId || 'guest_user';
      const cancelled = await BookingsService.cancelBooking(id, userId);

      res.status(200).json({
        success: true,
        message: 'Booking cancelled successfully',
        data: cancelled,
      });
    } catch (error) {
      next(error);
    }
  }

  static async extendBooking(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { additionalHours = 1, additionalAmount = 0 } = req.body;
      const updated = await BookingsService.extendBooking(id, Number(additionalHours), Number(additionalAmount));

      res.status(200).json({
        success: true,
        message: `Booking extended by ${additionalHours} hour(s)`,
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  static async getBookingByPass(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { passCode } = req.params;
      const booking = await BookingsService.getBookingByPass(passCode);

      res.status(200).json({
        success: true,
        data: booking,
      });
    } catch (error) {
      next(error);
    }
  }

  static async checkInBooking(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const updated = await BookingsService.checkInBooking(id);

      res.status(200).json({
        success: true,
        message: 'Vehicle checked in successfully',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  static async checkOutBooking(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const updated = await BookingsService.checkOutBooking(id);

      res.status(200).json({
        success: true,
        message: 'Vehicle checked out and slot released',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }
}
