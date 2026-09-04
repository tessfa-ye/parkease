import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { AuthService } from './auth.service';

const sendOtpSchema = z.object({
  phone: z.string().min(9, 'Valid phone number is required'),
});

const verifyOtpSchema = z.object({
  phone: z.string().min(9, 'Valid phone number is required'),
  otp: z.string().length(6, 'OTP must be 6 digits'),
  name: z.string().optional(),
});

export class AuthController {
  static async sendOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { phone } = sendOtpSchema.parse(req.body);
      const result = await AuthService.sendOtp(phone);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  static async verifyOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { phone, otp, name } = verifyOtpSchema.parse(req.body);
      const result = await AuthService.verifyOtp(phone, otp, name);
      res.status(200).json({
        success: true,
        message: 'Authentication successful',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
}
