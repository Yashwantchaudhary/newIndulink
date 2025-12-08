import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';

import 'api_service.dart';

/// 💳 Payment Service
/// Handles eSewa integration and payment processing
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final ApiService _api = ApiService();

  // eSewa Configuration (Sandbox)
  static const String _esewaClientId =
      'JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R';
  static const String _esewaSecretKey = 'BhwIWQQVDw==';

  /// Initiate eSewa Payment
  Future<PaymentResult> initiateEsewaPayment({
    required String orderId,
    required double amount,
    required String productName,
    required String productId,
    required Function(EsewaPaymentSuccessResult) onSuccess,
    required Function(String) onFailure,
  }) async {
    try {
      // 1. Create Payment Intent on Backend (to get signature/transactionId)
      // Note: SDK generates signature internally usually, but best practice is server-side.
      // However, esewa_flutter_sdk usually takes just parameters and handles flow.
      // Let's first try standard SDK flow using client-side config for Sandbox.

      final config = EsewaConfig(
        clientId: _esewaClientId,
        secretId: _esewaSecretKey,
        environment: Environment.test,
      );

      final payment = EsewaPayment(
        productId: productId,
        productName: productName,
        productPrice: amount.toString(),
        callbackUrl: '', // SDK handles callback internally?
      );

      try {
        EsewaFlutterSdk.initPayment(
          esewaConfig: config,
          esewaPayment: payment,
          onPaymentSuccess: (EsewaPaymentSuccessResult data) {
            onSuccess(data);
          },
          onPaymentFailure: (data) {
            onFailure(data.toString());
          },
          onPaymentCancellation: (data) {
            onFailure("Cancelled by user");
          },
        );

        return PaymentResult(success: true, message: 'Payment Initiated');
      } catch (e) {
        return PaymentResult(success: false, message: e.toString());
      }
    } catch (e) {
      return PaymentResult(success: false, message: e.toString());
    }
  }

  /// Verify Payment on Backend
  Future<PaymentResult> verifyPaymentOnBackend({
    required String transactionId,
    required String refId,
    required double amount,
  }) async {
    try {
      final response = await _api.get(
        '/payments/esewa/success',
        params: {
          'oid': transactionId,
          'amt': amount.toString(),
          'refId': refId,
        },
      );

      if (response.isSuccess) {
        return PaymentResult(
            success: true, message: 'Payment verified successfully');
      } else {
        return PaymentResult(
            success: false, message: response.message ?? 'Verification failed');
      }
    } catch (e) {
      return PaymentResult(success: false, message: e.toString());
    }
  }
}

class PaymentResult {
  final bool success;
  final String message;
  final dynamic data;

  PaymentResult({required this.success, required this.message, this.data});
}
