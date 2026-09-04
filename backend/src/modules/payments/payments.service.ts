import { v4 as uuidv4 } from 'uuid';
import { prisma } from '../../config/db';
import { ChapaClient } from './chapa.client';

export interface InitializeCheckoutDto {
  bookingId: string;
  amount: number;
  phone?: string;
  email?: string;
  name?: string;
}

export class PaymentsService {
  static async initializeCheckout(dto: InitializeCheckoutDto) {
    const txRef = `PE-TX-${Date.now()}-${uuidv4().substring(0, 6)}`;

    // Initialize with Chapa
    const chapaRes = await ChapaClient.initialize({
      amount: dto.amount,
      currency: 'ETB',
      tx_ref: txRef,
      email: dto.email || 'driver@parkease.et',
      phone_number: dto.phone,
      first_name: dto.name || 'ParkEase Driver',
      customization: {
        title: 'ParkEase Parking Pass',
        description: `Reservation Payment #${dto.bookingId}`,
      },
    });

    const checkoutUrl = chapaRes.data?.checkout_url;

    // Save payment record
    try {
      await prisma.payment.create({
        data: {
          bookingId: dto.bookingId,
          txRef,
          amount: dto.amount,
          currency: 'ETB',
          provider: 'CHAPA',
          status: 'PENDING',
          checkoutUrl,
        },
      });
    } catch (err) {
      // Fallback
    }

    return {
      txRef,
      checkoutUrl,
      amount: dto.amount,
      currency: 'ETB',
    };
  }

  static async verifyPayment(txRef: string) {
    const chapaRes = await ChapaClient.verify(txRef);

    if (chapaRes.status === 'success' || chapaRes.data?.status === 'success') {
      try {
        const payment = await prisma.payment.update({
          where: { txRef },
          data: { status: 'SUCCESS' },
          include: { booking: true },
        });

        if (payment.bookingId) {
          await prisma.booking.update({
            where: { id: payment.bookingId },
            data: { status: 'CONFIRMED' },
          });
        }
      } catch (err) {
        // Fallback
      }

      return {
        verified: true,
        status: 'SUCCESS',
        txRef,
      };
    }

    return {
      verified: false,
      status: 'FAILED',
      txRef,
    };
  }
}
