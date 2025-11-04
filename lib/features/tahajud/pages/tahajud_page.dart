import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/app/router.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/core/utils/connection/connection_provider.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';

class TahajudPage extends ConsumerStatefulWidget {
  const TahajudPage({super.key});

  @override
  ConsumerState<TahajudPage> createState() => _TahajudPageState();
}

class _TahajudPageState extends ConsumerState<TahajudPage>
    with TickerProviderStateMixin {
  late AnimationController _progressController;

  // Challenge data
  int currentStreak = 7;
  int longestStreak = 15;
  int totalDays = 45;
  int currentLevel = 3;
  int tahajudCount = 45;

  // Monthly tahajud count
  int monthlyTahajudCount = 12;

  // Calendar data - tahajud completed dates
  final Set<DateTime> completedDates = {
    DateTime(2025, 10, 24),
    DateTime(2025, 10, 25),
    DateTime(2025, 10, 27),
    DateTime(2025, 10, 28),
    DateTime(2025, 10, 22),
    DateTime(2025, 10, 20),
    DateTime(2025, 10, 18),
    DateTime(2025, 10, 16),
    DateTime(2025, 10, 15),
    DateTime(2025, 10, 13),
    DateTime(2025, 10, 11),
    DateTime(2025, 10, 10),
  };

  DateTime selectedMonth = DateTime.now();
  PageController calendarPageController = PageController();

  // Available badges
  final List<Map<String, dynamic>> badges = [
    {
      'id': 'first_step',
      'name': 'Langkah Pertama',
      'description': 'Lakukan tahajud pertama kali',
      'icon': Icons.star_rounded,
      'color': Colors.amber,
      'achieved': true,
      'date': DateTime(2025, 8, 15),
    },
    {
      'id': 'week_warrior',
      'name': 'Pejuang Seminggu',
      'description': 'Tahajud 7 hari berturut-turut',
      'icon': Icons.military_tech_rounded,
      'color': Colors.blue,
      'achieved': true,
      'date': DateTime(2025, 9, 10),
    },
    {
      'id': 'night_guardian',
      'name': 'Penjaga Malam',
      'description': 'Tahajud 30 hari dalam sebulan',
      'icon': Icons.shield_rounded,
      'color': Colors.purple,
      'achieved': false,
    },
    {
      'id': 'consistent_soul',
      'name': 'Jiwa Istiqomah',
      'description': 'Tahajud 100 hari total',
      'icon': Icons.psychology_rounded,
      'color': Colors.green,
      'achieved': false,
    },
    {
      'id': 'diamond_devotee',
      'name': 'Berlian Ibadah',
      'description': 'Tahajud 365 hari total',
      'icon': Icons.diamond_rounded,
      'color': Colors.cyan,
      'achieved': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressController.forward();
    _calculateMonthlyTahajud();
  }

  void _calculateMonthlyTahajud() {
    final now = DateTime.now();
    monthlyTahajudCount = completedDates.where((date) {
      return date.year == now.year && date.month == now.month;
    }).length;
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    final connectionState = ref.watch(connectionProvider);
    final isOffline = !connectionState.isOnline;
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState['status'] == AuthState.authenticated;

    if (!isAuthenticated) return _buildLoginRequired();
    // if (!isPremium) return _buildPremiumRequired();

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
              _buildStreakCard(isTablet, isDesktop),
              SizedBox(height: isTablet ? 16 : 12),
              Expanded(child: _buildCalendarSection(isTablet, isDesktop)),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== Header =====================

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
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppTheme.onSurface,
                tooltip: 'Kembali',
              ),
              const SizedBox(width: 12),
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
                  Icons.nightlight_round,
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
                      'Tahajud Challenge',
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
                      'Tracking ibadah malam',
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
                            SizedBox(width: 4),
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
          SizedBox(height: isTablet ? 20 : 16),
          // Quote Card
          //   Container(
          //     padding: EdgeInsets.all(isTablet ? 20 : 16),
          //     decoration: BoxDecoration(
          //       gradient: LinearGradient(
          //         colors: [
          //           AppTheme.primaryBlue.withValues(alpha: 0.05),
          //           AppTheme.accentGreen.withValues(alpha: 0.05),
          //         ],
          //       ),
          //       borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
          //       border: Border.all(
          //         color: AppTheme.primaryBlue.withValues(alpha: 0.1),
          //       ),
          //     ),
          //     child: Column(
          //       children: [
          //         Text(
          //           'وَمِنَ اللَّيْلِ فَتَهَجَّدْ بِهِ نَافِلَةً لَّكَ',
          //           style: TextStyle(
          //             color: AppTheme.primaryBlue,
          //             fontSize: isDesktop
          //                 ? 16
          //                 : isTablet
          //                 ? 15
          //                 : 14,
          //             fontWeight: FontWeight.w600,
          //             height: 1.8,
          //           ),
          //           textAlign: TextAlign.center,
          //         ),
          //         SizedBox(height: isTablet ? 12 : 10),
          //         Text(
          //           '"Dan pada sebagian malam, maka lakukanlah shalat tahajud sebagai suatu ibadah tambahan bagimu"',
          //           style: TextStyle(
          //             color: AppTheme.onSurface.withValues(alpha: 0.8),
          //             fontSize: isDesktop
          //                 ? 13
          //                 : isTablet
          //                 ? 12
          //                 : 11,
          //             fontStyle: FontStyle.italic,
          //           ),
          //           textAlign: TextAlign.center,
          //         ),
          //         SizedBox(height: isTablet ? 8 : 6),
          //         Text(
          //           'QS. Al-Isra: 79',
          //           style: TextStyle(
          //             color: AppTheme.onSurfaceVariant,
          //             fontSize: isDesktop
          //                 ? 12
          //                 : isTablet
          //                 ? 11
          //                 : 10,
          //             fontWeight: FontWeight.w500,
          //           ),
          //           textAlign: TextAlign.center,
          //         ),
          //       ],
          //     ),
          //   ),
        ],
      ),
    );
  }

  // ===================== Streak Card =====================

  Widget _buildStreakCard(bool isTablet, bool isDesktop) {
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
          _buildProgressCard(
            '$currentStreak',
            '30',
            'Streak Saat Ini',
            AppTheme.primaryBlue,
            Icons.local_fire_department_rounded,
            isTablet,
          ),
          SizedBox(width: isTablet ? 14 : 12),
          _buildProgressCard(
            '$tahajudCount',
            '∞',
            'Total Tahajud',
            AppTheme.accentGreen,
            Icons.calendar_today_rounded,
            isTablet,
          ),
          SizedBox(width: isTablet ? 14 : 12),
          _buildProgressCard(
            '$monthlyTahajudCount',
            '30',
            'Bulan Ini',
            AppTheme.primaryBlueDark,
            Icons.calendar_month_rounded,
            isTablet,
          ),
        ],
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
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.05),
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
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (total != '∞')
                    TextSpan(
                      text: '/$total',
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 11,
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

  // ===================== Calendar =====================

  Widget _buildCalendarSection(bool isTablet, bool isDesktop) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop
            ? 32.0
            : isTablet
            ? 28.0
            : 24.0,
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar Header
          Container(
            padding: EdgeInsets.all(isTablet ? 14 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.accentGreen.withValues(alpha: 0.03),
                  AppTheme.primaryBlue.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: AppTheme.primaryBlue,
                  size: isTablet ? 20 : 18,
                ),
                SizedBox(width: isTablet ? 8 : 6),
                Text(
                  'Kalender Tahajud',
                  style: TextStyle(
                    fontSize: isDesktop
                        ? 16
                        : isTablet
                        ? 15
                        : 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Expanded(child: _buildCalendarGrid(isTablet, isDesktop)),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(bool isTablet, bool isDesktop) {
    final firstDayOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    );
    final firstDayWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    final daysOfWeek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final cellSize = isTablet ? 44.0 : 36.0;

    return Column(
      children: [
        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  selectedMonth = DateTime(
                    selectedMonth.year,
                    selectedMonth.month - 1,
                  );
                  _calculateMonthlyTahajud();
                });
              },
              icon: Icon(
                Icons.chevron_left_rounded,
                color: AppTheme.primaryBlue,
                size: isTablet ? 24 : 20,
              ),
            ),
            Text(
              DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth),
              style: TextStyle(
                fontSize: isDesktop
                    ? 16
                    : isTablet
                    ? 15
                    : 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  selectedMonth = DateTime(
                    selectedMonth.year,
                    selectedMonth.month + 1,
                  );
                  _calculateMonthlyTahajud();
                });
              },
              icon: Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.primaryBlue,
                size: isTablet ? 24 : 20,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),
        // Header with day names
        Row(
          children: daysOfWeek.map((day) {
            return Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 6),
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isDesktop
                        ? 12
                        : isTablet
                        ? 11
                        : 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: isTablet ? 8 : 6),
        // Calendar grid
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: List.generate(
                (daysInMonth + firstDayWeekday - 1 + 6) ~/ 7,
                (weekIndex) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: isTablet ? 6 : 4),
                    child: Row(
                      children: List.generate(7, (dayIndex) {
                        final dayNumber =
                            weekIndex * 7 + dayIndex - firstDayWeekday + 2;
                        if (dayNumber < 1 || dayNumber > daysInMonth) {
                          return const Expanded(child: SizedBox());
                        }

                        final currentDate = DateTime(
                          selectedMonth.year,
                          selectedMonth.month,
                          dayNumber,
                        );
                        final isCompleted = completedDates.contains(
                          DateTime(
                            currentDate.year,
                            currentDate.month,
                            currentDate.day,
                          ),
                        );
                        final now = DateTime.now();
                        final isToday =
                            now.year == currentDate.year &&
                            now.month == currentDate.month &&
                            now.day == currentDate.day;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _showDayDetail(
                              dayNumber,
                              isCompleted,
                              currentDate,
                              isTablet,
                            ),
                            child: Container(
                              margin: EdgeInsets.all(isTablet ? 3 : 2),
                              height: cellSize,
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppTheme.primaryBlue.withValues(
                                        alpha: 0.1,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  isTablet ? 10 : 8,
                                ),
                                border: Border.all(
                                  color: isCompleted
                                      ? AppTheme.accentGreen
                                      : isToday
                                      ? AppTheme.primaryBlue
                                      : Colors.transparent,
                                  width: isCompleted ? 2 : (isToday ? 2 : 1),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    fontSize: isDesktop
                                        ? 14
                                        : isTablet
                                        ? 13
                                        : 12,
                                    fontWeight: isCompleted
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isCompleted
                                        ? AppTheme.accentGreen
                                        : isToday
                                        ? AppTheme.primaryBlue
                                        : AppTheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        // Legend
        Wrap(
          alignment: WrapAlignment.center,
          spacing: isTablet ? 24 : 20,
          runSpacing: isTablet ? 10 : 8,
          children: [
            _buildCalendarLegend(
              AppTheme.accentGreen,
              'Tahajud dilakukan',
              isTablet,
              isBorder: true,
            ),
            _buildCalendarLegend(
              AppTheme.primaryBlue,
              'Hari ini',
              isTablet,
              isBorder: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarLegend(
    Color color,
    String label,
    bool isTablet, {
    bool isBorder = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isTablet ? 14 : 12,
          height: isTablet ? 14 : 12,
          decoration: BoxDecoration(
            color: isBorder ? Colors.transparent : color,
            border: isBorder ? Border.all(color: color, width: 2) : null,
            borderRadius: BorderRadius.circular(isTablet ? 3 : 2),
          ),
        ),
        SizedBox(width: isTablet ? 8 : 6),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 12 : 11,
            color: AppTheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ===================== Modal Sheet =====================

  void _showDayDetail(
    int day,
    bool isCompleted,
    DateTime currentDate,
    bool isTablet,
  ) {
    final authState = ref.read(authProvider);
    final isAuthenticated = authState['status'] == AuthState.authenticated;
    final connectionState = ref.read(connectionProvider);
    final isOffline = !connectionState.isOnline;

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
                  colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
                ),
                borderRadius: BorderRadius.circular(isTablet ? 3 : 2),
              ),
            ),
            SizedBox(height: isTablet ? 24 : 20),
            Text(
              'Tahajud - ${DateFormat('d MMMM yyyy', 'id_ID').format(currentDate)}',
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
                  colors: [
                    AppTheme.accentGreen.withValues(alpha: 0.1),
                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
                border: Border.all(
                  color: isCompleted
                      ? AppTheme.accentGreen.withValues(alpha: 0.3)
                      : AppTheme.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.nightlight_round,
                    color: isCompleted
                        ? AppTheme.accentGreen
                        : AppTheme.primaryBlue,
                    size: isTablet ? 48 : 40,
                  ),
                  SizedBox(height: isTablet ? 12 : 10),
                  Text(
                    isCompleted
                        ? 'Tahajud telah ditandai'
                        : 'Tandai tahajud hari ini?',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isTablet ? 8 : 6),
                  Text(
                    isCompleted
                        ? 'Alhamdulillah, tetap istiqomah!'
                        : 'Catat ibadah tahajud Anda',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: isTablet ? 24 : 20),

            if (!isCompleted) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 14,
                        ),
                        side: BorderSide(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isTablet ? 14 : 12,
                          ),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 14 : 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (isAuthenticated && !isOffline)
                          ? () => _markTahajud(currentDate)
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 14,
                        ),
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isTablet ? 14 : 12,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: isTablet ? 20 : 18,
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                          Text(
                            'Tandai Tahajud',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (!isAuthenticated || isOffline) ...[
                SizedBox(height: isTablet ? 12 : 10),
                Text(
                  !isAuthenticated
                      ? 'Login untuk menandai tahajud'
                      : 'Tidak dapat menandai saat offline',
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 11,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 14,
                        ),
                        side: BorderSide(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
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
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 14 : 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (isAuthenticated && !isOffline)
                          ? () => _deleteTahajud(currentDate)
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 14,
                        ),
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isTablet ? 14 : 12,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: isTablet ? 20 : 18,
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                          Text(
                            'Hapus Tandai',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (!isAuthenticated || isOffline) ...[
                SizedBox(height: isTablet ? 12 : 10),
                Text(
                  !isAuthenticated
                      ? 'Login untuk menghapus tandai'
                      : 'Tidak dapat menghapus saat offline',
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 11,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _markTahajud(DateTime date) {
    setState(() {
      completedDates.add(DateTime(date.year, date.month, date.day));
      currentStreak++;
      tahajudCount++;
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
      _calculateMonthlyTahajud();
    });

    Navigator.pop(context);

    showMessageToast(
      context,
      message: 'Alhamdulillah! Tahajud berhasil ditandai',
      type: ToastType.success,
    );
  }

  void _deleteTahajud(DateTime date) {
    setState(() {
      completedDates.removeWhere(
        (d) =>
            d.year == date.year && d.month == date.month && d.day == date.day,
      );
      // Update streak and count
      if (tahajudCount > 0) tahajudCount--;
      if (currentStreak > 0) currentStreak--;
      _calculateMonthlyTahajud();
    });

    Navigator.pop(context);

    showMessageToast(
      context,
      message: 'Tandai tahajud berhasil dihapus',
      type: ToastType.info,
    );
  }

  // ===================== Auth & Premium =====================

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
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Anda harus login terlebih dahulu untuk mengakses Tahajud Challenge',
                    style: TextStyle(
                      fontSize: 16,
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
                          fontSize: 16,
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
                        fontSize: 16,
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
}
