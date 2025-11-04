import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/app/router.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/core/utils/connection/connection_provider.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';
import 'package:test_flutter/features/monitoring/pages/add_edit_child_page.dart';
import 'package:test_flutter/features/subscription/widgets/premium_gate.dart';

class MonitoringPage extends ConsumerStatefulWidget {
  const MonitoringPage({super.key});

  @override
  ConsumerState<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends ConsumerState<MonitoringPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String userRole = 'parent'; // 'parent' atau 'child'

  // Filter state
  String selectedFilter =
      'Monthly'; // Weekly, Monthly, Custom - Default Monthly
  DateTime? customStartDate;
  DateTime? customEndDate;
  String? selectedChildId; // null = all children
  String selectedReportType =
      'sholat_wajib'; // Current report type being viewed

  // Sample data anak
  final List<Map<String, dynamic>> children = [
    {
      'id': '1',
      'name': 'Ahmad Faiz',
      'age': 12,
      'avatar': Icons.boy_rounded,
      'lastActive': DateTime.now().subtract(const Duration(minutes: 30)),
      'todayProgress': {
        'sholat': 4,
        'totalSholat': 5,
        'quran': 2,
        'targetQuran': 3,
        'tahajud': true,
        'streak': 7,
      },
      'weeklyStats': {
        'sholat': [5, 4, 5, 3, 5, 5, 4],
        'quran': [3, 2, 3, 1, 2, 3, 2],
        'tahajud': [true, false, true, true, true, true, false],
      },
    },
    {
      'id': '2',
      'name': 'Siti Aisyah',
      'age': 10,
      'avatar': Icons.girl_rounded,
      'lastActive': DateTime.now().subtract(const Duration(hours: 2)),
      'todayProgress': {
        'sholat': 5,
        'totalSholat': 5,
        'quran': 3,
        'targetQuran': 3,
        'tahajud': false,
        'streak': 3,
      },
      'weeklyStats': {
        'sholat': [5, 5, 4, 5, 5, 3, 5],
        'quran': [3, 3, 2, 3, 3, 1, 3],
        'tahajud': [false, true, false, true, false, true, false],
      },
    },
  ];

  // Sample notifikasi
  final List<Map<String, dynamic>> notifications = [
    {
      'id': '1',
      'childName': 'Ahmad Faiz',
      'type': 'missed_prayer',
      'message': 'Terlewat sholat Ashar',
      'time': DateTime.now().subtract(const Duration(hours: 1)),
      'isRead': false,
    },
    {
      'id': '2',
      'childName': 'Siti Aisyah',
      'type': 'achievement',
      'message': 'Mencapai streak 3 hari berturut-turut!',
      'time': DateTime.now().subtract(const Duration(hours: 3)),
      'isRead': false,
    },
    {
      'id': '3',
      'childName': 'Ahmad Faiz',
      'type': 'quran_target',
      'message': 'Mencapai target membaca Al-Qur\'an hari ini',
      'time': DateTime.now().subtract(const Duration(hours: 5)),
      'isRead': true,
    },
  ];

  // Sample detailed report data
  final List<Map<String, dynamic>> sholatWajibReports = [
    {
      'date': '03/08/25',
      'time': '04:44 AM',
      'jenis': 'Fajr',
      'tepatWaktu': 'Ya',
      'dilakukan': 'Sendiri',
      'tempat': 'Di Masjid',
      'keterangan': '',
    },
    {
      'date': '03/08/25',
      'time': '12:00 PM',
      'jenis': 'Duhr',
      'tepatWaktu': 'Tidak',
      'dilakukan': 'Sendiri',
      'tempat': 'Di Kantor',
      'keterangan': 'ada pekerjaan',
    },
    {
      'date': '03/08/25',
      'time': '03:22 PM',
      'jenis': 'Asr',
      'tepatWaktu': 'Tidak',
      'dilakukan': 'Sendiri',
      'tempat': 'Di Kantor',
      'keterangan': 'ada pekerjaan',
    },
    {
      'date': '03/08/25',
      'time': '05:55 PM',
      'jenis': 'Maghrib',
      'tepatWaktu': 'Tidak Sholat',
      'dilakukan': '-',
      'tempat': '-',
      'keterangan': 'dalam Perjalanan pulang kantor',
    },
    {
      'date': '03/08/25',
      'time': '07:08 PM',
      'jenis': 'Isha',
      'tepatWaktu': 'Ya',
      'dilakukan': 'Berjamaah',
      'tempat': 'Di Rumah',
      'keterangan': '',
    },
  ];

  final List<Map<String, dynamic>> sholatSunnahReports = [
    {
      'date': '03/08/25',
      'time': '03:30 AM',
      'jenis': 'Tahajud',
      'rakaat': '8',
      'dilakukan': 'Sendiri',
      'tempat': 'Di Rumah',
      'keterangan': '',
    },
    {
      'date': '03/08/25',
      'time': '09:00 AM',
      'jenis': 'Duha',
      'rakaat': '4',
      'dilakukan': 'Sendiri',
      'tempat': 'Di Rumah',
      'keterangan': '',
    },
  ];

  final List<Map<String, dynamic>> quranReports = [
    {
      'date': '03/08/25',
      'time': '03:30 AM',
      'halaman': '10-15',
      'suratFavorit': 'Al-Baqarah',
      'dilakukan': 'Sendiri',
      'tempat': 'Di Rumah',
      'keterangan': '',
    },
    {
      'date': '03/08/25',
      'time': '09:00 AM',
      'halaman': '20-25',
      'suratFavorit': 'Ali Imran',
      'dilakukan': 'Sendiri',
      'tempat': 'Di Rumah',
      'keterangan': '',
    },
  ];

  final List<Map<String, dynamic>> tahajudReports = [
    {
      'date': '03/08/25',
      'time': '03:30 AM',
      'rakaat': '8',
      'makanTerakhir': '20:00 PM',
      'tidur': '22:00 PM',
      'keterangan': 'Sendiri',
    },
    {
      'date': '04/08/25',
      'time': '03:30 AM',
      'rakaat': '-',
      'makanTerakhir': '20:00 PM',
      'tidur': '01:00 AM',
      'keterangan': 'Tidak Sholat Tahajud karena Begadang',
    },
  ];

  final List<Map<String, dynamic>> puasaReports = [
    {'date': '03/08/25', 'jenis': 'Puasa Ramadhan', 'keterangan': ''},
    {'date': '03/08/25', 'jenis': 'Puasa Senin Kamis', 'keterangan': ''},
  ];

  final List<Map<String, dynamic>> zakatReports = [
    {'date': '03/08/25', 'jenis': 'Sedekah Subuh', 'nilai': 50000},
    {'date': '03/08/25', 'jenis': 'Infaq Masjid', 'nilai': 20000},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState['status'] == AuthState.authenticated;

    if (!isAuthenticated) return _buildLoginRequired();

    // Wrap with Premium Gate
    return PremiumGate(
      featureName: 'Monitoring',
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    final connectionState = ref.watch(connectionProvider);
    final isOffline = !connectionState.isOnline;

    // Main content when authenticated and premium
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
            stops: const [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isTablet, isDesktop, isOffline),
              SizedBox(height: isTablet ? 16 : 12),
              _buildTabBar(isTablet, isDesktop),
              SizedBox(height: isTablet ? 16 : 12),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDashboardTab(isTablet, isDesktop),
                      _buildChildrenTab(isTablet, isDesktop),
                      _buildNotificationsTab(isTablet, isDesktop),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========= Halaman Auth & Premium =========

  Widget _buildLoginRequired() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryBlue.withValues(alpha: 0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 80,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Login Diperlukan',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.adaptiveTextSize(context, 28),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Anda harus login terlebih dahulu untuk mengakses fitur Monitoring Keluarga',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.adaptiveTextSize(context, 16),
                      color: AppTheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Login Sekarang',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.adaptiveTextSize(
                            context,
                            16,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.home),
                    child: Text(
                      'Kembali ke Home',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.adaptiveTextSize(
                          context,
                          16,
                        ),
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
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

  Widget _buildPremiumRequired() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.amber.withValues(alpha: 0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withValues(alpha: 0.2),
                          Colors.orange.withValues(alpha: 0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.family_restroom_rounded,
                      size: 80,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Fitur Premium',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.adaptiveTextSize(context, 28),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Monitoring Keluarga adalah fitur premium. Pantau aktivitas ibadah keluarga dengan fitur lengkap!',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.adaptiveTextSize(context, 16),
                      color: AppTheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildPremiumFeature(
                    Icons.family_restroom_rounded,
                    'Monitor aktivitas semua anggota keluarga',
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumFeature(
                    Icons.analytics_rounded,
                    'Statistik dan grafik lengkap',
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumFeature(
                    Icons.notifications_active_rounded,
                    'Notifikasi real-time',
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumFeature(
                    Icons.emoji_events_rounded,
                    'Sistem reward dan achievement',
                  ),
                  const SizedBox(height: 48),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.amber, Colors.orange],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => showMessageToast(
                        context,
                        message: 'Fitur dalam pengembangan',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium_rounded, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Berlangganan Premium',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.adaptiveTextSize(
                                context,
                                16,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.home),
                    child: Text(
                      'Kembali ke Home',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.adaptiveTextSize(
                          context,
                          16,
                        ),
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
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

  Widget _buildPremiumFeature(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.amber, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: ResponsiveHelper.adaptiveTextSize(context, 14),
              color: AppTheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Icon(Icons.check_circle, color: Colors.green, size: 20),
      ],
    );
  }

  // ========= Header & Tab =========

  Widget _buildHeader(bool isTablet, bool isDesktop, bool isOffline) {
    return Container(
      padding: EdgeInsets.all(
        isDesktop
            ? 32.0
            : isTablet
            ? 28.0
            : 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 14 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.1),
                      AppTheme.accentGreen.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                ),
                child: Icon(
                  Icons.family_restroom_rounded,
                  color: AppTheme.primaryBlue,
                  size: isDesktop
                      ? 28
                      : isTablet
                      ? 26
                      : 24,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monitoring Keluarga',
                      style: TextStyle(
                        fontSize: isDesktop
                            ? 22
                            : isTablet
                            ? 20
                            : 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      userRole == 'parent'
                          ? 'Pantau aktivitas ibadah anak'
                          : 'Laporkan aktivitas ibadah Anda',
                      style: TextStyle(
                        fontSize: isDesktop
                            ? 15
                            : isTablet
                            ? 14
                            : 14,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    if (isOffline)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 12 : 10,
                          vertical: isTablet ? 6 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              color: Colors.red.shade700,
                              size: isTablet ? 16 : 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Offline',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: isTablet ? 12 : 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isTablet, bool isDesktop) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop
            ? 32.0
            : isTablet
            ? 28.0
            : 24.0,
      ),
      child: Row(
        children: [
          _buildStatsCard(
            '${children.length}',
            'Anak',
            AppTheme.primaryBlue,
            Icons.group_rounded,
            isTablet,
          ),
          SizedBox(width: isTablet ? 14 : 12),
          _buildStatsCard(
            '${notifications.where((n) => !n['isRead']).length}',
            'Notifikasi',
            Colors.orange,
            Icons.notifications_active_rounded,
            isTablet,
          ),
          SizedBox(width: isTablet ? 14 : 12),
          _buildStatsCard(
            '5',
            'Prestasi',
            AppTheme.accentGreen,
            Icons.emoji_events_rounded,
            isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    String value,
    String label,
    Color color,
    IconData icon,
    bool isTablet,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 10 : 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
              ),
              child: Icon(icon, color: color, size: isTablet ? 24 : 22),
            ),
            SizedBox(height: isTablet ? 10 : 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 22 : 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: isTablet ? 4 : 2),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 12 : 11,
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isTablet, bool isDesktop) {
    final unreadCount = notifications.where((n) => !n['isRead']).length;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop
            ? 32.0
            : isTablet
            ? 28.0
            : 24.0,
      ),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: AppTheme.onSurfaceVariant,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isTablet ? 14 : 13,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isTablet ? 14 : 13,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Text(
              'Laporan',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Tab(
            child: Text(
              'Anak-anak',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    isTablet ? 'Notifikasi' : 'Notif',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (unreadCount > 0) ...[
                  SizedBox(width: isTablet ? 6 : 4),
                  Container(
                    constraints: BoxConstraints(minWidth: isTablet ? 20 : 18),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 6 : 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 10 : 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========= Tab: Dashboard =========

  Widget _buildDashboardTab(bool isTablet, bool isDesktop) {
    // Check if children exist
    if (children.isEmpty) {
      return _buildNoChildrenView(isTablet);
    }

    // Set default child if not selected
    if (selectedChildId == null && children.isNotEmpty) {
      selectedChildId = children.first['id'];
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop
            ? 32.0
            : isTablet
            ? 28.0
            : 24.0,
        vertical: isTablet ? 16 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Child Selector
          _buildChildSelector(isTablet),
          const SizedBox(height: 16),

          // Report Type Selector
          _buildReportTypeSelector(isTablet),
          const SizedBox(height: 16),

          // Filter Section
          _buildFilterSection(isTablet),
          const SizedBox(height: 24),

          // Single Report Display based on selectedReportType
          _buildCurrentReport(isTablet),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNoChildrenView(bool isTablet) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(isTablet ? 32 : 24),
        padding: EdgeInsets.all(isTablet ? 40 : 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
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
                Icons.family_restroom_rounded,
                size: isTablet ? 64 : 48,
                color: AppTheme.primaryBlue,
              ),
            ),
            SizedBox(height: isTablet ? 24 : 20),
            Text(
              'Belum Ada Data Anak',
              style: TextStyle(
                fontSize: isTablet ? 22 : 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              'Silahkan tambahkan data anak Anda terlebih dahulu untuk memulai monitoring aktivitas ibadah',
              style: TextStyle(
                fontSize: isTablet ? 15 : 14,
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 32 : 24),
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(1); // Go to children tab
              },
              icon: Icon(Icons.add_rounded),
              label: Text('Tambah Data Anak'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 24,
                  vertical: isTablet ? 16 : 14,
                ),
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildSelector(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 14,
        vertical: isTablet ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline_rounded,
            color: AppTheme.primaryBlue,
            size: isTablet ? 22 : 20,
          ),
          SizedBox(width: isTablet ? 12 : 10),
          Text(
            'Anak:',
            style: TextStyle(
              fontSize: isTablet ? 15 : 14,
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: isTablet ? 12 : 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedChildId,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.primaryBlue,
                ),
                style: TextStyle(
                  fontSize: isTablet ? 15 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
                borderRadius: BorderRadius.circular(12),
                items: children.map((child) {
                  return DropdownMenuItem<String>(
                    value: child['id'],
                    child: Row(
                      children: [
                        Icon(
                          child['avatar'] as IconData,
                          size: 18,
                          color: AppTheme.primaryBlue,
                        ),
                        SizedBox(width: 8),
                        Text(child['name']),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedChildId = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector(bool isTablet) {
    final reportTypes = [
      {
        'id': 'sholat_wajib',
        'name': 'Sholat Wajib',
        'icon': Icons.mosque_rounded,
      },
      {
        'id': 'sholat_sunnah',
        'name': 'Sholat Sunnah',
        'icon': Icons.self_improvement_rounded,
      },
      {'id': 'quran', 'name': 'Al-Qur\'an', 'icon': Icons.menu_book_rounded},
      {'id': 'tahajud', 'name': 'Tahajud', 'icon': Icons.nightlight_round},
      {'id': 'puasa', 'name': 'Puasa', 'icon': Icons.fastfood_rounded},
      {
        'id': 'zakat',
        'name': 'Zakat & Sedekah',
        'icon': Icons.volunteer_activism_rounded,
      },
    ];

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Jenis Laporan',
            style: TextStyle(
              fontSize: isTablet ? 15 : 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(height: isTablet ? 14 : 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: reportTypes.map((type) {
              final isSelected = selectedReportType == type['id'];
              return InkWell(
                onTap: () {
                  setState(() {
                    selectedReportType = type['id'] as String;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 14,
                    vertical: isTablet ? 12 : 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.accentGreen,
                            ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : AppTheme.primaryBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : AppTheme.primaryBlue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type['icon'] as IconData,
                        size: isTablet ? 18 : 16,
                        color: isSelected ? Colors.white : AppTheme.primaryBlue,
                      ),
                      SizedBox(width: isTablet ? 8 : 6),
                      Text(
                        type['name'] as String,
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentReport(bool isTablet) {
    String title;
    List<Map<String, dynamic>> data;

    switch (selectedReportType) {
      case 'sholat_wajib':
        title = 'Laporan Sholat Wajib';
        data = sholatWajibReports;
        break;
      case 'sholat_sunnah':
        title = 'Laporan Sholat Sunnah';
        data = sholatSunnahReports;
        break;
      case 'quran':
        title = 'Laporan Baca Al-Qur\'an';
        data = quranReports;
        break;
      case 'tahajud':
        title = 'Laporan Tahajud Challenge';
        data = tahajudReports;
        break;
      case 'puasa':
        title = 'Laporan Puasa';
        data = puasaReports;
        break;
      case 'zakat':
        title = 'Laporan Zakat dan Sedekah';
        data = zakatReports;
        break;
      default:
        title = 'Laporan';
        data = [];
    }

    return _buildReportSection(title, data, selectedReportType, isTablet);
  }

  Widget _buildUserInfoHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.accentGreen.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 12 : 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: AppTheme.primaryBlue,
                  size: isTablet ? 28 : 24,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User: ${selectedChildId == null ? "Semua Anak" : children.firstWhere((c) => c['id'] == selectedChildId, orElse: () => {'name': 'Unknown'})['name']}',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lokasi: Tangerang, ${_formatDate(DateTime.now())}',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 13,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                color: AppTheme.primaryBlue,
                size: isTablet ? 22 : 20,
              ),
              SizedBox(width: 8),
              Text(
                'Filter',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Weekly', isTablet),
              _buildFilterChip('Monthly', isTablet),
              _buildFilterChip('Custom', isTablet),
            ],
          ),
          if (selectedFilter == 'Custom') ...[
            SizedBox(height: isTablet ? 16 : 14),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    customStartDate != null
                        ? _formatDate(customStartDate!)
                        : 'Tanggal Mulai',
                    () => _selectDate(true),
                    isTablet,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildDateButton(
                    customEndDate != null
                        ? _formatDate(customEndDate!)
                        : 'Tanggal Akhir',
                    () => _selectDate(false),
                    isTablet,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isTablet) {
    final isSelected = selectedFilter == label;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: isTablet ? 14 : 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = label;
        });
      },
      selectedColor: AppTheme.primaryBlue,
      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected
            ? AppTheme.primaryBlue
            : AppTheme.primaryBlue.withValues(alpha: 0.2),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 10,
        vertical: isTablet ? 8 : 6,
      ),
    );
  }

  Widget _buildDateButton(String label, VoidCallback onTap, bool isTablet) {
    final hasDate = label != 'Tanggal Mulai' && label != 'Tanggal Akhir';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 14,
            vertical: isTablet ? 16 : 14,
          ),
          decoration: BoxDecoration(
            gradient: hasDate
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.08),
                      AppTheme.accentGreen.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            color: hasDate ? null : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
            border: Border.all(
              color: hasDate
                  ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    fontWeight: hasDate ? FontWeight.w600 : FontWeight.w500,
                    color: hasDate
                        ? AppTheme.primaryBlue
                        : AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hasDate
                      ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: isTablet ? 20 : 18,
                  color: hasDate ? AppTheme.primaryBlue : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (customStartDate ?? DateTime.now())
          : (customEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: isStartDate ? 'Pilih Tanggal Mulai' : 'Pilih Tanggal Akhir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.onSurface,
              surface: Colors.white,
              surfaceContainerHighest: Colors.grey.shade100,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
              backgroundColor: Colors.white,
            ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: AppTheme.primaryBlue,
              headerForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              dayStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              yearStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              todayBorder: BorderSide(color: AppTheme.primaryBlue, width: 2),
              todayForegroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppTheme.primaryBlue;
              }),
              dayBackgroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.primaryBlue;
                }
                return Colors.transparent;
              }),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          customStartDate = picked;
        } else {
          customEndDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildReportSection(
    String title,
    List<Map<String, dynamic>> data,
    String type,
    bool isTablet,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                  AppTheme.accentGreen.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isTablet ? 16 : 14),
                topRight: Radius.circular(isTablet ? 16 : 14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getIconForType(type),
                  color: AppTheme.primaryBlue,
                  size: isTablet ? 24 : 20,
                ),
                SizedBox(width: isTablet ? 12 : 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: _buildDataTable(data, type, isTablet),
          ),

          // Results and Suggestions
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: _getResultColor(type).withValues(alpha: 0.05),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(isTablet ? 16 : 14),
                bottomRight: Radius.circular(isTablet ? 16 : 14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assessment_rounded,
                      color: _getResultColor(type),
                      size: isTablet ? 20 : 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Hasil: ${_getResult(type)}',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: _getResultColor(type),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 12 : 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Colors.amber.shade700,
                      size: isTablet ? 20 : 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saran:',
                            style: TextStyle(
                              fontSize: isTablet ? 15 : 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 4),
                          ..._getSuggestions(type).map(
                            (suggestion) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $suggestion',
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 13,
                                  color: AppTheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(
    List<Map<String, dynamic>> data,
    String type,
    bool isTablet,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            LinearGradient(
              colors: [
                AppTheme.primaryBlue.withValues(alpha: 0.12),
                AppTheme.accentGreen.withValues(alpha: 0.08),
              ],
            ).colors.first,
          ),
          dataRowColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppTheme.primaryBlue.withValues(alpha: 0.05);
            }
            return Colors.transparent;
          }),
          columnSpacing: isTablet ? 28 : 20,
          horizontalMargin: isTablet ? 16 : 12,
          headingRowHeight: isTablet ? 60 : 54,
          dataRowHeight: isTablet ? 68 : 62,
          headingTextStyle: TextStyle(
            fontSize: isTablet ? 14 : 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
            letterSpacing: 0.5,
          ),
          dataTextStyle: TextStyle(
            fontSize: isTablet ? 13 : 12,
            color: AppTheme.onSurface,
            height: 1.4,
          ),
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          decoration: BoxDecoration(color: Colors.white),
          columns: _getColumnsForType(type, isTablet),
          rows: data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildDataRow(item, type, isTablet, index);
          }).toList(),
        ),
      ),
    );
  }

  List<DataColumn> _getColumnsForType(String type, bool isTablet) {
    switch (type) {
      case 'sholat_wajib':
        return [
          DataColumn(label: Text('Tgl')),
          DataColumn(label: Text('Waktu Sholat')),
          DataColumn(label: Text('Jenis Sholat')),
          DataColumn(label: Text('Tepat waktu')),
          DataColumn(label: Text('Dilakukan')),
          DataColumn(label: Text('Tempat')),
          DataColumn(label: Text('Keterangan')),
        ];
      case 'sholat_sunnah':
        return [
          DataColumn(label: Text('Tgl')),
          DataColumn(label: Text('Waktu Sholat')),
          DataColumn(label: Text('Jenis Sholat')),
          DataColumn(label: Text('Rakaat')),
          DataColumn(label: Text('Dilakukan')),
          DataColumn(label: Text('Tempat')),
          DataColumn(label: Text('Keterangan')),
        ];
      case 'quran':
        return [
          DataColumn(label: Text('Tgl')),
          DataColumn(label: Text('Waktu Baca')),
          DataColumn(label: Text('Halaman')),
          DataColumn(label: Text('Surat Favorit')),
          DataColumn(label: Text('Dilakukan')),
          DataColumn(label: Text('Tempat')),
          DataColumn(label: Text('Keterangan')),
        ];
      case 'tahajud':
        return [
          DataColumn(label: Text('Tgl')),
          DataColumn(label: Text('Waktu Sholat')),
          DataColumn(label: Text('Rakaat')),
          DataColumn(label: Text('Makan terakhir')),
          DataColumn(label: Text('Tidur')),
          DataColumn(label: Text('Keterangan')),
        ];
      case 'puasa':
        return [
          DataColumn(label: Text('Tgl')),
          DataColumn(label: Text('Jenis Puasa')),
          DataColumn(label: Text('Keterangan')),
        ];
      case 'zakat':
        return [
          DataColumn(label: Text('Tgl')),
          DataColumn(label: Text('Jenis Sedekah')),
          DataColumn(label: Text('Nilai')),
        ];
      default:
        return [];
    }
  }

  DataRow _buildDataRow(
    Map<String, dynamic> item,
    String type,
    bool isTablet,
    int index,
  ) {
    final isEven = index % 2 == 0;
    final bgColor = isEven
        ? Colors.transparent
        : AppTheme.primaryBlue.withValues(alpha: 0.02);

    switch (type) {
      case 'sholat_wajib':
        return DataRow(
          color: WidgetStateProperty.all(bgColor),
          cells: [
            DataCell(
              Text(
                item['date'] ?? '-',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            DataCell(Text(item['time'] ?? '-')),
            DataCell(
              Text(
                item['jenis'] ?? '-',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataCell(
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item['tepatWaktu'] == 'Ya'
                      ? AppTheme.accentGreen.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item['tepatWaktu'] ?? '-',
                  style: TextStyle(
                    color: item['tepatWaktu'] == 'Ya'
                        ? AppTheme.accentGreen
                        : Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            DataCell(
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item['dilakukan'] == 'Ya'
                      ? AppTheme.accentGreen.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item['dilakukan'] ?? '-',
                  style: TextStyle(
                    color: item['dilakukan'] == 'Ya'
                        ? AppTheme.accentGreen
                        : Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            DataCell(Text(item['tempat'] ?? '-')),
            DataCell(
              Text(
                item['keterangan'] ?? '',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      case 'sholat_sunnah':
        return DataRow(
          color: WidgetStateProperty.all(bgColor),
          cells: [
            DataCell(
              Text(
                item['date'] ?? '-',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            DataCell(Text(item['time'] ?? '-')),
            DataCell(
              Text(
                item['jenis'] ?? '-',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataCell(Text(item['rakaat'] ?? '-')),
            DataCell(
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item['dilakukan'] == 'Ya'
                      ? AppTheme.accentGreen.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item['dilakukan'] ?? '-',
                  style: TextStyle(
                    color: item['dilakukan'] == 'Ya'
                        ? AppTheme.accentGreen
                        : Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            DataCell(Text(item['tempat'] ?? '-')),
            DataCell(
              Text(
                item['keterangan'] ?? '',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      case 'quran':
        return DataRow(
          color: WidgetStateProperty.all(bgColor),
          cells: [
            DataCell(
              Text(
                item['date'] ?? '-',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            DataCell(Text(item['time'] ?? '-')),
            DataCell(
              Text(
                item['halaman'] ?? '-',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataCell(
              Text(
                item['suratFavorit'] ?? '-',
                style: TextStyle(color: AppTheme.primaryBlue),
              ),
            ),
            DataCell(
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item['dilakukan'] == 'Ya'
                      ? AppTheme.accentGreen.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item['dilakukan'] ?? '-',
                  style: TextStyle(
                    color: item['dilakukan'] == 'Ya'
                        ? AppTheme.accentGreen
                        : Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            DataCell(Text(item['tempat'] ?? '-')),
            DataCell(
              Text(
                item['keterangan'] ?? '',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      case 'tahajud':
        return DataRow(
          color: WidgetStateProperty.all(bgColor),
          cells: [
            DataCell(
              Text(
                item['date'] ?? '-',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            DataCell(Text(item['time'] ?? '-')),
            DataCell(
              Text(
                item['rakaat'] ?? '-',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataCell(Text(item['makanTerakhir'] ?? '-')),
            DataCell(Text(item['tidur'] ?? '-')),
            DataCell(
              Text(
                item['keterangan'] ?? '',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      case 'puasa':
        return DataRow(
          color: WidgetStateProperty.all(bgColor),
          cells: [
            DataCell(
              Text(
                item['date'] ?? '-',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            DataCell(
              Text(
                item['jenis'] ?? '-',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            DataCell(
              Text(
                item['keterangan'] ?? '',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      case 'zakat':
        final nilai = item['nilai'] ?? 0;
        return DataRow(
          color: WidgetStateProperty.all(bgColor),
          cells: [
            DataCell(
              Text(
                item['date'] ?? '-',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            DataCell(
              Text(
                item['jenis'] ?? '-',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataCell(
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Rp ${nilai.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGreen,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        );
      default:
        return DataRow(cells: []);
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'sholat_wajib':
        return Icons.mosque_rounded;
      case 'sholat_sunnah':
        return Icons.self_improvement_rounded;
      case 'quran':
        return Icons.menu_book_rounded;
      case 'tahajud':
        return Icons.nightlight_round;
      case 'puasa':
        return Icons.fastfood_rounded;
      case 'zakat':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.analytics_rounded;
    }
  }

  Color _getResultColor(String type) {
    switch (type) {
      case 'sholat_wajib':
        return Colors.green;
      case 'sholat_sunnah':
        return AppTheme.accentGreen;
      case 'quran':
        return AppTheme.accentGreen;
      case 'tahajud':
        return Colors.orange;
      case 'puasa':
        return AppTheme.accentGreen;
      case 'zakat':
        return AppTheme.accentGreen;
      default:
        return AppTheme.primaryBlue;
    }
  }

  String _getResult(String type) {
    switch (type) {
      case 'sholat_wajib':
        return 'Good 75%';
      case 'sholat_sunnah':
        return 'Excellent 100%';
      case 'quran':
        return 'Excellent 100%';
      case 'tahajud':
        return 'Good 80%';
      case 'puasa':
        return 'Excellent';
      case 'zakat':
        return 'Excellent';
      default:
        return 'Good';
    }
  }

  List<String> _getSuggestions(String type) {
    switch (type) {
      case 'sholat_wajib':
        return [
          'Tingkatkan lagi Sholatnya',
          'Berhenti cari masjid terdekat saat pulang kantor',
        ];
      case 'sholat_sunnah':
        return ['Tingkatkan lagi Sholatnya'];
      case 'quran':
        return ['Alhamdulillah'];
      case 'tahajud':
        return ['Tidur lebih awal maksimal jam 22.00 PM'];
      case 'puasa':
        return ['Tingkatkan lagi Puasa'];
      case 'zakat':
        return ['Terus tingkatkan sedekah'];
      default:
        return [];
    }
  }

  // Keep old methods for compatibility (will be removed later)

  Widget _buildChildrenTab(bool isTablet, bool isDesktop) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop
              ? 32.0
              : isTablet
              ? 28.0
              : 24.0,
          vertical: isTablet ? 16 : 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Anak',
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditChildPage(),
                      ),
                    ).then((result) {
                      if (result == true) {
                        setState(() {});
                      }
                    });
                  },
                  icon: Icon(Icons.add_rounded, size: isTablet ? 20 : 18),
                  label: Text(
                    'Tambah Anak',
                    style: TextStyle(fontSize: isTablet ? 15 : 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 16,
                      vertical: isTablet ? 14 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),

            SizedBox(height: isTablet ? 12 : 8),

            // Children List
            if (children.isEmpty)
              _buildEmptyState(isTablet)
            else
              ...children
                  .map(
                    (child) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(isTablet ? 16 : 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  child['name'],
                                  style: TextStyle(
                                    fontSize: isTablet ? 17 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  child['email'] ?? '-',
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 13,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Usia: ${child['age']} tahun',
                                  style: TextStyle(
                                    fontSize: isTablet ? 13 : 12,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Action Buttons
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Edit Button
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddEditChildPage(childData: child),
                                    ),
                                  ).then((result) {
                                    if (result == true) {
                                      setState(() {});
                                    }
                                  });
                                },
                                icon: Icon(Icons.edit_rounded),
                                color: AppTheme.accentGreen,
                                tooltip: 'Edit',
                                iconSize: isTablet ? 22 : 20,
                              ),
                              // Delete Button
                              IconButton(
                                onPressed: () =>
                                    _showDeleteConfirmDialog(child, isTablet),
                                icon: Icon(Icons.delete_rounded),
                                color: Colors.red,
                                tooltip: 'Hapus',
                                iconSize: isTablet ? 22 : 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab(bool isTablet, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop
            ? 32.0
            : isTablet
            ? 28.0
            : 24.0,
        vertical: isTablet ? 16 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifikasi',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    for (var notification in notifications) {
                      notification['isRead'] = true;
                    }
                  });
                },
                icon: Icon(Icons.done_all_rounded, size: isTablet ? 18 : 16),
                label: Text(
                  'Tandai Semua',
                  style: TextStyle(fontSize: isTablet ? 14 : 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...notifications
              .map(
                (notif) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(isTablet ? 16 : 14),
                  decoration: BoxDecoration(
                    color: notif['isRead']
                        ? Colors.white
                        : AppTheme.primaryBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                    border: Border.all(
                      color: notif['isRead']
                          ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                          : AppTheme.primaryBlue.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isTablet ? 10 : 8),
                        decoration: BoxDecoration(
                          color: _getNotifColor(
                            notif['type'],
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            isTablet ? 10 : 8,
                          ),
                        ),
                        child: Icon(
                          _getNotifIcon(notif['type']),
                          color: _getNotifColor(notif['type']),
                          size: isTablet ? 24 : 20,
                        ),
                      ),
                      SizedBox(width: isTablet ? 14 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif['childName'],
                              style: TextStyle(
                                fontSize: isTablet ? 15 : 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              notif['message'],
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 13,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _getTimeAgo(notif['time']),
                              style: TextStyle(
                                fontSize: isTablet ? 12 : 11,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!notif['isRead'])
                        Container(
                          width: isTablet ? 10 : 8,
                          height: isTablet ? 10 : 8,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Color _getNotifColor(String type) {
    switch (type) {
      case 'missed_prayer':
        return Colors.red;
      case 'achievement':
        return AppTheme.accentGreen;
      case 'quran_target':
        return AppTheme.primaryBlue;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotifIcon(String type) {
    switch (type) {
      case 'missed_prayer':
        return Icons.warning_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      case 'quran_target':
        return Icons.menu_book_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} detik yang lalu';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else {
      return '${difference.inDays} hari yang lalu';
    }
  }

  // ========= CRUD Methods =========

  Widget _buildEmptyState(bool isTablet) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: isTablet ? 60 : 40),
        padding: EdgeInsets.all(isTablet ? 40 : 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: isTablet ? 64 : 48,
                color: AppTheme.primaryBlue,
              ),
            ),
            SizedBox(height: isTablet ? 24 : 20),
            Text(
              'Belum Ada Data Anak',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              'Klik tombol "Tambah Anak" untuk\nmenambahkan data anak',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 15 : 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> child, bool isTablet) {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    IconData selectedAvatar = Icons.child_care_rounded;

    final List<IconData> avatarOptions = [
      Icons.child_care_rounded,
      Icons.face_rounded,
      Icons.boy_rounded,
      Icons.girl_rounded,
      Icons.person_rounded,
      Icons.sentiment_satisfied_rounded,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.2),
                      AppTheme.accentGreen.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  color: AppTheme.primaryBlue,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Tambah Anak',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Anak',
                    hintText: 'Masukkan nama anak',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryBlue,
                        width: 2,
                      ),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: 16),

                // Age Field
                TextField(
                  controller: ageController,
                  decoration: InputDecoration(
                    labelText: 'Usia (tahun)',
                    hintText: 'Masukkan usia',
                    prefixIcon: Icon(Icons.cake_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryBlue,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 20),

                // Avatar Selection
                Text(
                  'Pilih Avatar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: avatarOptions.map((icon) {
                    final isSelected = selectedAvatar == icon;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          selectedAvatar = icon;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppTheme.primaryBlue,
                                    AppTheme.accentGreen,
                                  ],
                                )
                              : null,
                          color: isSelected ? null : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 32,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty || ageController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nama dan usia harus diisi'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                setState(() {
                  children.add({
                    'id': 'child_${children.length + 1}',
                    'name': nameController.text,
                    'age': int.parse(ageController.text),
                    'avatar': selectedAvatar,
                  });
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Anak berhasil ditambahkan'),
                      ],
                    ),
                    backgroundColor: AppTheme.accentGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditChildDialog(Map<String, dynamic> child, bool isTablet) {
    final nameController = TextEditingController(text: child['name']);
    final ageController = TextEditingController(text: child['age'].toString());
    IconData selectedAvatar = child['avatar'] as IconData;

    final List<IconData> avatarOptions = [
      Icons.child_care_rounded,
      Icons.face_rounded,
      Icons.boy_rounded,
      Icons.girl_rounded,
      Icons.person_rounded,
      Icons.sentiment_satisfied_rounded,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.edit_rounded, color: AppTheme.accentGreen),
              ),
              SizedBox(width: 12),
              Text(
                'Edit Data Anak',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Anak',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.accentGreen,
                        width: 2,
                      ),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: ageController,
                  decoration: InputDecoration(
                    labelText: 'Usia (tahun)',
                    prefixIcon: Icon(Icons.cake_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.accentGreen,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 20),
                Text(
                  'Pilih Avatar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: avatarOptions.map((icon) {
                    final isSelected = selectedAvatar == icon;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          selectedAvatar = icon;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.accentGreen
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.accentGreen
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 32,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty || ageController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nama dan usia harus diisi'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                setState(() {
                  final index = children.indexWhere(
                    (c) => c['id'] == child['id'],
                  );
                  if (index != -1) {
                    children[index] = {
                      'id': child['id'],
                      'name': nameController.text,
                      'age': int.parse(ageController.text),
                      'avatar': selectedAvatar,
                    };
                  }
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Data anak berhasil diperbarui'),
                      ],
                    ),
                    backgroundColor: AppTheme.accentGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
