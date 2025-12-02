import 'package:flutter/material.dart';

// Routes
import 'app_routes.dart';

// Models
import '../models/user.dart';

// Widgets
import '../core/widgets/route_guard_widget.dart';

// Screens - Initial
import '../screens/splash/splash_screen.dart';
import '../screens/role_selection/role_selection_screen.dart';

// Screens - Auth
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';

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
import '../screens/customer/profile/address_screen.dart';
import '../screens/customer/profile/add_edit_address_screen.dart';
import '../screens/customer/messages/customer_messages_screen.dart';
import '../screens/customer/notifications/customer_notifications_screen.dart';
import '../screens/customer/supplier_profile/customer_supplier_profile_screen.dart';
import '../screens/customer/products/full_reviews_screen.dart';
import '../screens/customer/rfq/customer_rfq_list_screen.dart';
import '../screens/customer/rfq/customer_rfq_detail_screen.dart';
import '../screens/customer/rfq/create_rfq_screen.dart';
import '../screens/customer/data/customer_data_management_screen.dart';
import '../screens/legal/legal_screen.dart';

// Screens - Test
import '../screens/test/test_api_screen.dart';

// Screens - Settings
import '../screens/settings/notification_settings_screen.dart';

// Screens - Supplier
import '../screens/supplier/dashboard/supplier_dashboard_screen.dart';
import '../screens/supplier/products/supplier_products_list_screen.dart';
import '../screens/supplier/products/supplier_product_add_edit_screen.dart';
import '../screens/supplier/orders/supplier_orders_screen.dart';
import '../screens/supplier/orders/supplier_order_detail_screen.dart';
import '../screens/supplier/analytics/supplier_analytics_screen.dart';
import '../screens/supplier/profile/supplier_profile_screen.dart';
import '../screens/supplier/data/supplier_data_management_screen.dart';

// Screens - Admin
import '../screens/admin/dashboard/admin_dashboard_screen.dart';
import '../screens/admin/users/admin_users_screen.dart';
import '../screens/admin/products/admin_products_screen.dart';
import '../screens/admin/categories/admin_categories_screen.dart';
import '../screens/admin/orders/admin_orders_screen.dart';
import '../screens/admin/data/admin_data_management_screen.dart';

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

    // Route guards will be handled by individual screens or providers
    // For now, allow all routes and let screens handle authentication

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
          LoginScreen(
              selectedRole: UserRole.fromString(selectedRole ?? 'customer')),
          settings: settings,
        );

      case AppRoutes.signup:
        final selectedRole = arguments as String?;
        return _buildPageRoute(
          SignUpScreen(
              selectedRole: UserRole.fromString(selectedRole ?? 'customer')),
          settings: settings,
        );

      case AppRoutes.forgotPassword:
        return _buildPageRoute(
          const ForgotPasswordScreen(),
          settings: settings,
        );

      // ==================== Customer Routes ====================
      case AppRoutes.customerHome:
        return _buildPageRoute(
          CustomerRouteGuard(child: const CustomerHomeScreen()),
          settings: settings,
        );

      case AppRoutes.customerDataManagement:
        return _buildPageRoute(
          CustomerRouteGuard(child: const CustomerDataManagementScreen()),
          settings: settings,
        );

      case AppRoutes.productList:
        return _buildPageRoute(
          CustomerRouteGuard(child: const ProductListScreen()),
          settings: settings,
        );

      case AppRoutes.productDetail:
        final productId = arguments as String;
        return _buildPageRoute(
          CustomerRouteGuard(child: ProductDetailScreen(productId: productId)),
          settings: settings,
        );

      case AppRoutes.categories:
        return _buildPageRoute(
          CustomerRouteGuard(child: const CustomerCategoriesScreen()),
          settings: settings,
        );

      case AppRoutes.search:
        return _buildPageRoute(
          CustomerRouteGuard(child: const SearchScreen()),
          settings: settings,
        );

      case AppRoutes.wishlist:
        return _buildPageRoute(
          CustomerRouteGuard(child: const CustomerWishlistScreen()),
          settings: settings,
        );

      case AppRoutes.cart:
        return _buildPageRoute(
          CustomerRouteGuard(child: const CartScreen()),
          settings: settings,
        );

      case AppRoutes.checkout:
        return _buildPageRoute(
          CustomerRouteGuard(child: const CheckoutScreen()),
          settings: settings,
        );

      case AppRoutes.orders:
        return _buildPageRoute(
          CustomerRouteGuard(child: const OrdersScreen()),
          settings: settings,
        );

      case AppRoutes.orderDetail:
        final orderId = arguments as String;
        return _buildPageRoute(
          CustomerRouteGuard(child: OrderDetailScreen(orderId: orderId)),
          settings: settings,
        );

      case AppRoutes.profile:
        return _buildPageRoute(
          CustomerRouteGuard(child: const ProfileScreen()),
          settings: settings,
        );

      case AppRoutes.messages:
        return _buildPageRoute(
          CustomerRouteGuard(child: const CustomerMessagesScreen()),
          settings: settings,
        );

      case AppRoutes.notifications:
        return _buildPageRoute(
          CustomerRouteGuard(child: const CustomerNotificationsScreen()),
          settings: settings,
        );

      case AppRoutes.supplierProfileView:
        final supplierId = arguments as String;
        return _buildPageRoute(
          CustomerRouteGuard(
              child: CustomerSupplierProfileScreen(supplierId: supplierId)),
          settings: settings,
        );

      case AppRoutes.fullReviews:
        final args = arguments as Map<String, dynamic>;
        final productId = args['productId'] as String;
        final productTitle = args['productTitle'] as String;
        final productImage = args['productImage'] as String?;
        return _buildPageRoute(
          CustomerRouteGuard(
              child: FullReviewsScreen(
            productId: productId,
            productTitle: productTitle,
            productImage: productImage,
          )),
          settings: settings,
        );

      case AppRoutes.addresses:
        return _buildPageRoute(
          CustomerRouteGuard(child: const AddressScreen()),
          settings: settings,
        );

      case AppRoutes.addAddress:
        return _buildPageRoute(
          CustomerRouteGuard(child: const AddEditAddressScreen()),
          settings: settings,
        );

      case AppRoutes.editAddress:
        // For now, we'll pass null since we need to fetch the address by ID
        // In a real implementation, you'd fetch the address first
        return _buildPageRoute(
          CustomerRouteGuard(child: const AddEditAddressScreen()),
          settings: settings,
        );

      // RFQ Routes
      case AppRoutes.rfqList:
        return _buildPageRoute(
          CustomerRouteGuard(child: const CustomerRFQListScreen()),
          settings: settings,
        );

      case AppRoutes.rfqDetail:
        final rfqId = arguments as String;
        return _buildPageRoute(
          CustomerRouteGuard(child: CustomerRFQDetailScreen(rfqId: rfqId)),
          settings: settings,
        );

      case AppRoutes.createRfq:
        return _buildPageRoute(
          CustomerRouteGuard(child: const CreateRFQScreen()),
          settings: settings,
        );

      // ==================== Legal Routes ====================
      case AppRoutes.privacyPolicy:
        return _buildPageRoute(
          const PrivacyPolicyScreen(),
          settings: settings,
        );

      case AppRoutes.termsOfService:
        return _buildPageRoute(
          const TermsOfServiceScreen(),
          settings: settings,
        );

      // ==================== Test Routes ====================
      case '/test-api':
        return _buildPageRoute(
          const ApiTestScreen(),
          settings: settings,
        );

      // ==================== Supplier Routes ====================
      case AppRoutes.supplierDashboard:
        return _buildPageRoute(
          SupplierRouteGuard(child: const SupplierDashboardScreen()),
          settings: settings,
        );

      case AppRoutes.supplierDataManagement:
        return _buildPageRoute(
          SupplierRouteGuard(child: const SupplierDataManagementScreen()),
          settings: settings,
        );

      case AppRoutes.supplierProducts:
        return _buildPageRoute(
          SupplierRouteGuard(child: const SupplierProductsListScreen()),
          settings: settings,
        );

      case AppRoutes.supplierProductAdd:
        return _buildPageRoute(
          SupplierRouteGuard(child: const SupplierProductAddEditScreen()),
          settings: settings,
        );

      case AppRoutes.supplierProductEdit:
        final productId = arguments as String;
        return _buildPageRoute(
          SupplierRouteGuard(
              child: SupplierProductAddEditScreen(productId: productId)),
          settings: settings,
        );

      case AppRoutes.supplierOrders:
        return _buildPageRoute(
          SupplierRouteGuard(child: const SupplierOrdersScreen()),
          settings: settings,
        );

      case AppRoutes.supplierOrderDetail:
        final orderId = arguments as String;
        return _buildPageRoute(
          SupplierRouteGuard(
              child: SupplierOrderDetailScreen(orderId: orderId)),
          settings: settings,
        );

      case AppRoutes.supplierProfile:
        return _buildPageRoute(
          SupplierRouteGuard(child: const SupplierProfileScreen()),
          settings: settings,
        );

      case AppRoutes.supplierAnalytics:
        return _buildPageRoute(
          SupplierRouteGuard(child: const SupplierAnalyticsScreen()),
          settings: settings,
        );

      // ==================== Admin Routes ====================
      case AppRoutes.adminDashboard:
        return _buildPageRoute(
          AdminRouteGuard(child: const AdminDashboardScreen()),
          settings: settings,
        );

      case AppRoutes.adminUsers:
        return _buildPageRoute(
          AdminRouteGuard(child: const AdminUsersScreen()),
          settings: settings,
        );

      case AppRoutes.adminProducts:
        return _buildPageRoute(
          AdminRouteGuard(child: const AdminProductsScreen()),
          settings: settings,
        );

      case AppRoutes.adminCategories:
        return _buildPageRoute(
          AdminRouteGuard(child: const AdminCategoriesScreen()),
          settings: settings,
        );

      case AppRoutes.adminOrders:
        return _buildPageRoute(
          AdminRouteGuard(child: const AdminOrdersScreen()),
          settings: settings,
        );

      // ==================== Data Management Routes ====================
      case AppRoutes.adminDataManagement:
        return _buildPageRoute(
          AdminRouteGuard(child: const AdminDataManagementScreen()),
          settings: settings,
        );

      case AppRoutes.adminDataUsers:
        return _buildPageRoute(
          AdminRouteGuard(child: const AdminDataManagementScreen()), // TODO: Create specific screen
          settings: settings,
        );

      case AppRoutes.adminDataProducts:
        return _buildPageRoute(
          AdminRouteGuard(child: const AdminDataManagementScreen()), // TODO: Create specific screen
          settings: settings,
        );

      case AppRoutes.adminDataCategories:
        return _buildPageRoute(
          AdminRouteGuard(child: const AdminDataManagementScreen()), // TODO: Create specific screen
          settings: settings,
        );

      case AppRoutes.adminDataOrders:
        return _buildPageRoute(
          AdminRouteGuard(child: const AdminDataManagementScreen()), // TODO: Create specific screen
          settings: settings,
        );

      case AppRoutes.adminDataReviews:
        return _buildPageRoute(
          AdminRouteGuard(child: const AdminDataManagementScreen()), // TODO: Create specific screen
          settings: settings,
        );

      case AppRoutes.adminDataRfqs:
        return _buildPageRoute(
          AdminRouteGuard(child: const AdminDataManagementScreen()), // TODO: Create specific screen
          settings: settings,
        );

      case AppRoutes.adminDataMessages:
        return _buildPageRoute(
          AdminRouteGuard(child: const AdminDataManagementScreen()), // TODO: Create specific screen
          settings: settings,
        );

      case AppRoutes.adminDataNotifications:
        return _buildPageRoute(
          AdminRouteGuard(child: const AdminDataManagementScreen()), // TODO: Create specific screen
          settings: settings,
        );

      case AppRoutes.adminDataBadges:
        return _buildPageRoute(
          AdminRouteGuard(child: const AdminDataManagementScreen()), // TODO: Create specific screen
          settings: settings,
        );

      // ==================== Settings Routes ====================
      case AppRoutes.notificationSettings:
        return _buildPageRoute(
          const NotificationSettingsScreen(),
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
