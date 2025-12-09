// Helper file for checkout screen order placement logic
import 'package:flutter/material.dart';
import 'package:newindulink/models/user.dart';
import 'package:newindulink/providers/order_provider.dart';
import 'package:newindulink/providers/cart_provider.dart';
import 'package:newindulink/services/payment_service.dart';

/// Handle Cash on Delivery order placement
Future<bool> handleCODOrder({
  required BuildContext context,
  required OrderProvider orderProvider,
  required CartProvider cartProvider,
  required Address deliveryAddress,
  String? notes,
}) async {
  try {
    final order = await orderProvider.createOrder(
      shippingAddress: deliveryAddress,
      paymentMethod: 'cash_on_delivery',
      notes: notes,
    );

    if (order != null) {
      // Clear cart after successful order
      await cartProvider.clearCart();
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('COD Order Error: $e');
    return false;
  }
}

/// Handle eSewa payment and order placement
Future<bool> handleESewaOrder({
  required BuildContext context,
  required OrderProvider orderProvider,
  required CartProvider cartProvider,
  required Address deliveryAddress,
  required double totalAmount,
  String? notes,
}) async {
  try {
    final paymentService = PaymentService();

    // Initiate eSewa payment
    // Use callback-based eSewa payment
    bool paymentSuccess = false;
    String? refId;
    String? transactionId;

    await paymentService.initiateEsewaPayment(
      orderId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
      amount: totalAmount,
      productName: 'INDULINK Order',
      productId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
      onSuccess: (result) {
        paymentSuccess = true;
        refId = result.refId;
        // Note: EsewaPaymentSuccessResult may not have transactionDetails
        // transactionId would be available in result if provided by eSewa
      },
      onFailure: (error) {
        paymentSuccess = false;
        debugPrint('eSewa payment failed: $error');
      },
    );

    if (!paymentSuccess) {
      return false;
    }

    // Payment successful, create order
    final order = await orderProvider.createOrder(
      shippingAddress: deliveryAddress,
      paymentMethod: 'esewa',
      notes: notes,
    );

    if (order != null) {
      await cartProvider.clearCart();
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('eSewa Order Error: $e');
    return false;
  }
}
