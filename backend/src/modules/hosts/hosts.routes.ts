import { Router } from 'express';
import { HostsController } from './hosts.controller';
import { authenticateToken } from '../../middlewares/auth.middleware';

const router = Router();

router.post('/apply', authenticateToken, HostsController.submitListing);
router.get('/dashboard', authenticateToken, HostsController.getDashboard);

export const hostsRoutes = router;
