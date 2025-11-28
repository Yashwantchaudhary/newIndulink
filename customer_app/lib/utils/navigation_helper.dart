import 'package:flutter/material.dart';
import '../config/app_routes.dart';
import '../utils/animations.dart';

/// Navigation Helper Utilities
class NavigationHelper {
  /// Navigate to a named route
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
    bool clearStack = false,
    PageTransitionType transition = PageTransitionType.slide,
  }) {
    if (clearStack) {
      return Navigator.pushNamedAndRemoveUntil(
        context,
        routeName,
        (route) => false,
        arguments: arguments,
      );
    } else if (replace) {
      return Navigator.pushReplacementNamed(
        context,
        routeName,
        arguments: arguments,
      );
    } else {
      return Navigator.pushNamed(
        context,
        routeName,
        arguments: arguments,
      );
    }
  }

  /// Navigate with custom page transition
  static Future<T?> navigateWithTransition<T>(
    BuildContext context,
    Widget page, {
    PageTransitionType transition = PageTransitionType.slide,
    bool replace = false,
  }) {
    Route<T> route;

    switch (transition) {
      case PageTransitionType.fade:
        route = PageTransitions.fadeTransition(page) as Route<T>;
        break;
      case PageTransitionType.slide:
        route = PageTransitions.slideFromRight(page) as Route<T>;
        break;
      case PageTransitionType.slideBottom:
        route = PageTransitions.slideFromBottom(page) as Route<T>;
        break;
      case PageTransitionType.scale:
        route = PageTransitions.scaleTransition(page) as Route<T>;
        break;
      case PageTransitionType.rotation:
        route = PageTransitions.rotationFadeTransition(page) as Route<T>;
        break;
      case PageTransitionType.sharedAxis:
        route = PageTransitions.sharedAxisTransition(page) as Route<T>;
        break;
    }

    if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }

  /// Go back
  static void goBack(BuildContext context, {Object? result}) {
    Navigator.pop(context, result);
  }

  /// Go back until a specific route
  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(
      context,
      (route) => route.settings.name == routeName,
    );
  }

  /// Check if can go back
  static bool canGoBack(BuildContext context) {
    return Navigator.canPop(context);
  }

  // ===== Quick Navigation Methods =====

  /// Navigate to Product Detail
  static Future navigateToProductDetail(
    BuildContext context,
    String productId, {
    String? heroTag,
  }) {
    return navigateTo(
      context,
      AppRoutes.productDetail,
      arguments: ProductDetailArgs(
        productId: productId,
        heroTag: heroTag,
      ),
    );
  }

  /// Navigate to Category Products
  static Future navigateToCategoryProducts(
    BuildContext context,
    String categoryId,
    String categoryName,
  ) {
    return navigateTo(
      context,
      AppRoutes.categoryProducts,
      arguments: CategoryProductsArgs(
        categoryId: categoryId,
        categoryName: categoryName,
      ),
    );
  }

  /// Navigate to Chat
  static Future navigateToChat(
    BuildContext context, {
    required String chatId,
    required String recipientName,
    required String recipientRole,
  }) {
    return navigateTo(
      context,
      AppRoutes.customerChat,
      arguments: ChatArgs(
        chatId: chatId,
        recipientName: recipientName,
        recipientRole: recipientRole,
      ),
    );
  }

  /// Navigate to Order Detail
  static Future navigateToOrderDetail(
    BuildContext context,
    String orderId,
  ) {
    return navigateTo(
      context,
      AppRoutes.supplierOrderDetail,
      arguments: OrderDetailArgs(orderId: orderId),
    );
  }

  /// Navigate to Checkout
  static Future navigateToCheckout(BuildContext context) {
    return navigateWithTransition(
      context,
      Container(), // Replace with actual checkout screen
      transition: PageTransitionType.slideBottom,
    );
  }

  /// Navigate to Wishlist
  static Future navigateToWishlist(BuildContext context) {
    return navigateTo(context, AppRoutes.customerWishlist);
  }

  /// Navigate to Cart
  static Future navigateToCart(BuildContext context) {
    return navigateTo(context, AppRoutes.customerCart);
  }

  /// Navigate to Search
  static Future navigateToSearch(BuildContext context) {
    return navigateWithTransition(
      context,
      Container(), // Replace with actual search screen
      transition: PageTransitionType.fade,
    );
  }

  /// Navigate to Notifications
  static Future navigateToNotifications(BuildContext context) {
    return navigateTo(context, AppRoutes.customerNotifications);
  }

  /// Navigate to Profile
  static Future navigateToProfile(BuildContext context,
      {bool isSupplier = false}) {
    return navigateTo(
      context,
      isSupplier ? AppRoutes.supplierProfile : AppRoutes.customerProfile,
    );
  }

  /// Navigate to Supplier Dashboard
  static Future navigateToSupplierDashboard(
    BuildContext context, {
    bool clearStack = true,
  }) {
    return navigateTo(
      context,
      AppRoutes.supplierDashboard,
      clearStack: clearStack,
    );
  }

  /// Navigate to Customer Home
  static Future navigateToCustomerHome(
    BuildContext context, {
    bool clearStack = true,
  }) {
    return navigateTo(
      context,
      AppRoutes.customerHome,
      clearStack: clearStack,
    );
  }

  /// Navigate to Login
  static Future navigateToLogin(
    BuildContext context, {
    bool clearStack = false,
  }) {
    return navigateTo(
      context,
      AppRoutes.login,
      clearStack: clearStack,
    );
  }
}

/// Page transition types
enum PageTransitionType {
  fade,
  slide,
  slideBottom,
  scale,
  rotation,
  sharedAxis,
}

/// Bottom Sheet Helper
class BottomSheetHelper {
  /// Show Modern Bottom Sheet
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor ?? Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor ??
              (isDark ? theme.colorScheme.surface : Colors.white),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: child,
      ),
    );
  }

  /// Show Filter Bottom Sheet
  static Future<Map<String, dynamic>?> showFilterSheet(
    BuildContext context,
  ) {
    return show(
      context,
      child: const Placeholder(), // Replace with actual filter widget
    );
  }

  /// Show Sort Bottom Sheet
  static Future<String?> showSortSheet(
    BuildContext context,
    List<String> options,
  ) {
    return show(
      context,
      child: const Placeholder(), // Replace with actual sort widget
    );
  }
}

/// Dialog Helper
class DialogHelper {
  /// Show Confirmation Dialog
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDangerous
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText ?? 'Confirm'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show Success Dialog
  static Future showSuccess(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: message != null ? Text(message) : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show Error Dialog
  static Future showError(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: message != null ? Text(message) : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show Loading Dialog
  static void showLoading(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Hide Loading Dialog
  static void hideLoading(BuildContext context) {
    Navigator.pop(context);
  }
}

/// Snackbar Helper
class SnackbarHelper {
  /// Show Success Snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show Error Snackbar
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show Info Snackbar
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
