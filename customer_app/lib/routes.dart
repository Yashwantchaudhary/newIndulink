import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/category.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/bottom_nav.dart';
import 'screens/home/enhanced_home_screen.dart';
import 'screens/dashboard/customer_dashboard_screen.dart';
import 'screens/dashboard/adaptive_dashboard_screen.dart';
import 'screens/category/categories_screen.dart';
import 'screens/category/category_products_screen.dart';
import 'screens/category/enhanced_categories_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/cart/enhanced_cart_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/notification_preferences_screen.dart';
import 'screens/profile/language_selection_screen.dart';
import 'screens/profile/modern_addresses_screen.dart';
import 'screens/profile/modern_payment_methods_screen.dart';
import 'screens/profile/help_center_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/order/orders_list_screen.dart';
import 'screens/order/order_detail_screen.dart';
import 'screens/order/order_success_screen.dart';
import 'screens/orders/modern_customer_orders_screen.dart';
import 'screens/orders/supplier_orders_screen.dart' as orders_supplier_orders;
import 'screens/checkout/checkout_address_screen.dart';
import 'screens/checkout/checkout_payment_screen.dart';
import 'screens/checkout/modern_checkout_screen.dart';
import 'screens/product/product_detail_screen.dart';
import 'screens/product/all_products_screen.dart';
import 'screens/product/enhanced_product_detail_screen.dart';
import 'screens/product/modern_product_reviews_screen.dart';
import 'screens/deals/deals_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/wishlist/wishlist_screen.dart' as basic_wishlist;
import 'screens/wishlist/modern_wishlist_screen.dart';
import 'screens/customer/wishlist_screen.dart' as customer_wishlist;
// import 'screens/messaging/messages_list_screen.dart';
// import 'screens/messaging/modern_chat_screen.dart';
// import 'screens/messaging/modern_conversations_screen.dart';
import 'screens/notifications/modern_notifications_screen.dart';
import 'screens/scanner/barcode_scanner_screen.dart';
import 'screens/search/modern_search_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';
import 'screens/legal/terms_conditions_screen.dart';
import 'screens/loyalty/premium_loyalty_screen.dart';
import 'screens/recommendations/premium_recommendations_screen.dart';
import 'screens/support/help_support_screen.dart';

/// Role-based access control
enum UserRole { customer, supplier, admin }

/// Check if user has required role for a screen
bool _hasRequiredRole(BuildContext context, List<UserRole> allowedRoles) {
  // Get user from auth provider - this requires the context to have access to providers
  // For now, we'll implement basic role checking in individual screens
  // This is a placeholder that allows all access
  return true;
}

/// Role-based route guard widget
class RoleGuard extends ConsumerWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      // Not authenticated, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      });
      return fallback ?? const SizedBox.shrink();
    }

    UserRole userRole;
    switch (user.role.toLowerCase()) {
      case 'admin':
        userRole = UserRole.admin;
        break;
      case 'supplier':
        userRole = UserRole.supplier;
        break;
      case 'customer':
      default:
        userRole = UserRole.customer;
        break;
    }

    if (allowedRoles.contains(userRole)) {
      return child;
    } else {
      // User doesn't have required role
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You don\'t have permission to access this screen'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      });
      return fallback ?? const SizedBox.shrink();
    }
  }
}

/// App Routes Configuration
/// Centralizes all navigation routes for the application
class AppRoutes {
  // Auth Routes
  static const String splash = '/';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String register = '/register';

  // Main App Routes
  static const String home = '/home';
  static const String enhancedHome = '/enhanced-home';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String profile = '/profile';

  // Dashboard Routes
  static const String customerDashboard = '/customer-dashboard';
  static const String dashboard =
      '/dashboard'; // Alias for role-based dashboard

  // Product Routes
  static const String productDetail = '/product-detail';
  static const String allProducts = '/all-products';
  static const String deals = '/deals';
  static const String enhancedProductDetail = '/enhanced-product-detail';
  static const String productReviews = '/product-reviews';

  // Order Routes
  static const String ordersList = '/orders-list';
  static const String orderDetail = '/order-detail';
  static const String orderSuccess = '/order-success';

  // Category Routes
  static const String categoryProducts = '/category-products';

  // Profile Routes
  static const String editProfile = '/edit-profile';
  static const String notificationPreferences = '/notification-preferences';
  static const String languageSelection = '/language-selection';

  // Checkout Routes
  static const String checkoutAddress = '/checkout-address';
  static const String checkoutPayment = '/checkout-payment';
  static const String modernCheckout = '/modern-checkout';


  // Settings Routes
  static const String settings = '/settings';

  // Wishlist Routes
  static const String wishlist = '/wishlist';
  static const String modernWishlist = '/modern-wishlist';
  static const String customerWishlist = '/customer-wishlist';

  // Messaging Routes
  static const String messages = '/messages';
  static const String modernChat = '/modern-chat';
  static const String modernConversations = '/modern-conversations';

  // Notifications Routes
  static const String notifications = '/notifications';


  // Search Routes
  static const String search = '/search';

  // Scanner Routes
  static const String barcodeScanner = '/barcode-scanner';



  // Legal Routes
  static const String privacyPolicy = '/privacy-policy';
  static const String termsConditions = '/terms-conditions';

  // Loyalty Routes
  static const String loyalty = '/loyalty';

  // Recommendations Routes
  static const String recommendations = '/recommendations';

  // Support Routes
  static const String helpSupport = '/help-support';

  // Profile Routes
  static const String modernAddresses = '/modern-addresses';
  static const String modernPaymentMethods = '/modern-payment-methods';
  static const String helpCenter = '/help-center';
  static const String profileNew = '/profile-new';

  // Order Routes
  static const String modernCustomerOrders = '/modern-customer-orders';
  static const String supplierOrdersList = '/supplier-orders-list';

  // Home Routes
  static const String homeBasic = '/home-basic';

  // Category Routes
  static const String enhancedCategories = '/enhanced-categories';

  // Cart Routes
  static const String enhancedCart = '/enhanced-cart';

  // Auth Routes
  static const String forgotPassword = '/forgot-password';

  /// Generate routes for the app
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    // Debug logging can be added back if needed

    switch (routeSettings.name) {
      // Auth Routes
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case roleSelection:
        return MaterialPageRoute(
          builder: (context) => RoleSelectionScreen(
            onRoleSelect: (role) {
              // Navigate to login with selected role
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => LoginScreen(userRole: role),
                ),
              );
            },
            onSkip: () {
              // Navigate to login with default role
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => const LoginScreen(),
                ),
              );
            },
          ),
        );
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        final userRole = routeSettings.arguments as String?;
        return MaterialPageRoute(
            builder: (_) => RegisterScreen(userRole: userRole));

      // Main App Routes
      case home:
        return MaterialPageRoute(builder: (_) => const BottomNavScreen());
      case enhancedHome:
        return MaterialPageRoute(builder: (_) => const EnhancedHomeScreen());
      case categories:
        return MaterialPageRoute(builder: (_) => const CategoriesScreen());
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreenNew());

      // Dashboard Routes
      case dashboard:
      case customerDashboard:
        return MaterialPageRoute(
          builder: (context) => const RoleGuard(
            allowedRoles: [UserRole.customer, UserRole.admin],
            child: CustomerDashboardScreen(),
          ),
        );

      // Product Routes
      case productDetail:
        final productId = routeSettings.arguments as String?;
        if (productId == null) {
          return _errorRoute('Product ID is required');
        }
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: productId),
        );
      case allProducts:
        return MaterialPageRoute(builder: (_) => const AllProductsScreen());
      case deals:
        return MaterialPageRoute(builder: (_) => const DealsScreen());
      case enhancedProductDetail:
        final productId = routeSettings.arguments as String?;
        if (productId == null) {
          return _errorRoute('Product ID is required');
        }
        return MaterialPageRoute(
          builder: (_) => EnhancedProductDetailScreen(productId: productId),
        );
      case productReviews:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        final productId = args?['productId'] as String?;
        final averageRating = args?['averageRating'] as double? ?? 0.0;
        final totalReviews = args?['totalReviews'] as int? ?? 0;
        if (productId == null) {
          return _errorRoute('Product ID is required');
        }
        return MaterialPageRoute(
          builder: (_) => ModernProductReviewsScreen(
            productId: productId,
            averageRating: averageRating,
            totalReviews: totalReviews,
          ),
        );

      // Order Routes
      case ordersList:
        return MaterialPageRoute(builder: (_) => const OrdersListScreen());
      case orderDetail:
        final orderId = routeSettings.arguments as String?;
        if (orderId == null) {
          return _errorRoute('Order ID is required');
        }
        return MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: orderId),
        );
      // Note: orderSuccess requires Order object, navigate directly with MaterialPageRoute

      // Category Routes
      case categoryProducts:
        final category = routeSettings.arguments as Category?;
        if (category == null) {
          return _errorRoute('Category object is required');
        }
        return MaterialPageRoute(
          builder: (_) => CategoryProductsScreen(categoryName: category.name),
        );

      // Profile Routes
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case notificationPreferences:
        return MaterialPageRoute(
            builder: (_) => const NotificationPreferencesScreen());
      case languageSelection:
        return MaterialPageRoute(
            builder: (_) => const LanguageSelectionScreen());

      // Checkout Routes
      case checkoutAddress:
        return MaterialPageRoute(builder: (_) => const CheckoutAddressScreen());
      // Note: checkoutPayment requires ShippingAddress object, navigate directly with MaterialPageRoute


      // Settings Routes
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      // Wishlist Routes
      case wishlist:
        return MaterialPageRoute(
            builder: (_) => const basic_wishlist.WishlistScreen());
      case modernWishlist:
        return MaterialPageRoute(builder: (_) => const ModernWishlistScreen());
      case customerWishlist:
        return MaterialPageRoute(
            builder: (_) => const customer_wishlist.WishlistScreen());

      // Messaging Routes - Temporarily disabled due to compilation issues
      // case messages:
      //   return MaterialPageRoute(builder: (_) => const MessagesListScreen());
      // case modernChat:
      //   final conversationId = routeSettings.arguments as String?;
      //   if (conversationId == null) {
      //     return _errorRoute('Conversation ID is required');
      //   }
      //   return MaterialPageRoute(
      //     builder: (_) => ModernChatScreen(conversationId: conversationId),
      //   );
      // case modernConversations:
      //   return MaterialPageRoute(
      //       builder: (_) => const ModernConversationsScreen());

      // Notifications Routes
      case notifications:
        return MaterialPageRoute(
            builder: (_) => const ModernNotificationsScreen());


      // Search Routes
      case search:
        return MaterialPageRoute(builder: (_) => const ModernSearchScreen());

      // Scanner Routes
      case barcodeScanner:
        return MaterialPageRoute(builder: (_) => const BarcodeScannerScreen());



      // Legal Routes
      case privacyPolicy:
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());
      case termsConditions:
        return MaterialPageRoute(builder: (_) => const TermsConditionsScreen());

      // Loyalty Routes
      case loyalty:
        return MaterialPageRoute(builder: (_) => const PremiumLoyaltyScreen());

      // Recommendations Routes
      case recommendations:
        return MaterialPageRoute(
            builder: (_) => const PremiumRecommendationsScreen());

      // Support Routes
      case helpSupport:
        return MaterialPageRoute(builder: (_) => const HelpSupportScreen());

      // Additional Profile Routes
      case modernAddresses:
        return MaterialPageRoute(builder: (_) => const ModernAddressesScreen());
      case modernPaymentMethods:
        return MaterialPageRoute(
            builder: (_) => const ModernPaymentMethodsScreen());
      case helpCenter:
        return MaterialPageRoute(builder: (_) => const HelpCenterScreen());
      case profileNew:
        return MaterialPageRoute(builder: (_) => const ProfileScreenNew());

      // Additional Order Routes
      case modernCustomerOrders:
        return MaterialPageRoute(
            builder: (_) => const ModernCustomerOrdersScreen());

      // Additional Home Routes
      case homeBasic:
        return MaterialPageRoute(builder: (_) => const EnhancedHomeScreen());

      // Additional Category Routes
      case enhancedCategories:
        return MaterialPageRoute(
            builder: (_) => const EnhancedCategoriesScreen());

      // Additional Cart Routes
      case enhancedCart:
        return MaterialPageRoute(builder: (_) => const EnhancedCartScreen());

      // Additional Auth Routes
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      default:
        return _errorRoute('Route ${routeSettings.name} not found');
    }
  }

  /// Error route for invalid navigation
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Navigate to a route with optional arguments
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  /// Navigate to a route and remove all previous routes
  static Future<T?> navigateToAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Navigate to a route and replace current route
  static Future<T?> navigateToAndReplace<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, dynamic>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Go back to previous screen
  static void goBack<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }
}
