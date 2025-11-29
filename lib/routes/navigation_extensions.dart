import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'navigation_service.dart';

/// 🧭 Navigation Extensions
/// Extension methods for easy navigation
extension NavigationExtensions on BuildContext {
  // ==================== Navigation Methods ====================

  /// Navigate to a named route
  Future<T?>? navigateTo<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Navigate and replace current route
  Future<T?>? navigateReplaceTo<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushReplacementNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate and remove all previous routes
  Future<T?>? navigateAndRemoveUntil<T>(
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return Navigator.of(this).pushNamedAndRemoveUntil<T>(
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  /// Pop current route
  void pop<T>([T? result]) {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop<T>(result);
    }
  }

  /// Pop until a specific route
  void popUntil(String routeName) {
    Navigator.of(this).popUntil((route) => route.settings.name == routeName);
  }

  /// Pop until root
  void popToRoot() {
    Navigator.of(this).popUntil((route) => route.isFirst);
  }

  // ==================== Quick Navigation Shortcuts ====================

  /// Navigate to customer home
  Future<void> navigateToCustomerHome() =>
      navigateTo(AppRoutes.customerHome) ?? Future.value();

  /// Navigate to supplier dashboard
  Future<void> navigateToSupplierDashboard() =>
      navigateTo(AppRoutes.supplierDashboard) ?? Future.value();

  /// Navigate to admin dashboard
  Future<void> navigateToAdminDashboard() =>
      navigateTo(AppRoutes.adminDashboard) ?? Future.value();

  /// Navigate to login
  Future<void> navigateToLogin({String? selectedRole}) =>
      navigateTo(AppRoutes.login, arguments: selectedRole) ?? Future.value();

  /// Navigate to signup
  Future<void> navigateToSignup({String? selectedRole}) =>
      navigateTo(AppRoutes.signup, arguments: selectedRole) ?? Future.value();

  /// Navigate to product detail
  Future<void> navigateToProductDetail(String productId) =>
      navigateTo(AppRoutes.productDetail, arguments: productId) ??
      Future.value();

  /// Navigate to order detail
  Future<void> navigateToOrderDetail(String orderId) =>
      navigateTo(AppRoutes.orderDetail, arguments: orderId) ?? Future.value();

  // ==================== UI Helpers ====================

  /// Show success snackbar
  void showSuccess(String message) {
    NavigationService().showSuccess(message);
  }

  /// Show error snackbar
  void showError(String message) {
    NavigationService().showError(message);
  }

  /// Show info snackbar
  void showInfo(String message) {
    NavigationService().showInfo(message);
  }

  /// Show warning snackbar
  void showWarning(String message) {
    NavigationService().showWarning(message);
  }
}

/// 🎯 Route Arguments Helper
/// Helper class for type-safe route arguments
class RouteArgs {
  RouteArgs._();

  /// Create product detail arguments
  static String productDetail(String productId) => productId;

  /// Create order detail arguments
  static String orderDetail(String orderId) => orderId;

  /// Create auth arguments
  static String auth(String selectedRole) => selectedRole;

  /// Create supplier product edit arguments
  static String productEdit(String productId) => productId;
}
