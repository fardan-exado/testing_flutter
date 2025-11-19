import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/storage_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/profile/helpers/profile_responsive_helper.dart';
import 'package:test_flutter/features/profile/profile_provider.dart';
import 'package:test_flutter/features/profile/profile_state.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isGoogleAuth = false;
  bool _isLoading = true;

  ProviderSubscription? _profileSub;

  @override
  void initState() {
    super.initState();
    _checkAuthMethod();

    // Setup manual listener for profile state changes
    _profileSub = ref.listenManual(profileProvider, (previous, next) {
      final route = ModalRoute.of(context);
      final isCurrent = route != null && route.isCurrent;
      if (!mounted || !isCurrent) return;

      if (next.status == ProfileStatus.success && next.message != null) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.success,
          duration: const Duration(seconds: 3),
        );
        ref.read(profileProvider.notifier).clearMessage();
        ref.read(profileProvider.notifier).resetStatus();

        // Clear form fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        // Navigate back after successful password change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushNamed(context, '/profile');
          }
        });
      } else if (next.status == ProfileStatus.error && next.message != null) {
        showMessageToast(
          context,
          message: next.message!.replaceFirst('Exception: ', ''),
          type: ToastType.error,
          duration: const Duration(seconds: 4),
        );
        ref.read(profileProvider.notifier).clearMessage();
      }
    });
  }

  Future<void> _checkAuthMethod() async {
    try {
      final user = await StorageHelper.getUser();

      setState(() {
        // Check if auth_method is 'google' (case-insensitive)
        _isGoogleAuth = user?['auth_method']?.toLowerCase() == 'google';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isGoogleAuth = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _profileSub?.close();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      final currentPassword = _currentPasswordController.text.trim();
      final newPassword = _newPasswordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      await ref
          .read(profileProvider.notifier)
          .editPassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
            confirmPassword: confirmPassword,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Watch profile state
    final profileState = ref.watch(profileProvider);
    final isProfileLoading = profileState.status == ProfileStatus.loading;

    // Show loading while checking auth method
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade200],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // ===== Header dengan Gradient =====
                Container(
                  padding: EdgeInsets.all(
                    ProfileResponsiveHelper.px(context, 20),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centered Title
                      Text(
                        'Ubah Password',
                        style: TextStyle(
                          fontSize: ProfileResponsiveHelper.ts(context, 20),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      // Back Button (Left aligned)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(
                            ProfileResponsiveHelper.px(context, 12),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: ProfileResponsiveHelper.px(context, 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.grey.shade200],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ===== Header dengan Gradient =====
              Container(
                padding: EdgeInsets.all(
                  ProfileResponsiveHelper.px(context, 20),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Centered Title
                    Text(
                      'Ubah Password',
                      style: TextStyle(
                        fontSize: ProfileResponsiveHelper.ts(context, 20),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    // Back Button (Left aligned)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(
                          ProfileResponsiveHelper.px(context, 12),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: ProfileResponsiveHelper.px(context, 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 32.0 : 20.0),
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Google Auth Warning (if applicable)
                        if (_isGoogleAuth) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isTablet ? 24 : 20),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFFA726,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFFFFA726,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      color: const Color(0xFF4A5568),
                                      size: isTablet ? 18 : 16,
                                    ),
                                    SizedBox(width: isTablet ? 8 : 6),
                                    Expanded(
                                      child: Text(
                                        'Fitur ubah password tidak tersedia untuk akun Google',
                                        style: TextStyle(
                                          fontSize: isTablet ? 14 : 12,
                                          color: const Color(0xFF4A5568),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isTablet ? 32 : 24),
                        ],

                        // Header Info
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isTablet ? 24 : 20),
                          decoration: BoxDecoration(
                            color: _isGoogleAuth
                                ? Colors.grey[100]
                                : const Color(
                                    0xFF1E88E5,
                                  ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isGoogleAuth
                                  ? Colors.grey[300]!
                                  : const Color(
                                      0xFF1E88E5,
                                    ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.security,
                                    color: _isGoogleAuth
                                        ? Colors.grey[400]
                                        : AppTheme.primaryBlue,
                                    size: isTablet ? 28 : 24,
                                  ),
                                  SizedBox(width: isTablet ? 16 : 12),
                                  Expanded(
                                    child: Text(
                                      'Keamanan Password',
                                      style: TextStyle(
                                        fontSize: isTablet ? 20 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: _isGoogleAuth
                                            ? Colors.grey[600]
                                            : AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isTablet ? 12 : 8),
                              Text(
                                _isGoogleAuth
                                    ? 'Password akun Google Anda dikelola oleh Google. Silakan gunakan pengaturan akun Google untuk mengubah password.'
                                    : 'Pastikan password baru Anda kuat dan tidak mudah ditebak. Gunakan kombinasi huruf besar, huruf kecil, angka, dan simbol.',
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  color: _isGoogleAuth
                                      ? Colors.grey[600]
                                      : const Color(0xFF4A5568),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isTablet ? 32 : 24),

                        // Current Password
                        _buildPasswordField(
                          controller: _currentPasswordController,
                          label: 'Password Saat Ini',
                          icon: Icons.lock_outline,
                          isVisible: _showCurrentPassword,
                          enabled: !isProfileLoading && !_isGoogleAuth,
                          onVisibilityToggle: () {
                            setState(() {
                              _showCurrentPassword = !_showCurrentPassword;
                            });
                          },
                          validator: (value) {
                            if (_isGoogleAuth) return null;
                            if (value == null || value.isEmpty) {
                              return 'Password saat ini harus diisi';
                            }
                            if (value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isTablet ? 20 : 16),

                        // New Password
                        _buildPasswordField(
                          controller: _newPasswordController,
                          label: 'Password Baru',
                          icon: Icons.lock,
                          isVisible: _showNewPassword,
                          enabled: !isProfileLoading && !_isGoogleAuth,
                          onVisibilityToggle: () {
                            setState(() {
                              _showNewPassword = !_showNewPassword;
                            });
                          },
                          validator: (value) {
                            if (_isGoogleAuth) return null;
                            if (value == null || value.isEmpty) {
                              return 'Password baru harus diisi';
                            }
                            if (value.length < 8) {
                              return 'Password baru minimal 8 karakter';
                            }
                            if (!RegExp(
                              r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)',
                            ).hasMatch(value)) {
                              return 'Password harus mengandung huruf besar, kecil, dan angka';
                            }
                            if (value == _currentPasswordController.text) {
                              return 'Password baru harus berbeda dari password lama';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isTablet ? 20 : 16),

                        // Confirm Password
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: 'Konfirmasi Password Baru',
                          icon: Icons.lock_reset,
                          isVisible: _showConfirmPassword,
                          enabled: !isProfileLoading && !_isGoogleAuth,
                          onVisibilityToggle: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                          validator: (value) {
                            if (_isGoogleAuth) return null;
                            if (value == null || value.isEmpty) {
                              return 'Konfirmasi password harus diisi';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Password tidak cocok';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isTablet ? 32 : 24),

                        // Password Strength Indicator
                        if (!_isGoogleAuth)
                          Container(
                            padding: EdgeInsets.all(isTablet ? 20 : 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tips Password Kuat:',
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2D3748),
                                  ),
                                ),
                                SizedBox(height: isTablet ? 12 : 8),
                                _buildPasswordTip(
                                  '✓ Minimal 8 karakter',
                                  isTablet,
                                ),
                                _buildPasswordTip(
                                  '✓ Mengandung huruf besar dan kecil',
                                  isTablet,
                                ),
                                _buildPasswordTip(
                                  '✓ Mengandung angka',
                                  isTablet,
                                ),
                                _buildPasswordTip(
                                  '✓ Mengandung simbol (!@#\$%^&*)',
                                  isTablet,
                                ),
                                _buildPasswordTip(
                                  '✓ Berbeda dari password sebelumnya',
                                  isTablet,
                                ),
                              ],
                            ),
                          ),

                        SizedBox(height: isTablet ? 40 : 32),

                        // Change Password Button
                        if (!_isGoogleAuth)
                          SizedBox(
                            width: double.infinity,
                            height: isTablet ? 56 : 48,
                            child: ElevatedButton(
                              onPressed: isProfileLoading
                                  ? null
                                  : _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[300],
                                disabledForegroundColor: Colors.grey[500],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: isProfileLoading ? 0 : 2,
                              ),
                              child: isProfileLoading
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: isTablet ? 20 : 18,
                                          height: isTablet ? 20 : 18,
                                          child:
                                              const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                        ),
                                        SizedBox(width: isTablet ? 12 : 10),
                                        Text(
                                          'Mengubah Password...',
                                          style: TextStyle(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.lock_reset,
                                          size: isTablet ? 22 : 20,
                                        ),
                                        SizedBox(width: isTablet ? 10 : 8),
                                        Text(
                                          'Ubah Password',
                                          style: TextStyle(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                        if (!_isGoogleAuth)
                          SizedBox(height: isTablet ? 20 : 16),

                        // Cancel/Back Button
                        SizedBox(
                          width: double.infinity,
                          height: isTablet ? 56 : 48,
                          child: OutlinedButton(
                            onPressed: isProfileLoading
                                ? null
                                : () => Navigator.pushReplacementNamed(
                                    context,
                                    '/profile',
                                  ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _isGoogleAuth
                                  ? const Color(0xFF4A5568)
                                  : AppTheme.primaryBlue,
                              side: BorderSide(
                                color: isProfileLoading
                                    ? Colors.grey[300]!
                                    : _isGoogleAuth
                                    ? const Color(0xFF4A5568)
                                    : AppTheme.primaryBlue,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isGoogleAuth ? 'Kembali' : 'Batal',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Builder(
      builder: (context) => TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: validator,
        enabled: enabled,
        style: TextStyle(
          fontSize: ProfileResponsiveHelper.textSize(context, 16),
          color: enabled ? const Color(0xFF2D3748) : Colors.grey[600],
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: enabled ? AppTheme.primaryBlue : Colors.grey[400],
            size: ProfileResponsiveHelper.getIconSize(
              context,
              small: 20,
              medium: 24,
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: enabled ? const Color(0xFF4A5568) : Colors.grey[400],
              size: ProfileResponsiveHelper.getIconSize(
                context,
                small: 20,
                medium: 24,
              ),
            ),
            onPressed: enabled ? onVisibilityToggle : null,
          ),
          border: OutlineInputBorder(
            borderRadius: ProfileResponsiveHelper.getBorderRadius(value: 12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: ProfileResponsiveHelper.getBorderRadius(value: 12),
            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: ProfileResponsiveHelper.getBorderRadius(value: 12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: ProfileResponsiveHelper.getBorderRadius(value: 12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: ProfileResponsiveHelper.getBorderRadius(value: 12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: ProfileResponsiveHelper.getBorderRadius(value: 12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(
            horizontal: ProfileResponsiveHelper.px(context, 16),
            vertical: ProfileResponsiveHelper.px(context, 16),
          ),
          labelStyle: TextStyle(
            color: enabled ? const Color(0xFF4A5568) : Colors.grey[500],
            fontSize: ProfileResponsiveHelper.textSize(context, 14),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordTip(String tip, bool isTablet) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 8 : 4),
      child: Text(
        tip,
        style: TextStyle(
          fontSize: isTablet ? 14 : 12,
          color: const Color(0xFF4A5568),
        ),
      ),
    );
  }
}
