import 'package:flutter/material.dart';
import 'package:test_flutter/app/theme.dart';

/// Child Detail Page - Halaman detail monitoring untuk setiap anak
///
/// Menampilkan:
/// - Profile dan statistik anak
/// - Summary bulanan untuk setiap kategori ibadah
/// - Timeline aktivitas terbaru
/// - Progress chart dan achievement
class ChildDetailPage extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildDetailPage({super.key, required this.childData});

  @override
  State<ChildDetailPage> createState() => _ChildDetailPageState();
}

class _ChildDetailPageState extends State<ChildDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Extended sample data for detailed view
  final Map<String, dynamic> extendedData = {
    'monthlyStats': {
      'sholat': {
        'completed': 140,
        'total': 150,
        'onTime': 125,
        'jamaah': 80,
        'missedDays': 2,
      },
      'quran': {
        'pagesRead': 45,
        'targetPages': 60,
        'daysActive': 25,
        'averageDaily': 1.8,
        'favoriteJuz': 'Juz 30',
      },
      'tahajud': {
        'completed': 18,
        'total': 30,
        'longestStreak': 12,
        'currentStreak': 7,
      },
      'puasa': {'completed': 15, 'sunnah': 8, 'wajib': 7, 'qadha': 2},
      'zakat': {
        'given': 3,
        'amount': 150000,
        'types': ['Zakat Fitrah', 'Sedekah Harian', 'Infaq Masjid'],
      },
    },
    'recentActivities': [
      {
        'type': 'sholat',
        'activity': 'Sholat Maghrib',
        'status': 'Tepat Waktu',
        'jamaah': true,
        'time': DateTime.now().subtract(const Duration(hours: 2)),
        'location': 'Masjid Al-Ikhlas',
      },
      {
        'type': 'quran',
        'activity': 'Membaca Al-Qur\'an',
        'pages': 2,
        'surah': 'Al-Kahf',
        'time': DateTime.now().subtract(const Duration(hours: 4)),
        'duration': '25 menit',
      },
      {
        'type': 'tahajud',
        'activity': 'Sholat Tahajud',
        'rakaat': 4,
        'time': DateTime.now().subtract(const Duration(hours: 18)),
        'doa': 'Istighfar & Doa Khusnul Khatimah',
      },
      {
        'type': 'sedekah',
        'activity': 'Sedekah Harian',
        'amount': 5000,
        'recipient': 'Fakir Miskin',
        'time': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'type': 'sholat',
        'activity': 'Sholat Ashar',
        'status': 'Terlambat 10 menit',
        'jamaah': false,
        'time': DateTime.now().subtract(const Duration(days: 1, hours: 8)),
        'location': 'Rumah',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue.withValues(alpha: 0.05),
              AppTheme.backgroundWhite,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: Column(
          children: [
            // Fixed Header and Child Info Card
            SafeArea(
              bottom: false,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildChildInfoCard(),
                    _buildTabBar(),
                  ],
                ),
              ),
            ),
            // Tab Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildSummaryTab(), _buildActivitiesTab()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        8,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                  AppTheme.accentGreen.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail ${widget.childData['name']}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Laporan aktivitas ibadah',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // PopupMenuButton<String>(
          //   icon: Icon(
          //     Icons.more_vert_rounded,
          //     color: AppTheme.onSurfaceVariant,
          //   ),
          //   itemBuilder: (context) => [
          //     const PopupMenuItem(
          //       value: 'export',
          //       child: Row(
          //         children: [
          //           Icon(Icons.download_rounded),
          //           SizedBox(width: 8),
          //           Text('Export Laporan'),
          //         ],
          //       ),
          //     ),
          //     const PopupMenuItem(
          //       value: 'settings',
          //       child: Row(
          //         children: [
          //           Icon(Icons.settings_rounded),
          //           SizedBox(width: 8),
          //           Text('Pengaturan'),
          //         ],
          //       ),
          //     ),
          //     const PopupMenuItem(
          //       value: 'reward',
          //       child: Row(
          //         children: [
          //           Icon(Icons.card_giftcard_rounded),
          //           SizedBox(width: 8),
          //           Text('Kirim Reward'),
          //         ],
          //       ),
          //     ),
          //   ],
          //   onSelected: _handleMenuAction,
          // ),
        ],
      ),
    );
  }

  Widget _buildChildInfoCard() {
    final progress = widget.childData['todayProgress'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.childData['avatar'],
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.childData['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Umur ${widget.childData['age']} tahun',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Streak ${progress['streak']} hari',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Aktif ${_getTimeAgo(widget.childData['lastActive'])}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Responsive Quick Stats
          // LayoutBuilder(
          //   builder: (context, constraints) {
          //     if (constraints.maxWidth < 400) {
          //       return Column(
          //         children: [
          //           Row(
          //             children: [
          //               Expanded(
          //                 child: _buildQuickStat(
          //                   'Sholat',
          //                   '${progress['sholat']}/${progress['totalSholat']}',
          //                   Icons.mosque_rounded,
          //                 ),
          //               ),
          //               const SizedBox(width: 8),
          //               Expanded(
          //                 child: _buildQuickStat(
          //                   'Al-Qur\'an',
          //                   '${progress['quran']}/${progress['targetQuran']}',
          //                   Icons.menu_book_rounded,
          //                 ),
          //               ),
          //             ],
          //           ),
          //           const SizedBox(height: 8),
          //           _buildQuickStat(
          //             'Tahajud',
          //             progress['tahajud'] ? 'Selesai' : 'Belum',
          //             Icons.nightlight_round,
          //           ),
          //         ],
          //       );
          //     } else {
          //       return Row(
          //         children: [
          //           Expanded(
          //             child: _buildQuickStat(
          //               'Sholat Hari Ini',
          //               '${progress['sholat']}/${progress['totalSholat']}',
          //               Icons.mosque_rounded,
          //             ),
          //           ),
          //           Container(
          //             width: 1,
          //             height: 32,
          //             color: Colors.white.withValues(alpha: 0.3),
          //           ),
          //           Expanded(
          //             child: _buildQuickStat(
          //               'Al-Qur\'an',
          //               '${progress['quran']}/${progress['targetQuran']}',
          //               Icons.menu_book_rounded,
          //             ),
          //           ),
          //           Container(
          //             width: 1,
          //             height: 32,
          //             color: Colors.white.withValues(alpha: 0.3),
          //           ),
          //           Expanded(
          //             child: _buildQuickStat(
          //               'Tahajud',
          //               progress['tahajud'] ? 'Selesai' : 'Belum',
          //               Icons.nightlight_round,
          //             ),
          //           ),
          //         ],
          //       );
          //     }
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Ringkasan', icon: Icon(Icons.dashboard_rounded, size: 20)),
          Tab(text: 'Aktivitas', icon: Icon(Icons.history_rounded, size: 20)),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Laporan Bulan Ini',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Responsive Layout
          LayoutBuilder(
            builder: (context, constraints) {
              // Mobile layout
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _buildSholatSummaryCard(),
                    const SizedBox(height: 16),
                    _buildQuranSummaryCard(),
                    const SizedBox(height: 16),
                    _buildTahajudSummaryCard(),
                    const SizedBox(height: 16),
                    _buildPuasaSummaryCard(),
                    const SizedBox(height: 16),
                    _buildZakatSummaryCard(),
                    const SizedBox(height: 100),
                  ],
                );
              }
              // Tablet/Desktop layout
              else {
                return Column(
                  children: [
                    _buildSholatSummaryCard(),
                    const SizedBox(height: 16),
                    _buildQuranSummaryCard(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTahajudSummaryCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPuasaSummaryCard()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildZakatSummaryCard(),
                    const SizedBox(height: 100),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSholatSummaryCard() {
    final stats = extendedData['monthlyStats']['sholat'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.2),
                      AppTheme.primaryBlue.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.mosque_rounded,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sholat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      '${stats['completed']} dari ${stats['total']} sholat',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${((stats['completed'] / stats['total']) * 100).round()}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Tepat Waktu',
                  '${stats['onTime']}',
                  '${((stats['onTime'] / stats['completed']) * 100).round()}%',
                  AppTheme.accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Berjamaah',
                  '${stats['jamaah']}',
                  '${((stats['jamaah'] / stats['completed']) * 100).round()}%',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Terlewat',
                  '${stats['missedDays']}',
                  'hari',
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuranSummaryCard() {
    final stats = extendedData['monthlyStats']['quran'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGreen.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentGreen.withValues(alpha: 0.2),
                      AppTheme.accentGreen.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: AppTheme.accentGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Al-Qur\'an',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      '${stats['pagesRead']} dari ${stats['targetPages']} halaman',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${((stats['pagesRead'] / stats['targetPages']) * 100).round()}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Hari Aktif',
                  '${stats['daysActive']}',
                  'hari',
                  AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Rata-rata',
                  '${stats['averageDaily']}',
                  'hal/hari',
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Favorit',
                  stats['favoriteJuz'],
                  '',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTahajudSummaryCard() {
    final stats = extendedData['monthlyStats']['tahajud'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.nightlight_round,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tahajud',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${stats['completed']}/${stats['total']}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Streak ${stats['currentStreak']} hari',
            style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildPuasaSummaryCard() {
    final stats = extendedData['monthlyStats']['puasa'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.brightness_3_rounded,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Puasa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${stats['completed']}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${stats['sunnah']} sunnah, ${stats['wajib']} wajib',
            style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildZakatSummaryCard() {
    final stats = extendedData['monthlyStats']['zakat'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGreen.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentGreen.withValues(alpha: 0.2),
                      AppTheme.accentGreen.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.volunteer_activism_rounded,
                  color: AppTheme.accentGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Zakat & Sedekah',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      '${stats['given']} kali pemberian',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Rp ${_formatCurrency(stats['amount'])}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (stats['types'] as List<String>).map((type) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (unit.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.download_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(child: Text('Laporan berhasil diexport')),
              ],
            ),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        break;
      case 'settings':
        // Navigate to settings
        break;
      case 'reward':
        _showRewardDialog();
        break;
    }
  }

  void _showRewardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Kirim Reward untuk ${widget.childData['name']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Pesan Semangat',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Icons.card_giftcard_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Reward berhasil dikirim!')),
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
              child: const Text('Kirim', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${difference.inDays} hari lalu';
    }
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    } else {
      return amount.toString();
    }
  }

  Widget _buildActivitiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aktivitas Terbaru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list_rounded, size: 18),
                label: const Text('Filter'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: extendedData['recentActivities'].length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final activity = extendedData['recentActivities'][index];
              return _buildActivityCard(activity);
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat Lebih Banyak'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                foregroundColor: AppTheme.primaryBlue,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    IconData icon;
    Color color;

    switch (activity['type']) {
      case 'sholat':
        icon = Icons.mosque_rounded;
        color = AppTheme.primaryBlue;
        break;
      case 'quran':
        icon = Icons.menu_book_rounded;
        color = AppTheme.accentGreen;
        break;
      case 'tahajud':
        icon = Icons.nightlight_round;
        color = Colors.purple;
        break;
      case 'sedekah':
        icon = Icons.volunteer_activism_rounded;
        color = Colors.orange;
        break;
      default:
        icon = Icons.star_rounded;
        color = AppTheme.primaryBlue;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['activity'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      _getTimeAgo(activity['time']),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildActivityStatus(activity),
            ],
          ),
          const SizedBox(height: 12),
          _buildActivityDetails(activity),
        ],
      ),
    );
  }

  Widget _buildActivityStatus(Map<String, dynamic> activity) {
    String statusText = '';
    Color statusColor = AppTheme.accentGreen;

    switch (activity['type']) {
      case 'sholat':
        statusText = activity['status'];
        statusColor = activity['status'].contains('Tepat')
            ? AppTheme.accentGreen
            : Colors.orange;
        break;
      case 'quran':
        statusText = '${activity['pages']} halaman';
        break;
      case 'tahajud':
        statusText = '${activity['rakaat']} rakaat';
        break;
      case 'sedekah':
        statusText = 'Rp ${_formatCurrency(activity['amount'])}';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildActivityDetails(Map<String, dynamic> activity) {
    List<Widget> details = [];

    switch (activity['type']) {
      case 'sholat':
        details.add(
          _buildDetailItem(
            Icons.location_on_rounded,
            activity['location'],
            AppTheme.onSurfaceVariant,
          ),
        );
        if (activity['jamaah']) {
          details.add(
            _buildDetailItem(
              Icons.group_rounded,
              'Berjamaah',
              AppTheme.accentGreen,
            ),
          );
        }
        break;
      case 'quran':
        details.add(
          _buildDetailItem(
            Icons.bookmark_rounded,
            'Surah ${activity['surah']}',
            AppTheme.onSurfaceVariant,
          ),
        );
        details.add(
          _buildDetailItem(
            Icons.timer_rounded,
            activity['duration'],
            AppTheme.onSurfaceVariant,
          ),
        );
        break;
      case 'tahajud':
        details.add(
          _buildDetailItem(
            Icons.favorite_rounded,
            activity['doa'],
            AppTheme.onSurfaceVariant,
          ),
        );
        break;
      case 'sedekah':
        details.add(
          _buildDetailItem(
            Icons.people_rounded,
            activity['recipient'],
            AppTheme.onSurfaceVariant,
          ),
        );
        break;
    }

    return Wrap(spacing: 16, runSpacing: 8, children: details);
  }

  Widget _buildDetailItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
