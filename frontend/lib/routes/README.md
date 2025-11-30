# 🧭 INDULINK Navigation & Routing System

## Overview
This routing system provides a **world-class navigation flow** for the INDULINK application with type-safe routes, role-based access control, and programmatic navigation capabilities.

## 📁 File Structure

```
lib/routes/
├── app_routes.dart              # Route name constants
├── app_router.dart              # Route generation logic
├── navigation_service.dart      # Global navigation service
├── navigation_extensions.dart   # Context-based navigation helpers
└── README.md                    # This file
```

## 🗺️ Key Components

### 1. **AppRoutes** (`app_routes.dart`)
Centralized route name constants for type-safe navigation.

**Features:**
- Organized by user role (Customer, Supplier, Admin)
- Helper methods for route authorization
- Initial route determination based on auth state

**Usage:**
```dart
// Type-safe navigation
Navigator.pushNamed(context, AppRoutes.customerHome);

// Check if route requires auth
if (AppRoutes.isProtectedRoute(routeName)) {
  // Handle authentication
}

// Check role authorization
if (AppRoutes.isRoleAuthorized(routeName, userRole)) {
  // Navigate
}
```

### 2. **AppRouter** (`app_router.dart`)
Centralized route generation with screen imports.

**Features:**
- Single source of truth for all routes
- Custom page transitions (slide, fade)
- Built-in 404 handling
- Typed route arguments

**Usage:**
```dart
// In main.dart
MaterialApp(
  onGenerateRoute: AppRouter.generateRoute,
  initialRoute: AppRoutes.splash,
)
```

### 3. **NavigationService** (`navigation_service.dart`)
Singleton service for navigation without BuildContext.

**Features:**
- Global navigator key
- Navigate from anywhere (providers, services)
- Built-in snackbar methods
- Route guards (auth & role checks)

**Usage:**
```dart
// From a provider or service
NavigationService().navigateTo(AppRoutes.customerHome);

// Show messages
NavigationService().showSuccess('Order placed!');
NavigationService().showError('Something went wrong');

// Navigate with auth check
NavigationService().navigateWithAuth(
  AppRoutes.profile,
  isAuthenticated: authProvider.isAuthenticated,
  fallbackRoute: AppRoutes.login,
);
```

### 4. **NavigationExtensions** (`navigation_extensions.dart`)
BuildContext extensions for easier navigation.

**Features:**
- Context-based shortcuts
- Quick navigation methods
- Snackbar helpers

**Usage:**
```dart
// From a widget (with BuildContext)
context.navigateTo(AppRoutes.cart);
context.navigateToProductDetail(productId);
context.showSuccess('Added to cart!');
context.pop();
```

## 📱 Navigation Flows

### **Authentication Flow**
```
Splash → Role Selection → Login/Signup
                         ↓
         Customer Home / Supplier Dashboard / Admin Dashboard
```

### **Customer Flow**
```
Home → Products → Product Detail → Add to Cart
                                  → Add to Wishlist
                                  → Reviews

Cart → Checkout → Order Placed → Order Tracking

Profile → Edit Profile
        → Addresses
        → Orders
        → Wishlist
        → Messages
        → Notifications
```

### **Supplier Flow**
```
Dashboard → Products → Add/Edit Product
          → Orders → Order Details
          → Analytics
          → RFQ Management

Profile → Edit Profile
        → Business Settings
```

### **Admin Flow**
```
Dashboard → Users → User Management
          → Products → Product Management
          → Categories → Category Management
          → Orders → Order Management
          → Analytics & Reports
```

## 🔐 Route Guards & Authorization

### Protected Routes
All routes except splash, role selection, login, signup, and password recovery require authentication.

### Role-Based Access
- **Customer routes** (`/customer/*`): Only accessible to customers
- **Supplier routes** (`/supplier/*`): Only accessible to suppliers
- **Admin routes** (`/admin/*`): Only accessible to admins

**Example Implementation:**
```dart
// In a middleware or provider
if (!authProvider.isAuthenticated && AppRoutes.isProtectedRoute(route)) {
  NavigationService().navigateTo(AppRoutes.login);
  return;
}

if (!AppRoutes.isRoleAuthorized(route, authProvider.user?.role)) {
  NavigationService().showError('Unauthorized access');
  NavigationService().pop();
  return;
}
```

## 🎯 Best Practices

### 1. **Always use route constants**
```dart
// ✅ Good
Navigator.pushNamed(context, AppRoutes.cart);

// ❌ Bad
Navigator.pushNamed(context, '/customer/cart');
```

### 2. **Use typed arguments**
```dart
// ✅ Good - Type-safe
context.navigateToProductDetail(product.id);

// ❌ Avoid - Unsafe
Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product.id);
```

### 3. **Leverage extensions for common operations**
```dart
// ✅ Good - Clean and readable
context.showSuccess('Saved!');
context.navigateToCustomerHome();

// ❌ Verbose
NavigationService().showSuccess('Saved!');
NavigationService().navigateTo(AppRoutes.customerHome);
```

### 4. **Use NavigationService in providers**
```dart
class CartProvider {
  Future<void> checkout() async {
    // ... checkout logic
    NavigationService().navigateTo(AppRoutes.orderDetail, 
      arguments: orderId);
    NavigationService().showSuccess('Order placed successfully!');
  }
}
```

## 🔄 Common Navigation Patterns

### Navigate and Replace
```dart
// Replace current screen
context.navigateReplaceTo(AppRoutes.customerHome);
```

### Navigate and Clear Stack
```dart
// Clear all previous routes
context.navigateAndRemoveUntil(AppRoutes.customerHome);
```

### Pop to Specific Route
```dart
// Go back to specific screen
context.popUntil(AppRoutes.customerHome);
```

### Pop to Root
```dart
// Go back to first screen
context.popToRoot();
```

## 🎨 Custom Transitions

Add custom transitions in `app_router.dart`:

```dart
// Slide transition
return _buildSlideRoute(ProductDetailScreen(...), settings: settings);

// Fade transition
return _buildFadeRoute(CheckoutScreen(), settings: settings);
```

## 📝 Adding New Routes

1. **Add route constant** in `app_routes.dart`:
```dart
static const String newFeature = '/customer/new-feature';
```

2. **Import screen** in `app_router.dart`:
```dart
import '../screens/customer/new_feature_screen.dart';
```

3. **Add route case** in `AppRouter.generateRoute()`:
```dart
case AppRoutes.newFeature:
  return _buildPageRoute(
    const NewFeatureScreen(),
    settings: settings,
  );
```

4. **Add extension method** (optional) in `navigation_extensions.dart`:
```dart
Future<void> navigateToNewFeature() =>
    navigateTo(AppRoutes.newFeature) ?? Future.value();
```

## 🚀 Performance Tips

1. **Lazy Loading**: Screens are only loaded when navigated to
2. **Route Caching**: Navigator automatically caches routes
3. **Minimal Rebuilds**: Use `const` constructors where possible
4. **Argument Validation**: Validate arguments in screen constructors

## 🐛 Debugging

Enable route logging in `app_router.dart`:
```dart
debugPrint('🧭 Navigating to: $routeName');
debugPrint('📦 With arguments: $arguments');
```

## 📚 Additional Resources

- [Flutter Navigation & Routing](https://docs.flutter.dev/development/ui/navigation)
- [Named Routes](https://docs.flutter.dev/cookbook/navigation/named-routes)
- [Navigation Best Practices](https://flutter.dev/docs/development/ui/navigation/navigation-basics)

---

**Created for INDULINK E-commerce Platform**
*Building Materials Marketplace*
