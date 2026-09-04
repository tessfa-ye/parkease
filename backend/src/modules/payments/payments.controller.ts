import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { PaymentsService } from './payments.service';

const initPaymentSchema = z.object({
  bookingId: z.string().min(1, 'Booking ID is required'),
  amount: z.number().min(1),
  phone: z.string().optional(),
  email: z.string().email().optional(),
  name: z.string().optional(),
});

export class PaymentsController {
  static async initializeCheckout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const validated = initPaymentSchema.parse(req.body);
      const result = await PaymentsService.initializeCheckout(validated);

      res.status(200).json({
        success: true,
        message: 'Chapa checkout initialized',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  static async verifyPayment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { txRef } = req.params;
      const result = await PaymentsService.verifyPayment(txRef);

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  static async handleWebhook(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const payload = req.body;
      const txRef = payload.tx_ref || payload.trx_ref;

      console.log('🔔 [Chapa Webhook Received]:', payload);

      if (txRef) {
        await PaymentsService.verifyPayment(txRef);
      }

      res.status(200).json({ status: 'received' });
    } catch (error) {
      next(error);
    }
  }
}
