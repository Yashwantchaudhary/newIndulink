import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/modern_text_field.dart';
import '../../widgets/common/premium_button.dart';

/// Forgot Password Screen
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _emailSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
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
                child: _emailSent
                    ? _buildSuccessView()
                    : _buildFormView(isDark, theme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(bool isDark, ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppConstants.borderRadiusXLarge,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_reset,
              size: 40,
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

          // Title
          Text(
            'Forgot Password?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: const Duration(milliseconds: 100)),

          const SizedBox(height: AppConstants.spacing12),

          // Subtitle
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

          const SizedBox(height: AppConstants.spacing48),

          // Email Field
          ModernTextField(
            label: 'Email',
            hint: 'you@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_rounded),
            textInputAction: TextInputAction.done,
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

          const SizedBox(height: AppConstants.spacing32),

          // Send Button
          PremiumButton.primary(
            text: 'Send Reset Link',
            onPressed: _sendResetLink,
            isLoading: _isLoading,
            isFullWidth: true,
          )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 400))
              .slideY(begin: 0.3, end: 0),

          const SizedBox(height: AppConstants.spacing24),

          // Back to Login
          PremiumButton.text(
            text: 'Back to Login',
            onPressed: () => Navigator.pop(context),
          ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.success,
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.check_circle,
            size: 50,
            color: AppColors.success,
          ),
        )
            .animate()
            .scale(
              duration: AppConstants.durationSlow,
              curve: AppConstants.curveBounce,
            )
            .fadeIn(),

        const SizedBox(height: AppConstants.spacing32),

        // Success Title
        Text(
          'Email Sent!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: const Duration(milliseconds: 100)),

        const SizedBox(height: AppConstants.spacing16),

        // Success Message
        Text(
          'We\'ve sent a password reset link to\n${_emailController.text}',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

        const SizedBox(height: AppConstants.spacing12),

        Text(
          'Please check your email and follow the instructions to reset your password.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: const Duration(milliseconds: 300)),

        const SizedBox(height: AppConstants.spacing48),

        // Back to Login Button
        PremiumButton.primary(
          text: 'Back to Login',
          onPressed: () => Navigator.pop(context),
          isFullWidth: true,
        ).animate().fadeIn(delay: const Duration(milliseconds: 400)),

        const SizedBox(height: AppConstants.spacing16),

        // Resend Link
        PremiumButton.text(
          text: 'Didn\'t receive email? Resend',
          onPressed: () {
            setState(() {
              _emailSent = false;
              _isLoading = false;
            });
          },
        ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
      ],
    );
  }
}
