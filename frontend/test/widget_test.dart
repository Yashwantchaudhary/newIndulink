import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newindulink/routes/app_router.dart';
import 'package:newindulink/routes/app_routes.dart';

void main() {
  test('AppRouter smoke test - validates route generation', () {
    // Verify that a key route generates a valid PageRoute.
    // This confirms that AppRouter dependencies (imports) are resolvable
    // and that the routing switch-case logic compiles and runs.

    // We use a route that doesn't require complex arguments for this simple smoke test.
    final route = AppRouter.generateRoute(
      const RouteSettings(name: AppRoutes.login),
    );

    expect(route, isA<MaterialPageRoute>());
  });
}
