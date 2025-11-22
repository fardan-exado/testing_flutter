import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/connection/connection_provider.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';
import 'package:test_flutter/features/puasa/puasa_provider.dart';
import 'package:test_flutter/features/puasa/puasa_state.dart';

class SunnahDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> puasaData;

  const SunnahDetailPage({super.key, required this.puasaData});

  @override
  ConsumerState<SunnahDetailPage> createState() => _SunnahDetailPageState();
}

class _SunnahDetailPageState extends ConsumerState<SunnahDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late String _jenisPuasa;
  bool _isInitialized = false;

  // Provider subscriptions
  late ProviderSubscription _connectionSub;
  late ProviderSubscription _authSub;
  late ProviderSubscription _puasaSub;

  final GlobalKey<RefreshIndicatorState> _refreshKeyTracking =
      GlobalKey<RefreshIndicatorState>();

  final Map<String, List<Map<String, dynamic>>> _puasaGuides = {
    'Puasa Senin Kamis': [
      {
        'title': 'Niat Puasa Senin Kamis',
        'content':
            'نَوَيْتُ صَوْمَ يَوْمِ الْاِثْنَيْنِ سُنَّةً لِلّٰهِ تَعَالَى\n\nArtinya: "Aku berniat puasa hari Senin sunnah karena Allah Ta\'ala"',
        'icon': Icons.favorite,
        'color': AppTheme.primaryBlue,
      },
      {
        'title': 'Keutamaan',
        'content':
            'Rasulullah SAW bersabda: "Amal perbuatan itu dilaporkan pada hari Senin dan Kamis, maka aku suka amalku dilaporkan dalam keadaan berpuasa." (HR. Tirmidzi)',
        'icon': Icons.star,
        'color': AppTheme.accentGreen,
      },
      {
        'title': 'Tips Pelaksanaan',
        'content':
            '• Mulai sahur lebih awal\n• Banyak minum saat berbuka\n• Jaga konsistensi setiap minggu\n• Kombinasikan dengan amalan lain',
        'icon': Icons.lightbulb,
        'color': AppTheme.primaryBlueDark,
      },
    ],
    'Puasa Ayyamul Bidh': [
      {
        'title': 'Niat Puasa Ayyamul Bidh',
        'content':
            'نَوَيْتُ صَوْمَ الْأَيَّامِ الْبِيْضِ سُنَّةً لِلّٰهِ تَعَالَى\n\nArtinya: "Aku berniat puasa Ayyamul Bidh sunnah karena Allah Ta\'ala"',
        'icon': Icons.favorite,
        'color': AppTheme.primaryBlue,
      },
      {
        'title': 'Waktu Pelaksanaan',
        'content':
            'Puasa pada tanggal 13, 14, dan 15 setiap bulan Hijriah. Disebut "Ayyamul Bidh" karena bulan purnama bersinar terang pada hari-hari tersebut.',
        'icon': Icons.calendar_month,
        'color': AppTheme.accentGreen,
      },
      {
        'title': 'Hikmah dan Manfaat',
        'content':
            '• Mengikuti sunnah Rasulullah SAW\n• Melatih kesabaran dan ketakwaan\n• Mendapat pahala seperti puasa setahun\n• Menjaga kesehatan tubuh',
        'icon': Icons.psychology,
        'color': AppTheme.primaryBlueDark,
      },
    ],
    'Puasa Daud': [
      {
        'title': 'Cara Pelaksanaan',
        'content':
            'Puasa sehari, berbuka sehari secara bergantian. Ini adalah puasa yang paling dicintai Allah menurut hadits Rasulullah SAW.',
        'icon': Icons.swap_horiz,
        'color': AppTheme.primaryBlue,
      },
      {
        'title': 'Keutamaan Istimewa',
        'content':
            'Rasulullah SAW bersabda: "Puasa yang paling dicintai Allah adalah puasa Daud. Dia berpuasa sehari dan berbuka sehari." (HR. Bukhari)',
        'icon': Icons.diamond,
        'color': AppTheme.accentGreen,
      },
      {
        'title': 'Panduan Praktis',
        'content':
            '• Mulai secara bertahap\n• Pilih hari yang sesuai aktivitas\n• Jaga konsistensi pola\n• Perhatikan kondisi kesehatan',
        'icon': Icons.schedule,
        'color': AppTheme.primaryBlueDark,
      },
    ],
    'Puasa Syawal': [
      {
        'title': 'Niat Puasa Syawal',
        'content':
            'نَوَيْتُ صَوْمَ غَدٍ عَنْ سِتَّةٍ مِنْ شَوَّالٍ سُنَّةً لِلّٰهِ تَعَالَى\n\nArtinya: "Aku berniat puasa besok dari enam hari Syawal, sunnah karena Allah Ta\'ala"',
        'icon': Icons.favorite,
        'color': AppTheme.primaryBlue,
      },
      {
        'title': 'Keutamaan Utama',
        'content':
            'Rasulullah SAW bersabda: "Barangsiapa yang berpuasa Ramadhan kemudian berpuasa enam hari di bulan Syawal, maka dia berpuasa seperti setahun penuh." (HR. Muslim)',
        'icon': Icons.star,
        'color': AppTheme.accentGreen,
      },
      {
        'title': 'Waktu Pelaksanaan',
        'content':
            '• Dilaksanakan selama 6 hari di bulan Syawal.\n• Boleh dilakukan berurutan atau terpisah.\n• Harus setelah menyelesaikan qadha puasa Ramadhan.',
        'icon': Icons.rule,
        'color': AppTheme.primaryBlueDark,
      },
    ],
    'Puasa Muharram': [
      {
        'title': 'Niat Puasa Tasu\'a (9 Muharram)',
        'content':
            'نَوَيْتُ صَوْمَ تَاسُوعَاءَ سُنَّةً لِلّٰهِ تَعَالَى\n\nArtinya: "Aku berniat puasa Tasu\'a, sunnah karena Allah Ta\'ala"',
        'icon': Icons.favorite,
        'color': AppTheme.primaryBlue,
      },
      {
        'title': 'Niat Puasa Asyura (10 Muharram)',
        'content':
            'نَوَيْتُ صَوْمَ عَاشُورَاءَ سُنَّةً لِلّٰهِ تَعَالَى\n\nArtinya: "Aku berniat puasa Asyura, sunnah karena Allah Ta\'ala"',
        'icon': Icons.favorite_border,
        'color': AppTheme.accentGreen,
      },
      {
        'title': 'Keutamaan & Hikmah',
        'content':
            '• Puasa Asyura dapat menghapus dosa setahun yang lalu. (HR. Muslim)\n• Puasa Tasu\'a dianjurkan untuk menyelisihi kebiasaan puasa orang Yahudi.',
        'icon': Icons.psychology_alt,
        'color': AppTheme.primaryBlueDark,
      },
    ],
    'Puasa Sya\'ban': [
      {
        'title': 'Niat Puasa Sya\'ban',
        'content':
            'نَوَيْتُ صَوْمَ شَعْبَانَ سُنَّةً لِلّٰهِ تَعَالَى\n\nArtinya: "Aku berniat puasa Sya\'ban, sunnah karena Allah Ta\'ala"',
        'icon': Icons.favorite,
        'color': AppTheme.primaryBlue,
      },
      {
        'title': 'Bulan Diangkatnya Amal',
        'content':
            'Usamah bin Zaid berkata, "Wahai Rasulullah, aku tidak pernah melihat engkau berpuasa dalam satu bulan sebagaimana engkau berpuasa di bulan Sya\'ban." Beliau bersabda, "Itulah bulan yang sering dilalaikan orang... yaitu bulan diangkatnya amal kepada Rabb semesta alam, maka aku suka amalku diangkat dalam keadaan berpuasa." (HR. An-Nasa\'i)',
        'icon': Icons.checklist,
        'color': AppTheme.accentGreen,
      },
      {
        'title': 'Larangan di Akhir Bulan',
        'content':
            'Tidak dianjurkan berpuasa pada pertengahan kedua bulan Sya\'ban (setelah tanggal 15) bagi yang tidak memiliki kebiasaan puasa sebelumnya, sebagai persiapan menyambut bulan Ramadhan.',
        'icon': Icons.gpp_bad,
        'color': AppTheme.primaryBlueDark,
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _jenisPuasa = widget.puasaData['type']!;

    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
      _setupListeners();
    });
  }

  void _setupListeners() {
    // Listen to auth state
    _authSub = ref.listenManual(authProvider, (previous, next) {
      if (previous?['status'] != next['status']) {
        if (next['status'] != AuthState.authenticated) {
          final route = ModalRoute.of(context);
          if (mounted && route != null && route.isCurrent) {
            showMessageToast(
              context,
              message: 'Sesi berakhir. Silakan login kembali.',
              type: ToastType.warning,
            );
          }
        }
      }
    });

    // Listen to puasa state
    _puasaSub = ref.listenManual(puasaProvider, (previous, next) {
      // Handle success state
      if (next.status == PuasaStatus.success &&
          previous?.status == PuasaStatus.loading) {
        if (next.message != null) {
          final route = ModalRoute.of(context);
          if (mounted && route != null && route.isCurrent) {
            showMessageToast(
              context,
              message: next.message!,
              type: ToastType.success,
            );
          }
        }
      }

      // Handle loaded data
      if (next.status == PuasaStatus.loaded) {}

      // Handle error state
      if (next.status == PuasaStatus.error) {
        if (previous?.status == PuasaStatus.loading && next.message != null) {
          final route = ModalRoute.of(context);
          if (mounted && route != null && route.isCurrent) {
            showMessageToast(
              context,
              message: next.message!,
              type: ToastType.error,
            );
          }
        }
      }
    });
  }

  Future<void> _fetchData() async {
    try {
      // Clear previous state to avoid confusion

      await ref
          .read(puasaProvider.notifier)
          .fetchRiwayatPuasaSunnah(jenis: _jenisPuasa);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error fetching Sunnah fasting data: $e');
        print(stackTrace);
      }
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    try {
      await _fetchData();
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

  @override
  void dispose() {
    _tabController.dispose();
    _connectionSub.close();
    _authSub.close();
    _puasaSub.close();
    super.dispose();
  }

  int _getCompletedCount() {
    final puasaState = ref.watch(puasaProvider);
    final riwayat = puasaState.riwayatPuasaSunnah ?? [];
    return riwayat.length;
  }

  // Check if today already has fasting record
  bool _isTodayMarked() {
    final puasaState = ref.watch(puasaProvider);
    final riwayat = puasaState.riwayatPuasaSunnah ?? [];

    if (riwayat.isEmpty) return false;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (var item in riwayat) {
      if (item.createdAt != null) {
        final itemDate = DateTime(
          item.createdAt!.year,
          item.createdAt!.month,
          item.createdAt!.day,
        );

        if (itemDate.isAtSameMomentAs(todayDate)) {
          return true;
        }
      }
    }

    return false;
  }

  // Get today's fasting record ID
  String? _getTodayRecordId() {
    final puasaState = ref.watch(puasaProvider);
    final riwayat = puasaState.riwayatPuasaSunnah ?? [];

    if (riwayat.isEmpty) return null;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (var item in riwayat) {
      if (item.createdAt != null) {
        final itemDate = DateTime(
          item.createdAt!.year,
          item.createdAt!.month,
          item.createdAt!.day,
        );

        if (itemDate.isAtSameMomentAs(todayDate)) {
          return item.id.toString();
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    final connectionState = ref.watch(connectionProvider);
    final isOffline = !connectionState.isOnline;
    final puasaState = ref.watch(puasaProvider);
    final completedCount = _getCompletedCount();

    // Deep logging for debugging

    // Show loading while fetching data
    if (!_isInitialized && puasaState.riwayatPuasaSunnah == null) {
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
                  'Memuat data $_jenisPuasa...',
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
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
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
                        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
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
                            widget.puasaData['name'],
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
                            widget.puasaData['description'],
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 14,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Offline Badge
                    if (isOffline)
                      Container(
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

              // Progress Summary
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isDesktop
                      ? 32.0
                      : isTablet
                      ? 28.0
                      : 24.0,
                ),
                child: _buildProgressCard(
                  completedCount.toString(),
                  'Puasa Diselesaikan',
                  AppTheme.accentGreen,
                  Icons.check_circle_rounded,
                  isTablet,
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
                    Tab(text: 'Tracking'),
                    Tab(text: 'Panduan'),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 16 : 12),

              // TabView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildTrackingTab(), _buildGuideTab()],
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
    String label,
    Color color,
    IconData icon,
    bool isTablet,
  ) {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
            ),
            child: Icon(icon, color: color, size: isTablet ? 24 : 22),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: isTablet ? 4 : 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    color: AppTheme.onSurfaceVariant,
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

  Widget _buildTrackingTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    final puasaState = ref.watch(puasaProvider);
    final isTodayMarked = _isTodayMarked();
    final isLoading = puasaState.status == PuasaStatus.loading;

    final riwayat = puasaState.riwayatPuasaSunnah ?? [];

    return Column(
      children: [
        // Scrollable Content
        Expanded(
          child: RefreshIndicator.adaptive(
            key: _refreshKeyTracking,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: isDesktop
                    ? 32.0
                    : isTablet
                    ? 28.0
                    : 24.0,
                right: isDesktop
                    ? 32.0
                    : isTablet
                    ? 28.0
                    : 24.0,
                bottom: isTablet ? 24 : 20,
              ),
              child: Column(
                children: [
                  // Recent Activity
                  Container(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              color: AppTheme.primaryBlue,
                              size: isTablet ? 24 : 22,
                            ),
                            SizedBox(width: isTablet ? 12 : 8),
                            Text(
                              'Aktivitas Terbaru',
                              style: TextStyle(
                                fontSize: isDesktop
                                    ? 20
                                    : isTablet
                                    ? 18
                                    : 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 20 : 16),

                        // Loading widget
                        if (isLoading)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(isTablet ? 24 : 20),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryBlue,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Memuat riwayat...',
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 13,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (riwayat.isEmpty)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(isTablet ? 24 : 20),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 48,
                                    color: AppTheme.onSurfaceVariant.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Belum ada riwayat puasa',
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 13,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                ],
                              ),
                            ),
                          )
                        else
                          ...riwayat.map(
                            (item) => _buildActivityItem(item, isTablet),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Fixed Button at Bottom
        Container(
          padding: EdgeInsets.only(
            left: isDesktop
                ? 32.0
                : isTablet
                ? 28.0
                : 24.0,
            right: isDesktop
                ? 32.0
                : isTablet
                ? 28.0
                : 24.0,
            bottom: isTablet ? 24 : 20,
            top: isTablet ? 16 : 12,
          ),
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () {
                      if (isTodayMarked) {
                        _deleteTodayFasting();
                      } else {
                        _markTodayFasting();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isTodayMarked
                    ? Colors.red.shade400
                    : widget.puasaData['color'],
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              icon: isLoading
                  ? SizedBox(
                      width: isTablet ? 20 : 18,
                      height: isTablet ? 20 : 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      isTodayMarked ? Icons.delete_outline : Icons.add_task,
                      size: isTablet ? 20 : 18,
                    ),
              label: Text(
                isTodayMarked
                    ? 'Hapus Tandai Puasa Hari Ini'
                    : 'Tandai Puasa Hari Ini',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 16 : 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;

    final guides = _puasaGuides[widget.puasaData['name']] ?? [];

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop
            ? 32.0
            : isTablet
            ? 28.0
            : 24.0,
      ),
      itemCount: guides.length,
      itemBuilder: (context, index) {
        final guide = guides[index];
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTablet ? 12 : 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            guide['color'].withValues(alpha: 0.15),
                            guide['color'].withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                      ),
                      child: Icon(
                        guide['icon'],
                        color: guide['color'],
                        size: isTablet ? 24 : 22,
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: Text(
                        guide['title'],
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
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 16 : 12),
                Text(
                  guide['content'],
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(dynamic item, bool isTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      padding: EdgeInsets.all(isTablet ? 12 : 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentGreen.withValues(alpha: 0.05),
            AppTheme.accentGreen.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppTheme.accentGreen,
            size: isTablet ? 20 : 18,
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMd().format(item.createdAt),
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '${widget.puasaData['name']}',
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 11,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _markTodayFasting() async {
    final authState = ref.read(authProvider);
    final connectionState = ref.read(connectionProvider);

    if (authState['status'] != AuthState.authenticated) {
      showMessageToast(
        context,
        message: 'Anda harus login terlebih dahulu',
        type: ToastType.error,
      );
      return;
    }

    if (!connectionState.isOnline) {
      showMessageToast(
        context,
        message: 'Tidak dapat menambah progress saat offline',
        type: ToastType.error,
      );
      return;
    }

    try {
      // Call the API to add progress
      await ref
          .read(puasaProvider.notifier)
          .addProgresPuasaSunnah(jenis: _jenisPuasa);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error marking today fasting: $e');
        print(stackTrace);
      }
    }
  }

  void _deleteTodayFasting() async {
    final authState = ref.read(authProvider);
    final connectionState = ref.read(connectionProvider);
    final todayRecordId = _getTodayRecordId();

    if (todayRecordId == null) {
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

    if (!connectionState.isOnline) {
      showMessageToast(
        context,
        message: 'Tidak dapat menghapus progress saat offline',
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
          'Apakah Anda yakin ingin menghapus tandai puasa hari ini?',
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
          .deleteProgresPuasaSunnah(id: todayRecordId, jenis: _jenisPuasa);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error deleting today fasting: $e');
        print(stackTrace);
      }
    }
  }
}
