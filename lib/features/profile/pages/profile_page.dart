import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_flutter/app/router.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';
import 'package:test_flutter/features/profile/helpers/profile_responsive_helper.dart';
import 'package:test_flutter/features/profile/profile_provider.dart';
import 'package:test_flutter/features/profile/profile_state.dart';
import 'package:test_flutter/features/subscription/providers/pesanan_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String selectedLanguage = 'Indonesia';
  final ImagePicker _imagePicker = ImagePicker();

  ProviderSubscription? _profileSub;

  // Helper untuk build avatar URL
  String _buildAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return '';

    final storage = dotenv.env['STORAGE_URL'] ?? '';
    if (storage.isEmpty) return '';

    // Jika sudah URL lengkap, return as is
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return avatarPath;
    }

    // Jika path relatif, tambahkan base URL
    return '$storage/$avatarPath';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check auth status first
      final authState = ref.read(authProvider);
      if (authState['status'] == AuthState.authenticated) {
        ref.read(profileProvider.notifier).loadUser();
      }
    });

    // Setup manual listener for profile state changes
    _profileSub = ref.listenManual(profileProvider, (previous, next) {
      final route = ModalRoute.of(context);
      final isCurrent = route != null && route.isCurrent;
      if (!mounted || !isCurrent) return;

      if (next.status == ProfileStatus.error && next.message != null) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.error,
        );
        ref.read(profileProvider.notifier).clearMessage();
      } else if (next.status == ProfileStatus.success && next.message != null) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.success,
        );
        ref.read(profileProvider.notifier).clearMessage();
        ref.read(profileProvider.notifier).resetStatus();
      }
    });
  }

  @override
  void dispose() {
    _profileSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState['status'] == AuthState.authenticated;

    // Watch profile state
    final profileState = ref.watch(profileProvider);
    final user = profileState.profile;
    final status = profileState.status;
    final message = profileState.message;

    // Create guest user if not authenticated
    final displayUser = isAuthenticated
        ? user
        : {
            'user': {
              'name': 'Guest',
              'email': 'guest@shollover.com',
              'phone': null,
            },
          };

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade200],
          ),
        ),
        child: SafeArea(
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
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        ProfileResponsiveHelper.px(context, 12),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: ProfileResponsiveHelper.px(context, 20),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: ProfileResponsiveHelper.ts(context, 20),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    // Refresh button - only for authenticated users
                    if (isAuthenticated && status != ProfileStatus.loading)
                      Container(
                        padding: EdgeInsets.all(
                          ProfileResponsiveHelper.px(context, 12),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            ref.read(profileProvider.notifier).loadUser();
                          },
                          child: Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: ProfileResponsiveHelper.px(context, 20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ===== Content =====
              Expanded(
                child: SingleChildScrollView(
                  padding: ProfileResponsiveHelper.getPageHorizontalPadding(
                    context,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: ProfileResponsiveHelper.getContentMaxWidth(
                          context,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Profile Card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(
                              ProfileResponsiveHelper.px(context, 20),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Show loading only if authenticated and loading
                                if (isAuthenticated &&
                                    status == ProfileStatus.loading)
                                  _buildLoadingProfile(context)
                                // Show error only if authenticated and error
                                else if (isAuthenticated &&
                                    status == ProfileStatus.error)
                                  _buildErrorProfile(context, message)
                                // Show profile (real or guest)
                                else
                                  _buildProfileContent(
                                    context,
                                    displayUser,
                                    isGuest: !isAuthenticated,
                                  ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: ProfileResponsiveHelper.px(context, 28),
                          ),

                          // Show login prompt for guest users
                          if (!isAuthenticated) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(
                                ProfileResponsiveHelper.px(context, 20),
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1E88E5),
                                    Color(0xFF26A69A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1E88E5,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: ProfileResponsiveHelper.px(
                                      context,
                                      48,
                                    ),
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                    height: ProfileResponsiveHelper.px(
                                      context,
                                      12,
                                    ),
                                  ),
                                  Text(
                                    'Masuk untuk Mengakses Fitur',
                                    style: TextStyle(
                                      fontSize: ProfileResponsiveHelper.ts(
                                        context,
                                        18,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                    height: ProfileResponsiveHelper.px(
                                      context,
                                      8,
                                    ),
                                  ),
                                  Text(
                                    'Login untuk mengelola profil, keluarga, dan mengakses fitur lengkap',
                                    style: TextStyle(
                                      fontSize: ProfileResponsiveHelper.ts(
                                        context,
                                        14,
                                      ),
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                    height: ProfileResponsiveHelper.px(
                                      context,
                                      16,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/welcome',
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF1E88E5),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: ProfileResponsiveHelper.px(
                                          context,
                                          32,
                                        ),
                                        vertical: ProfileResponsiveHelper.px(
                                          context,
                                          14,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Masuk Sekarang',
                                      style: TextStyle(
                                        fontSize: ProfileResponsiveHelper.ts(
                                          context,
                                          16,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: ProfileResponsiveHelper.px(context, 28),
                            ),
                          ],

                          // Menu Items (disabled for guest)
                          _buildMenuItem(
                            context: context,
                            icon: Icons.person_outline,
                            title: 'Edit Profile',
                            subtitle: isAuthenticated
                                ? 'Ubah informasi profil Anda'
                                : 'Login untuk mengedit profil',
                            enabled: isAuthenticated && displayUser != null,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.editProfile,
                              );
                            },
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.security,
                            title: 'Ubah Password',
                            subtitle: isAuthenticated
                                ? 'Ubah password untuk keamanan akun'
                                : 'Login untuk mengubah password',
                            enabled: isAuthenticated && displayUser != null,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.changePassword,
                            ),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.family_restroom,
                            title: 'Kelola Keluarga',
                            subtitle: isAuthenticated
                                ? 'Tambah atau edit anggota keluarga'
                                : 'Login untuk mengelola keluarga',
                            enabled: isAuthenticated && displayUser != null,
                            onTap: () =>
                                Navigator.pushNamed(context, '/manage-family'),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.workspace_premium_rounded,
                            title: 'Paket Premium',
                            subtitle: isAuthenticated
                                ? 'Upgrade akun dan lihat transaksi'
                                : 'Login untuk akses premium',
                            enabled: isAuthenticated && displayUser != null,
                            onTap: () =>
                                Navigator.pushNamed(context, AppRoutes.plan),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.help_outline,
                            title: 'Bantuan',
                            subtitle: 'FAQ dan dukungan pelanggan',
                            enabled: true,
                            onTap: () => _showHelp(context),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.info_outline,
                            title: 'Tentang Aplikasi',
                            subtitle: 'Versi dan informasi aplikasi',
                            enabled: true,
                            onTap: () => _showAbout(context),
                          ),

                          SizedBox(
                            height: ProfileResponsiveHelper.px(context, 16),
                          ),

                          // Logout (only for authenticated users)
                          if (isAuthenticated)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                vertical: ProfileResponsiveHelper.px(
                                  context,
                                  16,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: InkWell(
                                onTap: () => _showLogoutDialog(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout,
                                      color: Colors.red,
                                      size: ProfileResponsiveHelper.px(
                                        context,
                                        22,
                                      ),
                                    ),
                                    SizedBox(
                                      width: ProfileResponsiveHelper.px(
                                        context,
                                        10,
                                      ),
                                    ),
                                    Text(
                                      'Keluar',
                                      style: TextStyle(
                                        fontSize: ProfileResponsiveHelper.ts(
                                          context,
                                          16,
                                        ),
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          SizedBox(
                            height: ResponsiveHelper.getResponsivePadding(
                              context,
                            ).bottom,
                          ),
                        ],
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

  // ================== Widgets ==================

  Widget _buildLoadingProfile(BuildContext context) {
    return Column(
      children: [
        // Avatar loading
        Container(
          width: ProfileResponsiveHelper.px(context, 88),
          height: ProfileResponsiveHelper.px(context, 88),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
            ),
          ),
        ),
        SizedBox(height: ProfileResponsiveHelper.px(context, 18)),

        // Name skeleton
        Container(
          width: 150,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(height: ProfileResponsiveHelper.px(context, 6)),

        // Email skeleton
        Container(
          width: 200,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(height: ProfileResponsiveHelper.px(context, 22)),
      ],
    );
  }

  Widget _buildErrorProfile(BuildContext context, String? errorMessage) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: ProfileResponsiveHelper.px(context, 64),
          color: Colors.red,
        ),
        SizedBox(height: ProfileResponsiveHelper.px(context, 16)),
        Text(
          'Gagal memuat profil',
          style: TextStyle(
            fontSize: ProfileResponsiveHelper.ts(context, 18),
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        SizedBox(height: ProfileResponsiveHelper.px(context, 8)),
        if (errorMessage != null)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ProfileResponsiveHelper.px(context, 20),
            ),
            child: Text(
              errorMessage,
              style: TextStyle(
                fontSize: ProfileResponsiveHelper.ts(context, 14),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          Text(
            'Silakan coba lagi',
            style: TextStyle(
              fontSize: ProfileResponsiveHelper.ts(context, 14),
              color: Colors.grey[600],
            ),
          ),
        SizedBox(height: ProfileResponsiveHelper.px(context, 16)),
        ElevatedButton.icon(
          onPressed: () {
            ref.read(profileProvider.notifier).loadUser();
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Coba Lagi'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: ProfileResponsiveHelper.px(context, 16),
              vertical: ProfileResponsiveHelper.px(context, 8),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SizedBox(height: ProfileResponsiveHelper.px(context, 22)),
      ],
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    user, {
    bool isGuest = false,
  }) {
    // Handle case when user is null
    final name = user != null ? (user['name'] ?? '-') : '-';
    final email = user != null ? (user['email'] ?? '-') : '-';

    // Safely handle avatar - check type before casting
    String? avatarPath;
    if (user != null && user['avatar'] != null) {
      final avatar = user['avatar'];
      if (avatar is String) {
        avatarPath = avatar;
      }
    }

    final avatarUrl = _buildAvatarUrl(avatarPath);
    final isDataAvailable = user != null;

    return Column(
      children: [
        // Avatar with upload functionality
        GestureDetector(
          onTap: isGuest
              ? null
              : () {
                  if (isDataAvailable) {
                    _showAvatarSourceDialog(context);
                  }
                },
          child: Stack(
            children: [
              Container(
                width: ProfileResponsiveHelper.px(context, 88),
                height: ProfileResponsiveHelper.px(context, 88),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: avatarUrl.isEmpty
                      ? LinearGradient(
                          colors: isGuest
                              ? [Colors.grey.shade400, Colors.grey.shade500]
                              : isDataAvailable
                              ? [
                                  const Color(0xFF1E88E5),
                                  const Color(0xFF26A69A),
                                ]
                              : [Colors.grey.shade400, Colors.grey.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  image: avatarUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl.isEmpty
                    ? Icon(
                        isGuest
                            ? Icons.person_off_outlined
                            : isDataAvailable
                            ? Icons.person
                            : Icons.person_off,
                        size: ProfileResponsiveHelper.px(context, 44),
                        color: Colors.white,
                      )
                    : null,
              ),

              // Camera icon overlay (only for authenticated users with data)
              if (!isGuest && isDataAvailable)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(
                      ProfileResponsiveHelper.px(context, 6),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: ProfileResponsiveHelper.px(context, 14),
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: ProfileResponsiveHelper.px(context, 18)),

        // Name
        Text(
          name,
          style: TextStyle(
            fontSize: ProfileResponsiveHelper.ts(context, 22),
            fontWeight: FontWeight.bold,
            color: isGuest || !isDataAvailable
                ? Colors.grey.shade600
                : const Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: ProfileResponsiveHelper.px(context, 6)),

        // Email
        Text(
          email,
          style: TextStyle(
            fontSize: ProfileResponsiveHelper.ts(context, 14),
            color: isGuest || !isDataAvailable
                ? Colors.grey.shade500
                : const Color(0xFF4A5568),
          ),
        ),

        // Phone (if available and not guest)
        // if (!isGuest && phone != null && phone.isNotEmpty) ...[
        //   SizedBox(height: ProfileResponsiveHelper.px(context, 4)),
        //   Row(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       Icon(
        //         Icons.phone,
        //         size: ProfileResponsiveHelper.px(context, 14),
        //         color: const Color(0xFF4A5568),
        //       ),
        //       SizedBox(width: ProfileResponsiveHelper.px(context, 4)),
        //       Text(
        //         phone,
        //         style: TextStyle(
        //           fontSize: ProfileResponsiveHelper.ts(context, 13),
        //           color: const Color(0xFF4A5568),
        //         ),
        //       ),
        //     ],
        //   ),
        // ],

        // Guest indicator
        if (isGuest) ...[
          SizedBox(height: ProfileResponsiveHelper.px(context, 8)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ProfileResponsiveHelper.px(context, 12),
              vertical: ProfileResponsiveHelper.px(context, 4),
            ),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: ProfileResponsiveHelper.px(context, 14),
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: ProfileResponsiveHelper.px(context, 6)),
                Text(
                  'Mode Guest',
                  style: TextStyle(
                    fontSize: ProfileResponsiveHelper.ts(context, 12),
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Unavailable indicator (only for authenticated users with no data)
        if (!isGuest && !isDataAvailable) ...[
          SizedBox(height: ProfileResponsiveHelper.px(context, 8)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ProfileResponsiveHelper.px(context, 12),
              vertical: ProfileResponsiveHelper.px(context, 4),
            ),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Data tidak tersedia',
              style: TextStyle(
                fontSize: ProfileResponsiveHelper.ts(context, 12),
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        SizedBox(height: ProfileResponsiveHelper.px(context, 22)),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final iconSize = ProfileResponsiveHelper.px(context, 26);
    final titleFontSize = ProfileResponsiveHelper.ts(context, 16);
    final subtitleFontSize = ProfileResponsiveHelper.ts(context, 13);
    final vPad = ProfileResponsiveHelper.px(context, 14);
    final hPad = ProfileResponsiveHelper.px(context, 16);

    return Container(
      margin: EdgeInsets.only(bottom: ProfileResponsiveHelper.px(context, 14)),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        onTap: enabled ? onTap : null,
        contentPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        leading: Container(
          padding: EdgeInsets.all(ProfileResponsiveHelper.px(context, 10)),
          decoration: BoxDecoration(
            color: (enabled ? const Color(0xFF1E88E5) : Colors.grey).withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: enabled ? const Color(0xFF1E88E5) : Colors.grey,
            size: iconSize,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            color: enabled ? const Color(0xFF2D3748) : Colors.grey,
          ),
        ),
        subtitle: Text(
          enabled ? subtitle : 'Tidak tersedia',
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: enabled ? const Color(0xFF4A5568) : Colors.grey,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: ProfileResponsiveHelper.px(context, 16),
          color: enabled ? const Color(0xFF4A5568) : Colors.grey,
        ),
      ),
    );
  }

  // ================== Dialogs & Actions ==================

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear subscription provider state first
              ref.read(pesananProvider.notifier).clearPremiumStatus();
              // Then logout from auth
              ref.read(authProvider.notifier).logout();
              showMessageToast(
                context,
                message: 'Anda telah keluar dari aplikasi',
                type: ToastType.success,
              );
              Navigator.pushReplacementNamed(context, '/welcome');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bantuan'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🌐 Website: www.shollover.com'),
            SizedBox(height: 8),
            Text('📧 Email: support@shollover.com'),
            SizedBox(height: 8),
            Text('📱 WhatsApp: +62 xxx xxxx xxxx'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang Aplikasi'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shollover',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('📱 Versi: 1.0.0'),
            SizedBox(height: 8),
            Text('🔨 Build: 100'),
            SizedBox(height: 8),
            Text('👨‍💻 Developer: Tim Shollover'),
            SizedBox(height: 16),
            Text(
              'Aplikasi untuk membantu keluarga Muslim dalam menjalankan ibadah dan monitoring aktivitas keagamaan.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ================== Avatar Upload ==================

  void _showAvatarSourceDialog(BuildContext context) {
    // Check if user has avatar
    final profileState = ref.read(profileProvider);
    final user = profileState.profile;

    // Safely handle avatar - check type before casting
    String? avatarPath;
    if (user != null && user['avatar'] != null) {
      final avatar = user['avatar'];
      if (avatar is String) {
        avatarPath = avatar;
      }
    }

    final hasAvatar = avatarPath != null && avatarPath.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: ProfileResponsiveHelper.ts(context, 18),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 20),

              // Camera option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                title: const Text('Kamera'),
                subtitle: const Text('Ambil foto dengan kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),

              // Gallery option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26A69A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF26A69A),
                  ),
                ),
                title: const Text('Galeri'),
                subtitle: const Text('Pilih foto dari galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),

              // Delete avatar option (only show if user has avatar)
              if (hasAvatar)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                  ),
                  title: const Text(
                    'Hapus Avatar',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text('Hapus foto profil Anda'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteAvatarDialog(context);
                  },
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF1E88E5)),
                  const SizedBox(height: 16),
                  Text(
                    'Mengupload avatar...',
                    style: TextStyle(
                      fontSize: ProfileResponsiveHelper.ts(context, 14),
                      color: const Color(0xFF2D3748), // abu gelap
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Upload avatar
      await ref.read(profileProvider.notifier).updateAvatar(avatar: pickedFile);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        showMessageToast(
          context,
          message: 'Gagal mengupload avatar: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  void _showDeleteAvatarDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Avatar'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus foto profil Anda?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Save navigator state before closing dialog
              final navigator = Navigator.of(dialogContext);

              // Close confirmation dialog first
              navigator.pop();

              // Use dialogContext to show loading dialog (it's still valid here)
              if (mounted) {
                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (loadingContext) => Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF1E88E5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Menghapus avatar...',
                            style: TextStyle(
                              fontSize: ProfileResponsiveHelper.ts(context, 14),
                              color: const Color(0xFF2D3748),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              try {
                // Delete avatar
                await ref.read(profileProvider.notifier).deleteAvatar();

                // Close loading dialog
                if (mounted) {
                  navigator.pop();
                }
              } catch (e) {
                // Close loading dialog if open
                if (mounted) {
                  try {
                    navigator.pop();
                  } catch (_) {
                    // Dialog already closed
                  }
                }

                // Show error message using context from the page, not from dialog
                if (mounted && this.context.mounted) {
                  showMessageToast(
                    this.context,
                    message: 'Gagal menghapus avatar: ${e.toString()}',
                    type: ToastType.error,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
