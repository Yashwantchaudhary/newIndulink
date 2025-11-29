import 'package:flutter/material.dart';

/// 🧭 Navigation Service
/// Singleton service for programmatic navigation without BuildContext
class NavigationService {
  // Singleton instance
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Global navigator key
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Get current context
  BuildContext? get currentContext => navigatorKey.currentContext;

  /// Get current navigator state
  NavigatorState? get navigator => navigatorKey.currentState;

  // ==================== Navigation Methods ====================

  /// Navigate to a named route
  Future<T?>? navigateTo<T>(String routeName, {Object? arguments}) {
    return navigator?.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Navigate and replace current route
  Future<T?>? navigateReplaceTo<T>(String routeName, {Object? arguments}) {
    return navigator?.pushReplacementNamed(routeName, arguments: arguments);
  }

  /// Navigate and remove all previous routes
  Future<T?>? navigateAndRemoveUntil<T>(
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return navigator?.pushNamedAndRemoveUntil<T>(
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  /// Pop current route
  void pop<T>([T? result]) {
    if (canPop()) {
      navigator?.pop<T>(result);
    }
  }

  /// Pop until a specific route
  void popUntil(String routeName) {
    navigator?.popUntil((route) => route.settings.name == routeName);
  }

  /// Pop until root
  void popToRoot() {
    navigator?.popUntil((route) => route.isFirst);
  }

  /// Check if can pop
  bool canPop() {
    return navigator?.canPop() ?? false;
  }

  /// Show modal bottom sheet
  Future<T?> showBottomSheet<T>({
    required Widget Function(BuildContext) builder,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
  }) {
    if (currentContext == null) {
      throw Exception('Navigator context is null');
    }

    return showModalBottomSheet<T>(
      context: currentContext!,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      builder: builder,
    );
  }

  /// Show dialog
  Future<T?> showCustomDialog<T>({
    required Widget Function(BuildContext) builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    if (currentContext == null) {
      throw Exception('Navigator context is null');
    }

    return showDialog<T>(
      context: currentContext!,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      builder: builder,
    );
  }

  /// Show snackbar
  void showSnackBar({
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    if (currentContext == null) return;

    ScaffoldMessenger.of(currentContext!).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Show success message
  void showSuccess(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.green,
    );
  }

  /// Show error message
  void showError(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 5),
    );
  }

  /// Show info message
  void showInfo(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.blue,
    );
  }

  /// Show warning message
  void showWarning(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.orange,
    );
  }

  // ==================== Route Guards ====================

  /// Navigate with authentication check
  Future<T?>? navigateWithAuth<T>(
    String routeName, {
    required bool isAuthenticated,
    String? fallbackRoute,
    Object? arguments,
  }) {
    if (!isAuthenticated && fallbackRoute != null) {
      return navigateTo<T>(fallbackRoute);
    }
    return navigateTo<T>(routeName, arguments: arguments);
  }

  /// Navigate with role check
  Future<T?>? navigateWithRole<T>(
    String routeName, {
    required bool isAuthorized,
    String? unauthorizedRoute,
    Object? arguments,
  }) {
    if (!isAuthorized && unauthorizedRoute != null) {
      showError('You are not authorized to access this page');
      return navigateTo<T>(unauthorizedRoute);
    }
    return navigateTo<T>(routeName, arguments: arguments);
  }
}
