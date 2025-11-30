import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/user.dart';
import '../auth/login_screen.dart';

/// 🎭 Role Selection Screen
/// Premium screen for users to select their role before authentication
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _selectRole(UserRole role) {
    // Navigate to login with selected role
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoginScreen(selectedRole: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.primaryLightest.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                const SizedBox(height: AppDimensions.space48),

                // Header
                _buildHeader(),

                const SizedBox(height: AppDimensions.space64),

                // Role Cards
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.pageHorizontalPadding,
                    ),
                    children: [
                      _buildRoleCard(
                        role: UserRole.customer,
                        icon: Icons.shopping_bag,
                        title: 'Customer',
                        description:
                            'Browse and purchase building materials for your projects',
                        gradient: LinearGradient(
                          colors: [
                            AppColors.customerRole,
                            AppColors.customerRole.withOpacity(0.7),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space24),
                      _buildRoleCard(
                        role: UserRole.supplier,
                        icon: Icons.business,
                        title: 'Supplier',
                        description:
                            'Sell your building materials and manage your business',
                        gradient: LinearGradient(
                          colors: [
                            AppColors.supplierRole,
                            AppColors.supplierRole.withOpacity(0.7),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space24),
                      _buildRoleCard(
                        role: UserRole.admin,
                        icon: Icons.admin_panel_settings,
                        title: 'Admin',
                        description:
                            'Manage platform, users, and monitor all activities',
                        gradient: LinearGradient(
                          colors: [
                            AppColors.adminRole,
                            AppColors.adminRole.withOpacity(0.7),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
      ),
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(AppDimensions.space20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.hardware,
              size: AppDimensions.iconXL,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: AppDimensions.space24),

          // Title
          Text(
            'Welcome to INDULINK',
            style: AppTypography.h2.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppDimensions.space12),

          // Subtitle
          Text(
            'Select your role to continue',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
  }) {
    return GestureDetector(
      onTap: () => _selectRole(role),
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectRole(role),
              borderRadius:
                  BorderRadius.circular(AppDimensions.cardRadiusLarge),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM),
                      ),
                      child: Icon(
                        icon,
                        size: AppDimensions.iconL,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: AppDimensions.space20),

                    // Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.h4.copyWith(
                              color: Colors.white,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space8),
                          Text(
                            description,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow Icon
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: AppDimensions.iconS,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
