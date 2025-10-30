import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/core/constants/app_config.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';
import '../../../app/theme.dart';

enum OTPType {
  registration, // Untuk verifikasi registrasi
  forgotPassword, // Untuk forgot password flow
}

class OTPPage extends ConsumerStatefulWidget {
  final String email;
  final OTPType type;

  const OTPPage({super.key, required this.email, required this.type});

  @override
  ConsumerState<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends ConsumerState<OTPPage>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Timer? _timer;
  int _resendCountdown = 60;
  bool _canResend = false;

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

    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _fadeController.dispose();
    _slideController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String _getOTPCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _handleOTPSubmit() async {
    final otp = _getOTPCode();

    if (otp.length != 6) {
      showMessageToast(
        context,
        message: 'Harap masukkan kode OTP lengkap',
        type: ToastType.error,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (widget.type == OTPType.registration) {
      // Verify OTP untuk registrasi
      await ref
          .read(authProvider.notifier)
          .verifyRegistrationOTP(email: widget.email, otp: otp);
    } else {
      // Untuk forgot password, navigate ke reset password page dengan OTP
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/reset-password',
        arguments: {'otp': otp, 'email': widget.email},
      );
    }
  }

  void _handleResendOTP() async {
    if (!_canResend) return;

    await ref.read(authProvider.notifier).resendOTP(widget.email);
    _startResendTimer();
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
      } else if (status == AuthState.authenticated &&
          widget.type == OTPType.registration) {
        // Registrasi berhasil, navigate ke home
        showMessageToast(
          context,
          message: message?.toString() ?? 'Registrasi berhasil!',
          type: ToastType.success,
          duration: const Duration(seconds: 3),
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false);
          }
        });
      } else if (status == AuthState.otpSent) {
        // OTP berhasil dikirim ulang
        showMessageToast(
          context,
          message: message?.toString() ?? 'Kode OTP telah dikirim ulang.',
          type: ToastType.success,
          duration: const Duration(seconds: 3),
        );
      }
    });

    // Watch auth state for UI updates
    final authState = ref.watch(authProvider);
    final isLoading = authState['status'] == AuthState.loading;

    // Title berdasarkan type
    final pageTitle = widget.type == OTPType.registration
        ? "Verifikasi Email"
        : "Verifikasi OTP";

    final pageSubtitle = widget.type == OTPType.registration
        ? "Masukkan kode OTP yang telah dikirim ke\n${widget.email}"
        : "Masukkan kode OTP untuk reset password\n${widget.email}";

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
                          onPressed: () => Navigator.pop(context),
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
                              pageTitle,
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
                            pageSubtitle,
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

                // ——— Kartu Form OTP ———
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
                          child: Column(
                            children: [
                              // OTP Input Fields
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(6, (index) {
                                  return Container(
                                    width: isSmall ? 45 : 55,
                                    height: isSmall ? 60 : 70,
                                    alignment: Alignment.center,
                                    child: TextField(
                                      controller: _otpControllers[index],
                                      focusNode: _focusNodes[index],
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      maxLength: 1,
                                      style: TextStyle(
                                        fontSize:
                                            ResponsiveHelper.adaptiveTextSize(
                                              context,
                                              24,
                                            ),
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryBlue,
                                        height: 1.2,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        filled: true,
                                        fillColor: AppTheme.primaryBlue
                                            .withValues(alpha: 0.05),
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: isSmall ? 16 : 20,
                                          horizontal: 8,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: AppTheme.primaryBlue,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          // Move to next field
                                          if (index < 5) {
                                            _focusNodes[index + 1]
                                                .requestFocus();
                                          } else {
                                            // Last field, submit
                                            _focusNodes[index].unfocus();
                                          }
                                        } else if (value.isEmpty && index > 0) {
                                          // Move to previous field
                                          _focusNodes[index - 1].requestFocus();
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(height: _gapMedium(context)),

                              // Verify Button
                              SizedBox(
                                width: double.infinity,
                                height: _fieldHeight(context),
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : _handleOTPSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
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
                                              "Verifikasi",
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
                                              Icons.check_circle_outline,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              SizedBox(height: _gapMedium(context)),

                              // Resend OTP
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Tidak menerima kode? ",
                                    style: TextStyle(
                                      color: AppTheme.onSurfaceVariant,
                                      fontSize:
                                          ResponsiveHelper.adaptiveTextSize(
                                            context,
                                            14,
                                          ),
                                    ),
                                  ),
                                  if (_canResend)
                                    TextButton(
                                      onPressed: isLoading
                                          ? null
                                          : _handleResendOTP,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        "Kirim Ulang",
                                        style: TextStyle(
                                          color: AppTheme.primaryBlue,
                                          fontSize:
                                              ResponsiveHelper.adaptiveTextSize(
                                                context,
                                                14,
                                              ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      "($_resendCountdown detik)",
                                      style: TextStyle(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize:
                                            ResponsiveHelper.adaptiveTextSize(
                                              context,
                                              14,
                                            ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
                              Expanded(child: formCard),
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
  double _gapMedium(BuildContext context) =>
      ResponsiveHelper.getScreenHeight(context) * 0.025;
  double _gapLarge(BuildContext context) =>
      ResponsiveHelper.getScreenHeight(context) * 0.04;
  double _fieldHeight(BuildContext context) =>
      ResponsiveHelper.getScreenHeight(context) * 0.065;
}
