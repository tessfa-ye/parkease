import { Router } from 'express';
import { PaymentsController } from './payments.controller';

const router = Router();

router.post('/initialize', PaymentsController.initializeCheckout);
router.get('/verify/:txRef', PaymentsController.verifyPayment);
router.post('/webhook', PaymentsController.handleWebhook);

export const paymentsRoutes = router;
