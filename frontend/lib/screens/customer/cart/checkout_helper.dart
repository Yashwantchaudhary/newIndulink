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
    final success = await orderProvider.createOrder(
      deliveryAddress: deliveryAddress,
      paymentMethod: 'cash_on_delivery',
      notes: notes,
    );

    if (success) {
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
    final paymentResult = await paymentService.initiateESewaPayment(
      amount: totalAmount,
      productId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
      productName: 'INDULINK Order',
    );

    if (paymentResult != null && paymentResult.hasData) {
      // Payment successful, create order
      final success = await orderProvider.createOrder(
        deliveryAddress: deliveryAddress,
        paymentMethod: 'esewa',
        notes: notes,
        paymentDetails: {
          'refId': paymentResult.refId,
          'transactionId': paymentResult.transactionDetails?.transactionId,
        },
      );

      if (success) {
        await cartProvider.clearCart();
        return true;
      }
    }
    return false;
  } catch (e) {
    debugPrint('eSewa Order Error: $e');
    return false;
  }
}
