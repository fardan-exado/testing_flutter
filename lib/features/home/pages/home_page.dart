import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/app/router.dart';
import 'package:test_flutter/core/constants/app_config.dart';
import 'package:test_flutter/core/utils/format_helper.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/core/widgets/menu/custom_bottom_app_bar.dart';
import 'package:test_flutter/core/widgets/offline_badge.dart';
import 'package:test_flutter/data/models/artikel/artikel.dart';
import 'package:test_flutter/data/models/sholat/sholat.dart';
import 'package:test_flutter/features/home/home_provider.dart';
import 'package:test_flutter/features/home/home_state.dart';
import 'package:test_flutter/features/home/widgets/prayer_time_display.dart';
import 'package:test_flutter/features/home/widgets/prayer_times_row.dart';
import 'package:test_flutter/features/komunitas/pages/komunitas_page.dart';
import 'package:test_flutter/features/monitoring/pages/monitoring_page.dart';
import 'package:test_flutter/features/quran/pages/quran_page.dart';
import 'package:test_flutter/features/sholat/pages/sholat_page.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import '../../../app/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeTabContent(),
      const SholatPage(),
      const QuranPage(),
      const MonitoringPage(),
      const KomunitasPage(),
    ];
  }

  void navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomAppBar(
        currentIndex: _currentIndex,
        onTabSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class HomeTabContent extends ConsumerStatefulWidget {
  const HomeTabContent({super.key});

  @override
  ConsumerState<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends ConsumerState<HomeTabContent> {
  // ---------- tiny helpers (dibangun di atas ResponsiveHelper) ----------
  double _scaleFactor(BuildContext context) {
    if (ResponsiveHelper.isSmallScreen(context)) return .9;
    if (ResponsiveHelper.isMediumScreen(context)) return 1.0;
    if (ResponsiveHelper.isLargeScreen(context)) return 1.1;
    return 1.2; // extra large
  }

  double _t(BuildContext c, double base) =>
      ResponsiveHelper.adaptiveTextSize(c, base);

  double _px(BuildContext c, double base) => base * _scaleFactor(c);

  double _icon(BuildContext c, double base) => base * _scaleFactor(c);

  double _hpad(BuildContext c) {
    if (ResponsiveHelper.isExtraLargeScreen(c)) return 48;
    if (ResponsiveHelper.isLargeScreen(c)) return 32;
    return ResponsiveHelper.getScreenWidth(c) * 0.04;
  }

  double _contentMaxWidth(BuildContext c) {
    if (ResponsiveHelper.isExtraLargeScreen(c)) return 980;
    if (ResponsiveHelper.isLargeScreen(c)) return 820;
    return double.infinity;
  }

  bool _isDesktop(BuildContext c) =>
      ResponsiveHelper.isLargeScreen(c) ||
      ResponsiveHelper.isExtraLargeScreen(c);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(homeProvider.notifier);

      // Check and load cache first
      notifier.checkIsJadwalSholatCacheExist();
      notifier.checkIsArtikelCacheExist();

      // Then try to fetch fresh data if needed
      final currentState = ref.read(homeProvider);

      // Fetch jadwal sholat if not available
      if (currentState.jadwalSholat == null ||
          currentState.jadwalSholat == Sholat.empty()) {
        notifier.fetchJadwalSholat(useCurrentLocation: true);
      }

      // Fetch artikel if not available
      if (currentState.articles.isEmpty) {
        notifier.fetchArtikelTerbaru();
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _formatGregorianDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    // Only refresh prayer schedule and location
    await ref
        .read(homeProvider.notifier)
        .fetchJadwalSholat(forceRefresh: true, useCurrentLocation: true);
  }

  void _navigateToTab(int index) {
    // Find parent HomePage state
    final homePageState = context.findAncestorStateOfType<_HomePageState>();
    homePageState?.navigateToTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final status = homeState.status;
    final articles = homeState.articles;
    final error = homeState.message;

    // Get location data from state
    final locationName = homeState.locationName;
    final localDate =
        homeState.localDate ?? DateTime.now().toIso8601String().split('T')[0];

    // Get screen height for responsive adjustments
    final screenHeight = MediaQuery.of(context).size.height;
    final isShortScreen = screenHeight < 700;

    // Format dates
    String gregorianDate = 'Loading...';
    String hijriDate = 'Loading...';

    try {
      final dateParts = localDate.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final date = DateTime(year, month, day);
      gregorianDate = _formatGregorianDate(date);
      hijriDate = FormatHelper.getHijriDate(date);
    } catch (e) {
      logger.warning('Error parsing date: $e');
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.primaryBlue,
        backgroundColor: Colors.white,
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
                ),
              ),
            ),

            // Scrollable content for pull to refresh
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        // Header with adjusted padding
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: _hpad(context),
                            vertical: isShortScreen
                                ? _px(context, 12)
                                : _px(context, 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hijriDate,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: _t(
                                          context,
                                          isShortScreen ? 15 : 16,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: _px(context, 4)),
                                    Text(
                                      gregorianDate,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: _t(
                                          context,
                                          isShortScreen ? 12 : 13,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: _px(context, 6)),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.white70,
                                          size: _icon(context, 14),
                                        ),
                                        SizedBox(width: _px(context, 4)),
                                        Flexible(
                                          child: Text(
                                            locationName!,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: _t(
                                                context,
                                                isShortScreen ? 12 : 13,
                                              ),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/profile',
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.all(_px(context, 8)),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: _icon(context, 24),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: isShortScreen
                              ? _px(context, 12)
                              : _px(context, 18),
                        ),

                        // Prayer time display widget
                        const PrayerTimeDisplay(),

                        SizedBox(
                          height: isShortScreen
                              ? _px(context, 16)
                              : _px(context, 28),
                        ),

                        // Prayer times row widget
                        const PrayerTimesRow(),

                        SizedBox(
                          height: isShortScreen
                              ? _px(context, 12)
                              : _px(context, 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bottom sheet with articles
            LayoutBuilder(
              builder: (context, constraints) {
                final max = _isDesktop(context) ? 0.9 : 0.88;

                return DraggableScrollableSheet(
                  initialChildSize: 0.45,
                  minChildSize: 0.45,
                  maxChildSize: max,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundWhite,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Handle bar
                          Container(
                            margin: const EdgeInsets.only(top: 16, bottom: 12),
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue.withValues(alpha: 0.3),
                                  AppTheme.accentGreen.withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),

                          // Offline indicator widget
                          const OfflineBadge(),

                          // Content
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: _contentMaxWidth(context),
                                ),
                                child: _buildBottomSheetContent(
                                  context,
                                  scrollController,
                                  articles,
                                  status,
                                  error,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetContent(
    BuildContext context,
    ScrollController scrollController,
    List<Artikel> articles,
    HomeStatus status,
    String? error,
  ) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: _hpad(context),
        vertical: _px(context, 12),
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        // Quick Access header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                    AppTheme.accentGreen.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.apps_rounded,
                color: AppTheme.primaryBlue,
                size: _icon(context, 24),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'All Features',
                style: TextStyle(
                  fontSize: _t(context, 20),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: _px(context, 16)),

        // Grid menu
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _getGridColumns(context),
          mainAxisSpacing: _px(context, 20),
          crossAxisSpacing: _px(context, 16),
          childAspectRatio: _getChildAspectRatio(context),
          children: [
            _buildEnhancedFeatureButton(
              context,
              FlutterIslamicIcons.family,
              'Monitoring',
              AppTheme.primaryBlueLight,
              onTap: () => _navigateToTab(3),
            ),
            _buildEnhancedFeatureButton(
              context,
              FlutterIslamicIcons.prayer,
              'Tahajud',
              AppTheme.primaryBlueLight,
              onTap: () => Navigator.pushNamed(context, '/tahajud'),
            ),
            _buildEnhancedFeatureButton(
              context,
              FlutterIslamicIcons.prayingPerson,
              'Sholat',
              AppTheme.primaryBlueLight,
              onTap: () => _navigateToTab(1),
            ),
            _buildEnhancedFeatureButton(
              context,
              FlutterIslamicIcons.zakat,
              'Sedekah',
              AppTheme.primaryBlueLight,
              onTap: () => Navigator.pushNamed(context, '/zakat'),
            ),
            _buildEnhancedFeatureButton(
              context,
              FlutterIslamicIcons.ramadan,
              'Puasa',
              AppTheme.primaryBlueLight,
              onTap: () => Navigator.pushNamed(context, '/puasa'),
            ),
            _buildEnhancedFeatureButton(
              context,
              FlutterIslamicIcons.kaaba,
              'Haji',
              AppTheme.primaryBlueLight,
              onTap: () => Navigator.pushNamed(context, '/haji'),
            ),
            _buildEnhancedFeatureButton(
              context,
              FlutterIslamicIcons.quran2,
              'Al-Quran',
              AppTheme.primaryBlueLight,
              onTap: () => _navigateToTab(2),
            ),
            _buildEnhancedFeatureButton(
              context,
              FlutterIslamicIcons.allah,
              'Syahadat',
              AppTheme.primaryBlueLight,
              onTap: () => Navigator.pushNamed(context, '/syahadat'),
            ),
            _buildEnhancedFeatureButton(
              context,
              FlutterIslamicIcons.qibla,
              'Qibla',
              AppTheme.primaryBlueLight,
              onTap: () => Navigator.pushNamed(context, '/qibla-compass'),
            ),
            _buildEnhancedFeatureButton(
              context,
              Icons.article,
              'Artikel',
              AppTheme.primaryBlueLight,
              onTap: () => Navigator.pushNamed(context, '/article'),
            ),
            _buildEnhancedFeatureButton(
              context,
              Icons.forum_outlined,
              'Komunitas',
              AppTheme.primaryBlueLight,
              onTap: () => _navigateToTab(4),
            ),
          ],
        ),

        SizedBox(height: _px(context, 32)),

        // Latest Articles section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _buildSectionHeader(
                context,
                'Artikel Terbaru',
                Icons.article_rounded,
                AppTheme.primaryBlue,
              ),
            ),
            if (status == HomeStatus.refreshing)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryBlue,
                  ),
                ),
              )
            else
              IconButton(
                onPressed: () {
                  ref
                      .read(homeProvider.notifier)
                      .fetchArtikelTerbaru(forceRefresh: true);
                },
                icon: Icon(
                  Icons.refresh,
                  color: AppTheme.primaryBlue,
                  size: _icon(context, 20),
                ),
                padding: EdgeInsets.all(_px(context, 8)),
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        SizedBox(height: _px(context, 16)),

        // Articles list with loading state
        _buildArticlesSection(context, articles, status, error),

        SizedBox(height: _px(context, 100)), // for bottom nav
      ],
    );
  }

  // ...existing code... (method lainnya tetap sama)

  // Method helper untuk menentukan jumlah kolom grid
  int _getGridColumns(BuildContext context) {
    final w = ResponsiveHelper.getScreenWidth(context);
    if (w < 360) return 3;
    if (w < ResponsiveHelper.mediumScreenSize) return 4;
    if (w < ResponsiveHelper.largeScreenSize) return 5;
    return 6;
  }

  double _getChildAspectRatio(BuildContext context) {
    final w = ResponsiveHelper.getScreenWidth(context);
    if (w < 360) return 0.85;
    if (w < ResponsiveHelper.mediumScreenSize) return 0.90;
    if (w < ResponsiveHelper.largeScreenSize) return 0.95;
    return 1.0;
  }

  Widget _buildArticlesSection(
    BuildContext context,
    List<Artikel> articles,
    HomeStatus status,
    String? error,
  ) {
    if (status == HomeStatus.loading && articles.isEmpty) {
      return _buildArticlesLoadingState(context);
    }

    if (status == HomeStatus.error && articles.isEmpty) {
      return _buildArticlesErrorState(context, error ?? 'Unknown error');
    }

    if (articles.isEmpty) {
      return _buildArticlesEmptyState(context);
    }

    final storageUrl = AppConfig.storageUrl;

    return Column(
      children: [
        ...articles.take(3).map((article) {
          return _buildEnhancedArticleCard(
            article: article,
            title: article.judul,
            summary: article.excerpt ?? '',
            imageUrl: article.cover.isNotEmpty
                ? '$storageUrl/${article.cover}'
                : 'https://picsum.photos/120/100?random=${article.id}',
            date: _formatDate(article.createdAt),
            context: context,
            category: article.kategori.nama,
          );
        }),
      ],
    );
  }

  Widget _buildArticlesErrorState(BuildContext context, String error) {
    return Container(
      padding: EdgeInsets.all(_px(context, 20)),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade400,
            size: _icon(context, 48),
          ),
          SizedBox(height: _px(context, 12)),
          Text(
            'Gagal Memuat Artikel',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: _t(context, 16),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: _px(context, 8)),
          Text(
            'Tidak dapat terhubung ke server',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: _t(context, 14),
            ),
            textAlign: TextAlign.center,
          ),
          if (error.isNotEmpty) ...[
            SizedBox(height: _px(context, 4)),
            Text(
              error,
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: _t(context, 12),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: _px(context, 16)),
          ElevatedButton.icon(
            onPressed: () {
              ref
                  .read(homeProvider.notifier)
                  .fetchArtikelTerbaru(forceRefresh: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: _px(context, 24),
                vertical: _px(context, 12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildArticlesEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_px(context, 20)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.article_outlined,
            color: AppTheme.onSurfaceVariant,
            size: _icon(context, 48),
          ),
          SizedBox(height: _px(context, 12)),
          Text(
            'Belum Ada Artikel',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: _t(context, 16),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: _px(context, 8)),
          Text(
            'Artikel terbaru akan muncul di sini',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: _t(context, 14),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildArticlesLoadingState(BuildContext context) {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(_px(context, 12)),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: _px(context, 100),
                height: _px(context, 90),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: MediaQuery.of(context).size.width * 0.6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: MediaQuery.of(context).size.width * 0.4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${difference.inDays ~/ 7} week${difference.inDays ~/ 7 > 1 ? 's' : ''} ago';
    }
  }

  Widget _buildEnhancedFeatureButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    double scale(BuildContext c) {
      if (ResponsiveHelper.isSmallScreen(c)) return .9;
      if (ResponsiveHelper.isMediumScreen(c)) return 1.0;
      if (ResponsiveHelper.isLargeScreen(c)) return 1.1;
      return 1.2;
    }

    double px(double base) => base * scale(context);
    double ts(double base) => ResponsiveHelper.adaptiveTextSize(context, base);

    final w = ResponsiveHelper.getScreenWidth(context);

    final iconContainerSize = w < 360 ? px(52) : px(64);
    final iconSize = w < 360 ? px(24) : px(28);
    final fontSize = w < 360 ? ts(11) : ts(13);
    final spacing = w < 360 ? 6.0 : 10.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(w < 360 ? 14 : 18),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          SizedBox(height: spacing),
          Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: px(2)),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    double px(double base) {
      if (ResponsiveHelper.isSmallScreen(context)) return base * .9;
      if (ResponsiveHelper.isMediumScreen(context)) return base;
      if (ResponsiveHelper.isLargeScreen(context)) return base * 1.1;
      return base * 1.2;
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(px(8)),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: px(20)),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveHelper.adaptiveTextSize(context, 20),
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedArticleCard({
    required Artikel article,
    required String title,
    required String summary,
    required String imageUrl,
    required String date,
    required String category,
    required BuildContext context,
  }) {
    double scale(BuildContext c) {
      if (ResponsiveHelper.isSmallScreen(c)) return .9;
      if (ResponsiveHelper.isMediumScreen(c)) return 1.0;
      if (ResponsiveHelper.isLargeScreen(c)) return 1.1;
      return 1.2;
    }

    double px(double base) => base * scale(context);
    double ts(double base) => ResponsiveHelper.adaptiveTextSize(context, base);

    final imgW = px(100);
    final imgH = px(90);

    final isVideo = article.tipe.toLowerCase() == 'video';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: -3,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.articleDetail,
            arguments: article.id,
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.all(px(12)),
          child: Row(
            children: [
              Container(
                width: imgW,
                height: imgH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.network(
                        imageUrl,
                        width: imgW,
                        height: imgH,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: imgW,
                            height: imgH,
                            color: Colors.grey.shade200,
                            child: Icon(
                              isVideo ? Icons.video_library : Icons.image,
                              color: Colors.grey.shade400,
                              size: px(32),
                            ),
                          );
                        },
                      ),

                      if (isVideo)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.all(px(8)),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: AppTheme.primaryBlue,
                                  size: px(24),
                                ),
                              ),
                            ),
                          ),
                        ),

                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: px(8),
                            vertical: px(4),
                          ),
                          decoration: BoxDecoration(
                            color: isVideo
                                ? Colors.red.shade600
                                : AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isVideo) ...[
                                Icon(
                                  Icons.videocam_rounded,
                                  color: Colors.white,
                                  size: px(12),
                                ),
                                SizedBox(width: px(4)),
                              ],
                              Text(
                                category,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: ts(10),
                                  fontWeight: FontWeight.w600,
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: ts(15),
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: px(6)),
                    Text(
                      summary,
                      style: TextStyle(
                        fontSize: ts(13),
                        color: AppTheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: px(8)),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: px(14),
                          color: AppTheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: ts(12),
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: px(14),
                          color: isVideo
                              ? Colors.red.shade600
                              : AppTheme.primaryBlue,
                        ),
                      ],
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
}
