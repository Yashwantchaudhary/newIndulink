import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../routes.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/modern_text_field.dart';
import '../../widgets/common/premium_button.dart';
import '../../widgets/common/error_state_widget.dart';
import 'forgot_password_screen.dart';

/// World-class login screen with modern design
class LoginScreen extends ConsumerStatefulWidget {
  final String? userRole;

  const LoginScreen({super.key, this.userRole});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Clear previous error
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    // Additional validation
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Map 'buyer' to 'customer' for backend compatibility
      final roleToUse = widget.userRole == 'buyer'
          ? 'customer'
          : (widget.userRole ??
              (_emailController.text.contains('supplier')
                  ? 'supplier'
                  : 'customer'));

      final success = await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
            role: roleToUse,
          );

      if (success && mounted) {
        // Verify authentication state
        final authState = ref.read(authProvider);
        if (authState.isAuthenticated && authState.user != null) {
          // Navigate to main app
          AppRoutes.navigateToAndReplace(context, AppRoutes.home);
        } else {
          setState(
              () => _errorMessage = 'Authentication failed. Please try again.');
        }
      } else if (mounted) {
        final error = ref.read(authProvider).error;
        setState(() {
          _errorMessage =
              error ?? 'Login failed. Please check your credentials.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _errorMessage = 'Network error. Please check your connection.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    // Clear previous error
    setState(() => _errorMessage = null);

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(authProvider.notifier).signInWithGoogle(
            role: widget.userRole,
          );

      if (success && mounted) {
        // Verify authentication state
        final authState = ref.read(authProvider);
        if (authState.isAuthenticated && authState.user != null) {
          // Navigate to main app
          AppRoutes.navigateToAndReplace(context, AppRoutes.home);
        } else {
          setState(() => _errorMessage =
              'Google authentication failed. Please try again.');
        }
      } else if (mounted) {
        final error = ref.read(authProvider).error;
        setState(() {
          _errorMessage = error ?? 'Google sign in failed. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _errorMessage = 'Network error. Please check your connection.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.darkBackground,
                    AppColors.darkSurface,
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.05),
                    AppColors.accentCoral.withValues(alpha: 0.05),
                  ],
                ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppConstants.paddingAll24,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: AppConstants.borderRadiusXLarge,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shopping_bag_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      )
                          .animate()
                          .scale(
                            duration: AppConstants.durationSlow,
                            curve: AppConstants.curveBounce,
                          )
                          .fadeIn(),

                      const SizedBox(height: AppConstants.spacing32),

                      // Welcome Text
                      Text(
                        'Welcome Back!',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 100)),

                      const SizedBox(height: AppConstants.spacing8),

                      Text(
                        widget.userRole != null
                            ? 'Login as ${widget.userRole == 'buyer' ? 'Buyer' : 'Supplier'}'
                            : 'Sign in to your account',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 200)),

                      const SizedBox(height: AppConstants.spacing48),

                      // Error Banner
                      if (_errorMessage != null)
                        ErrorBanner(
                          message: _errorMessage!,
                          onDismiss: () => setState(() => _errorMessage = null),
                        ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                      if (_errorMessage != null)
                        const SizedBox(height: AppConstants.spacing24),

                      // Email Field
                      ModernTextField(
                        label: 'Email',
                        hint: 'you@example.com',
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_rounded),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        onChanged: (_) {
                          if (_errorMessage != null) {
                            setState(() => _errorMessage = null);
                          }
                        },
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 300))
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: AppConstants.spacing20),

                      // Password Field
                      ModernTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                          onPressed: () {
                            setState(
                                () => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        onChanged: (_) {
                          if (_errorMessage != null) {
                            setState(() => _errorMessage = null);
                          }
                        },
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 400))
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: AppConstants.spacing12),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: PremiumButton.text(
                          text: 'Forgot Password?',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            );
                          },
                        ),
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 500)),

                      const SizedBox(height: AppConstants.spacing32),

                      // Login Button
                      PremiumButton.primary(
                        text: 'Log In',
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                        isFullWidth: true,
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 600))
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: AppConstants.spacing32),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacing16),
                            child: Text(
                              'OR',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 700)),

                      const SizedBox(height: AppConstants.spacing24),

                      // Google Sign In Button
                      PremiumButton.secondary(
                        text: 'Continue with Google',
                        onPressed: _handleGoogleSignIn,
                        isFullWidth: true,
                        icon: const Icon(
                          Icons.g_mobiledata,
                          size: 20,
                          color: AppColors.primaryBlue,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 750))
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: AppConstants.spacing32),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          PremiumButton.text(
                            text: 'Sign Up',
                            onPressed: () {
                              AppRoutes.navigateTo(
                                context,
                                AppRoutes.register,
                                arguments: widget.userRole,
                              );
                            },
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 800)),

                      const SizedBox(height: AppConstants.spacing16),

                      // Trust indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Secure & encrypted login',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 900)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
