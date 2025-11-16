import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/core/constants/app_config.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';
import '../../../app/theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  ProviderSubscription? _authSub;

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

    // 🔥 pindahin listener ke sini, tapi pake listenManual
    _authSub = ref.listenManual(authProvider, (previous, next) {
      // Pastikan widget masih mounted dan route ini lagi di paling atas
      final route = ModalRoute.of(context);
      final isCurrent = route != null && route.isCurrent;
      if (!mounted || !isCurrent) return;

      final status = next['status'];
      final error = next['error'];

      if (status == AuthState.error &&
          error != null &&
          error.toString().contains(
            'Email belum diverifikasi. Silakan verifikasi terlebih dahulu.',
          )) {
        final email = next['email'];

        showMessageToast(
          context,
          message:
              'Email belum diverifikasi. Silakan verifikasi terlebih dahulu.',
          type: ToastType.warning,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamed('/otp', arguments: {'email': email, 'type': 'login'});
          }
        });
      } else if (status == AuthState.error && error != null) {
        showMessageToast(
          context,
          message: error.toString(),
          type: ToastType.error,
        );
        ref.read(authProvider.notifier).clearError();
      } else if (status == AuthState.authenticated) {
        showMessageToast(
          context,
          message: 'Login berhasil! Selamat datang kembali.',
          type: ToastType.success,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.close();
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      ref.read(authProvider.notifier).login(email, password);
    }
  }

  double _gapSmall(BuildContext context) =>
      ResponsiveHelper.isSmallScreen(context) ? 12 : 16;
  double _gapMedium(BuildContext context) =>
      ResponsiveHelper.isSmallScreen(context) ? 20 : 28;
  double _fieldHeight(BuildContext context) =>
      ResponsiveHelper.isSmallScreen(context) ? 52 : 56;

  @override
  Widget build(BuildContext context) {
    final isSmall = ResponsiveHelper.isSmallScreen(context);
    final isMedium = ResponsiveHelper.isMediumScreen(context);
    final isLarge = ResponsiveHelper.isLargeScreen(context);
    final isXL = ResponsiveHelper.isExtraLargeScreen(context);

    // Watch auth state for UI updates
    final authState = ref.watch(authProvider);
    final isLoading = authState['status'] == AuthState.loading;

    // Dimensi responsif
    final logoSize = isSmall
        ? 70.0
        : isMedium
        ? 85.0
        : 95.0;
    final cardRadius = isXL ? 32.0 : 28.0;
    final fieldRadius = 16.0;

    // Lebar maksimum kartu/form agar nyaman di tablet/desktop
    final maxFormWidth = isXL
        ? 520.0
        : isLarge
        ? 480.0
        : 440.0;

    // Padding global responsif
    final pagePadding = ResponsiveHelper.getResponsivePadding(context);

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
                              "Selamat Datang Kembali",
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
                            "Masuk untuk melanjutkan perjalanan islami Anda",
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

                // ——— Kartu Form Login ———
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
                                    labelText: 'Password',
                                    hintText: "Masukkan kata sandi Anda",
                                    prefixIcon: Icon(
                                      Icons.lock_outlined,
                                      color: AppTheme.accentGreen,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
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
                                    fillColor: AppTheme.accentGreen.withValues(
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
                                        color: AppTheme.accentGreen,
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
                                      return "Harap masukkan kata sandi";
                                    }
                                    if (value.length < 6) {
                                      return "Kata sandi minimal 6 karakter";
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 8),

                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(
                                        context,
                                      ).pushReplacementNamed(
                                        '/forgot-password',
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                    child: Text(
                                      "Lupa Kata Sandi?",
                                      style: TextStyle(
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.w600,
                                        fontSize:
                                            ResponsiveHelper.adaptiveTextSize(
                                              context,
                                              14,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: _gapSmall(context)),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: _fieldHeight(context),
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _handleLogin,
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
                                                "Masuk",
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

                // ——— Social Login Section ———
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
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  "Atau lanjutkan dengan",
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
                                side: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    fieldRadius,
                                  ),
                                ),
                                backgroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[100],
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.black54,
                                            ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.g_mobiledata_rounded,
                                          size: isSmall ? 26 : 28,
                                          color: AppTheme.onSurface,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Lanjutkan dengan Google",
                                          style: TextStyle(
                                            fontSize:
                                                ResponsiveHelper.adaptiveTextSize(
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

                // ——— Sign Up Link ———
                final signup = Padding(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Belum punya akun?",
                                style: TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: ResponsiveHelper.adaptiveTextSize(
                                    context,
                                    14,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/signup',
                                  );
                                },
                                child: Text(
                                  " Daftar",
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
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

                // ——— Panel kiri (hiasan) untuk layar besar ———
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
                        Icons.mosque_rounded,
                        size: isXL ? 120 : 96,
                        color: AppTheme.primaryBlue.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Tumbuh dalam Iman",
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
                        "Akses konten islami pilihan dan lanjutkan perjalananmu.",
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

                // ——— Susun final layout ———
                if (useTwoColumns) {
                  // Desktop/large tablet: 2 kolom
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      appBar,
                      Expanded(
                        child: Row(
                          children: [
                            // kiri
                            Expanded(
                              flex: 6,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: pagePadding.right / 2,
                                ),
                                child: leftPane,
                              ),
                            ),
                            // kanan (form)
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(
                                padding: EdgeInsets.symmetric(
                                  horizontal: pagePadding.horizontal / 2,
                                  vertical: 12,
                                ),
                                child: Column(
                                  children: [header, formCard, social, signup],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // Mobile/tablet kecil: 1 kolom
                  return Column(
                    children: [
                      appBar,
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [header, formCard, social, signup],
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
