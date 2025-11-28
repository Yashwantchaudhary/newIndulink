/// Modern App Routes Configuration
class AppRoutes {
  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String roleSelection = '/role-selection';

  // Customer Routes
  static const String customerHome = '/customer/home';
  static const String customerProfile = '/customer/profile';
  static const String customerWishlist = '/customer/wishlist';
  static const String customerOrders = '/customer/orders';
  static const String customerCart = '/customer/cart';
  static const String customerCheckout = '/customer/checkout';
  static const String customerNotifications = '/customer/notifications';
  static const String customerAddresses = '/customer/addresses';
  static const String customerPaymentMethods = '/customer/payment-methods';
  static const String customerRFQList = '/customer/rfq-list';
  static const String customerConversations = '/customer/conversations';
  static const String customerChat = '/customer/chat';
  static const String customerHelpCenter = '/customer/help-center';

  // Product Routes
  static const String categories = '/categories';
  static const String categoryProducts = '/category-products';
  static const String productDetail = '/product';
  static const String productSearch = '/search';
  static const String productReviews = '/product/reviews';

  // Supplier Routes
  static const String supplierDashboard = '/supplier/dashboard';
  static const String supplierProducts = '/supplier/products';
  static const String supplierAddProduct = '/supplier/products/add';
  static const String supplierEditProduct = '/supplier/products/edit';
  static const String supplierOrders = '/supplier/orders';
  static const String supplierOrderDetail = '/supplier/orders/detail';
  static const String supplierAnalytics = '/supplier/analytics';
  static const String supplierInventory = '/supplier/inventory';
  static const String supplierRFQList = '/supplier/rfq-list';
  static const String supplierProfile = '/supplier/profile';

  // All Routes Map
  static Map<String, String> get allRoutes => {
        splash: '/',
        login: '/login',
        register: '/register',
        forgotPassword: '/forgot-password',
        roleSelection: '/role-selection',
        customerHome: '/customer/home',
        customerProfile: '/customer/profile',
        customerWishlist: '/customer/wishlist',
        customerOrders: '/customer/orders',
        customerCart: '/customer/cart',
        customerCheckout: '/customer/checkout',
        customerNotifications: '/customer/notifications',
        customerAddresses: '/customer/addresses',
        customerPaymentMethods: '/customer/payment-methods',
        customerRFQList: '/customer/rfq-list',
        customerConversations: '/customer/conversations',
        customerChat: '/customer/chat',
        customerHelpCenter: '/customer/help-center',
        categories: '/categories',
        categoryProducts: '/category-products',
        productDetail: '/product',
        productSearch: '/search',
        productReviews: '/product/reviews',
        supplierDashboard: '/supplier/dashboard',
        supplierProducts: '/supplier/products',
        supplierAddProduct: '/supplier/products/add',
        supplierEditProduct: '/supplier/products/edit',
        supplierOrders: '/supplier/orders',
        supplierOrderDetail: '/supplier/orders/detail',
        supplierAnalytics: '/supplier/analytics',
        supplierInventory: '/supplier/inventory',
        supplierRFQList: '/supplier/rfq-list',
        supplierProfile: '/supplier/profile',
      };
}

/// Route Arguments Classes
class ProductDetailArgs {
  final String productId;
  final String? heroTag;

  ProductDetailArgs({
    required this.productId,
    this.heroTag,
  });
}

class CategoryProductsArgs {
  final String categoryId;
  final String categoryName;

  CategoryProductsArgs({
    required this.categoryId,
    required this.categoryName,
  });
}

class ChatArgs {
  final String chatId;
  final String recipientName;
  final String recipientRole;

  ChatArgs({
    required this.chatId,
    required this.recipientName,
    required this.recipientRole,
  });
}

class OrderDetailArgs {
  final String orderId;

  OrderDetailArgs({required this.orderId});
}

class ProductReviewsArgs {
  final String productId;
  final double averageRating;
  final int totalReviews;

  ProductReviewsArgs({
    required this.productId,
    required this.averageRating,
    required this.totalReviews,
  });
}

class EditProductArgs {
  final String productId;

  EditProductArgs({required this.productId});
}
