import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../onboarding/presentation/controllers/onboarding_providers.dart';

enum AuthMode { signIn, signUp, phoneOtp }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  
  AuthMode _authMode = AuthMode.signIn;

  // Phone OTP specific variables
  String? _verificationId;
  bool _otpSent = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _shakeForm() {
    _shakeController.forward(from: 0.0);
  }

  double _getPasswordStrength() {
    final pass = _passwordController.text;
    if (pass.isEmpty) return 0.0;
    double strength = 0.0;
    
    // Length check
    if (pass.length >= 6) strength += 0.3;
    if (pass.length >= 10) strength += 0.2;
    
    // Contain numbers
    if (RegExp(r'[0-9]').hasMatch(pass)) strength += 0.25;
    
    // Contain special characters / uppercase
    if (RegExp(r'[A-Z]').hasMatch(pass)) strength += 0.15;
    if (RegExp(r'[!@#\$&*~]').hasMatch(pass)) strength += 0.1;
    
    return strength.clamp(0.0, 1.0);
  }
  
  Color _getStrengthColor(double strength) {
    if (strength <= 0.3) return Colors.redAccent;
    if (strength <= 0.6) return Colors.amber;
    return Colors.green;
  }

  String _getStrengthText(double strength) {
    if (strength <= 0.3) return 'Weak';
    if (strength <= 0.6) return 'Moderate';
    return 'Strong';
  }

  void _showForgotPasswordSheet() {
    final theme = Theme.of(context);
    final emailResetController = TextEditingController();
    final sheetFormKey = GlobalKey<FormState>();
    bool isResetLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 16,
              ),
              child: Form(
                key: sheetFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant.withAlpha(120),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Reset Password',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter your email address below and we will send you a link to reset your password.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: emailResetController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isResetLoading
                          ? null
                          : () async {
                              if (!sheetFormKey.currentState!.validate()) return;
                              setModalState(() => isResetLoading = true);
                              try {
                                await ref.read(authRepositoryProvider).sendPasswordResetEmail(
                                      emailResetController.text.trim(),
                                    );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Password reset link sent to ${emailResetController.text.trim()}!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed: ${e.toString()}'),
                                      backgroundColor: theme.colorScheme.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } finally {
                                setModalState(() => isResetLoading = false);
                              }
                            },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isResetLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              'Send Reset Link',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      _shakeForm();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      if (_authMode == AuthMode.signUp) {
        await authRepo.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await authRepo.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_authMode == AuthMode.signUp ? 'Registration successful!' : 'Login successful!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(onboardingStepProvider.notifier).setStep(1);
      }
    } catch (e) {
      _shakeForm();
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains(']')) {
          errorMsg = errorMsg.substring(errorMsg.indexOf(']') + 1).trim();
        }
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auth failed: $errorMsg'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePhoneAuth() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _shakeForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.verifyPhoneNumber(
        phoneNumber: phone,
        onVerificationFailed: (e) {
          _shakeForm();
          setState(() => _isLoading = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification failed: ${e.message}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onCodeSent: (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully! Check your SMS.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onVerificationCompletedAutomatically: (verificationId) {
          setState(() {
            _isLoading = false;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone verified automatically!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(onboardingStepProvider.notifier).setStep(1);
        },
      );
    } catch (e) {
      _shakeForm();
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.isEmpty || smsCode.length < 6) {
      _shakeForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP code')),
      );
      return;
    }

    if (_verificationId == null) {
      _shakeForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification session expired. Please resend code.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithPhoneCode(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone login successful!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(onboardingStepProvider.notifier).setStep(1);
      }
    } catch (e) {
      _shakeForm();
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains(']')) {
          errorMsg = errorMsg.substring(errorMsg.indexOf(']') + 1).trim();
        }
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $errorMsg'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithGoogle();
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Login successful!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(onboardingStepProvider.notifier).setStep(1);
      }
    } catch (e) {
      _shakeForm();
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains(']')) {
          errorMsg = errorMsg.substring(errorMsg.indexOf(']') + 1).trim();
        }
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $errorMsg'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider Sign-In is not configured yet.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Image.asset(
                    isDark ? 'assets/logo/app_logo.png' : 'assets/logo/app_logo_light.jpg',
                    height: 100,
                    width: 100,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'AroundU',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Discover who's AroundU.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(200),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // Glassmorphic Input Form Container with Shake Animation
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0.0),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121212) : const Color(0xFFF3F5F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2),
                        width: 1.2,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        transitionBuilder: (child, animation) {
                          final offsetAnimation = Tween<Offset>(
                            begin: const Offset(0.08, 0.0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<AuthMode>(_authMode),
                          child: _buildFormContent(theme),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: theme.colorScheme.outlineVariant),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'or connect with',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: theme.colorScheme.outlineVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Social Auth Buttons
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2)),
                  ),
                  icon: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                    height: 20,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.g_mobiledata, size: 24),
                  ),
                  label: Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _handleSocialLogin('Apple'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    foregroundColor: theme.brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.apple, size: 20),
                  label: const Text(
                    'Continue with Apple',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(ThemeData theme) {
    switch (_authMode) {
      case AuthMode.signUp:
        return _buildSignUpForm(theme);
      case AuthMode.phoneOtp:
        return _buildPhoneOtpForm(theme);
      case AuthMode.signIn:
        return _buildSignInForm(theme);
    }
  }

  Widget _buildSignInForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome Back',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Email Field
        TextFormField(
          key: const ValueKey('signin_email'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Password Field
        TextFormField(
          key: const ValueKey('signin_password'),
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
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

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordSheet,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        FilledButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 16),

        // Switching buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _authMode = AuthMode.signUp;
                  _passwordController.clear();
                  _confirmPasswordController.clear();
                });
              },
              child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _authMode = AuthMode.phoneOtp;
                  _phoneController.clear();
                  _otpController.clear();
                  _otpSent = false;
                });
              },
              icon: const Icon(Icons.phone_iphone_rounded, size: 16),
              label: const Text('Use Phone OTP', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignUpForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Create Account',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Email Field
        TextFormField(
          key: const ValueKey('signup_email'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Password Field
        TextFormField(
          key: const ValueKey('signup_password'),
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          onChanged: (val) => setState(() {}),
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

        // Password Strength bar (Sign Up only)
        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _getPasswordStrength(),
                    color: _getStrengthColor(_getPasswordStrength()),
                    backgroundColor: theme.colorScheme.outlineVariant.withAlpha(50),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getStrengthText(_getPasswordStrength()),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getStrengthColor(_getPasswordStrength()),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),

        // Confirm Password Field
        TextFormField(
          key: const ValueKey('signup_confirmpassword'),
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_reset_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        FilledButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 16),

        // Switching buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _authMode = AuthMode.signIn;
                });
              },
              child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _authMode = AuthMode.phoneOtp;
                  _phoneController.clear();
                  _otpController.clear();
                  _otpSent = false;
                });
              },
              icon: const Icon(Icons.phone_iphone_rounded, size: 16),
              label: const Text('Use Phone OTP', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhoneOtpForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _otpSent ? 'Enter Verification Code' : 'Phone Authentication',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        if (!_otpSent) ...[
          // Phone Input
          TextFormField(
            key: const ValueKey('phone_number_input'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: 'e.g. +1 555-010-0000',
              prefixIcon: Icon(Icons.phone_rounded),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isLoading ? null : _handlePhoneAuth,
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send Verification Code', style: TextStyle(fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ] else ...[
          // OTP code Input
          TextFormField(
            key: const ValueKey('otp_code_input'),
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: '6-digit OTP Code',
              prefixIcon: Icon(Icons.sms_rounded),
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            icon: const Icon(Icons.verified_user_rounded, size: 16),
            label: const Text('Verify & Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _otpSent = false;
                _otpController.clear();
              });
            },
            child: const Text('Back / Edit Phone Number', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _authMode = AuthMode.signIn;
                });
              },
              child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _authMode = AuthMode.signUp;
                });
              },
              child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}
