import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension NavigationExtensions on BuildContext {
  /// Navigate to a route (push)
  void pushTo(String route, {Object? extra}) {
    push(route, extra: extra);
  }

  /// Replace current route
  void goTo(String route, {Object? extra}) {
    go(route, extra: extra);
  }

  /// Push with expected result type (generic safe)
  Future<T?> pushForResult<T>(String route, {Object? extra}) {
    return push<T>(route, extra: extra);
  }

  /// Pop screen
  void pop<T extends Object?>([T? result]) {
    Navigator.of(this).pop(result);
  }
}