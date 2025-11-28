import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../l10n/app_localizations.dart';
import '../routes.dart';
import 'home/enhanced_home_screen.dart';
import 'dashboard/customer_dashboard_screen.dart';
import 'dashboard/adaptive_dashboard_screen.dart';
import 'cart/cart_screen.dart';
import 'category/categories_screen.dart';
import 'orders/supplier_orders_screen.dart';
import 'profile/profile_screen.dart';

class BottomNavScreen extends ConsumerStatefulWidget {
  const BottomNavScreen({super.key});

  @override
  ConsumerState<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends ConsumerState<BottomNavScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Set initial screen based on role after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      final userRole = authState.user?.role;
      final isSupplier = userRole == 'supplier';

      print(
          'BottomNavScreen: User role detected: $userRole, isSupplier: $isSupplier');

      // Customers start at Home (index 1), Suppliers start at Dashboard (index 0)
      if (!isSupplier && mounted) {
        setState(() => _selectedIndex = 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userRole = authState.user?.role;
    final isSupplier = userRole == 'supplier';
    final isAdmin = userRole == 'admin' ||
        userRole == 'supplier'; // Suppliers have admin access
    final cartItemCount = ref.watch(cartItemCountProvider);
    final l10n =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

    print(
        'BottomNavScreen: Build - User: ${authState.user?.email}, Role: $userRole, isSupplier: $isSupplier');

    // Handle loading or error states
    if (authState.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.loading),
            ],
          ),
        ),
      );
    }

    // Redirect to login if not authenticated
    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      });
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.loading),
            ],
          ),
        ),
      );
    }

    if (authState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(l10n.error),
              const SizedBox(height: 8),
              Text(
                authState.error!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.splash),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final screens = [
      // Dashboard (role-based)
      _buildScreenWithErrorBoundary(
        isSupplier || isAdmin
            ? const AdaptiveDashboardScreen()
            : const CustomerDashboardScreen(),
      ),
      // Enhanced Home/Products
      _buildScreenWithErrorBoundary(const EnhancedHomeScreen()),
      // Categories
      _buildScreenWithErrorBoundary(const CategoriesScreen()),
      // Cart/Orders (role-based)
      _buildScreenWithErrorBoundary(
        isSupplier ? const SupplierOrdersScreen() : const CartScreen(),
      ),
      // Profile
      _buildScreenWithErrorBoundary(const ProfileScreenNew()),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: _buildBottomNavItems(isSupplier, cartItemCount, l10n),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildBottomNavItems(
    bool isSupplier,
    int cartItemCount,
    AppLocalizations l10n,
  ) {
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.dashboard_outlined),
        activeIcon: const Icon(Icons.dashboard),
        label: l10n.dashboard,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        activeIcon: const Icon(Icons.home),
        label: l10n.home,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.category_outlined),
        activeIcon: const Icon(Icons.category),
        label: l10n.categories,
      ),
      BottomNavigationBarItem(
        icon: cartItemCount > 0
            ? badges.Badge(
                badgeContent: Text(
                  cartItemCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                child: Icon(isSupplier
                    ? Icons.receipt_long_outlined
                    : Icons.shopping_cart_outlined),
              )
            : Icon(isSupplier
                ? Icons.receipt_long_outlined
                : Icons.shopping_cart_outlined),
        activeIcon: Icon(isSupplier ? Icons.receipt_long : Icons.shopping_cart),
        label: isSupplier ? 'Orders' : l10n.cart,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline),
        activeIcon: const Icon(Icons.person),
        label: l10n.profile,
      ),
    ];
  }

  Widget _buildScreenWithErrorBoundary(Widget child) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e) {
          final l10n = AppLocalizations.of(context) ??
              AppLocalizations(const Locale('en'));
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Screen Error',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This screen encountered an error',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _selectedIndex = 1); // Navigate to home
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Go to Home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
