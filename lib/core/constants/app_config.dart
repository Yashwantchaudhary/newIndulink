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
  // Change these to your actual backend URLs
  static const String devBaseUrl = 'http://localhost:5000/api';
  static const String prodBaseUrl = 'https://your-production-api.com/api';

  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;

  // ==================== API Version ====================
  static const String apiVersion = 'v1';

  // ==================== Timeout Configuration ====================
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ==================== Authentication Endpoints ====================
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String googleLoginEndpoint = '/auth/google';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String verifyEmailEndpoint = '/auth/verify-email';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String changePasswordEndpoint = '/auth/change-password';

  // ==================== User Endpoints ====================
  static const String userProfileEndpoint = '/users/profile';
  static const String updateProfileEndpoint = '/users/profile';
  static const String uploadProfileImageEndpoint = '/users/profile-image';
  static const String userAddressesEndpoint = '/users/addresses';
  static const String userWishlistEndpoint = '/users/wishlist';
  static const String userOrdersEndpoint = '/users/orders';

  // ==================== Product Endpoints ====================
  static const String productsEndpoint = '/products';
  static const String productDetailsEndpoint = '/products/:id';
  static const String featuredProductsEndpoint = '/products/featured';
  static const String searchProductsEndpoint = '/products/search';
  static const String productReviewsEndpoint = '/products/:id/reviews';
  static const String addReviewEndpoint = '/products/:id/reviews';

  // ==================== Category Endpoints ====================
  static const String categoriesEndpoint = '/categories';
  static const String categoryProductsEndpoint = '/categories/:id/products';

  // ==================== Cart Endpoints ====================
  static const String cartEndpoint = '/cart';
  static const String addToCartEndpoint = '/cart/add';
  static const String updateCartEndpoint = '/cart/update';
  static const String removeFromCartEndpoint = '/cart/remove';
  static const String clearCartEndpoint = '/cart/clear';

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

  // ==================== Admin Endpoints ====================
  static const String adminDashboardEndpoint = '/admin/dashboard';
  static const String adminUsersEndpoint = '/admin/users';
  static const String adminProductsEndpoint = '/admin/products';
  static const String adminOrdersEndpoint = '/admin/orders';
  static const String adminCategoriesEndpoint = '/admin/categories';
  static const String adminAnalyticsEndpoint = '/admin/analytics';

  // ==================== Wishlist Endpoints ====================
  static const String wishlistEndpoint = '/wishlist';
  static const String addToWishlistEndpoint = '/wishlist/add';
  static const String removeFromWishlistEndpoint = '/wishlist/remove';

  // ==================== Notification Endpoints ====================
  static const String notificationsEndpoint = '/notifications';
  static const String markNotificationReadEndpoint = '/notifications/:id/read';
  static const String fcmTokenEndpoint = '/notifications/fcm-token';

  // ==================== Message/Chat Endpoints ====================
  static const String conversationsEndpoint = '/conversations';
  static const String messagesEndpoint = '/conversations/:id/messages';
  static const String sendMessageEndpoint = '/conversations/:id/messages';

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
