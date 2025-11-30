import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../role_selection/role_selection_screen.dart';
import '../../routes/app_routes.dart';

/// 🎬 Premium Splash Screen
/// World-class animated splash with logo and tagline
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _taglineOpacityAnimation;
  late Animation<Offset> _taglineSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _navigateToNext();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Logo scale animation (zoom in effect)
    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Logo opacity animation (fade in)
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Tagline opacity animation (fade in)
    _taglineOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    // Tagline slide animation (slide up)
    _taglineSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  void _navigateToNext() {
    Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isAuthenticated && authProvider.user != null) {
        // Navigate to appropriate dashboard based on role
        _navigateToDashboard(authProvider.user!.role);
      } else {
        // Navigate to role selection
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const RoleSelectionScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  void _navigateToDashboard(UserRole role) {
    String routeName;
    switch (role) {
      case UserRole.customer:
        routeName = AppRoutes.customerHome;
        break;
      case UserRole.supplier:
        routeName = AppRoutes.supplierDashboard;
        break;
      case UserRole.admin:
        routeName = AppRoutes.adminDashboard;
        break;
    }

    Navigator.of(context).pushReplacementNamed(routeName);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Stack(
          children: [
            // Animated circles in background
            _buildAnimatedBackground(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacityAnimation.value,
                        child: Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: _buildLogo(),
                  ),

                  const SizedBox(height: AppDimensions.space32),

                  // Animated Tagline
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _taglineSlideAnimation,
                        child: Opacity(
                          opacity: _taglineOpacityAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: _buildTagline(),
                  ),
                ],
              ),
            ),

            // Loading indicator at bottom
            Positioned(
              bottom: AppDimensions.space64,
              left: 0,
              right: 0,
              child: _buildLoadingIndicator(),
            ),

            // Version number
            Positioned(
              bottom: AppDimensions.space24,
              left: 0,
              right: 0,
              child: _buildVersion(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Circle 1
        Positioned(
          top: -100,
          right: -100,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _animationController.value,
                child: child,
              );
            },
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
        ),

        // Circle 2
        Positioned(
          bottom: -150,
          left: -100,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _animationController.value,
                child: child,
              );
            },
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space32),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hardware,
            size: AppDimensions.iconHuge,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            'INDULINK',
            style: AppTypography.h3.copyWith(
              color: AppColors.primary,
              fontWeight: AppTypography.extraBold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagline() {
    return Column(
      children: [
        Text(
          'Building Materials',
          style: AppTypography.h4.copyWith(
            color: Colors.white,
            fontWeight: AppTypography.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.space8),
        Text(
          'Marketplace',
          style: AppTypography.h5.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontWeight: AppTypography.medium,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildVersion() {
    return Center(
      child: Text(
        'Version 1.0.0',
        style: AppTypography.caption.copyWith(
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }
}
