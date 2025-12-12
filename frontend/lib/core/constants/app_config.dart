import 'package:flutter/foundation.dart' show kIsWeb;

/// 🔗 API Configuration and Endpoints
class AppConfig {
  AppConfig._();

  // ==================== Environment Configuration ====================
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';

  // ==================== API Base URLs ====================
  // For Android Emulator: 10.0.2.2 maps to localhost on host machine
  // For iOS Simulator: localhost works directly
  // For Physical devices: Use your computer's actual IP address (e.g., 192.168.x.x)
  // For Web: Use localhost

  // Change this to your computer's IP for testing on physical devices
  static const String _hostIp =
      '192.168.1.206'; // Computer's IP address for physical device testing
  static const int _port = 5000;

  static String get devBaseUrl {
    // Web uses localhost directly
    if (kIsWeb) {
      return 'http://localhost:$_port/api';
    }
    // Android emulator uses 10.0.2.2 to reach host machine's localhost
    // For physical device testing, change _hostIp to your computer's IP
    return 'http://$_hostIp:$_port/api';
  }

  static const String prodBaseUrl = 'https://your-production-api.com/api';

  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;

  static String get serverUrl {
    if (isProduction) return 'https://your-production-api.com';
    if (kIsWeb) return 'http://localhost:$_port';
    return 'http://$_hostIp:$_port';
  }

  // ==================== API Version ====================
  static const String apiVersion = 'v1';

  // ==================== Timeout Configuration ====================
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ==================== Authentication Endpoints ====================
  static const String loginEndpoint = '/auth/login';
  static const String googleLoginEndpoint = '/auth/google';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String verifyEmailEndpoint = '/auth/verify-email';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String changePasswordEndpoint =
      '/auth/update-password'; // Changed from /auth/change-password to match backend
  static const String deleteAccountEndpoint = '/auth/delete-account';

  // ==================== User Endpoints ====================
  static const String userProfileEndpoint = '/users/profile';
  static const String publicProfileEndpoint = '/users/:id/public-profile';
  static const String updateProfileEndpoint = '/users/profile';
  static const String uploadProfileImageEndpoint = '/users/profile/image';
  static const String userAddressesEndpoint = '/users/addresses';
  static const String userWishlistEndpoint = '/users/wishlist';
  static const String userOrdersEndpoint = '/users/orders';
  static const String addressesEndpoint = '/addresses';
  static const String addAddressEndpoint = '/addresses';
  static const String updateAddressEndpoint = '/addresses/:id';
  static const String deleteAddressEndpoint = '/addresses/:id';
  static const String setDefaultAddressEndpoint = '/addresses/:id/set-default';

  // ==================== Product Endpoints ====================
  static const String productsEndpoint = '/products';
  static const String productDetailsEndpoint = '/products/:id';
  static const String featuredProductsEndpoint = '/products/featured';
  static const String searchProductsEndpoint = '/products/search';
  static const String productReviewsEndpoint = '/reviews/product/:id';
  static const String addReviewEndpoint = '/reviews';
  static const String updateReviewEndpoint = '/reviews/:id';
  static const String deleteReviewEndpoint = '/reviews/:id';
  static const String markReviewHelpfulEndpoint = '/reviews/:id/helpful';
  static const String supplierReviewsEndpoint = '/reviews/supplier/me';
  static const String replyToReviewEndpoint = '/reviews/:id/response';

  // ==================== Category Endpoints ====================
  static const String categoriesEndpoint = '/categories';
  static const String categoryProductsEndpoint = '/categories/:id/products';

  // ==================== Cart Endpoints ====================
  static const String cartEndpoint = '/cart';
  static const String addToCartEndpoint = '/cart'; // POST to /cart to add items
  static const String updateCartEndpoint =
      '/cart'; // PUT to /cart/:itemId to update
  static const String removeFromCartEndpoint =
      '/cart'; // DELETE to /cart/:itemId to remove
  static const String clearCartEndpoint = '/cart'; // DELETE to /cart to clear

  // ==================== Order Endpoints ====================
  static const String ordersEndpoint = '/orders';
  static const String createOrderEndpoint = '/orders';
  static const String orderDetailsEndpoint = '/orders/:id';
  static const String cancelOrderEndpoint = '/orders/:id/cancel';
  static const String trackOrderEndpoint = '/orders/:id/track';

  // ==================== Supplier Endpoints ====================
  static const String supplierProductsEndpoint = '/supplier/products';
  static const String supplierOrdersEndpoint = '/supplier/orders';
  static const String supplierDashboardEndpoint = '/supplier/dashboard';
  static const String supplierAnalyticsEndpoint = '/supplier/analytics';
  static const String createProductEndpoint = '/supplier/products';
  static const String updateProductEndpoint = '/supplier/products/:id';
  static const String deleteProductEndpoint = '/supplier/products/:id';
  static const String updateOrderStatusEndpoint = '/supplier/orders/:id/status';
  static const String updateOrderTrackingEndpoint = '/orders/:id/tracking';

  // ==================== Admin Endpoints ====================
  static const String adminDashboardEndpoint = '/dashboard/admin';
  static const String adminUsersEndpoint = '/admin/users';
  static const String adminProductsEndpoint = '/admin/products';
  static const String adminOrdersEndpoint = '/admin/orders';
  static const String adminCategoriesEndpoint = '/admin/categories';
  static const String adminAnalyticsEndpoint = '/admin/analytics';

  // ==================== Wishlist Endpoints ====================
  static const String wishlistEndpoint = '/wishlist';

  // ==================== Notification Endpoints ====================
  static const String notificationsEndpoint = '/notifications';
  static const String markNotificationReadEndpoint = '/notifications/:id/read';
  static const String markAllNotificationsReadEndpoint =
      '/notifications/read-all';

  // ==================== Message/Chat Endpoints ====================
  static const String conversationsEndpoint = '/messages/conversations';
  static const String conversationMessagesEndpoint =
      '/messages/conversation/:userId';
  static const String sendMessageEndpoint = '/messages';
  static const String markMessagesReadEndpoint =
      '/messages/read/:conversationId';

  // ==================== RFQ (Request for Quotation) Endpoints ====================
  static const String rfqEndpoint = '/rfq';
  static const String createRfqEndpoint = '/rfq';
  static const String rfqDetailsEndpoint = '/rfq/:id';
  static const String respondRfqEndpoint = '/rfq/:id/respond';

  // ==================== Helper Methods ====================
  /// Replace path parameters in endpoint
  /// Example: replaceParams('/products/:id', {'id': '123'}) -> '/products/123'
  static String replaceParams(String endpoint, Map<String, String> params) {
    String result = endpoint;
    params.forEach((key, value) {
      result = result.replaceAll(':$key', value);
    });
    return result;
  }

  /// Build full API URL
  static String buildUrl(String endpoint, [Map<String, String>? params]) {
    String finalEndpoint = endpoint;
    if (params != null && params.isNotEmpty) {
      finalEndpoint = replaceParams(endpoint, params);
    }
    return '$baseUrl$finalEndpoint';
  }
}

/// 🎨 App Information
class AppInfo {
  AppInfo._();

  static const String appName = 'INDULINK';
  static const String appTagline = 'Building Materials Marketplace';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Contact Information
  static const String supportEmail = 'support@indulink.com';
  static const String supportPhone = '+977 9800000000';
  static const String website = 'https://indulink.com';

  // Social Media
  static const String facebookUrl = 'https://facebook.com/indulink';
  static const String instagramUrl = 'https://instagram.com/indulink';
  static const String twitterUrl = 'https://twitter.com/indulink';

  // Legal
  static const String privacyPolicyUrl = 'https://indulink.com/privacy';
  static const String termsOfServiceUrl = 'https://indulink.com/terms';
}

/// 🔑 Storage Keys for SharedPreferences
class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String isLoggedIn = 'is_logged_in';
  static const String fcmToken = 'fcm_token';
  static const String themeMode = 'theme_mode';
  static const String languageCode = 'language_code';
  static const String onboardingComplete = 'onboarding_complete';
  static const String cartItems = 'cart_items';
  static const String searchHistory = 'search_history';
  static const String recentlyViewed = 'recently_viewed';
}
