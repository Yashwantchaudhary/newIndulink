import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_button.dart';

/// World-class role selection screen with gradient cards
class RoleSelectionScreen extends StatefulWidget {
  final Function(String) onRoleSelect;
  final VoidCallback onSkip;

  const RoleSelectionScreen({
    required this.onRoleSelect,
    required this.onSkip,
    super.key,
  });

  @override
  RoleSelectionScreenState createState() => RoleSelectionScreenState();
}

class RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? selectedRole;

  void _handleRoleSelect(String role) {
    setState(() {
      selectedRole = role;
    });
  }

  void _handleContinue() {
    if (selectedRole != null) {
      widget.onRoleSelect(selectedRole!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.darkBackground,
                    AppColors.darkSurface,
                  ],
                )
              : AppColors.heroGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppConstants.paddingAll24,
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: widget.onSkip,
                    child: Text(
                      'Skip',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),

                SizedBox(
                    height: isWide
                        ? AppConstants.spacing48
                        : AppConstants.spacing24),

                // Title section
                Column(
                  children: [
                    Text(
                      'Choose Your Role',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color:
                            isDark ? AppColors.darkTextPrimary : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.spacing12),
                    Text(
                      'Select how you\'ll be using INDULINK',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ).animate().fadeIn(
                      duration: AppConstants.durationNormal,
                      curve: AppConstants.curveEmphasized,
                    ),

                SizedBox(
                    height: isWide
                        ? AppConstants.spacing48
                        : AppConstants.spacing32),

                // Role cards
                isWide
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: _buildRoleCard(
                              context: context,
                              role: 'buyer',
                              title: 'I\'m a Buyer',
                              description:
                                  'Find suppliers, request quotes, manage orders',
                              icon: Icons.shopping_cart_rounded,
                              gradient: AppColors.cyanBlueGradient,
                              features: [
                                'Source materials efficiently',
                                'Instant price comparison',
                                'Track orders in real-time',
                              ],
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacing24),
                          Flexible(
                            child: _buildRoleCard(
                              context: context,
                              role: 'supplier',
                              title: 'I\'m a Supplier',
                              description:
                                  'List products, receive orders, grow business',
                              icon: Icons.inventory_2_rounded,
                              gradient: AppColors.purpleGradient,
                              features: [
                                'Reach more buyers',
                                'Track revenue analytics',
                                'Manage inventory easily',
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildRoleCard(
                            context: context,
                            role: 'buyer',
                            title: 'I\'m a Buyer',
                            description:
                                'Find suppliers, request quotes, manage orders',
                            icon: Icons.shopping_cart_rounded,
                            gradient: AppColors.cyanBlueGradient,
                            features: [
                              'Source materials efficiently',
                              'Instant price comparison',
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacing20),
                          _buildRoleCard(
                            context: context,
                            role: 'supplier',
                            title: 'I\'m a Supplier',
                            description:
                                'List products, receive orders, grow business',
                            icon: Icons.inventory_2_rounded,
                            gradient: AppColors.purpleGradient,
                            features: [
                              'Reach more buyers',
                              'Track revenue analytics',
                            ],
                          ),
                        ],
                      ),

                SizedBox(
                    height: isWide
                        ? AppConstants.spacing48
                        : AppConstants.spacing32),

                // Continue button
                PremiumButton.primary(
                  text: 'Continue',
                  onPressed: selectedRole != null ? _handleContinue : null,
                  isFullWidth: !isWide,
                )
                    .animate()
                    .fadeIn(
                      duration: AppConstants.durationNormal,
                      delay: const Duration(milliseconds: 400),
                    )
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: AppConstants.spacing16),

                // Footer note
                Text(
                  'You can switch roles anytime in settings',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: const Duration(milliseconds: 600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String role,
    required String title,
    required String description,
    required IconData icon,
    required LinearGradient gradient,
    required List<String> features,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = selectedRole == role;
    final delay = role == 'buyer' ? 200 : 300;

    return GestureDetector(
      onTap: () => _handleRoleSelect(role),
      child: AnimatedContainer(
        duration: AppConstants.durationNormal,
        curve: AppConstants.curveStandard,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: AppConstants.paddingAll24,
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: AppConstants.borderRadiusLarge,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : AppColors.neutral300),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : AppConstants.shadowMedium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : gradient.colors.first.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: isSelected ? Colors.white : gradient.colors.first,
              ),
            ),

            const SizedBox(height: AppConstants.spacing20),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppConstants.spacing8),

            // Description
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppConstants.spacing20),

            // Features
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.white : gradient.colors.first,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Selected indicator
            if (isSelected) ...[
              const SizedBox(height: AppConstants.spacing16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Selected',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: AppConstants.durationNormal,
          delay: Duration(milliseconds: delay),
        )
        .slideY(
          begin: 0.3,
          end: 0,
          curve: AppConstants.curveEmphasized,
        );
  }
}
