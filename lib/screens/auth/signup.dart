import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'signin.dart';
import '../main_screen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _rememberMe = true;

  late AnimationController _animationController;
  late AnimationController _logoAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.animationDurationLong,
      vsync: this,
    );
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _animationController.forward();
    _logoAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logoAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      rememberUser: _rememberMe,
    );

    if (mounted) {
      if (result.isSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage!),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // Main content
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    MediaQuery.of(context).size.height * _slideAnimation.value,
                  ),
                  child: Opacity(opacity: _fadeAnimation.value, child: child),
                );
              },
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    children: [
                      const SizedBox(height: AppTheme.spacingXl),

                      // Logo section
                      AnimatedBuilder(
                        animation: _logoAnimationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoAnimation.value,
                            child: Container(
                              height: 120,
                              decoration: AppTheme.logoContainerDecoration,

                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    AppTheme.logoPath,
                                    fit: BoxFit.cover,
                                  ),
                                  Text(
                                    AppTheme.appName,
                                    style: TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: AppTheme.spacingXl),

                      // Welcome text
                      Text(
                        'Join Us Today',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.spacingSm),

                      Text(
                        'Create your account to start managing disasters',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.spacingXl),

                      // Form container with glass morphism
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.primaryColor,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusLg,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!AuthService.isValidEmail(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.emailAddress,
                            ),

                            const SizedBox(height: AppTheme.spacingLg),

                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.primaryColor,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(
                                      () => _isPasswordVisible =
                                          !_isPasswordVisible,
                                    );
                                  },
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusLg,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (!AuthService.isValidPassword(value)) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: AppTheme.spacingLg),

                            // Confirm password field
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: 'Re-enter your password',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.primaryColor,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(
                                      () => _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible,
                                    );
                                  },
                                  icon: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusLg,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (!AuthService.passwordsMatch(
                                  _passwordController.text,
                                  value,
                                )) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: AppTheme.spacingLg),

                            // Remember me checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? true;
                                    });
                                  },
                                  activeColor: AppTheme.primaryColor,
                                ),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppTheme.spacingXl),

                            // Sign up button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: AppTheme.primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusLg,
                                    ),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingXl),

                      // Sign in link
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(fontSize: 16),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => const SignInPage(),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return SlideTransition(
                                            position: animation.drive(
                                              Tween(
                                                begin: const Offset(-1.0, 0.0),
                                                end: Offset.zero,
                                              ).chain(
                                                CurveTween(
                                                  curve: Curves.easeInOut,
                                                ),
                                              ),
                                            ),
                                            child: child,
                                          );
                                        },
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
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
