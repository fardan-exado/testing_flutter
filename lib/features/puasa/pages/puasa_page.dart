import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';
import 'package:test_flutter/features/puasa/widgets/sunnah_tab.dart';
import 'package:test_flutter/features/puasa/pages/ramadhan_detail_page.dart';
import 'package:test_flutter/features/puasa/pages/sunnah_detail_page.dart';
import 'package:test_flutter/features/puasa/puasa_provider.dart';
import 'package:test_flutter/features/puasa/puasa_state.dart';

class PuasaPage extends ConsumerStatefulWidget {
  const PuasaPage({super.key});

  @override
  ConsumerState<PuasaPage> createState() => _PuasaPageState();
}

class _PuasaPageState extends ConsumerState<PuasaPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _hasInitializedWajib = false;
  bool _hasInitializedSunnah = false;
  late ProviderSubscription _puasaSub;
  late ProviderSubscription _authSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes
    _tabController.addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPuasaWajib();
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

    // Setup manual listener for puasa state
    _puasaSub = ref.listenManual(puasaProvider, (previous, next) {
      final route = ModalRoute.of(context);
      final isCurrent = route != null && route.isCurrent;
      if (!mounted || !isCurrent) return;

      // Handle messages
      if (next.message != null && next.message!.isNotEmpty) {
        if (next.status == PuasaStatus.error) {
          showMessageToast(
            context,
            message: next.message!,
            type: ToastType.error,
          );
        } else if (next.status == PuasaStatus.success) {
          showMessageToast(
            context,
            message: next.message!,
            type: ToastType.success,
          );
        }
      }
    });
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;

    final currentIndex = _tabController.index;

    if (currentIndex == 0 && !_hasInitializedWajib) {
      // Tab Puasa Wajib
      _initPuasaWajib();
    } else if (currentIndex == 1 && !_hasInitializedSunnah) {
      // Tab Puasa Sunnah
      _initPuasaSunnah();
    }
  }

  Future<void> _initPuasaWajib() async {
    if (_hasInitializedWajib) return;

    final authState = ref.read(authProvider);
    final isLoggedIn = authState['status'] == AuthState.authenticated;

    if (!isLoggedIn) {
      return;
    }

    try {
      final hijriYear = HijriCalendar.now().hYear;
      final tahunHijriah = hijriYear.toString();
      await ref
          .read(puasaProvider.notifier)
          .fetchRiwayatPuasaWajib(tahunHijriah: tahunHijriah);
      _hasInitializedWajib = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching Puasa Wajib: $e');
      }
    }
  }

  Future<void> _initPuasaSunnah() async {
    if (_hasInitializedSunnah) return;

    try {
      // First, fetch the list of puasa sunnah types from database
      await ref.read(puasaProvider.notifier).fetchPuasaSunnahList();

      // Get the list from provider state
      final puasaState = ref.read(puasaProvider);
      final puasaSunnahList = puasaState.puasaSunnahList ?? [];

      // Then fetch riwayat for each puasa sunnah type using their slugs
      for (final puasaSunnah in puasaSunnahList) {
        await ref
            .read(puasaProvider.notifier)
            .fetchRiwayatPuasaSunnah(jenis: puasaSunnah.slug);
      }

      _hasInitializedSunnah = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching Puasa Sunnah: $e');
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _puasaSub.close();
    _authSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    final puasaState = ref.watch(puasaProvider);
    final puasaSunnahList = puasaState.puasaSunnahList ?? [];

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
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
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
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
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
                            borderRadius: BorderRadius.circular(
                              isTablet ? 16 : 14,
                            ),
                          ),
                          child: Icon(
                            Icons.mosque,
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
                                'Kalender Puasa',
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
                                'Tracking ibadah puasa',
                                style: TextStyle(
                                  fontSize: isDesktop
                                      ? 15
                                      : isTablet
                                      ? 14
                                      : 14,
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
                    Tab(text: 'Puasa Wajib'),
                    Tab(text: 'Puasa Sunnah'),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 16 : 12),

              // TabView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    RamadhanDetailPage(isEmbedded: true),
                    SunnahTab(
                      puasaSunnahList: puasaSunnahList,
                      onPuasaTap: _showPuasaDetail,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPuasaDetail(Map<String, dynamic> puasa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SunnahDetailPage(puasaData: puasa),
      ),
    );
  }
}
