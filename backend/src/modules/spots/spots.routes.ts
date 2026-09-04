import { Router } from 'express';
import { SpotsController } from './spots.controller';

const router = Router();

router.get('/', SpotsController.getSpots);
router.get('/:id', SpotsController.getSpotById);

export const spotsRoutes = router;
