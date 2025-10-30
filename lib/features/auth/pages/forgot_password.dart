import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/core/constants/app_config.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';
import '../../../app/theme.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
    _emailController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final isXL = screenWidth >= ResponsiveHelper.extraLargeScreenSize;
    final isLarge = screenWidth >= ResponsiveHelper.largeScreenSize;
    final isMedium = screenWidth >= ResponsiveHelper.mediumScreenSize;
    final isSmall = screenWidth < ResponsiveHelper.mediumScreenSize;

    final logoSize = isSmall
        ? 70.0
        : isMedium
        ? 85.0
        : 95.0;
    final cardRadius = isXL ? 32.0 : 28.0;
    final fieldRadius = 16.0;

    // Lebar maksimum kartu/form
    final maxFormWidth = isXL
        ? 520.0
        : isLarge
        ? 480.0
        : 440.0;

    // Padding global responsif
    final pagePadding = ResponsiveHelper.getResponsivePadding(context);

    // Listen to auth state changes
    ref.listen(authProvider, (previous, next) {
      final status = next['status'];
      final error = next['error'];
      final message = next['message'];

      if (status == AuthState.error && error != null) {
        showMessageToast(
          context,
          message: error.toString(),
          type: ToastType.error,
          duration: const Duration(seconds: 4),
        );
        ref.read(authProvider.notifier).clearError();
      } else if (status == AuthState.forgotPasswordSent) {
        showMessageToast(
          context,
          message:
              message?.toString() ?? 'Kode OTP telah dikirim ke email Anda.',
          type: ToastType.success,
          duration: const Duration(seconds: 3),
        );

        // Navigate to OTP page after showing success
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/otp',
              arguments: {
                'email': _emailController.text.trim(),
                'type': 'forgot_password',
              },
            );
          }
        });
      }
    });

    // Watch auth state for UI updates
    final authState = ref.watch(authProvider);
    final isLoading = authState['status'] == AuthState.loading;

    // Body
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
                final useTwoColumns =
                    constraints.maxWidth >=
                    ResponsiveHelper.largeScreenSize; // >= 900 px

                // ——— AppBar ringan (selalu tampil) ———
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
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                // ——— Header (logo + judul) ———
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
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 25,
                              offset: const Offset(0, 8),
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            AppConfig.appLogo,
                            fit: BoxFit.cover,
                          ),
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
                              colors: [
                                AppTheme.primaryBlue,
                                AppTheme.accentGreen,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              "Lupa Kata Sandi?",
                              style: TextStyle(
                                fontSize: ResponsiveHelper.adaptiveTextSize(
                                  context,
                                  30,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: isSmall ? 6 : 8),
                          Text(
                            "Masukkan email Anda dan kami akan mengirimkan\nlink untuk mereset kata sandi",
                            style: TextStyle(
                              fontSize: ResponsiveHelper.adaptiveTextSize(
                                context,
                                15,
                              ),
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

                // ——— Kartu Form Forgot Password ———
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
                                color: AppTheme.primaryBlue.withValues(
                                  alpha: 0.08,
                                ),
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
                                    hintText: "Masukkan email Anda",
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.primaryBlue.withValues(
                                      alpha: 0.05,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        fieldRadius,
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        fieldRadius,
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        fieldRadius,
                                      ),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryBlue,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        fieldRadius,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.red.shade300,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Harap masukkan email";
                                    }
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
                                      return "Harap masukkan email yang valid";
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: _gapSmall(context) + 8),

                                // Submit Button
                                SizedBox(
                                  width: double.infinity,
                                  height: _fieldHeight(context),
                                  child: ElevatedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              await ref
                                                  .read(authProvider.notifier)
                                                  .forgotPassword(
                                                    _emailController.text
                                                        .trim(),
                                                  );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          fieldRadius,
                                        ),
                                      ),
                                      elevation: 0,
                                      disabledBackgroundColor: AppTheme
                                          .primaryBlue
                                          .withValues(alpha: 0.6),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "Kirim Link Verifikasi",
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
                                                Icons.send_rounded,
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

                // ——— Link ke Login ———
                final loginLink = FadeTransition(
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Sudah ingat kata sandi? ",
                                style: TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: ResponsiveHelper.adaptiveTextSize(
                                    context,
                                    14,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  "Masuk",
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontSize: ResponsiveHelper.adaptiveTextSize(
                                      context,
                                      14,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                // ——— Layout ———
                if (useTwoColumns) {
                  // Untuk layar besar: 2 kolom
                  return Column(
                    children: [
                      appBar,
                      Expanded(
                        child: SingleChildScrollView(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Kolom kiri: header
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 24),
                                  child: header,
                                ),
                              ),
                              // Kolom kanan: form
                              Expanded(
                                child: Column(children: [formCard, loginLink]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Untuk layar kecil: 1 kolom
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        appBar,
                        header,
                        formCard,
                        loginLink,
                        SizedBox(height: _gapLarge(context)),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  // Responsive helper methods
  double _gapSmall(BuildContext context) =>
      ResponsiveHelper.getScreenHeight(context) * 0.015;
  double _gapMedium(BuildContext context) =>
      ResponsiveHelper.getScreenHeight(context) * 0.025;
  double _gapLarge(BuildContext context) =>
      ResponsiveHelper.getScreenHeight(context) * 0.04;
  double _fieldHeight(BuildContext context) =>
      ResponsiveHelper.getScreenHeight(context) * 0.065;
}
