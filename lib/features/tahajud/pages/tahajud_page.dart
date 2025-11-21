import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/app/router.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/core/utils/connection/connection_provider.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';
import 'package:test_flutter/features/tahajud/providers/tahajud_provider.dart';
import 'package:test_flutter/features/tahajud/states/tahajud_state.dart';
import 'package:test_flutter/features/tahajud/models/tahajud.dart';

class TahajudPage extends ConsumerStatefulWidget {
  const TahajudPage({super.key});

  @override
  ConsumerState<TahajudPage> createState() => _TahajudPageState();
}

class _TahajudPageState extends ConsumerState<TahajudPage>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late DateTime selectedMonth;
  late ProviderSubscription<TahajudState> _tahajudSub;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressController.forward();
    selectedMonth = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Setup manual listener for tahajud state changes
    _tahajudSub = ref.listenManual(tahajudProvider, (previous, next) {
      final route = ModalRoute.of(context);
      final isCurrent = route != null && route.isCurrent;
      if (!mounted || !isCurrent) return;

      if (next.status == TahajudStatus.success && next.message != null) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.success,
          duration: const Duration(seconds: 3),
        );
        ref.read(tahajudProvider.notifier).clearMessage();
        ref.read(tahajudProvider.notifier).resetStatus();
      } else if (next.status == TahajudStatus.error && next.message != null) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.error,
          duration: const Duration(seconds: 4),
        );
        ref.read(tahajudProvider.notifier).clearMessage();
      }
    });
  }

  @override
  void dispose() {
    _tahajudSub.close();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    final connectionState = ref.watch(connectionProvider);
    final isOffline = !connectionState.isOnline;
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState['status'] == AuthState.authenticated;

    if (!isAuthenticated) return _buildLoginRequired();

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
        ],
      ),
    );
  }

  // ===================== Streak Card =====================

  Widget _buildStreakCard(bool isTablet, bool isDesktop) {
    final tahajudState = ref.watch(tahajudProvider);
    final statistik = tahajudState.statistikTahajud;
    final isLoading = tahajudState.status == TahajudStatus.loading;

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
            isLoading ? '-' : '${statistik?.streakBulanIni ?? 0}',
            '${statistik?.jumlahHariBulanIni ?? 30}',
            'Streak Saat Ini',
            AppTheme.primaryBlue,
            Icons.local_fire_department_rounded,
            isTablet,
          ),
          SizedBox(width: isTablet ? 14 : 12),
          _buildProgressCard(
            isLoading ? '-' : '${statistik?.totalTahajudKeseluruhan ?? 0}',
            '∞',
            'Total Tahajud',
            AppTheme.accentGreen,
            Icons.calendar_today_rounded,
            isTablet,
          ),
          SizedBox(width: isTablet ? 14 : 12),
          _buildProgressCard(
            isLoading ? '-' : '${statistik?.totalTahajudBulanIni ?? 0}',
            '${statistik?.jumlahHariBulanIni ?? 30}',
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
    final tahajudState = ref.watch(tahajudProvider);
    final isLoading = tahajudState.status == TahajudStatus.loading;

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
          Expanded(
            child: isLoading
                ? _buildCalendarLoadingAnimation(isTablet, isDesktop)
                : _buildCalendarGrid(isTablet, isDesktop, tahajudState),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarLoadingAnimation(bool isTablet, bool isDesktop) {
    final daysOfWeek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: null,
              icon: const Icon(Icons.chevron_left_rounded),
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
              onPressed: null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),
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
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            mainAxisSpacing: isTablet ? 6 : 4,
            crossAxisSpacing: isTablet ? 3 : 2,
            children: List.generate(35, (index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: SizedBox(
                    width: isTablet ? 20 : 16,
                    height: isTablet ? 20 : 16,
                    child: CircularProgressIndicator(
                      strokeWidth: isTablet ? 2 : 1.5,
                      valueColor: AlwaysStoppedAnimation(
                        AppTheme.primaryBlue.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: isTablet ? 24 : 20,
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

  Widget _buildCalendarGrid(
    bool isTablet,
    bool isDesktop,
    TahajudState tahajudState,
  ) {
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

    // Create map of completed dates from riwayat
    final completedDates = <DateTime>{};
    for (var riwayat in tahajudState.riwayatTahajud) {
      if (riwayat.status) {
        completedDates.add(
          DateTime(
            riwayat.tanggal.year,
            riwayat.tanggal.month,
            riwayat.tanggal.day,
          ),
        );
      }
    }

    return Column(
      children: [
        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                final prevMonth = DateTime(
                  selectedMonth.year,
                  selectedMonth.month - 1,
                );
                setState(() {
                  selectedMonth = prevMonth;
                });
                final monthFormat =
                    '${prevMonth.year}-${prevMonth.month.toString().padLeft(2, '0')}';
                ref.read(tahajudProvider.notifier).changeMonth(monthFormat);
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
                final nextMonth = DateTime(
                  selectedMonth.year,
                  selectedMonth.month + 1,
                );
                setState(() {
                  selectedMonth = nextMonth;
                });
                final monthFormat =
                    '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}';
                ref.read(tahajudProvider.notifier).changeMonth(monthFormat);
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
                              tahajudState,
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
    TahajudState tahajudState,
  ) {
    final authState = ref.read(authProvider);
    final isAuthenticated = authState['status'] == AuthState.authenticated;
    final connectionState = ref.read(connectionProvider);
    final isOffline = !connectionState.isOnline;

    // Get the tahajud record for this date
    final existingRiwayat = tahajudState.riwayatTahajud.firstWhere(
      (r) =>
          r.tanggal.year == currentDate.year &&
          r.tanggal.month == currentDate.month &&
          r.tanggal.day == currentDate.day,
      orElse: () =>
          RiwayatTahajud(tanggal: currentDate, status: false, tahajud: null),
    );
    final tahajud = existingRiwayat.tahajud;

    // Controllers for form
    final waktuSholatController = TextEditingController(
      text: tahajud?.waktuSholat != null
          ? DateFormat('HH:mm').format(tahajud!.waktuSholat!)
          : '',
    );
    final rakaatController = TextEditingController(
      text: tahajud?.jumlahRakaat?.toString() ?? '',
    );
    final makanController = TextEditingController(
      text: tahajud?.waktuMakanTerakhir != null
          ? DateFormat('HH:mm').format(tahajud!.waktuMakanTerakhir!)
          : '',
    );
    final tidurController = TextEditingController(
      text: tahajud?.waktuTidur != null
          ? DateFormat('HH:mm').format(tahajud!.waktuTidur!)
          : '',
    );
    final keteranganController = TextEditingController(
      text: tahajud?.keterangan ?? '',
    );

    // State for form validation
    final formKey = GlobalKey<FormState>();
    final formState = <String, String?>{
      'waktuSholat': waktuSholatController.text.isNotEmpty
          ? waktuSholatController.text
          : null,
      'rakaat': rakaatController.text.isNotEmpty ? rakaatController.text : null,
      'makanTerakhir': makanController.text.isNotEmpty
          ? makanController.text
          : null,
      'tidur': tidurController.text.isNotEmpty ? tidurController.text : null,
    };

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
        child: SingleChildScrollView(
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

              // Show detail if exists, otherwise show form
              if (isCompleted && tahajud != null) ...[
                // Detail View
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
                      color: AppTheme.accentGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.accentGreen,
                        size: isTablet ? 48 : 40,
                      ),
                      SizedBox(height: isTablet ? 12 : 10),
                      Text(
                        'Tahajud telah ditandai',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isTablet ? 20 : 16),

                // Detail Data
                Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'Waktu Sholat',
                        tahajud?.waktuSholat != null
                            ? DateFormat('HH:mm').format(tahajud!.waktuSholat!)
                            : '-',
                        Icons.access_time_rounded,
                        isTablet,
                      ),
                      SizedBox(height: isTablet ? 14 : 12),
                      _buildDetailRow(
                        'Rakaat',
                        tahajud?.jumlahRakaat != null &&
                                tahajud!.jumlahRakaat! > 0
                            ? '${tahajud?.jumlahRakaat} rakaat'
                            : '-',
                        Icons.format_list_numbered_rounded,
                        isTablet,
                      ),
                      SizedBox(height: isTablet ? 14 : 12),
                      _buildDetailRow(
                        'Makan Terakhir',
                        tahajud?.waktuMakanTerakhir != null
                            ? DateFormat(
                                'HH:mm',
                              ).format(tahajud!.waktuMakanTerakhir!)
                            : '-',
                        Icons.restaurant_rounded,
                        isTablet,
                      ),
                      SizedBox(height: isTablet ? 14 : 12),
                      _buildDetailRow(
                        'Tidur',
                        tahajud?.waktuTidur != null
                            ? DateFormat('HH:mm').format(tahajud!.waktuTidur!)
                            : '-',
                        Icons.bedtime_rounded,
                        isTablet,
                      ),
                      if (tahajud?.keterangan != null &&
                          tahajud!.keterangan!.isNotEmpty) ...[
                        SizedBox(height: isTablet ? 14 : 12),
                        Divider(color: Colors.grey.shade300),
                        SizedBox(height: isTablet ? 14 : 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.notes_rounded,
                              color: AppTheme.primaryBlue,
                              size: isTablet ? 20 : 18,
                            ),
                            SizedBox(width: isTablet ? 12 : 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Keterangan',
                                    style: TextStyle(
                                      fontSize: isTablet ? 13 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    tahajud?.keterangan ?? '',
                                    style: TextStyle(
                                      fontSize: isTablet ? 15 : 14,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                // Form Input
                Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Tahajud',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      SizedBox(height: isTablet ? 16 : 14),

                      // Waktu Sholat
                      _buildTimeField(
                        'Waktu Sholat *',
                        waktuSholatController,
                        Icons.access_time_rounded,
                        isTablet,
                        context,
                        isRequired: true,
                      ),
                      SizedBox(height: isTablet ? 14 : 12),

                      // Rakaat
                      _buildFormField(
                        'Rakaat *',
                        rakaatController,
                        'Contoh: 8',
                        Icons.format_list_numbered_rounded,
                        isTablet,
                        isNumber: true,
                        isRequired: true,
                      ),
                      SizedBox(height: isTablet ? 14 : 12),

                      // Makan Terakhir
                      _buildTimeField(
                        'Makan Terakhir *',
                        makanController,
                        Icons.restaurant_rounded,
                        isTablet,
                        context,
                        isRequired: true,
                      ),
                      SizedBox(height: isTablet ? 14 : 12),

                      // Tidur
                      _buildTimeField(
                        'Tidur *',
                        tidurController,
                        Icons.bedtime_rounded,
                        isTablet,
                        context,
                        isRequired: true,
                      ),
                      SizedBox(height: isTablet ? 14 : 12),

                      // Keterangan
                      _buildFormField(
                        'Keterangan',
                        keteranganController,
                        'Contoh: Sendiri, Berjamaah, dll',
                        Icons.notes_rounded,
                        isTablet,
                        maxLines: 3,
                        isRequired: false,
                      ),
                    ],
                  ),
                ),
              ],

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
                            ? () {
                                // Validate required fields
                                if (waktuSholatController.text.isEmpty ||
                                    rakaatController.text.isEmpty ||
                                    makanController.text.isEmpty ||
                                    tidurController.text.isEmpty) {
                                  showMessageToast(
                                    context,
                                    message:
                                        'Semua field yang ditandai * harus diisi',
                                    type: ToastType.error,
                                  );
                                  return;
                                }

                                // Validate rakaat is a number
                                if (int.tryParse(rakaatController.text) ==
                                    null) {
                                  showMessageToast(
                                    context,
                                    message: 'Rakaat harus berupa angka',
                                    type: ToastType.error,
                                  );
                                  return;
                                }

                                _markTahajud(
                                  currentDate,
                                  waktuSholatController.text,
                                  rakaatController.text,
                                  makanController.text,
                                  tidurController.text,
                                  keteranganController.text,
                                );
                                Navigator.pop(context);
                              }
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
                            ? () {
                                _deleteTahajud(tahajud?.id ?? 0);
                                Navigator.pop(context);
                              }
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
      ),
    );
  }

  void _markTahajud(
    DateTime date,
    String waktuSholat,
    String rakaat,
    String makanTerakhir,
    String tidur,
    String keterangan,
  ) {
    try {
      // Parse time strings and combine with date to create DateTime
      DateTime waktuSholatDate = date;
      DateTime waktuMakanDate = date;
      DateTime waktuTidurDate = date;

      if (waktuSholat.isNotEmpty) {
        final parts = waktuSholat.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        waktuSholatDate = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
      }

      if (makanTerakhir.isNotEmpty) {
        final parts = makanTerakhir.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        waktuMakanDate = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
      }

      if (tidur.isNotEmpty) {
        final parts = tidur.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        waktuTidurDate = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
      }

      final jumlahRakaat = rakaat.isNotEmpty ? int.tryParse(rakaat) ?? 0 : 0;

      // Call provider to add tahajud
      ref
          .read(tahajudProvider.notifier)
          .addTahajud(
            waktuSholat: waktuSholatDate,
            jumlahRakaat: jumlahRakaat,
            waktuMakanTerakhir: waktuMakanDate,
            waktuTidur: waktuTidurDate,
            keterangan: keterangan,
          );
      // Toast message is handled by the listener in didChangeDependencies
    } catch (e) {
      showMessageToast(
        context,
        message: 'Gagal memproses data: $e',
        type: ToastType.error,
      );
    }
  }

  void _deleteTahajud(int tahajudId) {
    ref.read(tahajudProvider.notifier).deleteTahajud(tahajudId.toString());
    // Toast message is handled by the listener in didChangeDependencies
  }

  // Helper widget for detail row
  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    bool isTablet,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: isTablet ? 20 : 18),
        SizedBox(width: isTablet ? 12 : 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 13 : 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isTablet ? 15 : 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widget for time field with picker
  Widget _buildTimeField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isTablet,
    BuildContext context, {
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 13 : 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    timePickerTheme: TimePickerThemeData(
                      backgroundColor: Colors.white,
                      hourMinuteShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      dayPeriodShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    colorScheme: ColorScheme.light(
                      primary: AppTheme.primaryBlue,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: AppTheme.onSurface,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              final formattedTime =
                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
              controller.text = formattedTime;
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 14 : 12,
              vertical: isTablet ? 14 : 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: controller.text.isEmpty && isRequired
                    ? Colors.red.shade300
                    : Colors.grey.shade300,
                width: controller.text.isEmpty && isRequired ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: isTablet ? 20 : 18,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: isTablet ? 12 : 10),
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? 'Pilih waktu' : controller.text,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 13,
                      color: controller.text.isEmpty
                          ? Colors.grey.shade500
                          : AppTheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Colors.grey.shade600,
                  size: isTablet ? 24 : 22,
                ),
              ],
            ),
          ),
        ),
        if (controller.text.isEmpty && isRequired) ...[
          SizedBox(height: 4),
          Text(
            'Field ini harus diisi',
            style: TextStyle(
              fontSize: isTablet ? 11 : 10,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  // Helper widget for form field
  Widget _buildFormField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon,
    bool isTablet, {
    bool isNumber = false,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 13 : 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: isTablet ? 20 : 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
              borderSide: BorderSide(
                color: controller.text.isEmpty && isRequired
                    ? Colors.red.shade300
                    : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
              borderSide: BorderSide(
                color: controller.text.isEmpty && isRequired
                    ? Colors.red.shade300
                    : Colors.grey.shade300,
                width: controller.text.isEmpty && isRequired ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
              borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 14 : 12,
              vertical: isTablet ? 14 : 12,
            ),
            errorText: controller.text.isEmpty && isRequired
                ? 'Field ini harus diisi'
                : null,
          ),
          style: TextStyle(fontSize: isTablet ? 14 : 13),
        ),
      ],
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
