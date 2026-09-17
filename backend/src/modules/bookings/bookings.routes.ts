import { Router } from 'express';
import { BookingsController } from './bookings.controller';
import { optionalAuthenticateToken } from '../../middlewares/auth.middleware';

const router = Router();

// Allow authenticated users or guests to book and view bookings
router.post('/', optionalAuthenticateToken, BookingsController.createBooking);
router.get('/my', optionalAuthenticateToken, BookingsController.getMyBookings);
router.get('/:id', optionalAuthenticateToken, BookingsController.getBookingById);
router.patch('/:id/cancel', optionalAuthenticateToken, BookingsController.cancelBooking);

export const bookingsRoutes = router;

