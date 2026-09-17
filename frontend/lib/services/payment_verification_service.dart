import 'api_service.dart';

/// Result of a payment verification attempt.
enum PaymentVerificationStatus { success, failed, timeout }

class PaymentResult {
  final PaymentVerificationStatus status;
  final String txRef;
  final String? qrCodeData;

  const PaymentResult({
    required this.status,
    required this.txRef,
    this.qrCodeData,
  });

  bool get isSuccess => status == PaymentVerificationStatus.success;
}

/// Polls the backend to verify a Chapa payment by txRef.
/// Retries up to [maxRetries] times with [retryDelay] between attempts.
/// In sandbox/mock mode the backend always returns success immediately.
class PaymentVerificationService {
  static Future<PaymentResult> verify(
    String txRef, {
    int maxRetries = 5,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final data = await ApiService.verifyPayment(txRef);
        if (data != null) {
          final verified = data['verified'] == true ||
              data['status'] == 'SUCCESS' ||
              data['status'] == 'success';
          if (verified) {
            return PaymentResult(
              status: PaymentVerificationStatus.success,
              txRef: txRef,
              qrCodeData: data['qrCodeData'] as String?,
            );
          }
          // Explicitly failed (not just a network error)
          if (data['status'] == 'FAILED' || data['status'] == 'failed') {
            return PaymentResult(
              status: PaymentVerificationStatus.failed,
              txRef: txRef,
            );
          }
        }
      } catch (_) {
        // Network error — keep retrying
      }

      if (attempt < maxRetries) {
        await Future.delayed(retryDelay);
      }
    }

    return PaymentResult(
      status: PaymentVerificationStatus.timeout,
      txRef: txRef,
    );
  }
}
