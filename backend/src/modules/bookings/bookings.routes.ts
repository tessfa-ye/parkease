import { Router } from 'express';
import { BookingsController } from './bookings.controller';
import { authenticateToken } from '../../middlewares/auth.middleware';

const router = Router();

// Allow authenticated bookings (or fallback token)
router.post('/', authenticateToken, BookingsController.createBooking);
router.get('/my', authenticateToken, BookingsController.getMyBookings);
router.get('/:id', authenticateToken, BookingsController.getBookingById);

export const bookingsRoutes = router;
