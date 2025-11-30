/// 🗺️ App Routes Configuration
/// Centralized route name constants for type-safe navigation
class AppRoutes {
  AppRoutes._(); // Private constructor to prevent instantiation

  // ==================== Initial Routes ====================
  static const String splash = '/';
  static const String roleSelection = '/role-selection';

  // ==================== Authentication Routes ====================
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // ==================== Customer Routes ====================
  static const String customerHome = '/customer/home';
  static const String customerDashboard = '/customer/dashboard';

  // Products
  static const String productList = '/customer/products';
  static const String productDetail = '/customer/products/detail';
  static const String categoryProducts = '/customer/categories/products';

  // Search & Filter
  static const String search = '/customer/search';
  static const String searchResults = '/customer/search/results';

  // Categories
  static const String categories = '/customer/categories';

  // Wishlist
  static const String wishlist = '/customer/wishlist';

  // Cart & Checkout
  static const String cart = '/customer/cart';
  static const String checkout = '/customer/checkout';

  // Orders
  static const String orders = '/customer/orders';
  static const String orderDetail = '/customer/orders/detail';
  static const String orderTracking = '/customer/orders/tracking';

  // Profile & Settings
  static const String profile = '/customer/profile';
  static const String editProfile = '/customer/profile/edit';
  static const String addresses = '/customer/addresses';
  static const String addAddress = '/customer/addresses/add';
  static const String editAddress = '/customer/addresses/edit';
  static const String paymentMethods = '/customer/payment-methods';

  // Messages & Notifications
  static const String messages = '/customer/messages';
  static const String conversation = '/customer/messages/conversation';
  static const String notifications = '/customer/notifications';

  // RFQ (Request for Quote)
  static const String rfqList = '/customer/rfq';
  static const String rfqDetail = '/customer/rfq/detail';
  static const String createRfq = '/customer/rfq/create';

  // ==================== Supplier Routes ====================
  static const String supplierDashboard = '/supplier/dashboard';

  // Supplier Products
  static const String supplierProducts = '/supplier/products';
  static const String supplierProductAdd = '/supplier/products/add';
  static const String supplierProductEdit = '/supplier/products/edit';
  static const String supplierProductDetail = '/supplier/products/detail';

  // Supplier Orders
  static const String supplierOrders = '/supplier/orders';
  static const String supplierOrderDetail = '/supplier/orders/detail';

  // Supplier Profile
  static const String supplierProfile = '/supplier/profile';
  static const String supplierEditProfile = '/supplier/profile/edit';

  // Supplier Analytics
  static const String supplierAnalytics = '/supplier/analytics';

  // Supplier RFQ
  static const String supplierRfqList = '/supplier/rfq';
  static const String supplierRfqDetail = '/supplier/rfq/detail';

  // ==================== Admin Routes ====================
  static const String adminDashboard = '/admin/dashboard';

  // Admin Usersssssssss
  static const String adminUsers = '/admin/users';
  static const String adminUserDetail = '/admin/users/detail';

  // Admin Products
  static const String adminProducts = '/admin/products';
  static const String adminProductDetail = '/admin/products/detail';

  // Admin Categories
  static const String adminCategories = '/admin/categories';
  static const String adminCategoryDetail = '/admin/categories/detail';

  // Admin Orders
  static const String adminOrders = '/admin/orders';
  static const String adminOrderDetail = '/admin/orders/detail';

  // Admin Analytics
  static const String adminAnalytics = '/admin/analytics';
  static const String adminReports = '/admin/reports';

  // ==================== Common Routes ====================
  static const String settings = '/settings';
  static const String help = '/help';
  static const String about = '/about';
  static const String termsOfService = '/terms-of-service';
  static const String privacyPolicy = '/privacy-policy';

  // ==================== Helper Methods ====================

  /// Get initial route based on authentication state and user role
  static String getInitialRoute({
    required bool isAuthenticated,
    String? userRole,
  }) {
    if (!isAuthenticated) {
      return splash;
    }

    switch (userRole?.toLowerCase()) {
      case 'customer':
        return customerHome;
      case 'supplier':
        return supplierDashboard;
      case 'admin':
        return adminDashboard;
      default:
        return roleSelection;
    }
  }

  /// Check if route is protected (requires authentication)
  static bool isProtectedRoute(String route) {
    return route != splash &&
        route != roleSelection &&
        route != login &&
        route != signup &&
        route != forgotPassword &&
        route != resetPassword;
  }

  /// Check if route is for specific role
  static bool isRoleAuthorized(String route, String? userRole) {
    if (userRole == null) return false;

    if (route.startsWith('/customer/')) {
      return userRole.toLowerCase() == 'customer';
    } else if (route.startsWith('/supplier/')) {
      return userRole.toLowerCase() == 'supplier';
    } else if (route.startsWith('/admin/')) {
      return userRole.toLowerCase() == 'admin';
    }

    return true; // Common routes accessible to all
  }
}
