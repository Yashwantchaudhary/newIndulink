import 'package:flutter/material.dart';
import 'models/category.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/bottom_nav.dart';
import 'screens/home/enhanced_home_screen.dart';
import 'screens/dashboard/customer_dashboard_screen.dart';
import 'screens/dashboard/supplier_dashboard_screen.dart' as supplier_dashboard;
import 'screens/category/categories_screen.dart';
import 'screens/category/category_products_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/order/orders_list_screen.dart';
import 'screens/order/order_detail_screen.dart';
import 'screens/checkout/checkout_address_screen.dart';

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
  static const String supplierDashboard = '/supplier-dashboard';
  static const String dashboard = '/dashboard'; // Alias for role-based dashboard

  // Product Routes
  static const String productDetail = '/product-detail';
  static const String allProducts = '/all-products';
  static const String deals = '/deals';

  // Order Routes
  static const String ordersList = '/orders-list';
  static const String orderDetail = '/order-detail';
  static const String orderSuccess = '/order-success';

  // Category Routes
  static const String categoryProducts = '/category-products';

  // Profile Routes
  static const String editProfile = '/edit-profile';

  // Checkout Routes
  static const String checkoutAddress = '/checkout-address';
  static const String checkoutPayment = '/checkout-payment';

  // Analytics Routes
  static const String analytics = '/analytics';

  // Settings Routes
  static const String settings = '/settings';

  // Wishlist Routes
  static const String wishlist = '/wishlist';

  // Messaging Routes
  static const String messages = '/messages';

  // RFQ Routes
  static const String rfqList = '/rfq-list';

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
        return MaterialPageRoute(builder: (_) => RegisterScreen(userRole: userRole));

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
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      // Dashboard Routes
      case dashboard:
      case customerDashboard:
        return MaterialPageRoute(builder: (_) => const CustomerDashboardScreen());
      case supplierDashboard:
        return MaterialPageRoute(builder: (_) => const supplier_dashboard.SupplierDashboardScreenNew());

      // Product Routes - Temporarily disabled due to missing implementations
      // case productDetail:
      //   final productId = routeSettings.arguments as String?;
      //   if (productId == null) {
      //     return _errorRoute('Product ID is required');
      //   }
      //   return MaterialPageRoute(
      //     builder: (_) => ProductDetailScreen(productId: productId),
      //   );
      // case allProducts:
      //   return MaterialPageRoute(builder: (_) => const AllProductsScreen());
      // case deals:
      //   return MaterialPageRoute(builder: (_) => const DealsScreen());

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

      // Checkout Routes
      case checkoutAddress:
        return MaterialPageRoute(builder: (_) => const CheckoutAddressScreen());
      // Note: checkoutPayment requires ShippingAddress object, navigate directly with MaterialPageRoute

      // Analytics Routes - Temporarily disabled
      // case analytics:
      //   return MaterialPageRoute(builder: (_) => const AnalyticsScreen());

      // Settings Routes - Temporarily disabled
      // case settings:
      //   return MaterialPageRoute(builder: (_) => const SettingsScreen());

      // Wishlist Routes - Temporarily disabled
      // case wishlist:
      //   return MaterialPageRoute(builder: (_) => const WishlistScreen());

      // Messaging Routes - Temporarily disabled
      // case messages:
      //   return MaterialPageRoute(builder: (_) => const MessagesListScreen());

      // RFQ Routes - Temporarily disabled
      // case rfqList:
      //   return MaterialPageRoute(builder: (_) => const RFQListScreen());

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