import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../routes/navigation_service.dart';

/// 🔐 Route Guard Widget
/// Wraps screens that require authentication and role-based access
class RouteGuardWidget extends StatefulWidget {
  final Widget child;
  final bool requiresAuth;
  final List<String>? allowedRoles;
  final String? redirectRoute;
  final Widget? loadingWidget;

  const RouteGuardWidget({
    super.key,
    required this.child,
    this.requiresAuth = true,
    this.allowedRoles,
    this.redirectRoute,
    this.loadingWidget,
  });

  @override
  State<RouteGuardWidget> createState() => _RouteGuardWidgetState();
}

class _RouteGuardWidgetState extends State<RouteGuardWidget> {
  bool _isChecking = true;
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _checkAccess();
    }
  }

  Future<void> _checkAccess() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Auth is already initialized in main.dart

    if (!mounted) return;

    setState(() {
      _isChecking = false;
    });

    // Check authentication
    if (widget.requiresAuth && !authProvider.isAuthenticated) {
      _redirectToLogin();
      return;
    }

    // Check role authorization
    if (widget.allowedRoles != null && widget.allowedRoles!.isNotEmpty) {
      final userRole = authProvider.user?.role.value;
      if (userRole == null || !widget.allowedRoles!.contains(userRole)) {
        _redirectToUnauthorized();
        return;
      }
    }
  }

  void _redirectToLogin() {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    NavigationService().navigateAndRemoveUntil(
      AppRoutes.roleSelection,
      arguments: currentRoute, // Pass current route to redirect back after login
    );
  }

  void _redirectToUnauthorized() {
    NavigationService().showError('You are not authorized to access this page');

    // Navigate back or to appropriate screen
    if (NavigationService().canPop()) {
      NavigationService().pop();
    } else {
      NavigationService().navigateAndRemoveUntil(AppRoutes.roleSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return widget.loadingWidget ??
          const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
    }

    return widget.child;
  }
}

/// 🛡️ Auth Route Guard - For screens requiring authentication
class AuthRouteGuard extends StatelessWidget {
  final Widget child;
  final List<String>? allowedRoles;

  const AuthRouteGuard({
    super.key,
    required this.child,
    this.allowedRoles,
  });

  @override
  Widget build(BuildContext context) {
    return RouteGuardWidget(
      requiresAuth: true,
      allowedRoles: allowedRoles,
      child: child,
    );
  }
}

/// 👤 Customer Route Guard - For customer-only screens
class CustomerRouteGuard extends StatelessWidget {
  final Widget child;

  const CustomerRouteGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RouteGuardWidget(
      requiresAuth: true,
      allowedRoles: ['customer'],
      child: child,
    );
  }
}

/// 🏭 Supplier Route Guard - For supplier-only screens
class SupplierRouteGuard extends StatelessWidget {
  final Widget child;

  const SupplierRouteGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RouteGuardWidget(
      requiresAuth: true,
      allowedRoles: ['supplier'],
      child: child,
    );
  }
}

/// 👨‍💼 Admin Route Guard - For admin-only screens
class AdminRouteGuard extends StatelessWidget {
  final Widget child;

  const AdminRouteGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RouteGuardWidget(
      requiresAuth: true,
      allowedRoles: ['admin'],
      child: child,
    );
  }
}