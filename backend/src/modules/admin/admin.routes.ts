import { Router } from 'express';
import { AdminController } from './admin.controller';

export const adminRoutes = Router();

// Admin monitoring endpoints (no auth required in dev, add middleware in production)
adminRoutes.get('/health', AdminController.getHealth);
adminRoutes.get('/scheduler/jobs', AdminController.getSchedulerJobs);
adminRoutes.get('/scheduler/stats', AdminController.getSchedulerStats);
adminRoutes.get('/spots/stats', AdminController.getSpotStats);
adminRoutes.get('/bookings/stats', AdminController.getBookingStats);
