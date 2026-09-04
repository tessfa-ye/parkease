import { env } from '../../config/env';

export interface InitializePaymentParams {
  amount: number;
  currency?: string;
  email?: string;
  first_name?: string;
  last_name?: string;
  phone_number?: string;
  tx_ref: string;
  callback_url?: string;
  return_url?: string;
  customization?: {
    title?: string;
    description?: string;
  };
}

export class ChapaClient {
  private static baseUrl = 'https://api.chapa.co/v1';

  /**
   * Initializes a Chapa checkout session.
   * Can be paid via Telebirr, CBE Birr, cards directly on Chapa's checkout page.
   */
  static async initialize(params: InitializePaymentParams) {
    const isMock = !env.CHAPA_SECRET_KEY || env.CHAPA_SECRET_KEY.includes('sample_test_key') || env.CHAPA_SECRET_KEY.includes('xxx');

    if (isMock) {
      console.log(`💳 [Chapa Sandbox Mode] Mocking checkout for tx_ref: ${params.tx_ref}, Amount: ${params.amount} ETB`);
      return {
        status: 'success',
        message: 'Hosted Link (Sandbox Mock)',
        data: {
          checkout_url: `https://checkout.chapa.co/checkout/payment-receipt/mock-${params.tx_ref}`,
        },
      };
    }

    try {
      const response = await fetch(`${this.baseUrl}/transaction/initialize`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.CHAPA_SECRET_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          amount: params.amount.toString(),
          currency: params.currency || 'ETB',
          email: params.email || 'customer@parkease.et',
          first_name: params.first_name || 'ParkEase',
          last_name: params.last_name || 'Driver',
          phone_number: params.phone_number,
          tx_ref: params.tx_ref,
          callback_url: params.callback_url,
          return_url: params.return_url,
          'customization[title]': params.customization?.title || 'ParkEase Parking Reservation',
          'customization[description]': params.customization?.description || 'Secure Parking Reservation Fee',
        }),
      });

      const data = await response.json();
      return data;
    } catch (err: any) {
      console.error('❌ Chapa initialization error:', err);
      throw new Error(`Failed to initialize Chapa payment: ${err.message}`);
    }
  }

  /**
   * Verifies a transaction by tx_ref.
   */
  static async verify(tx_ref: string) {
    const isMock = !env.CHAPA_SECRET_KEY || env.CHAPA_SECRET_KEY.includes('sample_test_key') || env.CHAPA_SECRET_KEY.includes('xxx');

    if (isMock) {
      return {
        status: 'success',
        message: 'Payment verified (Sandbox Mock)',
        data: {
          tx_ref,
          status: 'success',
          amount: 50,
          currency: 'ETB',
          payment_method: 'telebirr',
        },
      };
    }

    try {
      const response = await fetch(`${this.baseUrl}/transaction/verify/${tx_ref}`, {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${env.CHAPA_SECRET_KEY}`,
        },
      });

      const data = await response.json();
      return data;
    } catch (err: any) {
      console.error('❌ Chapa verification error:', err);
      throw new Error(`Failed to verify Chapa payment: ${err.message}`);
    }
  }
}
