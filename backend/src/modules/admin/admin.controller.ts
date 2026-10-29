import { Request, Response } from 'express';
import { SchedulerService } from '../../services/scheduler.service';
import { prisma } from '../../config/db';
import { env } from '../../config/env';

export class AdminController {
  /**
   * System health check
   */
  static async getHealth(req: Request, res: Response) {
    try {
      // Test database connection
      const dbHealthTest = await prisma.user.count();
      
      return res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        environment: env.NODE_ENV,
        database: 'connected',
        userCount: dbHealthTest,
      });
    } catch (err: any) {
      return res.status(503).json({
        status: 'unhealthy',
        error: err.message,
        database: 'disconnected',
      });
    }
  }

  /**
   * Get active background jobs
   */
  static async getSchedulerJobs(req: Request, res: Response) {
    const jobs = SchedulerService.getJobs();
    
    return res.status(200).json({
      activeJobs: jobs.length,
      jobs: jobs.map((jobName) => ({
        name: jobName,
        status: 'running',
        nextRun: 'auto-scheduled',
      })),
      schedulerStatus: jobs.length > 0 ? 'active' : 'inactive',
    });
  }

  /**
   * Get scheduler performance stats
   */
  static async getSchedulerStats(req: Request, res: Response) {
    try {
      const expiredBookings = await prisma.booking.count({
        where: {
          status: { in: ['COMPLETED', 'CANCELLED'] },
        },
      });

      const activeBookings = await prisma.booking.count({
        where: {
          status: { in: ['ACTIVE', 'CONFIRMED'] },
        },
      });

      return res.status(200).json({
        stats: {
          activeBookings,
          expiredBookings,
          completedRate: expiredBookings / (expiredBookings + activeBookings) || 0,
        },
        jobs: SchedulerService.getJobs(),
        message: 'Background jobs running every 5-60 minutes',
      });
    } catch (err: any) {
      return res.status(200).json({
        stats: {
          activeBookings: 0,
          expiredBookings: 0,
        },
        error: 'Database query failed, using fallback',
      });
    }
  }

  /**
   * Get parking spot availability stats
   */
  static async getSpotStats(req: Request, res: Response) {
    try {
      const spots = await prisma.parkingSpot.findMany({
        select: {
          id: true,
          title: true,
          totalSpots: true,
          availableSpots: true,
          status: true,
          spotType: true,
        },
      });

      const totalCapacity = spots.reduce((sum, s) => sum + s.totalSpots, 0);
      const totalAvailable = spots.reduce((sum, s) => sum + s.availableSpots, 0);
      const availabilityRate = totalCapacity > 0 ? (totalAvailable / totalCapacity * 100).toFixed(2) : '0';

      const statusBreakdown = {
        AVAILABLE: spots.filter((s) => s.status === 'AVAILABLE').length,
        FILLING_FAST: spots.filter((s) => s.status === 'FILLING_FAST').length,
        FULL: spots.filter((s) => s.status === 'FULL').length,
      };

      return res.status(200).json({
        totalSpots: spots.length,
        totalCapacity,
        totalAvailable,
        availabilityRate: `${availabilityRate}%`,
        statusBreakdown,
        topSpots: spots
          .sort((a, b) => b.availableSpots - a.availableSpots)
          .slice(0, 5)
          .map((s) => ({
            id: s.id,
            title: s.title,
            available: s.availableSpots,
            total: s.totalSpots,
            status: s.status,
          })),
      });
    } catch (err: any) {
      return res.status(200).json({
        error: 'Could not fetch spot stats',
        message: err.message,
      });
    }
  }

  /**
   * Get booking metrics
   */
  static async getBookingStats(req: Request, res: Response) {
    try {
      const bookings = await prisma.booking.findMany({
        select: {
          id: true,
          status: true,
          totalAmount: true,
          createdAt: true,
        },
      });

      const statusBreakdown = {
        PENDING: bookings.filter((b) => b.status === 'PENDING').length,
        CONFIRMED: bookings.filter((b) => b.status === 'CONFIRMED').length,
        ACTIVE: bookings.filter((b) => b.status === 'ACTIVE').length,
        COMPLETED: bookings.filter((b) => b.status === 'COMPLETED').length,
        CANCELLED: bookings.filter((b) => b.status === 'CANCELLED').length,
      };

      const totalRevenue = bookings
        .filter((b) => b.status === 'COMPLETED')
        .reduce((sum, b) => sum + b.totalAmount, 0);

      return res.status(200).json({
        totalBookings: bookings.length,
        statusBreakdown,
        totalRevenue,
        avgBookingValue: bookings.length > 0 ? (bookings.reduce((sum, b) => sum + b.totalAmount, 0) / bookings.length).toFixed(2) : '0',
        revenuePerDay: (totalRevenue / (Math.max(1, Math.floor((Date.now() - (bookings[0]?.createdAt?.getTime() || Date.now())) / (1000 * 60 * 60 * 24))) + 1)).toFixed(2),
      });
    } catch (err: any) {
      return res.status(200).json({
        error: 'Could not fetch booking stats',
        message: err.message,
      });
    }
  }
}
