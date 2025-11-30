import 'package:flutter/material.dart';

// Routes
import 'app_routes.dart';

// Models
import '../models/user.dart';

// Screens - Initial
import '../screens/splash/splash_screen.dart';
import '../screens/role_selection/role_selection_screen.dart';

// Screens - Auth
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';

// Screens - Customer
import '../screens/customer/home/customer_home_screen.dart';
import '../screens/customer/products/product_list_screen.dart';
import '../screens/customer/products/product_detail_screen.dart';
import '../screens/customer/categories/customer_categories_screen.dart';
import '../screens/customer/search/search_screen.dart';
import '../screens/customer/wishlist/customer_wishlist_screen.dart';
import '../screens/customer/cart/cart_screen.dart';
import '../screens/customer/cart/checkout_screen.dart';
import '../screens/customer/orders/orders_screen.dart';
import '../screens/customer/orders/order_detail_screen.dart';
import '../screens/customer/profile/profile_screen.dart';
import '../screens/customer/messages/customer_messages_screen.dart';
import '../screens/customer/notifications/customer_notifications_screen.dart';

// Screens - Supplier
import '../screens/supplier/dashboard/supplier_dashboard_screen.dart';
import '../screens/supplier/products/supplier_products_list_screen.dart';
import '../screens/supplier/products/supplier_product_add_edit_screen.dart';
import '../screens/supplier/orders/supplier_orders_screen.dart';
import '../screens/supplier/orders/supplier_order_detail_screen.dart';
import '../screens/supplier/profile/supplier_profile_screen.dart';

// Screens - Admin
import '../screens/admin/dashboard/admin_dashboard_screen.dart';
import '../screens/admin/users/admin_users_screen.dart';
import '../screens/admin/products/admin_products_screen.dart';
import '../screens/admin/categories/admin_categories_screen.dart';
import '../screens/admin/orders/admin_orders_screen.dart';

/// 🧭 App Router
/// Centralized route generation and navigation logic
class AppRouter {
  AppRouter._(); // Private constructor

  /// Generate route based on route settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract route name and arguments
    final routeName = settings.name ?? AppRoutes.splash;
    final arguments = settings.arguments;

    // Log navigation for debugging
    debugPrint('🧭 Navigating to: $routeName');
    if (arguments != null) {
      debugPrint('📦 With arguments: $arguments');
    }

    // Route mapping
    switch (routeName) {
      // ==================== Initial Routes ====================
      case AppRoutes.splash:
        return _buildPageRoute(
          const SplashScreen(),
          settings: settings,
        );

      case AppRoutes.roleSelection:
        return _buildPageRoute(
          const RoleSelectionScreen(),
          settings: settings,
        );

      // ==================== Authentication Routes ====================
      case AppRoutes.login:
        final selectedRole = arguments as String?;
        return _buildPageRoute(
          LoginScreen(selectedRole: UserRole.fromString(selectedRole ?? 'customer')),
          settings: settings,
        );

      case AppRoutes.signup:
        final selectedRole = arguments as String?;
        return _buildPageRoute(
          SignUpScreen(selectedRole: UserRole.fromString(selectedRole ?? 'customer')),
          settings: settings,
        );

      // ==================== Customer Routes ====================
      case AppRoutes.customerHome:
        return _buildPageRoute(
          const CustomerHomeScreen(),
          settings: settings,
        );

      case AppRoutes.productList:
        return _buildPageRoute(
          const ProductListScreen(),
          settings: settings,
        );

      case AppRoutes.productDetail:
        final productId = arguments as String;
        return _buildPageRoute(
          ProductDetailScreen(productId: productId),
          settings: settings,
        );

      case AppRoutes.categories:
        return _buildPageRoute(
          const CustomerCategoriesScreen(),
          settings: settings,
        );

      case AppRoutes.search:
        return _buildPageRoute(
          const SearchScreen(),
          settings: settings,
        );

      case AppRoutes.wishlist:
        return _buildPageRoute(
          const CustomerWishlistScreen(),
          settings: settings,
        );

      case AppRoutes.cart:
        return _buildPageRoute(
          const CartScreen(),
          settings: settings,
        );

      case AppRoutes.checkout:
        return _buildPageRoute(
          const CheckoutScreen(),
          settings: settings,
        );

      case AppRoutes.orders:
        return _buildPageRoute(
          const OrdersScreen(),
          settings: settings,
        );

      case AppRoutes.orderDetail:
        final orderId = arguments as String;
        return _buildPageRoute(
          OrderDetailScreen(orderId: orderId),
          settings: settings,
        );

      case AppRoutes.profile:
        return _buildPageRoute(
          const ProfileScreen(),
          settings: settings,
        );

      case AppRoutes.messages:
        return _buildPageRoute(
          const CustomerMessagesScreen(),
          settings: settings,
        );

      case AppRoutes.notifications:
        return _buildPageRoute(
          const CustomerNotificationsScreen(),
          settings: settings,
        );

      // ==================== Supplier Routes ====================
      case AppRoutes.supplierDashboard:
        return _buildPageRoute(
          const SupplierDashboardScreen(),
          settings: settings,
        );

      case AppRoutes.supplierProducts:
        return _buildPageRoute(
          const SupplierProductsListScreen(),
          settings: settings,
        );

      case AppRoutes.supplierProductAdd:
        return _buildPageRoute(
          const SupplierProductAddEditScreen(),
          settings: settings,
        );

      case AppRoutes.supplierProductEdit:
        final productId = arguments as String;
        return _buildPageRoute(
          SupplierProductAddEditScreen(productId: productId),
          settings: settings,
        );

      case AppRoutes.supplierOrders:
        return _buildPageRoute(
          const SupplierOrdersScreen(),
          settings: settings,
        );

      // case AppRoutes.supplierOrderDetail:
      //   final orderId = arguments as String;
      //   return _buildPageRoute(
      //     SupplierOrderDetailScreen(orderId: orderId),
      //     settings: settings,
      //   );

      case AppRoutes.supplierProfile:
        return _buildPageRoute(
          const SupplierProfileScreen(),
          settings: settings,
        );

      // ==================== Admin Routes ====================
      case AppRoutes.adminDashboard:
        return _buildPageRoute(
          const AdminDashboardScreen(),
          settings: settings,
        );

      case AppRoutes.adminUsers:
        return _buildPageRoute(
          const AdminUsersScreen(),
          settings: settings,
        );

      case AppRoutes.adminProducts:
        return _buildPageRoute(
          const AdminProductsScreen(),
          settings: settings,
        );

      case AppRoutes.adminCategories:
        return _buildPageRoute(
          const AdminCategoriesScreen(),
          settings: settings,
        );

      case AppRoutes.adminOrders:
        return _buildPageRoute(
          const AdminOrdersScreen(),
          settings: settings,
        );

      // ==================== Default (404) ====================
      default:
        return _buildPageRoute(
          _build404Screen(routeName),
          settings: settings,
        );
    }
  }

  /// Build a page route with custom transition
  static PageRoute<dynamic> _buildPageRoute(
    Widget page, {
    required RouteSettings settings,
    bool fullscreenDialog = false,
  }) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }

  /// Build custom slide transition route
  static PageRoute<dynamic> _buildSlideRoute(
    Widget page, {
    required RouteSettings settings,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Build custom fade transition route
  static PageRoute<dynamic> _buildFadeRoute(
    Widget page, {
    required RouteSettings settings,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Build 404 Not Found screen
  static Widget _build404Screen(String routeName) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              '404',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Route "$routeName" not found',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate back or to home
              },
              icon: const Icon(Icons.home),
              label: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
