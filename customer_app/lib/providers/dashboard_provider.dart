import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_models.dart';
import '../services/dashboard_service.dart';
import 'auth_provider.dart';

// ===== ADMIN DASHBOARD STATE =====

/// Admin dashboard state
class AdminDashboardState {
  final AdminDashboardData? data;
  final bool isLoading;
  final String? error;

  AdminDashboardState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  AdminDashboardState copyWith({
    AdminDashboardData? data,
    bool? isLoading,
    String? error,
  }) {
    return AdminDashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Admin dashboard provider
class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  final DashboardService _service;

  AdminDashboardNotifier(this._service) : super(AdminDashboardState());

  /// Fetch admin dashboard data
  Future<void> fetchDashboard() async {
    developer.log('Fetching admin dashboard data',
        name: 'AdminDashboardProvider');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = await _service.getAdminDashboard();
      developer.log('Admin dashboard data fetched successfully',
          name: 'AdminDashboardProvider');
      state = state.copyWith(
        data: data,
        isLoading: false,
      );
    } catch (e) {
      developer.log('Error fetching admin dashboard: $e',
          name: 'AdminDashboardProvider', error: e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh admin dashboard data
  Future<void> refresh() async {
    await fetchDashboard();
  }
}

final adminDashboardProvider =
    StateNotifierProvider<AdminDashboardNotifier, AdminDashboardState>(
  (ref) {
    final service = ref.watch(dashboardServiceProvider);
    return AdminDashboardNotifier(service);
  },
);

/// Provider for dashboard service
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final service = DashboardService();

  // Watch auth state - no need to manually set token
  // ApiService automatically adds token from SharedPreferences
  ref.listen<AuthState>(authProvider, (previous, next) {
    // Token is handled by ApiService interceptor
    // Just log for debugging
    developer.log('Auth state changed: isAuthenticated=${next.isAuthenticated}',
        name: 'DashboardProvider');
  });

  return service;
});

/// Customer dashboard state
class CustomerDashboardState {
  final CustomerDashboardData? data;
  final bool isLoading;
  final String? error;

  CustomerDashboardState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  CustomerDashboardState copyWith({
    CustomerDashboardData? data,
    bool? isLoading,
    String? error,
  }) {
    return CustomerDashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Customer dashboard provider
class CustomerDashboardNotifier extends StateNotifier<CustomerDashboardState> {
  final DashboardService _service;

  CustomerDashboardNotifier(this._service) : super(CustomerDashboardState());

  /// Fetch dashboard data
  Future<void> fetchDashboard() async {
    developer.log('Fetching customer dashboard data',
        name: 'DashboardProvider');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = await _service.getCustomerDashboard();
      developer.log('Customer dashboard data fetched successfully',
          name: 'DashboardProvider');
      state = state.copyWith(
        data: data,
        isLoading: false,
      );
    } catch (e) {
      developer.log('Error fetching customer dashboard: $e',
          name: 'DashboardProvider', error: e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await fetchDashboard();
  }
}

final customerDashboardProvider =
    StateNotifierProvider<CustomerDashboardNotifier, CustomerDashboardState>(
  (ref) {
    final service = ref.watch(dashboardServiceProvider);
    return CustomerDashboardNotifier(service);
  },
);

/// Supplier dashboard state
class SupplierDashboardState {
  final SupplierDashboardData? data;
  final bool isLoading;
  final String? error;
  final int selectedDays;

  SupplierDashboardState({
    this.data,
    this.isLoading = false,
    this.error,
    this.selectedDays = 30,
  });

  SupplierDashboardState copyWith({
    SupplierDashboardData? data,
    bool? isLoading,
    String? error,
    int? selectedDays,
  }) {
    return SupplierDashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDays: selectedDays ?? this.selectedDays,
    );
  }
}

/// Supplier dashboard provider
class SupplierDashboardNotifier extends StateNotifier<SupplierDashboardState> {
  final DashboardService _service;

  SupplierDashboardNotifier(this._service) : super(SupplierDashboardState());

  /// Fetch dashboard data
  Future<void> fetchDashboard({int? days}) async {
    final selectedDays = days ?? state.selectedDays;
    developer.log('Fetching supplier dashboard data for $selectedDays days',
        name: 'DashboardProvider');
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedDays: selectedDays,
    );

    try {
      final data = await _service.getSupplierDashboard(days: selectedDays);
      developer.log('Supplier dashboard data fetched successfully',
          name: 'DashboardProvider');
      state = state.copyWith(
        data: data,
        isLoading: false,
      );
    } catch (e) {
      developer.log('Error fetching supplier dashboard: $e',
          name: 'DashboardProvider', error: e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await fetchDashboard();
  }

  /// Change date range
  Future<void> changeDateRange(int days) async {
    await fetchDashboard(days: days);
  }
}

final supplierDashboardProvider =
    StateNotifierProvider<SupplierDashboardNotifier, SupplierDashboardState>(
  (ref) {
    final service = ref.watch(dashboardServiceProvider);
    return SupplierDashboardNotifier(service);
  },
);
