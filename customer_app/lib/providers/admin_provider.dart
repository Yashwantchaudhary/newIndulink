import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';

// ==================== ADMIN SERVICE PROVIDER ====================

final adminServiceProvider = Provider<AdminService>((ref) {
  final authService = AuthService();
  return AdminService(authService);
});

// ==================== ADMIN STATS PROVIDER ====================

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  final result = await adminService.getSystemStats();
  return result['data'];
});

// ==================== USER MANAGEMENT PROVIDERS ====================

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AsyncValue<AdminUsersState>>(
        (ref) {
  final adminService = ref.watch(adminServiceProvider);
  return AdminUsersNotifier(adminService);
});

class AdminUsersState {
  final List<dynamic> users;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final String? searchQuery;
  final String? roleFilter;
  final bool? isActiveFilter;

  AdminUsersState({
    required this.users,
    required this.total,
    this.page = 1,
    this.limit = 20,
    required this.totalPages,
    this.searchQuery,
    this.roleFilter,
    this.isActiveFilter,
  });

  AdminUsersState copyWith({
    List<dynamic>? users,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
    String? searchQuery,
    String? roleFilter,
    bool? isActiveFilter,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: roleFilter ?? this.roleFilter,
      isActiveFilter: isActiveFilter ?? this.isActiveFilter,
    );
  }
}

class AdminUsersNotifier extends StateNotifier<AsyncValue<AdminUsersState>> {
  final AdminService _adminService;

  AdminUsersNotifier(this._adminService) : super(const AsyncValue.loading()) {
    loadUsers();
  }

  Future<void> loadUsers({
    int? page,
    String? search,
    String? role,
    bool? isActive,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _adminService.getAllUsers(
        page: page ?? 1,
        search: search,
        role: role,
        isActive: isActive,
      );

      state = AsyncValue.data(AdminUsersState(
        users: result['data'] as List<dynamic>,
        total: result['pagination']['total'],
        page: result['pagination']['page'],
        limit: result['pagination']['limit'],
        totalPages: result['pagination']['pages'],
        searchQuery: search,
        roleFilter: role,
        isActiveFilter: isActive,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleUserStatus(String userId) async {
    try {
      await _adminService.toggleUserStatus(userId);
      // Reload users after toggle
      final currentState = state.value;
      if (currentState != null) {
        await loadUsers(
          page: currentState.page,
          search: currentState.searchQuery,
          role: currentState.roleFilter,
          isActive: currentState.isActiveFilter,
        );
      }
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _adminService.deleteUser(userId);
      // Reload users after delete
      final currentState = state.value;
      if (currentState != null) {
        await loadUsers(
          page: currentState.page,
          search: currentState.searchQuery,
          role: currentState.roleFilter,
          isActive: currentState.isActiveFilter,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

// ==================== PRODUCT MANAGEMENT PROVIDERS ====================

final adminProductsProvider = StateNotifierProvider<AdminProductsNotifier,
    AsyncValue<AdminProductsState>>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return AdminProductsNotifier(adminService);
});

class AdminProductsState {
  final List<dynamic> products;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final String? searchQuery;
  final String? categoryFilter;
  final String? statusFilter;

  AdminProductsState({
    required this.products,
    required this.total,
    this.page = 1,
    this.limit = 20,
    required this.totalPages,
    this.searchQuery,
    this.categoryFilter,
    this.statusFilter,
  });

  AdminProductsState copyWith({
    List<dynamic>? products,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
    String? searchQuery,
    String? categoryFilter,
    String? statusFilter,
  }) {
    return AdminProductsState(
      products: products ?? this.products,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class AdminProductsNotifier
    extends StateNotifier<AsyncValue<AdminProductsState>> {
  final AdminService _adminService;

  AdminProductsNotifier(this._adminService)
      : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts({
    int? page,
    String? search,
    String? category,
    String? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _adminService.getAllProducts(
        page: page ?? 1,
        search: search,
        category: category,
        status: status,
      );

      state = AsyncValue.data(AdminProductsState(
        products: result['data'] as List<dynamic>,
        total: result['pagination']['total'],
        page: result['pagination']['page'],
        limit: result['pagination']['limit'],
        totalPages: result['pagination']['pages'],
        searchQuery: search,
        categoryFilter: category,
        statusFilter: status,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> approveProduct(String productId) async {
    try {
      await _adminService.approveProduct(productId);
      // Reload products
      final currentState = state.value;
      if (currentState != null) {
        await loadProducts(
          page: currentState.page,
          search: currentState.searchQuery,
          category: currentState.categoryFilter,
          status: currentState.statusFilter,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> featureProduct(String productId, bool isFeatured) async {
    try {
      await _adminService.featureProduct(productId, isFeatured);
      // Reload products
      final currentState = state.value;
      if (currentState != null) {
        await loadProducts(
          page: currentState.page,
          search: currentState.searchQuery,
          category: currentState.categoryFilter,
          status: currentState.statusFilter,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

// ==================== ORDER MANAGEMENT PROVIDERS ====================

final adminOrdersProvider =
    StateNotifierProvider<AdminOrdersNotifier, AsyncValue<AdminOrdersState>>(
        (ref) {
  final adminService = ref.watch(adminServiceProvider);
  return AdminOrdersNotifier(adminService);
});

class AdminOrdersState {
  final List<dynamic> orders;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final String? searchQuery;
  final String? statusFilter;

  AdminOrdersState({
    required this.orders,
    required this.total,
    this.page = 1,
    this.limit = 20,
    required this.totalPages,
    this.searchQuery,
    this.statusFilter,
  });

  AdminOrdersState copyWith({
    List<dynamic>? orders,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
    String? searchQuery,
    String? statusFilter,
  }) {
    return AdminOrdersState(
      orders: orders ?? this.orders,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class AdminOrdersNotifier extends StateNotifier<AsyncValue<AdminOrdersState>> {
  final AdminService _adminService;

  AdminOrdersNotifier(this._adminService) : super(const AsyncValue.loading()) {
    loadOrders();
  }

  Future<void> loadOrders({
    int? page,
    String? search,
    String? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _adminService.getAllOrders(
        page: page ?? 1,
        search: search,
        status: status,
      );

      state = AsyncValue.data(AdminOrdersState(
        orders: result['data'] as List<dynamic>,
        total: result['pagination']['total'],
        page: result['pagination']['page'],
        limit: result['pagination']['limit'],
        totalPages: result['pagination']['pages'],
        searchQuery: search,
        statusFilter: status,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateOrderStatus(String orderId, String status,
      {String? note}) async {
    try {
      await _adminService.updateOrderStatus(orderId, status, note: note);
      // Reload orders
      final currentState = state.value;
      if (currentState != null) {
        await loadOrders(
          page: currentState.page,
          search: currentState.searchQuery,
          status: currentState.statusFilter,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

// ==================== SUPPLIER MANAGEMENT PROVIDERS ====================

final adminSuppliersProvider = StateNotifierProvider<AdminSuppliersNotifier,
    AsyncValue<AdminSuppliersState>>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return AdminSuppliersNotifier(adminService);
});

class AdminSuppliersState {
  final List<dynamic> suppliers;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final String? searchQuery;
  final bool? isActiveFilter;

  AdminSuppliersState({
    required this.suppliers,
    required this.total,
    this.page = 1,
    this.limit = 20,
    required this.totalPages,
    this.searchQuery,
    this.isActiveFilter,
  });

  AdminSuppliersState copyWith({
    List<dynamic>? suppliers,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
    String? searchQuery,
    bool? isActiveFilter,
  }) {
    return AdminSuppliersState(
      suppliers: suppliers ?? this.suppliers,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      isActiveFilter: isActiveFilter ?? this.isActiveFilter,
    );
  }
}

class AdminSuppliersNotifier
    extends StateNotifier<AsyncValue<AdminSuppliersState>> {
  final AdminService _adminService;

  AdminSuppliersNotifier(this._adminService)
      : super(const AsyncValue.loading()) {
    loadSuppliers();
  }

  Future<void> loadSuppliers({
    int? page,
    String? search,
    bool? isActive,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _adminService.getAllSuppliers(
        page: page ?? 1,
        search: search,
        isActive: isActive,
      );

      state = AsyncValue.data(AdminSuppliersState(
        suppliers: result['data'] as List<dynamic>,
        total: result['pagination']['total'],
        page: result['pagination']['page'],
        limit: result['pagination']['limit'],
        totalPages: result['pagination']['pages'],
        searchQuery: search,
        isActiveFilter: isActive,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> approveSupplier(String supplierId) async {
    try {
      await _adminService.approveSupplier(supplierId);
      // Reload suppliers
      final currentState = state.value;
      if (currentState != null) {
        await loadSuppliers(
          page: currentState.page,
          search: currentState.searchQuery,
          isActive: currentState.isActiveFilter,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> suspendSupplier(String supplierId) async {
    try {
      await _adminService.suspendSupplier(supplierId);
      // Reload suppliers
      final currentState = state.value;
      if (currentState != null) {
        await loadSuppliers(
          page: currentState.page,
          search: currentState.searchQuery,
          isActive: currentState.isActiveFilter,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
