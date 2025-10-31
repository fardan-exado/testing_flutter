import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/data/models/sedekah/sedekah.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';
import 'package:test_flutter/features/sedekah/pages/tambah_sedekah_page.dart';
import 'package:test_flutter/features/sedekah/sedekah_provider.dart';
import 'package:test_flutter/features/sedekah/sedekah_state.dart';

class SedekahPage extends ConsumerStatefulWidget {
  const SedekahPage({super.key});

  @override
  ConsumerState<SedekahPage> createState() => _SedekahPageState();
}

class _SedekahPageState extends ConsumerState<SedekahPage> {
  // ---------- Responsive utils ----------
  double _scale(BuildContext c) {
    if (ResponsiveHelper.isSmallScreen(c)) return .9;
    if (ResponsiveHelper.isMediumScreen(c)) return 1.0;
    if (ResponsiveHelper.isLargeScreen(c)) return 1.1;
    return 1.2;
  }

  double _px(BuildContext c, double base) => base * _scale(c);
  double _ts(BuildContext c, double base) =>
      ResponsiveHelper.adaptiveTextSize(c, base);

  double _maxWidth(BuildContext c) {
    if (ResponsiveHelper.isExtraLargeScreen(c)) return 960;
    if (ResponsiveHelper.isLargeScreen(c)) return 820;
    return double.infinity;
  }

  EdgeInsets _hpad(BuildContext c) => EdgeInsets.symmetric(
    horizontal: ResponsiveHelper.getResponsivePadding(c).left,
  );

  Future<void> _goToAdd() async {
    final result = await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TambahSedekahPage()),
      (route) => false,
    );

    // Refresh data after coming back from add page if success
    if (result != null && result['success'] == true) {
      await _refreshData();
    }
  }

  Future<void> _refreshData() async {
    await ref.read(sedekahProvider.notifier).loadSedekah();
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.2),
                    AppTheme.accentGreen.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Login Diperlukan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda harus login untuk mencatat sedekah',
              style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Login untuk menyimpan dan melacak sedekah Anda',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Nanti',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/welcome');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _init();
    _setupStateListener();
  }

  void _init() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check auth status first
      final authState = ref.read(authProvider);
      final isAuthenticated = authState['status'] == AuthState.authenticated;

      // Only fetch data if authenticated
      if (isAuthenticated) {
        ref.read(sedekahProvider.notifier).loadSedekah();
      }
    });
  }

  void _setupStateListener() {
    ref.listenManual<SedekahState>(sedekahProvider, (previous, next) {
      if (!mounted) return;

      // Handle success state (for delete/add operations)
      // if (previous?.status == SedekahStatus.loading &&
      //     next.status == SedekahStatus.success &&
      //     next.message != null &&
      //     next.message!.isNotEmpty) {
      //   showMessageToast(
      //     context,
      //     message: next.message!,
      //     type: ToastType.success,
      //     duration: const Duration(seconds: 3),
      //   );
      //   ref.read(sedekahProvider.notifier).clearMessage();
      // }

      // Handle error state
      if (previous?.status == SedekahStatus.loading &&
          next.status == SedekahStatus.error &&
          next.message != null &&
          next.message!.isNotEmpty) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.error,
          duration: const Duration(seconds: 4),
        );
        ref.read(sedekahProvider.notifier).clearMessage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState['status'] == AuthState.authenticated;

    // Watch provider
    final sedekahState = ref.watch(sedekahProvider);
    final sedekahStats = sedekahState.sedekahStats;
    final totalHariIni = sedekahStats?.totalHariIni ?? 0;
    final totalBulanIni = sedekahStats?.totalBulanIni ?? 0;
    final riwayat = sedekahStats?.riwayat ?? <Sedekah>[];
    final status = sedekahState.status;
    final message = sedekahState.message;
    final isOffline = sedekahState.isOffline;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue.withValues(alpha: 0.03),
              AppTheme.backgroundWhite,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _maxWidth(context)),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: _hpad(
                      context,
                    ).copyWith(top: _px(context, 20), bottom: _px(context, 8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Back button (left)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/home',
                                  );
                                },
                                icon: const Icon(Icons.arrow_back_rounded),
                                color: AppTheme.onSurface,
                                tooltip: 'Kembali',
                              ),
                            ),
                            // Title (center)
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(_px(context, 8)),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.primaryBlue.withValues(
                                              alpha: 0.1,
                                            ),
                                            AppTheme.accentGreen.withValues(
                                              alpha: 0.1,
                                            ),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.volunteer_activism_rounded,
                                        color: AppTheme.primaryBlue,
                                        size: _px(context, 20),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Tracker Sedekah',
                                      style: TextStyle(
                                        fontSize: _ts(context, 24),
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.onSurface,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    if (!isAuthenticated) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.person_off_outlined,
                                              size: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Guest',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else if (isOffline) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.cloud_off,
                                              size: 10,
                                              color: Colors.orange.shade700,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Offline',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: _px(context, 4)),
                                Text(
                                  isAuthenticated
                                      ? 'Catat amal sedekah Anda'
                                      : 'Login untuk mencatat sedekah',
                                  style: TextStyle(
                                    fontSize: _ts(context, 13),
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            // Refresh button (right) - only for authenticated
                            if (isAuthenticated &&
                                status != SedekahStatus.loading &&
                                status != SedekahStatus.refreshing)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryBlue.withValues(
                                          alpha: 0.1,
                                        ),
                                        AppTheme.accentGreen.withValues(
                                          alpha: 0.1,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: _refreshData,
                                    icon: const Icon(Icons.refresh_rounded),
                                    color: AppTheme.primaryBlue,
                                    tooltip: 'Refresh',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: _px(context, 16)),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: !isAuthenticated
                        ? _buildGuestState(context)
                        : _buildContent(
                            context,
                            status,
                            message,
                            riwayat,
                            totalHariIni,
                            totalBulanIni,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isAuthenticated
                ? [AppTheme.primaryBlue, AppTheme.accentGreen]
                : [Colors.grey.shade400, Colors.grey.shade500],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isAuthenticated
                  ? AppTheme.primaryBlue.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: isAuthenticated ? _goToAdd : _showLoginPrompt,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(
            isAuthenticated ? Icons.add : Icons.lock_outline_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildGuestState(BuildContext context) {
    return Center(
      child: Padding(
        padding: _hpad(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Guest statistics (disabled)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _StatCard(
                    value: '-',
                    label: 'Hari ini',
                    color: Colors.grey.shade400,
                    icon: Icons.today_rounded,
                    ts: (x) => _ts(context, x),
                    px: (x) => _px(context, x),
                    isDisabled: true,
                  ),
                ),
                SizedBox(width: _px(context, 12)),
                Expanded(
                  child: _StatCard(
                    value: '-',
                    label: 'Bulan ini',
                    color: Colors.grey.shade400,
                    icon: Icons.calendar_month_rounded,
                    ts: (x) => _ts(context, x),
                    px: (x) => _px(context, x),
                    isDisabled: true,
                  ),
                ),
              ],
            ),

            SizedBox(height: _px(context, 40)),

            // Login prompt illustration
            Container(
              padding: EdgeInsets.all(_px(context, 30)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                    AppTheme.accentGreen.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_person_rounded,
                size: _px(context, 80),
                color: AppTheme.primaryBlue,
              ),
            ),

            SizedBox(height: _px(context, 24)),

            // Title
            Text(
              'Login untuk Melanjutkan',
              style: TextStyle(
                fontSize: _ts(context, 22),
                color: AppTheme.onSurface,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: _px(context, 10)),

            // Description
            Text(
              'Masuk untuk mencatat dan melacak\nsedekah Anda',
              style: TextStyle(
                fontSize: _ts(context, 15),
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: _px(context, 32)),

            // Login button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/welcome');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: _px(context, 32),
                    vertical: _px(context, 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.login_rounded, size: 24),
                label: Text(
                  'Masuk Sekarang',
                  style: TextStyle(
                    fontSize: _ts(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(height: _px(context, 16)),

            // Features list
            Container(
              padding: EdgeInsets.all(_px(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  _buildFeatureItem(
                    context,
                    Icons.checklist_rounded,
                    'Catat sedekah harian',
                  ),
                  SizedBox(height: _px(context, 12)),
                  _buildFeatureItem(
                    context,
                    Icons.timeline_rounded,
                    'Lacak riwayat sedekah',
                  ),
                  SizedBox(height: _px(context, 12)),
                  _buildFeatureItem(
                    context,
                    Icons.insights_rounded,
                    'Lihat statistik lengkap',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(_px(context, 8)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withValues(alpha: 0.15),
                AppTheme.accentGreen.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryBlue,
            size: _px(context, 18),
          ),
        ),
        SizedBox(width: _px(context, 12)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: _ts(context, 14),
              color: AppTheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    SedekahStatus status,
    String? message,
    List<Sedekah> riwayat,
    int totalHariIni,
    int totalBulanIni,
  ) {
    // Loading state (initial load)
    if (status == SedekahStatus.loading) {
      return _buildLoadingState(context);
    }

    // Error state
    if (status == SedekahStatus.error && message != null) {
      return _buildErrorState(context, message);
    }

    // Success state (loaded, offline, refreshing)
    return Column(
      children: [
        // Statistics
        Padding(
          padding: _hpad(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatCard(
                  value: totalHariIni.toString(),
                  label: 'Hari ini',
                  color: AppTheme.accentGreen,
                  icon: Icons.today_rounded,
                  ts: (x) => _ts(context, x),
                  px: (x) => _px(context, x),
                ),
              ),
              SizedBox(width: _px(context, 12)),
              Expanded(
                child: _StatCard(
                  value: totalBulanIni.toString(),
                  label: 'Bulan ini',
                  color: AppTheme.primaryBlue,
                  icon: Icons.calendar_month_rounded,
                  ts: (x) => _ts(context, x),
                  px: (x) => _px(context, x),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: _px(context, 18)),

        // Section header
        Padding(
          padding: _hpad(context),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(_px(context, 6)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.15),
                      AppTheme.primaryBlue.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: AppTheme.primaryBlue,
                  size: _px(context, 18),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Riwayat Sedekah',
                style: TextStyle(
                  fontSize: _ts(context, 18),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: _px(context, 10)),

        // List
        Expanded(
          child: riwayat.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  color: AppTheme.primaryBlue,
                  child: ListView.builder(
                    padding: _hpad(context),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: riwayat.length,
                    itemBuilder: (_, i) => _riwayatTile(context, riwayat[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      children: [
        // Loading statistics
        Padding(
          padding: _hpad(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildLoadingCard(context)),
              SizedBox(width: _px(context, 12)),
              Expanded(child: _buildLoadingCard(context)),
            ],
          ),
        ),

        SizedBox(height: _px(context, 18)),

        // Section header
        Padding(
          padding: _hpad(context),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(_px(context, 6)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.15),
                      AppTheme.primaryBlue.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: AppTheme.primaryBlue,
                  size: _px(context, 18),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Riwayat Sedekah',
                style: TextStyle(
                  fontSize: _ts(context, 18),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: _px(context, 10)),

        // Loading list
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppTheme.primaryBlue,
                  strokeWidth: 3,
                ),
                SizedBox(height: _px(context, 16)),
                Text(
                  'Memuat data sedekah...',
                  style: TextStyle(
                    fontSize: _ts(context, 16),
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_px(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: _px(context, 44),
            height: _px(context, 44),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.circle,
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              size: _px(context, 22),
            ),
          ),
          SizedBox(width: _px(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: _px(context, 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(height: _px(context, 8)),
                Container(
                  height: _px(context, 12),
                  width: _px(context, 60),
                  decoration: BoxDecoration(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Center(
      child: Padding(
        padding: _hpad(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(_px(context, 22)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withValues(alpha: 0.1),
                    Colors.red.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: _px(context, 58),
                color: Colors.red,
              ),
            ),
            SizedBox(height: _px(context, 18)),
            Text(
              'Gagal memuat data',
              style: TextStyle(
                fontSize: _ts(context, 18),
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: _px(context, 6)),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: _ts(context, 14),
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: _px(context, 20)),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: _px(context, 20),
                  vertical: _px(context, 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: _hpad(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(_px(context, 22)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                    AppTheme.accentGreen.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volunteer_activism_outlined,
                size: _px(context, 58),
                color: AppTheme.primaryBlue,
              ),
            ),
            SizedBox(height: _px(context, 18)),
            Text(
              'Belum ada sedekah tercatat',
              style: TextStyle(
                fontSize: _ts(context, 18),
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: _px(context, 6)),
            Text(
              'Mulai catat sedekah dengan menekan tombol +',
              style: TextStyle(
                fontSize: _ts(context, 14),
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Sedekah sedekah) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hapus Sedekah?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus sedekah ini?',
              style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.category_rounded,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sedekah.jenisSedekah,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(sedekah.jumlah)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data yang dihapus tidak dapat dikembalikan',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);

              // Delete sedekah
              await ref
                  .read(sedekahProvider.notifier)
                  .deleteSedekah(sedekah.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _riwayatTile(BuildContext context, Sedekah sedekah) {
    final formattedDate = DateFormat(
      "d MMMM y 'pukul' HH:mm",
      "id_ID",
    ).format(sedekah.tanggal);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGreen.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(_px(context, 16)),
        child: Row(
          children: [
            Container(
              width: _px(context, 50),
              height: _px(context, 50),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentGreen.withValues(alpha: 0.2),
                    AppTheme.accentGreen.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: AppTheme.accentGreen,
                size: _px(context, 26),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sedekah.jenisSedekah,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: _ts(context, 16),
                      color: AppTheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: _px(context, 4)),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: _px(context, 12),
                        color: AppTheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: _ts(context, 13),
                            color: AppTheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (sedekah.keterangan?.isNotEmpty ?? false) ...[
                    SizedBox(height: _px(context, 4)),
                    Text(
                      sedekah.keterangan!,
                      style: TextStyle(
                        fontSize: _ts(context, 12),
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp ${NumberFormat('#,###', 'id_ID').format(sedekah.jumlah)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: _ts(context, 16),
                    color: AppTheme.accentGreen,
                  ),
                ),
                SizedBox(height: _px(context, 4)),
                // Delete button
                InkWell(
                  onTap: () => _showDeleteConfirmation(sedekah),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.all(_px(context, 6)),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: _px(context, 18),
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final double Function(double) px;
  final double Function(double) ts;
  final bool isDisabled;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    required this.px,
    required this.ts,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBox = px(44);
    final effectiveColor = isDisabled ? color : color;

    return Container(
      padding: EdgeInsets.all(px(14)),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: effectiveColor.withValues(alpha: isDisabled ? 0.1 : 0.2),
        ),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: effectiveColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                  spreadRadius: -2,
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  effectiveColor.withValues(alpha: isDisabled ? 0.1 : 0.2),
                  effectiveColor.withValues(alpha: isDisabled ? 0.05 : 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: effectiveColor, size: px(22)),
          ),

          SizedBox(width: px(12)),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ts(16),
                    fontWeight: FontWeight.bold,
                    color: effectiveColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: px(4)),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: ts(12),
                    color: isDisabled
                        ? Colors.grey.shade500
                        : AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
