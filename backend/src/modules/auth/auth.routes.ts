import { Router } from 'express';
import { AuthController } from './auth.controller';

const router = Router();

router.post('/otp/send', AuthController.sendOtp);
router.post('/otp/verify', AuthController.verifyOtp);

export const authRoutes = router;
