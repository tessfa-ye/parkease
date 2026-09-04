import { Response, NextFunction } from 'express';
import { z } from 'zod';
import { HostsService } from './hosts.service';
import { AuthRequest } from '../../middlewares/auth.middleware';

const submitListingSchema = z.object({
  spaceType: z.string().min(2),
  capacity: z.number().min(1),
  dimensions: z.string().optional(),
  pricePerHour: z.number().min(5),
  availableDays: z.array(z.string()).optional(),
  payoutMethod: z.string().min(2),
  payoutAccount: z.string().min(5),
});

export class HostsController {
  static async submitListing(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const validated = submitListingSchema.parse(req.body);
      const userId = req.user?.userId || 'sample_host_user';

      const listing = await HostsService.submitListing({
        ...validated,
        userId,
      });

      res.status(201).json({
        success: true,
        message: 'Host space listing submitted successfully for approval',
        data: listing,
      });
    } catch (error) {
      next(error);
    }
  }

  static async getDashboard(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.userId || 'sample_host_user';
      const stats = await HostsService.getHostDashboard(userId);

      res.status(200).json({
        success: true,
        data: stats,
      });
    } catch (error) {
      next(error);
    }
  }
}
