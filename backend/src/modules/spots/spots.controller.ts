import { Request, Response, NextFunction } from 'express';
import { SpotsService } from './spots.service';

export class SpotsController {
  static async getSpots(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const lat = req.query.lat ? parseFloat(req.query.lat as string) : undefined;
      const lng = req.query.lng ? parseFloat(req.query.lng as string) : undefined;
      const radiusKm = req.query.radiusKm ? parseFloat(req.query.radiusKm as string) : undefined;
      const spotType = req.query.spotType as string | undefined;
      const amenity = req.query.amenity as string | undefined;
      const search = req.query.search as string | undefined;

      const spots = await SpotsService.getSpots({
        lat,
        lng,
        radiusKm,
        spotType,
        amenity,
        search,
      });

      res.status(200).json({
        success: true,
        count: spots.length,
        data: spots,
      });
    } catch (error) {
      next(error);
    }
  }

  static async getSpotById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const spot = await SpotsService.getSpotById(id);
      res.status(200).json({
        success: true,
        data: spot,
      });
    } catch (error) {
      next(error);
    }
  }
}
