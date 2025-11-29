import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _floatController1;
  late AnimationController _floatController2;
  late AnimationController _floatController3;
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _floatController1 = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _floatController2 = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _floatController3 = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _bounceController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _dotsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

    _scaleController.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _floatController1.dispose();
    _floatController2.dispose();
    _floatController3.dispose();
    _scaleController.dispose();
    _bounceController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (authState.isAuthenticated) {
      AppRoutes.navigateToAndReplace(context, AppRoutes.home);
    } else {
      // Navigate to role selection screen instead of login
      AppRoutes.navigateToAndReplace(context, AppRoutes.roleSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF312E81), Color(0xFF7C3AED), Color(0xFFEC4899)],
          ),
        ),
        child: Stack(
          children: [
            // Floating circles with blur
            AnimatedBuilder(
              animation: Listenable.merge([_floatController1, _floatController2, _floatController3]),
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned(
                      top: 40 + 50 * sin(_floatController1.value * 2 * pi),
                      left: 80 + 100 * sin(_floatController1.value * 2 * pi),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          width: 256,
                          height: 256,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(26),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40 + 100 * sin(_floatController2.value * 2 * pi),
                      right: 60 + 80 * sin(_floatController2.value * 2 * pi),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          width: 384,
                          height: 384,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(26),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.5 + 60 * sin(_floatController3.value * 2 * pi),
                      right: 120 + 60 * sin(_floatController3.value * 2 * pi),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          width: 192,
                          height: 192,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(26),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Main content
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut)),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0, end: 1).animate(_scaleController),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with bounce
                      AnimatedBuilder(
                        animation: _bounceController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, -10 * sin(_bounceController.value * 2 * pi)),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(51),
                                    blurRadius: 25,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: Colors.purple.withAlpha(26),
                                    blurRadius: 50,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.inventory, size: 64, color: Color(0xFF7C3AED)),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Title
                      FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _scaleController, curve: const Interval(0.3, 1.0))),
                        child: const Text(
                          'InduLink',
                          style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Subtitle
                      FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _scaleController, curve: const Interval(0.5, 1.0))),
                        child: Text(
                          'Smart B2B Raw Materials Trading',
                          style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Loading dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          return AnimatedBuilder(
                            animation: _dotsController,
                            builder: (context, child) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(((sin(_dotsController.value * 2 * pi - i * 0.4 * pi) + 1) / 2 * 255).toInt()),
                                  shape: BoxShape.circle,
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
