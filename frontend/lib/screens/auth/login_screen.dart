import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import 'signup_screen.dart';

/// 🔐 Login Screen
/// Premium login screen with email/password and Google Sign-In
class LoginScreen extends StatefulWidget {
  final UserRole selectedRole;

  const LoginScreen({
    super.key,
    required this.selectedRole,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.loginWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: widget.selectedRole,
    );

    if (mounted) {
      if (success) {
        _navigateToDashboard();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateToDashboard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?.role ?? widget.selectedRole;
    String routeName;
    switch (userRole) {
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

    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          color: Colors.blue,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Form Container
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(
                        AppDimensions.pageHorizontalPadding,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: AppDimensions.space32),

                          // Login Card
                          _buildLoginCard(),

                          const SizedBox(height: AppDimensions.space24),

                          // Sign Up Link
                          _buildSignUpLink(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        children: [
          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.space24),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingS,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRoleIcon(),
                  color: Colors.white,
                  size: AppDimensions.iconS,
                ),
                const SizedBox(width: AppDimensions.space8),
                Text(
                  widget.selectedRole.displayName,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.space16),

          // Title
          Text(
            'Welcome Back!',
            style: AppTypography.h2.copyWith(
              color: Colors.white,
            ),
          ),

          const SizedBox(height: AppDimensions.space8),

          // Subtitle
          Text(
            'Sign in to continue',
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'Enter your email',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppDimensions.space20),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  hintText: 'Enter your password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppDimensions.space16),

              // Remember Me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusXS),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Text(
                        'Remember me',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                    },
                    child: Text(
                      'Forgot Password?',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.space24),

              // Login Button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) => SizedBox(
                  height: AppDimensions.buttonHeight,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleLogin,
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Sign In',
                            style: AppTypography.buttonMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: "Don't have an account? ",
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          children: [
            TextSpan(
              text: 'Sign Up',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: AppTypography.semiBold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SignUpScreen(
                        selectedRole: widget.selectedRole,
                      ),
                    ),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon() {
    switch (widget.selectedRole) {
      case UserRole.customer:
        return Icons.shopping_bag;
      case UserRole.supplier:
        return Icons.business;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }
}
