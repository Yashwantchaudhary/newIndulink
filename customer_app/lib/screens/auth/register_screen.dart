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

/// World-class register screen with modern design
class RegisterScreen extends ConsumerStatefulWidget {
  final String? userRole;

  const RegisterScreen({super.key, this.userRole});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Clear previous error
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      setState(
          () => _errorMessage = 'Please agree to the Terms and Privacy Policy');
      return;
    }

    setState(() => _isLoading = true);

    // Map 'buyer' to 'customer' for backend compatibility
    final roleToUse = widget.userRole == 'buyer'
        ? 'customer'
        : (widget.userRole ?? 'customer');

    final nameParts = _nameController.text.trim().split(' ');
    final firstName = nameParts.first;
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : firstName;

    final success = await ref.read(authProvider.notifier).register(
          firstName: firstName,
          lastName: lastName,
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          role: roleToUse,
        );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Navigate to main app
      AppRoutes.navigateToAndReplace(context, AppRoutes.home);
    } else if (mounted) {
      final error = ref.read(authProvider).error;
      setState(() {
        _errorMessage = error ?? 'Registration failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                    AppColors.accentCoral.withValues(alpha: 0.05),
                    AppColors.primaryBlue.withValues(alpha: 0.05),
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
                      // Title
                      Text(
                        'Create Account',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(),

                      const SizedBox(height: AppConstants.spacing8),

                      Text(
                        widget.userRole != null
                            ? 'Register as ${widget.userRole == 'buyer' ? 'Buyer' : 'Supplier'}'
                            : 'Sign up to get started',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 100)),

                      const SizedBox(height: AppConstants.spacing32),

                      // Error Banner
                      if (_errorMessage != null)
                        ErrorBanner(
                          message: _errorMessage!,
                          onDismiss: () => setState(() => _errorMessage = null),
                        ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                      if (_errorMessage != null)
                        const SizedBox(height: AppConstants.spacing20),

                      // Name Field
                      ModernTextField(
                        label: 'Full Name',
                        hint: 'John Doe',
                        controller: _nameController,
                        prefixIcon: const Icon(Icons.person_rounded),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          if (value.length < 3) {
                            return 'Name must be at least 3 characters';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 200))
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: AppConstants.spacing16),

                      // Email Field
                      ModernTextField(
                        label: 'Email',
                        hint: 'you@example.com',
                        controller: _emailController,
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
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 300))
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: AppConstants.spacing16),

                      // Phone Field
                      ModernTextField(
                        label: 'Phone Number',
                        hint: '+1 234 567 8900',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_rounded),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.length < 10) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 400))
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: AppConstants.spacing16),

                      // Password Field
                      ModernTextField(
                        label: 'Password',
                        hint: 'At least 6 characters',
                        controller: _passwordController,
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
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 500))
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: AppConstants.spacing16),

                      // Confirm Password Field
                      ModernTextField(
                        label: 'Confirm Password',
                        hint: 'Re-enter password',
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword =
                                !_obscureConfirmPassword);
                          },
                        ),
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 600))
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: AppConstants.spacing20),

                      // Terms Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (value) {
                              setState(() => _agreedToTerms = value ?? false);
                            },
                            activeColor: AppColors.primaryBlue,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(
                                    () => _agreedToTerms = !_agreedToTerms);
                              },
                              child: Text.rich(
                                TextSpan(
                                  text: 'I agree to the ',
                                  style: theme.textTheme.bodySmall,
                                  children: const [
                                    TextSpan(
                                      text: 'Terms & Conditions',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 700)),

                      const SizedBox(height: AppConstants.spacing24),

                      // Register Button
                      PremiumButton.primary(
                        text: 'Create Account',
                        onPressed: _handleRegister,
                        isLoading: _isLoading,
                        isFullWidth: true,
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 800))
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: AppConstants.spacing24),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          PremiumButton.text(
                            text: 'Log In',
                            onPressed: () => Navigator.pop(context),
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
