import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/core/constants/app_config.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';
import 'package:test_flutter/features/auth/helper.dart';
import 'package:test_flutter/features/auth/widgets/policy_modal.dart';
import '../../../app/theme.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeTerms = false;

  // Error messages for each field
  String? _nameError;
  String? _emailError;
  String? _passwordError;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // 🆕 Show Terms of Service Modal
  void _showTermsOfService() {
    PolicyModal.show(
      context,
      title: 'Ketentuan Layanan',
      content: getTermsOfServiceContent(),
      icon: Icons.gavel_rounded,
      iconColor: AppTheme.primaryBlue,
    );
  }

  // 🆕 Show Privacy Policy Modal
  void _showPrivacyPolicy() {
    PolicyModal.show(
      context,
      title: 'Kebijakan Privasi',
      content: getPrivacyPolicyContent(),
      icon: Icons.privacy_tip_rounded,
      iconColor: AppTheme.accentGreen,
    );
  }

  Future<void> _handleSignup() async {
    // Clear previous errors
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
    });

    if (_formKey.currentState?.validate() ?? false) {
      if (!_agreeTerms) {
        showMessageToast(
          context,
          message:
              'Anda harus menyetujui Ketentuan Layanan dan Kebijakan Privasi',
          type: ToastType.error,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final confirmationPassword = _confirmPasswordController.text.trim();

      ref
          .read(authProvider.notifier)
          .register(name, email, password, confirmationPassword);
    }
  }

  // Parse field errors from server response
  void _parseFieldErrors(String errorMessage) {
    try {
      // Extract the error object from message like: "Exception: {email: [The email has already been taken.]}"
      final startIndex = errorMessage.indexOf('{');
      final endIndex = errorMessage.lastIndexOf('}');

      if (startIndex != -1 && endIndex != -1) {
        final errorString = errorMessage.substring(startIndex + 1, endIndex);

        // Simple parsing for field errors
        if (errorString.contains('name:')) {
          final nameMatch = RegExp(
            r'name:\s*\[(.*?)\]',
          ).firstMatch(errorString);
          if (nameMatch != null) {
            _nameError = nameMatch.group(1);
          }
        }

        if (errorString.contains('email:')) {
          final emailMatch = RegExp(
            r'email:\s*\[(.*?)\]',
          ).firstMatch(errorString);
          if (emailMatch != null) {
            _emailError = emailMatch.group(1);
          }
        }

        if (errorString.contains('password:')) {
          final passwordMatch = RegExp(
            r'password:\s*\[(.*?)\]',
          ).firstMatch(errorString);
          if (passwordMatch != null) {
            _passwordError = passwordMatch.group(1);
          }
        }
      }
    } catch (e) {
      // If parsing fails, keep errors as null
    }
  }

  double _gapSmall(BuildContext context) =>
      ResponsiveHelper.isSmallScreen(context) ? 12 : 16;
  double _gapMedium(BuildContext context) =>
      ResponsiveHelper.isSmallScreen(context) ? 20 : 28;
  double _fieldHeight(BuildContext context) =>
      ResponsiveHelper.isSmallScreen(context) ? 52 : 56;

  final isLoadingGoogle = false;

  @override
  Widget build(BuildContext context) {
    final isSmall = ResponsiveHelper.isSmallScreen(context);
    final isMedium = ResponsiveHelper.isMediumScreen(context);
    final isLarge = ResponsiveHelper.isLargeScreen(context);
    final isXL = ResponsiveHelper.isExtraLargeScreen(context);

    // Listen to auth state changes (only triggered on actual state changes)
    ref.listen(authProvider, (previous, next) {
      final status = next['status'];
      final error = next['error'];

      // Only process if state actually changed
      if (previous != null && previous['status'] == status) {
        return;
      }

      if (status == AuthState.error && error != null) {
        final errorMsg = error.toString();

        // Parse field-specific errors (without setState to avoid rebuild)
        _parseFieldErrors(errorMsg);

        // Show toast for the first field error found (priority: name -> email -> password)
        String? displayError;

        // Check field errors in priority order
        if (_nameError != null) {
          displayError = _nameError;
        } else if (_emailError != null) {
          displayError = _emailError;
        } else if (_passwordError != null) {
          displayError = _passwordError;
        }

        // Show toast with the first field error or general error
        showMessageToast(
          context,
          message: displayError ?? errorMsg,
          type: ToastType.error,
          duration: const Duration(seconds: 4),
        );

        // Clear field errors for next attempt
        _nameError = null;
        _emailError = null;
        _passwordError = null;

        ref.read(authProvider.notifier).clearError();
      } else if (status == AuthState.isRegistered) {
        // Show success toast
        showMessageToast(
          context,
          message: 'Pendaftaran berhasil! Silakan verifikasi email Anda.',
          type: ToastType.success,
          duration: const Duration(seconds: 3),
        );

        // Navigate to OTP page for verification
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(
              '/otp',
              arguments: {
                'email': _emailController.text.trim(),
                'type': 'registration',
              },
            );
          }
        });
      }
    });

    // Watch auth state for UI updates
    final authState = ref.watch(authProvider);
    final isLoading = authState['status'] == AuthState.loading;

    final pagePadding = ResponsiveHelper.getResponsivePadding(context);
    final useTwoColumns =
        MediaQuery.of(context).size.width >= ResponsiveHelper.largeScreenSize;

    final logoSize = isSmall
        ? 70.0
        : isMedium
        ? 85.0
        : 95.0;
    final cardRadius = isXL ? 32.0 : 28.0;
    const fieldRadius = 16.0;

    final maxFormWidth = isXL
        ? 520.0
        : isLarge
        ? 480.0
        : 440.0;

    final appBar = Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_rounded, color: AppTheme.onSurface),
            ),
          ),
        ],
      ),
    );

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: isSmall ? 6 : 10),
        // Logo
        FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                  spreadRadius: -5,
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(AppConfig.appLogo, fit: BoxFit.cover),
            ),
          ),
        ),
        SizedBox(height: _gapMedium(context) - 4),

        // Title & subtitle
        FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
                ).createShader(bounds),
                child: Text(
                  'Buat Akun',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.adaptiveTextSize(context, 30),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SizedBox(height: isSmall ? 6 : 8),
              Text(
                'Bergabunglah dengan komunitas Islami kami hari ini',
                style: TextStyle(
                  fontSize: ResponsiveHelper.adaptiveTextSize(context, 15),
                  color: AppTheme.onSurfaceVariant,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: _gapMedium(context)),
      ],
    );

    final formCard = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: useTwoColumns ? maxFormWidth : 600,
        ),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: EdgeInsets.all(
                isSmall
                    ? 20
                    : isMedium
                    ? 24
                    : 28,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.adaptiveTextSize(
                          context,
                          15,
                        ),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        hintText: 'Masukkan nama lengkap Anda',
                        prefixIcon: Icon(
                          Icons.person_outlined,
                          color: AppTheme.primaryBlue,
                        ),
                        filled: true,
                        fillColor: AppTheme.primaryBlue.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(fieldRadius),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(fieldRadius),
                          borderSide: BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(fieldRadius),
                          borderSide: BorderSide(
                            color: Colors.red.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: (value) {
                        // Server-side errors are now shown as toast, not in field
                        // Only validate client-side
                        if (value == null || value.isEmpty) {
                          return 'Silakan masukkan nama Anda';
                        }
                        if (value.length < 3) {
                          return 'Nama harus memiliki setidaknya 3 karakter';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: _gapSmall(context) + 4),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.adaptiveTextSize(
                          context,
                          15,
                        ),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Masukkan email Anda',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: AppTheme.accentGreen,
                        ),
                        filled: true,
                        fillColor: AppTheme.accentGreen.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(fieldRadius),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(fieldRadius),
                          borderSide: BorderSide(
                            color: AppTheme.accentGreen,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(fieldRadius),
                          borderSide: BorderSide(
                            color: Colors.red.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: (value) {
                        // Server-side errors are now shown as toast, not in field
                        // Only validate client-side
                        if (value == null || value.isEmpty) {
                          return 'Silakan masukkan email Anda';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Silakan masukkan email yang valid';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: _gapSmall(context) + 4),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.adaptiveTextSize(
                          context,
                          15,
                        ),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi',
                        hintText: 'Buat kata sandi',
                        prefixIcon: Icon(
                          Icons.lock_outlined,
                          color: AppTheme.primaryBlue,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        filled: true,
                        fillColor: AppTheme.primaryBlue.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(fieldRadius),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(fieldRadius),
                          borderSide: BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(fieldRadius),
                          borderSide: BorderSide(
                            color: Colors.red.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: (value) {
                        // Server-side errors are now shown as toast, not in field
                        // Only validate client-side
                        if (value == null || value.isEmpty) {
                          return 'Silakan masukkan kata sandi';
                        }
                        if (value.length < 6) {
                          return 'Kata sandi harus memiliki setidaknya 6 karakter';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: _gapSmall(context) + 4),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.adaptiveTextSize(
                          context,
                          15,
                        ),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi',
                        hintText: 'Masukkan ulang kata sandi',
                        prefixIcon: Icon(
                          Icons.lock_outlined,
                          color: AppTheme.accentGreen,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        filled: true,
                        fillColor: AppTheme.accentGreen.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(fieldRadius),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(fieldRadius),
                          borderSide: BorderSide(
                            color: AppTheme.accentGreen,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Silakan konfirmasi kata sandi Anda';
                        }
                        if (value != _passwordController.text) {
                          return 'Kata sandi tidak cocok';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: _gapMedium(context) - 4),

                    // Terms - 🆕 UPDATED WITH CLICKABLE LINKS
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _agreeTerms,
                            onChanged: (value) {
                              setState(() => _agreeTerms = value ?? false);
                            },
                            activeColor: AppTheme.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.adaptiveTextSize(
                                    context,
                                    13,
                                  ),
                                  color: AppTheme.onSurfaceVariant,
                                ),
                                children: [
                                  const TextSpan(text: 'Saya setuju dengan '),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: _showTermsOfService,
                                      child: Text(
                                        'Ketentuan Layanan',
                                        style: TextStyle(
                                          color: AppTheme.primaryBlue,
                                          fontWeight: FontWeight.w600,
                                          fontSize:
                                              ResponsiveHelper.adaptiveTextSize(
                                                context,
                                                13,
                                              ),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(text: ' dan '),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: _showPrivacyPolicy,
                                      child: Text(
                                        'Kebijakan Privasi',
                                        style: TextStyle(
                                          color: AppTheme.primaryBlue,
                                          fontWeight: FontWeight.w600,
                                          fontSize:
                                              ResponsiveHelper.adaptiveTextSize(
                                                context,
                                                13,
                                              ),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: _gapMedium(context) - 4),

                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: _fieldHeight(context),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(fieldRadius),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: AppTheme.accentGreen
                              .withValues(alpha: 0.6),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Daftar',
                                    style: TextStyle(
                                      fontSize:
                                          ResponsiveHelper.adaptiveTextSize(
                                            context,
                                            16,
                                          ),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
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
      ),
    );

    final social = FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: useTwoColumns ? maxFormWidth : 600,
          ),
          child: Column(
            children: [
              SizedBox(height: _gapMedium(context)),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Atau daftar dengan',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              SizedBox(height: _gapSmall(context) + 8),
              SizedBox(
                width: double.infinity,
                height: _fieldHeight(context),
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          try {
                            await ref
                                .read(authProvider.notifier)
                                .loginWithGoogle();
                          } catch (e) {
                            if (mounted) {
                              showMessageToast(
                                context,
                                message: e.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                ),
                                type: ToastType.error,
                              );
                            }
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(fieldRadius),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.g_mobiledata_rounded,
                        size: isSmall ? 26 : 28,
                        color: AppTheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lanjutkan dengan Google',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.adaptiveTextSize(
                            context,
                            16,
                          ),
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final signupLink = Padding(
      padding: EdgeInsets.only(
        top: _gapMedium(context),
        left: 4,
        right: 4,
        bottom: isSmall ? 8 : 0,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: useTwoColumns ? maxFormWidth : 600,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentGreen.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun?',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: ResponsiveHelper.adaptiveTextSize(context, 14),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/login'),
                    child: Text(
                      ' Masuk',
                      style: TextStyle(
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.adaptiveTextSize(
                          context,
                          14,
                        ),
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

    // ===== Scaffold body =====
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue.withValues(alpha: 0.05),
              AppTheme.accentGreen.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: pagePadding,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (useTwoColumns) {
                  final leftPane = AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.all(isXL ? 32 : 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: isXL ? 120 : 96,
                          color: AppTheme.accentGreen.withValues(alpha: 0.9),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Mulai Perjalananmu',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.adaptiveTextSize(
                              context,
                              22,
                            ),
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Buat akun untuk mengakses konten dan fitur Islami pilihan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.adaptiveTextSize(
                              context,
                              14,
                            ),
                            color: AppTheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      appBar,
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: pagePadding.right / 2,
                                ),
                                child: leftPane,
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(
                                padding: EdgeInsets.symmetric(
                                  horizontal: pagePadding.horizontal / 2,
                                  vertical: 12,
                                ),
                                child: Column(
                                  children: [
                                    header,
                                    formCard,
                                    social,
                                    signupLink,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // mobile / tablet kecil
                  return Column(
                    children: [
                      appBar,
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [header, formCard, social, signupLink],
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
