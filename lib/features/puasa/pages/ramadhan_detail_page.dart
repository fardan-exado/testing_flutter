import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/puasa/models/progres_puasa.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';
import 'package:test_flutter/features/puasa/puasa_provider.dart';
import 'package:test_flutter/features/puasa/puasa_state.dart';

class RamadhanDetailPage extends ConsumerStatefulWidget {
  final Map<DateTime, Map<String, dynamic>>? puasaData;
  final Function(DateTime)? onMarkFasting;
  final bool isEmbedded;

  const RamadhanDetailPage({
    super.key,
    this.puasaData,
    this.onMarkFasting,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<RamadhanDetailPage> createState() => _RamadhanDetailPageState();
}

class _RamadhanDetailPageState extends ConsumerState<RamadhanDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late int _currentHijriYear;
  int _ramadhanDaysInSelectedYear = 30;
  late ProviderSubscription _authSub;

  final GlobalKey<RefreshIndicatorState> _refreshKeyCalendar =
      GlobalKey<RefreshIndicatorState>();

  final List<Map<String, dynamic>> _sunnah = [
    {
      'title': 'Sahur',
      'description': 'Makan sahur sebelum subuh',
      'reward': 'Mendapat berkah dan kekuatan',
      'icon': Icons.restaurant,
      'color': AppTheme.accentGreen,
    },
    {
      'title': 'Doa Berbuka',
      'description': 'Membaca doa ketika berbuka puasa',
      'reward': 'Doa mustajab saat berbuka',
      'icon': Icons.favorite,
      'color': AppTheme.primaryBlue,
    },
    {
      'title': 'Tarawih',
      'description': 'Sholat tarawih berjamaah',
      'reward': 'Pahala sholat malam',
      'icon': Icons.mosque,
      'color': AppTheme.primaryBlueDark,
    },
    {
      'title': 'Tadarus',
      'description': 'Membaca Al-Quran setiap hari',
      'reward': 'Setiap huruf bernilai 10 kebaikan',
      'icon': Icons.menu_book,
      'color': AppTheme.accentGreenDark,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeHijriYear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupListeners();
    });
  }

  void _setupListeners() {
    // Setup manual listener for auth state
    _authSub = ref.listenManual(authProvider, (previous, next) {
      final route = ModalRoute.of(context);
      final isCurrent = route != null && route.isCurrent;
      if (!mounted || !isCurrent) return;

      if (previous?['status'] != next['status']) {
        if (next['status'] != AuthState.authenticated) {
          showMessageToast(
            context,
            message: 'Sesi berakhir. Silakan login kembali.',
            type: ToastType.warning,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _authSub.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    try {
      final tahunHijriah = _currentHijriYear.toString();
      await ref
          .read(puasaProvider.notifier)
          .fetchRiwayatPuasaWajib(tahunHijriah: tahunHijriah);
    } catch (e) {
      if (mounted) {
        showMessageToast(
          context,
          message: 'Gagal memuat ulang. Coba lagi.',
          type: ToastType.error,
        );
      }
    }
  }

  void _initializeHijriYear() {
    final now = HijriCalendar.now();
    _currentHijriYear = now.hYear;
    _calculateRamadhanDetails(_currentHijriYear);
  }

  void _calculateRamadhanDetails(int hijriYear) {
    // Set Ramadhan month (month 9 in Hijri calendar)
    final ramadhanHijri = HijriCalendar()
      ..hYear = hijriYear
      ..hMonth = 9
      ..hDay = 1;

    ramadhanHijri.hijriToGregorian(
      ramadhanHijri.hYear,
      ramadhanHijri.hMonth,
      ramadhanHijri.hDay,
    );

    // Calculate days in Ramadhan for this year (29 or 30)
    final lastDayRamadhan = HijriCalendar()
      ..hYear = hijriYear
      ..hMonth = 9
      ..hDay = 30;

    try {
      lastDayRamadhan.hijriToGregorian(
        lastDayRamadhan.hYear,
        lastDayRamadhan.hMonth,
        lastDayRamadhan.hDay,
      );
      _ramadhanDaysInSelectedYear = 30;
    } catch (e) {
      _ramadhanDaysInSelectedYear = 29;
    }
  }

  Future<void> _changeHijriYear(int offset) async {
    final newYear = _currentHijriYear + offset;
    setState(() {
      _currentHijriYear = newYear;
    });
    _calculateRamadhanDetails(newYear);

    // Fetch data for new year
    try {
      final tahunHijriah = newYear.toString();
      await ref
          .read(puasaProvider.notifier)
          .fetchRiwayatPuasaWajib(tahunHijriah: tahunHijriah);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching data for year $newYear: $e');
      }
    }
  }

  // Get current year's data from riwayat
  List<RiwayatProgresPuasaWajib> _getCurrentYearData() {
    final puasaState = ref.watch(puasaProvider);
    final riwayat = puasaState.riwayatPuasaWajib ?? [];

    if (riwayat.isEmpty) {
      return [];
    }

    // Filter data untuk tahun hijriah saat ini
    return riwayat;
  }

  // Check if a specific day is completed
  bool _isDayCompleted(int day) {
    final currentYearData = _getCurrentYearData();

    if (currentYearData.isEmpty) return false;

    // Check if this day's status is completed
    return currentYearData.any(
      (item) => item.tanggalRamadhan == day && item.status,
    );
  }

  // Get ID of a specific completed day
  int? _getDayRecordId(int day) {
    final currentYearData = _getCurrentYearData();

    if (currentYearData.isEmpty) return null;

    try {
      final item = currentYearData.firstWhere(
        (item) => item.tanggalRamadhan == day && item.status,
      );
      return item.progres?.id;
    } catch (e) {
      return null;
    }
  }

  // Get total completed days for current year
  int _getCompletedDays() {
    final currentYearData = _getCurrentYearData();

    if (currentYearData.isEmpty) return 0;

    return currentYearData.where((item) => item.status).length;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    final puasaState = ref.watch(puasaProvider);
    final completedDays = _getCompletedDays();

    // Show loading while fetching data
    if (puasaState.status == PuasaStatus.loading &&
        puasaState.riwayatPuasaWajib == null) {
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryBlue,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Memuat data...',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              if (!widget.isEmbedded) ...[
                Container(
                  padding: EdgeInsets.all(
                    isDesktop
                        ? 32.0
                        : isTablet
                        ? 28.0
                        : 24.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            isTablet ? 14 : 12,
                          ),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: AppTheme.primaryBlue,
                            size: isTablet ? 26 : 24,
                          ),
                        ),
                      ),
                      SizedBox(width: isTablet ? 20 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Puasa Ramadhan $_currentHijriYear H',
                              style: TextStyle(
                                fontSize: isDesktop
                                    ? 22
                                    : isTablet
                                    ? 20
                                    : 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Bulan penuh berkah dan ampunan',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 14,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: isTablet ? 16 : 12),

              // Progress Summary Cards
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isDesktop
                      ? 32.0
                      : isTablet
                      ? 28.0
                      : 24.0,
                ),
                child: Row(
                  children: [
                    _buildProgressCard(
                      '$completedDays',
                      '$_ramadhanDaysInSelectedYear',
                      'Completed',
                      AppTheme.accentGreen,
                      Icons.check_circle_rounded,
                      isTablet,
                    ),
                    SizedBox(width: isTablet ? 12 : 10),
                    _buildProgressCard(
                      '${_ramadhanDaysInSelectedYear - completedDays}',
                      '$_ramadhanDaysInSelectedYear',
                      'Tersisa',
                      AppTheme.primaryBlue,
                      Icons.schedule_rounded,
                      isTablet,
                    ),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 16 : 12),

              // Tab Bar
              Container(
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
                  tabs: const [
                    Tab(text: 'Kalender'),
                    Tab(text: 'Amalan Sunnah'),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 16 : 12),

              // TabView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildRamadhanCalendar(), _buildSunnahTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    String value,
    String total,
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
              offset: const Offset(0, 3),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 8 : 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
              ),
              child: Icon(icon, color: color, size: isTablet ? 18 : 16),
            ),
            SizedBox(height: isTablet ? 8 : 6),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (total.isNotEmpty)
                    TextSpan(
                      text: '/$total',
                      style: TextStyle(
                        fontSize: isTablet ? 11 : 10,
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: isTablet ? 4 : 2),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 10 : 9,
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

  Widget _buildRamadhanCalendar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    final puasaState = ref.watch(puasaProvider);
    final isLoading = puasaState.status == PuasaStatus.loading;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop
            ? 32.0
            : isTablet
            ? 28.0
            : 24.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 22 : 20),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Calendar Header with Year Navigation
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12 : 8,
              vertical: isTablet ? 16 : 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.05),
                  AppTheme.accentGreen.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isTablet ? 22 : 20),
                topRight: Radius.circular(isTablet ? 22 : 20),
              ),
            ),
            child: Row(
              children: [
                // Previous Year Button
                IconButton(
                  onPressed: () => _changeHijriYear(-1),
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: AppTheme.primaryBlue,
                    size: isTablet ? 28 : 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: isTablet ? 48 : 40),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ramadhan',
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 12,
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isTablet ? 4 : 2),
                      Text(
                        '$_currentHijriYear H ($_ramadhanDaysInSelectedYear hari)',
                        style: TextStyle(
                          fontSize: isDesktop
                              ? 20
                              : isTablet
                              ? 18
                              : 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                // Next Year Button
                IconButton(
                  onPressed: () => _changeHijriYear(1),
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.primaryBlue,
                    size: isTablet ? 28 : 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: isTablet ? 48 : 40),
                ),
              ],
            ),
          ),

          // Calendar Grid
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              child: RefreshIndicator.adaptive(
                key: _refreshKeyCalendar,
                onRefresh: _onRefresh,
                displacement: 24,
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryBlue,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Memuat kalender...',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 13,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: isDesktop
                              ? 1.0
                              : isTablet
                              ? 0.95
                              : 0.85,
                          crossAxisSpacing: isTablet ? 8 : 6,
                          mainAxisSpacing: isTablet ? 8 : 6,
                        ),
                        itemCount: _ramadhanDaysInSelectedYear,
                        itemBuilder: (context, index) {
                          final day = index + 1;
                          final isCompleted = _isDayCompleted(day);

                          return GestureDetector(
                            onTap: () => _showDayDetail(day, isCompleted),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: isCompleted
                                    ? LinearGradient(
                                        colors: [
                                          AppTheme.accentGreen.withValues(
                                            alpha: 0.2,
                                          ),
                                          AppTheme.accentGreen.withValues(
                                            alpha: 0.1,
                                          ),
                                        ],
                                      )
                                    : LinearGradient(
                                        colors: [
                                          AppTheme.primaryBlue.withValues(
                                            alpha: 0.1,
                                          ),
                                          AppTheme.primaryBlue.withValues(
                                            alpha: 0.05,
                                          ),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(
                                  isTablet ? 12 : 10,
                                ),
                                border: Border.all(
                                  color: isCompleted
                                      ? AppTheme.accentGreen.withValues(
                                          alpha: 0.3,
                                        )
                                      : AppTheme.primaryBlue.withValues(
                                          alpha: 0.1,
                                        ),
                                  width: 1,
                                ),
                                boxShadow: isCompleted
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.accentGreen
                                              .withValues(alpha: 0.1),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    day.toString(),
                                    style: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w600,
                                      color: isCompleted
                                          ? AppTheme.accentGreen
                                          : AppTheme.onSurface,
                                    ),
                                  ),
                                  if (isCompleted) ...[
                                    SizedBox(height: 2),
                                    Icon(
                                      Icons.check_circle,
                                      color: AppTheme.accentGreen,
                                      size: isTablet ? 14 : 12,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunnahTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop
            ? 32.0
            : isTablet
            ? 28.0
            : 24.0,
      ),
      itemCount: _sunnah.length,
      itemBuilder: (context, index) {
        final sunnah = _sunnah[index];
        return Container(
          margin: EdgeInsets.only(bottom: isTablet ? 18 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 22 : 20),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(
              isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : 20,
            ),
            child: Row(
              children: [
                Container(
                  width: isDesktop
                      ? 60
                      : isTablet
                      ? 56
                      : 52,
                  height: isDesktop
                      ? 60
                      : isTablet
                      ? 56
                      : 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        sunnah['color'].withValues(alpha: 0.15),
                        sunnah['color'].withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                    border: Border.all(
                      color: sunnah['color'].withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    sunnah['icon'],
                    color: sunnah['color'],
                    size: isTablet ? 28 : 26,
                  ),
                ),
                SizedBox(width: isTablet ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sunnah['title'],
                        style: TextStyle(
                          fontSize: isDesktop
                              ? 18
                              : isTablet
                              ? 17
                              : 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      SizedBox(height: isTablet ? 6 : 4),
                      Text(
                        sunnah['description'],
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 14,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: isTablet ? 8 : 6),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 12 : 10,
                          vertical: isTablet ? 6 : 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentGreen.withValues(alpha: 0.1),
                              AppTheme.accentGreen.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                          border: Border.all(
                            color: AppTheme.accentGreen.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          sunnah['reward'],
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 11,
                            color: AppTheme.accentGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDayDetail(int day, bool isCompleted) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final authState = ref.read(authProvider);
    final isAuthenticated = authState['status'] == AuthState.authenticated;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTablet ? 28 : 24),
            topRight: Radius.circular(isTablet ? 28 : 24),
          ),
        ),
        padding: EdgeInsets.all(isTablet ? 28 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isTablet ? 50 : 40,
              height: isTablet ? 6 : 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.3),
                    AppTheme.accentGreen.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(isTablet ? 3 : 2),
              ),
            ),
            SizedBox(height: isTablet ? 24 : 20),
            Text(
              'Hari ke-$day Ramadhan $_currentHijriYear H',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCompleted
                      ? [
                          AppTheme.accentGreen.withValues(alpha: 0.15),
                          AppTheme.accentGreen.withValues(alpha: 0.1),
                        ]
                      : [
                          AppTheme.primaryBlue.withValues(alpha: 0.15),
                          AppTheme.primaryBlue.withValues(alpha: 0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
                border: Border.all(
                  color:
                      (isCompleted
                              ? AppTheme.accentGreen
                              : AppTheme.primaryBlue)
                          .withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.event_available_outlined,
                    color: isCompleted
                        ? AppTheme.accentGreen
                        : AppTheme.onSurfaceVariant,
                    size: isTablet ? 36 : 32,
                  ),
                  SizedBox(height: isTablet ? 12 : 10),
                  Text(
                    isCompleted
                        ? 'Puasa Completed!'
                        : 'Belum ada aktivitas puasa',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? AppTheme.onSurface
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isTablet ? 24 : 20),

            if (!isCompleted) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !isAuthenticated
                          ? null
                          : () {
                              Navigator.pop(context);
                              if (!isAuthenticated) {
                                showMessageToast(
                                  context,
                                  message: 'Anda harus login terlebih dahulu',
                                  type: ToastType.error,
                                );
                              } else {
                                _markRamadhanFasting(day);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isTablet ? 14 : 12,
                          ),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                      ),
                      child: Text(
                        'Tandai Puasa',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 15 : 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: BorderSide(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isTablet ? 14 : 12,
                          ),
                        ),
                      ),
                      child: Text(
                        'Tutup',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 15 : 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !isAuthenticated
                          ? null
                          : () {
                              Navigator.pop(context);
                              if (!isAuthenticated) {
                                showMessageToast(
                                  context,
                                  message: 'Anda harus login terlebih dahulu',
                                  type: ToastType.error,
                                );
                              } else {
                                _deleteRamadhanFasting(day);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isTablet ? 14 : 12,
                          ),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                      ),
                      child: Text(
                        'Hapus Tandai',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 15 : 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: BorderSide(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isTablet ? 14 : 12,
                          ),
                        ),
                      ),
                      child: Text(
                        'Tutup',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 15 : 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _markRamadhanFasting(int day) async {
    final authState = ref.read(authProvider);

    if (authState['status'] != AuthState.authenticated) {
      showMessageToast(
        context,
        message: 'Anda harus login terlebih dahulu',
        type: ToastType.error,
      );
      return;
    }

    try {
      // Call the API to add progress
      await ref
          .read(puasaProvider.notifier)
          .addProgresPuasaWajib(
            tanggalRamadhan: day.toString(),
            tahunHijriah: _currentHijriYear.toString(),
          );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error marking Ramadhan fasting: $e');
        print(stackTrace);
      }
    }
  }

  void _deleteRamadhanFasting(int day) async {
    final authState = ref.read(authProvider);
    final recordId = _getDayRecordId(day);

    if (recordId == null) {
      showMessageToast(
        context,
        message: 'Tidak ada data untuk dihapus',
        type: ToastType.error,
      );
      return;
    }

    if (authState['status'] != AuthState.authenticated) {
      showMessageToast(
        context,
        message: 'Anda harus login terlebih dahulu',
        type: ToastType.error,
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Tandai Puasa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus tandai puasa hari ke-$day?',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Call the API to delete progress
      await ref
          .read(puasaProvider.notifier)
          .deleteProgresPuasaWajib(
            id: recordId.toString(),
            tahunHijriah: _currentHijriYear.toString(),
          );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error deleting Ramadhan fasting: $e');
        print(stackTrace);
      }
    }
  }
}
