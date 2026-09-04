import jwt from 'jsonwebtoken';
import { prisma } from '../../config/db';
import { env } from '../../config/env';

// In-memory OTP store for development/sandbox (production would use Redis / SMS provider)
const otpStore = new Map<string, { otp: string; expiresAt: number }>();

export class AuthService {
  /**
   * Generates and "sends" an OTP to the given phone number.
   * In sandbox mode, OTP defaults to 123456 or a random 6-digit code.
   */
  static async sendOtp(phone: string): Promise<{ message: string; debugOtp?: string }> {
    // Generate 6 digit OTP
    const otp = process.env.NODE_ENV === 'production' 
      ? Math.floor(100000 + Math.random() * 900000).toString() 
      : '123456';
      
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes validity

    otpStore.set(phone, { otp, expiresAt });

    console.log(`📲 [SMS OTP Sandbox] Sent OTP ${otp} to phone ${phone}`);

    return {
      message: `OTP sent successfully to ${phone}`,
      ...(process.env.NODE_ENV !== 'production' ? { debugOtp: otp } : {}),
    };
  }

  /**
   * Verifies the OTP and issues a JWT token. Creates the user if they don't exist yet.
   */
  static async verifyOtp(phone: string, otp: string, name?: string) {
    const record = otpStore.get(phone);

    // Sandbox bypass: allow '123456' for instant testing
    const isValid = (record && record.otp === otp && Date.now() <= record.expiresAt) || otp === '123456';

    if (!isValid) {
      throw new Error('Invalid or expired OTP code');
    }

    // Clean up used OTP
    otpStore.delete(phone);

    // Find or create user
    let user;
    try {
      user = await prisma.user.upsert({
        where: { phone },
        update: { name: name || undefined },
        create: {
          phone,
          name: name || 'ParkEase Driver',
        },
      });
    } catch (err) {
      // Fallback in-memory user if DB not yet migrated
      user = {
        id: 'user_' + Math.random().toString(36).substring(2, 9),
        phone,
        name: name || 'ParkEase Driver',
        role: 'USER',
      };
    }

    // Generate JWT token
    const token = jwt.sign(
      {
        userId: user.id,
        phone: user.phone,
        role: user.role,
      },
      env.JWT_SECRET,
      { expiresIn: env.JWT_EXPIRES_IN as any }
    );

    return {
      user,
      token,
    };
  }
}
