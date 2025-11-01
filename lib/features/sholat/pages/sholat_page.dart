import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/format_helper.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';
import 'package:test_flutter/features/sholat/services/alarm_service.dart';
import 'package:test_flutter/features/sholat/sholat_provider.dart';
import 'package:test_flutter/features/sholat/sholat_state.dart';
import 'package:test_flutter/features/sholat/widgets/sholat_card.dart';
import 'package:test_flutter/features/sholat/widgets/sholat_header.dart';

class SholatPage extends ConsumerStatefulWidget {
  const SholatPage({super.key});

  @override
  ConsumerState<SholatPage> createState() => _SholatPageState();
}

class _SholatPageState extends ConsumerState<SholatPage>
    with TickerProviderStateMixin {
  // Controllers
  late TabController _tabController;
  late AnimationController _headerAnimationController;
  late Animation<Color?> _headerColorAnimation;

  // State
  DateTime _selectedDate = DateTime.now();
  bool _isInitialized = false;
  bool _isLoadingProgress = false; // TAMBAH INI

  // Services
  final AlarmService _alarmService = AlarmService();

  // Alarm states
  final Map<String, bool> _wajibAlarms = {
    'Shubuh': false,
    'Dzuhur': false,
    'Ashar': false,
    'Maghrib': false,
    'Isya': false,
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAlarmService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        _isInitialized = true;
        _initializeData();
      }
    });
  }

  void _initializeAlarmService() {
    _alarmService.initialize();

    // TAMBAH: Monitor pending notifications (development only)
    if (kDebugMode) {
      Future.delayed(const Duration(seconds: 2), () async {
        final pending = await _alarmService.getPendingNotifications();
        logger.info('Active alarms: ${pending.length}');

        await _alarmService.debugAlarmStatus();
      });
    }
  }

  void _initializeControllers() {
    _tabController = TabController(length: 2, vsync: this);
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _updateHeaderColorAnimation();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _updateHeaderColorAnimation();
        if (_tabController.index == 0) {
          _headerAnimationController.reverse();
        } else {
          _headerAnimationController.forward();
        }
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _initializeData() async {
    try {
      await ref.read(authProvider.notifier).checkAuthStatus();
      await _loadAlarmStates();

      final currentState = ref.read(sholatProvider);

      if (currentState.sholatList.isEmpty) {
        logger.info('No jadwal data, fetching...');
        await ref.read(sholatProvider.notifier).fetchJadwalSholat();
      } else {
        logger.info(
          'Jadwal already loaded: ${currentState.sholatList.length} items',
        );
      }

      final authState = ref.read(authProvider);
      if (authState['status'] == AuthState.authenticated) {
        await _fetchProgressData();
      }
    } catch (e) {
      logger.severe('Error initializing data: $e');
    }
  }

  Future<void> _fetchProgressData() async {
    await Future.wait([
      ref.read(sholatProvider.notifier).fetchProgressSholatWajibHariIni(),
      ref.read(sholatProvider.notifier).fetchProgressSholatSunnahHariIni(),
    ]);
  }

  Future<void> _loadAlarmStates() async {
    try {
      final states = await _alarmService.getAllAlarmStates();
      if (mounted) {
        setState(() {
          _wajibAlarms['Shubuh'] = states['Shubuh'] ?? false;
          _wajibAlarms['Dzuhur'] = states['Dzuhur'] ?? false;
          _wajibAlarms['Ashar'] = states['Ashar'] ?? false;
          _wajibAlarms['Maghrib'] = states['Maghrib'] ?? false;
          _wajibAlarms['Isya'] = states['Isya'] ?? false;
        });
      }
    } catch (e) {
      logger.warning('Error loading alarm states: $e');
    }
  }

  void _updateAlarmTimes(dynamic jadwal) {
    if (jadwal != null) {
      _alarmService.updatePrayerTimes({
        'Shubuh': jadwal.wajib.shubuh ?? '00:00',
        'Dzuhur': jadwal.wajib.dzuhur ?? '00:00',
        'Ashar': jadwal.wajib.ashar ?? '00:00',
        'Maghrib': jadwal.wajib.maghrib ?? '00:00',
        'Isya': jadwal.wajib.isya ?? '00:00',
      });
    }
  }

  void _updateHeaderColorAnimation() {
    _headerColorAnimation =
        ColorTween(
          begin: AppTheme.primaryBlue,
          end: AppTheme.accentGreen,
        ).animate(
          CurvedAnimation(
            parent: _headerAnimationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  Future<void> _handleRefresh() async {
    try {
      await ref.read(authProvider.notifier).checkAuthStatus();

      await Future.wait([
        ref.read(sholatProvider.notifier).fetchJadwalSholat(forceRefresh: true),
        if (ref.read(authProvider)['status'] == AuthState.authenticated)
          _fetchProgressData(),
      ]);

      if (mounted) {
        showMessageToast(
          context,
          message: 'Data berhasil diperbarui',
          type: ToastType.success,
        );
      }
    } catch (e) {
      logger.severe('Error refreshing data: $e');
      if (mounted) {
        showMessageToast(
          context,
          message: 'Gagal memperbarui data',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _updateLocation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref
          .read(sholatProvider.notifier)
          .fetchJadwalSholat(forceRefresh: true, useCurrentLocation: true);

      if (mounted) {
        Navigator.pop(context);
        showMessageToast(
          context,
          message: 'Lokasi berhasil diperbarui',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showMessageToast(
          context,
          message: 'Gagal memperbarui lokasi',
          type: ToastType.error,
        );
      }
    }
  }

  void _showLoginRequired() {
    showMessageToast(
      context,
      message: 'Anda harus login untuk menggunakan fitur ini',
      type: ToastType.warning,
    );
  }

  /// Modal untuk input detail sholat (baru)
  Future<void> _showSholatDetailModal(
    BuildContext context,
    String sholatName,
    Map<String, dynamic> jadwalData,
    String jenis,
  ) async {
    String status = 'tepat_waktu'; // tepat_waktu, terlambat, tidak_sholat
    bool berjamaah = false;
    String tempat = '';
    String keterangan = '';
    bool isLoading = false;
    final keteranganController = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  (jenis == 'wajib'
                                          ? AppTheme.primaryBlue
                                          : AppTheme.accentGreen)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              jadwalData['icon'] as IconData,
                              color: jenis == 'wajib'
                                  ? AppTheme.primaryBlue
                                  : AppTheme.accentGreen,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sholat $sholatName',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                Text(
                                  jadwalData['time'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Status
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          _buildOptionButton(
                            context: context,
                            label: 'Tepat Waktu',
                            icon: Icons.check_circle_outline_rounded,
                            isSelected: status == 'tepat_waktu',
                            onTap: () =>
                                setModalState(() => status = 'tepat_waktu'),
                            color: jenis == 'wajib'
                                ? AppTheme.primaryBlue
                                : AppTheme.accentGreen,
                          ),
                          const SizedBox(height: 8),
                          _buildOptionButton(
                            context: context,
                            label: 'Terlambat',
                            icon: Icons.access_time_rounded,
                            isSelected: status == 'terlambat',
                            onTap: () =>
                                setModalState(() => status = 'terlambat'),
                            color: jenis == 'wajib'
                                ? AppTheme.primaryBlue
                                : AppTheme.accentGreen,
                          ),
                          const SizedBox(height: 8),
                          _buildOptionButton(
                            context: context,
                            label: 'Tidak Sholat',
                            icon: Icons.cancel_outlined,
                            isSelected: status == 'tidak_sholat',
                            onTap: () =>
                                setModalState(() => status = 'tidak_sholat'),
                            color: jenis == 'wajib'
                                ? AppTheme.primaryBlue
                                : AppTheme.accentGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Berjamaah (hanya untuk wajib)
                      if (jenis == 'wajib') ...[
                        Text(
                          'Berjamaah',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildOptionButton(
                                context: context,
                                label: 'Ya',
                                icon: Icons.groups_rounded,
                                isSelected: berjamaah,
                                onTap: () =>
                                    setModalState(() => berjamaah = true),
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildOptionButton(
                                context: context,
                                label: 'Tidak',
                                icon: Icons.person_rounded,
                                isSelected: !berjamaah,
                                onTap: () =>
                                    setModalState(() => berjamaah = false),
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Tempat
                        Text(
                          'Tempat',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPlaceChip(
                              context: context,
                              label: 'Masjid',
                              icon: Icons.mosque_rounded,
                              isSelected: tempat == 'Masjid',
                              onTap: () =>
                                  setModalState(() => tempat = 'Masjid'),
                              color: AppTheme.primaryBlue,
                            ),
                            _buildPlaceChip(
                              context: context,
                              label: 'Rumah',
                              icon: Icons.home_rounded,
                              isSelected: tempat == 'Rumah',
                              onTap: () =>
                                  setModalState(() => tempat = 'Rumah'),
                              color: AppTheme.primaryBlue,
                            ),
                            _buildPlaceChip(
                              context: context,
                              label: 'Kantor',
                              icon: Icons.business_rounded,
                              isSelected: tempat == 'Kantor',
                              onTap: () =>
                                  setModalState(() => tempat = 'Kantor'),
                              color: AppTheme.primaryBlue,
                            ),
                            _buildPlaceChip(
                              context: context,
                              label: 'Lainnya',
                              icon: Icons.location_on_rounded,
                              isSelected: tempat == 'Lainnya',
                              onTap: () =>
                                  setModalState(() => tempat = 'Lainnya'),
                              color: AppTheme.primaryBlue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Keterangan
                        Text(
                          'Keterangan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: keteranganController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Contoh: Kesiangan, di perjalanan, dll',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.primaryBlue,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) =>
                              setModalState(() => keterangan = value),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Button Simpan dengan loading
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              (jenis == 'wajib' && tempat.isEmpty) || isLoading
                              ? null
                              : () async {
                                  setModalState(
                                    () => isLoading = true,
                                  ); // UPDATED: set loading true

                                  try {
                                    // Simpan ke database via provider
                                    final response = await ref
                                        .read(sholatProvider.notifier)
                                        .addProgressSholat(
                                          jenis: jenis,
                                          sholat: jadwalData['dbKey'] as String,
                                          status: status,
                                          isJamaah: jenis == 'wajib'
                                              ? berjamaah
                                              : null,
                                          lokasi: jenis == 'wajib'
                                              ? tempat
                                              : null,
                                          keterangan: jenis == 'wajib'
                                              ? keterangan
                                              : null,
                                        );

                                    if (response != null && mounted) {
                                      // Tutup modal
                                      Navigator.pop(context, true);
                                      _showCompletionFeedback(sholatName);

                                      // Refresh data progress
                                      await _fetchProgressData();
                                    }
                                  } catch (e) {
                                    logger.severe('Error saving progress: $e');

                                    // Ambil message dari exception
                                    String errorMessage =
                                        'Gagal menyimpan data';

                                    if (e is Exception) {
                                      final errorString = e.toString();
                                      if (errorString.contains('Exception:')) {
                                        errorMessage = errorString
                                            .replaceAll('Exception:', '')
                                            .trim();
                                      }
                                    }

                                    if (mounted) {
                                      showMessageToast(
                                        context,
                                        message: errorMessage,
                                        type: ToastType.error,
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setModalState(
                                        () => isLoading = false,
                                      ); // UPDATED: set loading false
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: jenis == 'wajib'
                                ? AppTheme.primaryBlue
                                : AppTheme.accentGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade500,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    // Refresh data jika berhasil simpan
    if (result == true && mounted) {
      setState(() {});
    }
  }

  /// Widget untuk option button (Ya/Tidak)
  Widget _buildOptionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk place chip (Masjid, Rumah, dll)
  Widget _buildPlaceChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade400,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String name,
    String jenis,
    int? progressId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Hapus Progress'),
              content: Text(
                'Apakah Anda yakin ingin menghapus progress $name?',
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);

                          try {
                            await ref
                                .read(sholatProvider.notifier)
                                .deleteProgressSholat(
                                  id: progressId!,
                                  jenis: jenis,
                                );

                            if (mounted) {
                              Navigator.pop(context);
                              showMessageToast(
                                context,
                                message: 'Progress berhasil dihapus',
                                type: ToastType.success,
                              );
                              await _fetchProgressData();
                            }
                          } catch (e) {
                            if (mounted) {
                              setDialogState(() => isDeleting = false);
                              showMessageToast(
                                context,
                                message: 'Gagal menghapus progress',
                                type: ToastType.error,
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isDeleting
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Hapus'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCompletionFeedback(String prayerName) {
    showMessageToast(
      context,
      message: '✨ Alhamdulillah, $prayerName telah dicatat!',
      type: ToastType.success,
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'tepat_waktu':
        return 'Tepat Waktu';
      case 'terlambat':
        return 'Terlambat';
      case 'tidak_sholat':
        return 'Tidak Sholat';
      default:
        return status;
    }
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimationController.dispose();
    _alarmService.dispose();
    super.dispose();
  }

  // Getters
  bool get _isWajibTab => _tabController.index == 0;

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  // UPDATED: Get progress data based on selected date
  Map<String, dynamic> get _currentProgressData {
    final state = ref.watch(sholatProvider);
    final jenis = _isWajibTab ? 'wajib' : 'sunnah';

    if (_isToday) {
      logger.info('Getting progress for today: $_selectedDate');
      logger.info('Progress Wajib Hari Ini: ${state.progressWajibHariIni}');
      logger.info('Progress Sunnah Hari Ini: ${state.progressSunnahHariIni}');

      if (jenis == 'wajib') {
        // WAJIB: struktur { total: int, statistik: {...}, detail: [...] }
        final progressToday = state.progressWajibHariIni;
        final Map<String, dynamic> formattedProgress = {};

        // Ambil statistik dan detail dari response
        final statistik =
            progressToday['statistik'] as Map<String, dynamic>? ?? {};
        final detail = progressToday['detail'] as List<dynamic>? ?? [];

        // Map nama sholat dari sholat_wajib_id ke key
        final Map<int, String> wajibIdToKey = {
          1: 'shubuh',
          2: 'dzuhur',
          3: 'ashar',
          4: 'maghrib',
          5: 'isya',
        };

        logger.info('=== PARSING PROGRESS WAJIB ===');
        logger.info('Statistik: $statistik');
        logger.info('Detail count: ${detail.length}');

        // Loop detail untuk build progress data dengan informasi lengkap
        for (var item in detail) {
          final sholatWajibId = item['sholat_wajib_id'] as int;
          final sholatKey = wajibIdToKey[sholatWajibId];

          if (sholatKey != null) {
            final progressItem = {
              'id': item['id'],
              'completed': true, // Ada di detail = sudah ada progress
              'status': item['status'] as String? ?? 'tepat_waktu',
              'is_jamaah': item['is_jamaah'] == 1,
              'lokasi': item['lokasi'] as String? ?? '',
              'keterangan': item['keterangan'] as String? ?? '',
            };

            formattedProgress[sholatKey] = progressItem;
            logger.info('$sholatKey: $progressItem');
          }
        }

        // Tambahkan sholat yang belum ada progress (dari statistik)
        statistik.forEach((key, value) {
          if (!formattedProgress.containsKey(key)) {
            formattedProgress[key] = {
              'completed': false, // Belum ada di detail = belum ada progress
              'status': 'tepat_waktu',
              'is_jamaah': false,
              'lokasi': '',
              'keterangan': '',
            };
            logger.info('$key: no progress yet');
          }
        });

        logger.info('=== FORMATTED PROGRESS: $formattedProgress ===');
        return formattedProgress;
      } else {
        // SUNNAH: struktur array [{ sholat_sunnah: {...}, progres: bool }]
        final progressToday =
            state.progressSunnahHariIni as List<dynamic>? ?? [];
        final Map<String, dynamic> formattedProgress = {};

        for (var item in progressToday) {
          final sholatSunnah = item['sholat_sunnah'] as Map<String, dynamic>?;
          final progres = item['progres'] as bool? ?? false;

          if (sholatSunnah != null) {
            final slug = sholatSunnah['slug'] as String;
            final dbKey = slug.replaceAll('-', '_');

            formattedProgress[dbKey] = {
              'completed': progres,
              'status': progres ? 'tepat_waktu' : '',
            };
          }
        }

        return formattedProgress;
      }
    } else {
      final formatter = DateFormat('yyyy-MM-dd');
      final dateKey = formatter.format(_selectedDate);
      final riwayat = jenis == 'wajib'
          ? state.progressWajibRiwayat
          : state.progressSunnahRiwayat;

      // Untuk riwayat, struktur mungkin berbeda
      final riwayatData = (riwayat[dateKey] as Map<String, dynamic>?) ?? {};

      // Jika riwayat juga punya struktur sama dengan hari ini
      if (riwayatData.containsKey('statistik')) {
        final Map<String, dynamic> formattedProgress = {};
        final statistik =
            riwayatData['statistik'] as Map<String, dynamic>? ?? {};
        final detail = riwayatData['detail'] as List<dynamic>? ?? [];

        for (var item in detail) {
          final sholatKey = item['sholat'] as String;
          formattedProgress[sholatKey] = {
            'id': item['id'],
            'completed': statistik[sholatKey] == true,
            'is_on_time': item['is_on_time'] == 1,
            'is_jamaah': item['is_jamaah'] == 1,
            'lokasi': item['lokasi'] as String? ?? '',
          };
        }

        statistik.forEach((key, value) {
          if (!formattedProgress.containsKey(key)) {
            formattedProgress[key] = {
              'completed': value == true,
              'is_on_time': false,
              'is_jamaah': false,
              'lokasi': '',
            };
          }
        });

        return formattedProgress;
      }

      return riwayatData;
    }
  }

  int get _completedCount {
    // UPDATED: Gunakan _currentProgressData agar sesuai dengan tanggal yang dipilih
    final state = ref.watch(sholatProvider);
    final jenis = _isWajibTab ? 'wajib' : 'sunnah';

    if (_isToday) {
      if (jenis == 'wajib') {
        final progressToday = state.progressWajibHariIni;
        final total = progressToday['total'] as int? ?? 0;
        return total;
      } else {
        final progressToday =
            state.progressSunnahHariIni as List<dynamic>? ?? [];
        return progressToday.where((item) => item['progres'] == true).length;
      }
    } else {
      // Untuk tanggal lain, gunakan _currentProgressData
      return _currentProgressData.values
          .where((v) => v is Map && (v['completed'] == true))
          .length;
    }
  }

  int get _totalCount {
    if (_isWajibTab) {
      return 5;
    } else {
      // Untuk sunnah, ambil dari state
      final state = ref.watch(sholatProvider);
      if (_isToday) {
        final progressToday =
            state.progressSunnahHariIni as List<dynamic>? ?? [];
        return progressToday.length;
      }
      return 10; // default
    }
  }

  String get _formattedDate {
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
    return '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';
  }

  String get _dayName {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days[_selectedDate.weekday - 1];
  }

  String get _hijriDate => FormatHelper.getHijriDate(_selectedDate);

  // Responsive helpers
  double _px(BuildContext c, double base) {
    if (ResponsiveHelper.isSmallScreen(c)) return base;
    if (ResponsiveHelper.isMediumScreen(c)) return base * 1.1;
    if (ResponsiveHelper.isLargeScreen(c)) return base * 1.2;
    return base * 1.3;
  }

  double _ts(BuildContext c, double base) =>
      ResponsiveHelper.adaptiveTextSize(c, base * 1.1);

  EdgeInsets _hpad(BuildContext c) => EdgeInsets.symmetric(
    horizontal: ResponsiveHelper.getResponsivePadding(c).left,
  );

  double _maxWidth(BuildContext c) {
    if (ResponsiveHelper.isExtraLargeScreen(c)) return 980;
    if (ResponsiveHelper.isLargeScreen(c)) return 860;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final sholatState = ref.watch(sholatProvider);
    final jadwal = ref
        .read(sholatProvider.notifier)
        .getJadwalByDate(_selectedDate);

    if (jadwal != null) {
      _updateAlarmTimes(jadwal);
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.primaryBlue,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _maxWidth(context)),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _headerAnimationController,
                    builder: (context, child) {
                      return SholatHeader(
                        sholatState: sholatState,
                        selectedDate: _selectedDate,
                        formattedDate: _formattedDate,
                        dayName: _dayName,
                        hijriDate: _hijriDate,
                        isToday: _isToday,
                        completedCount: _completedCount,
                        totalCount: _totalCount,
                        isWajibTab: _isWajibTab,
                        jadwal: jadwal,
                        progressColor:
                            _headerColorAnimation.value ?? AppTheme.primaryBlue,
                        onPreviousDay: () async {
                          setState(() {
                            _selectedDate = _selectedDate.subtract(
                              const Duration(days: 1),
                            );
                          });
                          final authState = ref.read(authProvider);
                          if (authState['status'] == AuthState.authenticated) {
                            await _fetchProgressData();
                          }
                        },
                        onNextDay: () async {
                          setState(() {
                            _selectedDate = _selectedDate.add(
                              const Duration(days: 1),
                            );
                          });
                          final authState = ref.read(authProvider);
                          if (authState['status'] == AuthState.authenticated) {
                            await _fetchProgressData();
                          }
                        },
                        onLocationUpdate: _updateLocation,
                      );
                    },
                  ),
                  if (sholatState.status == SholatStatus.loading ||
                      _isLoadingProgress)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (sholatState.status == SholatStatus.error)
                    _buildErrorState(sholatState)
                  else
                    Expanded(child: _buildPrayerTimesList(sholatState, jadwal)),
                ],
              ),
            ),
          ),
        ),
      ),
      // TAMBAH: FAB untuk test alarm (development only)
      floatingActionButton: kDebugMode
          ? FloatingActionButton.extended(
              onPressed: () async {
                await _alarmService.playAdzanTest();
                showMessageToast(
                  context,
                  message: 'Test alarm dimulai. Cek notifikasi!',
                  type: ToastType.info,
                );
              },
              icon: const Icon(Icons.alarm),
              label: const Text('Test Alarm'),
              backgroundColor: AppTheme.primaryBlue,
            )
          : null,
    );
  }

  Widget _buildErrorState(SholatState sholatState) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              sholatState.message ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(sholatProvider.notifier)
                  .fetchJadwalSholat(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesList(SholatState sholatState, dynamic jadwal) {
    final small = ResponsiveHelper.isSmallScreen(context);

    return Column(
      children: [
        _buildTabs(small),
        SizedBox(height: _px(context, 16)),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildWajibTab(jadwal, small),
              _buildSunnahTab(jadwal, small),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(bool small) {
    return Container(
      margin: _hpad(context).add(EdgeInsets.only(top: _px(context, 12))),
      padding: EdgeInsets.all(_px(context, 4)),
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
          fontSize: _ts(context, small ? 13 : 14),
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Wajib'),
          Tab(text: 'Sunnah'),
        ],
      ),
    );
  }

  // UPDATED: Test Alarm Card
  Widget _buildTestAlarmCard() {
    // State untuk test alarm
    bool isTestAlarmActive = false;
    String testTime = '';

    return StatefulBuilder(
      builder: (context, setTestState) {
        return Container(
          margin: EdgeInsets.only(bottom: _px(context, 12)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                // Get time 1 minute from now
                final now = DateTime.now();
                final testDateTime = now.add(const Duration(minutes: 1));
                testTime =
                    '${testDateTime.hour.toString().padLeft(2, '0')}:${testDateTime.minute.toString().padLeft(2, '0')}';

                final newState = !isTestAlarmActive;

                try {
                  // Set alarm dengan waktu +1 menit
                  await _alarmService.setAlarm('Test', newState, testTime);

                  // Verify
                  final isEnabled = await _alarmService.isAlarmEnabled('Test');

                  setTestState(() {
                    isTestAlarmActive = newState;
                  });

                  if (mounted) {
                    showMessageToast(
                      context,
                      message: newState
                          ? '🧪 Test alarm set untuk $testTime (1 menit lagi)'
                          : '🧪 Test alarm dimatikan',
                      type: ToastType.success,
                    );
                  }

                  logger.info(
                    'Test alarm ${newState ? "enabled" : "disabled"} for $testTime',
                  );
                  logger.info('Verification: $isEnabled');

                  // Show debug info
                  await _alarmService.debugAlarmStatus();
                } catch (e) {
                  logger.severe('Error setting test alarm: $e');
                  if (mounted) {
                    showMessageToast(
                      context,
                      message: 'Gagal set test alarm: $e',
                      type: ToastType.error,
                    );
                  }
                }
              },
              child: Padding(
                padding: EdgeInsets.all(_px(context, 16)),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      padding: EdgeInsets.all(_px(context, 12)),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.science_rounded,
                        color: Colors.white,
                        size: _px(context, 28),
                      ),
                    ),
                    SizedBox(width: _px(context, 16)),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '🧪 TEST ALARM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _ts(context, 16),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: _px(context, 8)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: _px(context, 8),
                                  vertical: _px(context, 4),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'DEBUG',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _ts(context, 10),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: _px(context, 4)),
                          Text(
                            testTime.isEmpty
                                ? 'Tap untuk set alarm (+1 menit)'
                                : 'Alarm: $testTime',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: _ts(context, 14),
                            ),
                          ),
                          SizedBox(height: _px(context, 4)),
                          Text(
                            'Akan bunyi 1 menit dari sekarang',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: _ts(context, 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Alarm Toggle
                    Container(
                      width: _px(context, 50),
                      height: _px(context, 30),
                      decoration: BoxDecoration(
                        color: isTestAlarmActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 200),
                            left: isTestAlarmActive
                                ? _px(context, 22)
                                : _px(context, 2),
                            top: _px(context, 2),
                            child: Container(
                              width: _px(context, 26),
                              height: _px(context, 26),
                              decoration: BoxDecoration(
                                color: isTestAlarmActive
                                    ? Colors.orange.shade600
                                    : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.alarm,
                                color: isTestAlarmActive
                                    ? Colors.white
                                    : Colors.orange.shade600,
                                size: _px(context, 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWajibTab(dynamic jadwal, bool small) {
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState['status'] == AuthState.authenticated;
    final progressData = _currentProgressData;

    final wajibList = {
      'Shubuh': {
        'time': jadwal?.wajib.shubuh ?? '--:--',
        'icon': Icons.wb_sunny_outlined,
        'dbKey': 'shubuh',
      },
      'Dzuhur': {
        'time': jadwal?.wajib.dzuhur ?? '--:--',
        'icon': Icons.wb_sunny,
        'dbKey': 'dzuhur',
      },
      'Ashar': {
        'time': jadwal?.wajib.ashar ?? '--:--',
        'icon': Icons.wb_cloudy,
        'dbKey': 'ashar',
      },
      'Maghrib': {
        'time': jadwal?.wajib.maghrib ?? '--:--',
        'icon': Icons.wb_twilight,
        'dbKey': 'maghrib',
      },
      'Isya': {
        'time': jadwal?.wajib.isya ?? '--:--',
        'icon': Icons.nights_stay,
        'dbKey': 'isya',
      },
    };

    return ListView.builder(
      padding: _hpad(context).add(EdgeInsets.only(bottom: _px(context, 16))),
      physics: const BouncingScrollPhysics(),
      // UPDATED: Tambah 1 untuk test card di debug mode
      itemCount: kDebugMode ? wajibList.length + 1 : wajibList.length,
      itemBuilder: (_, i) {
        // UPDATED: Test card di posisi pertama (debug mode only)
        if (kDebugMode && i == 0) {
          return _buildTestAlarmCard();
        }

        // UPDATED: Adjust index jika ada test card
        final actualIndex = kDebugMode ? i - 1 : i;
        final name = wajibList.keys.elementAt(actualIndex);
        final jadwalData = wajibList[name]!;
        final dbKey = jadwalData['dbKey'] as String;
        final time = jadwalData['time'] as String;
        final sholatProgress = progressData[dbKey] as Map<String, dynamic>?;
        final isCompleted = sholatProgress?['completed'] as bool? ?? false;

        logger.info(
          'Sholat: $name, dbKey: $dbKey, isCompleted: $isCompleted, progress: $sholatProgress',
        );

        return SholatCard(
          name: name,
          jadwalData: jadwalData,
          isCompleted: isCompleted,
          status: sholatProgress?['status'] as String? ?? 'tepat_waktu',
          isJamaah: sholatProgress?['is_jamaah'] as bool? ?? false,
          lokasi: sholatProgress?['lokasi'] as String? ?? '',
          jenis: 'wajib',
          canTap: jadwal != null && time != '--:--',
          isAlarmActive: _wajibAlarms[name] ?? false,
          onTap: () async {
            if (!isLoggedIn) {
              _showLoginRequired();
              return;
            }

            // Jika bukan hari ini, tampilkan warning
            if (!_isToday && !isCompleted) {
              showMessageToast(
                context,
                message: 'Hanya bisa menambah progress untuk hari ini',
                type: ToastType.warning,
              );
              return;
            }

            // UPDATED: Logic untuk modal
            if (isCompleted) {
              // Jika sudah ada progress, tampilkan modal detail dengan opsi hapus
              _showDetailWithDeleteOption(
                context,
                name,
                jadwalData,
                'wajib',
                sholatProgress,
                sholatProgress?['id'] as int?,
              );
            } else {
              // Jika belum ada progress dan hari ini, tampilkan modal input
              if (_isToday) {
                await _showSholatDetailModal(
                  context,
                  name,
                  jadwalData,
                  'wajib',
                );
              } else {
                showMessageToast(
                  context,
                  message: 'Tidak ada data progress untuk tanggal ini',
                  type: ToastType.info,
                );
              }
            }
          },
          onAlarmTap: () async {
            if (!isLoggedIn) {
              _showLoginRequired();
              return;
            }

            final newState = !(_wajibAlarms[name] ?? false);

            if (time == '--:--') {
              showMessageToast(
                context,
                message: 'Waktu sholat belum tersedia',
                type: ToastType.warning,
              );
              return;
            }

            try {
              await _alarmService.setAlarm(name, newState, time);

              final isEnabled = await _alarmService.isAlarmEnabled(name);
              logger.info('Alarm verification for $name: $isEnabled');

              if (mounted) {
                setState(() {
                  _wajibAlarms[name] = newState;
                });

                showMessageToast(
                  context,
                  message: newState
                      ? 'Alarm $name diaktifkan pada $time'
                      : 'Alarm $name dinonaktifkan',
                  type: ToastType.success,
                );
              }
            } catch (e) {
              if (mounted) {
                showMessageToast(
                  context,
                  message: 'Gagal mengatur alarm: $e',
                  type: ToastType.error,
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildSunnahTab(dynamic jadwal, bool small) {
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState['status'] == AuthState.authenticated;
    final progressData = _currentProgressData;

    // Ambil list sunnah dari jadwal (dari API)
    final sunnahList = jadwal?.sunnah as List<dynamic>? ?? [];

    // Map icon berdasarkan slug
    IconData _getIconBySlug(String slug) {
      switch (slug.toLowerCase()) {
        case 'tahajud':
          return Icons.nightlight_round;
        case 'witir':
          return Icons.nights_stay;
        case 'dhuha':
          return Icons.wb_sunny;
        case 'qabliyah-subuh':
          return Icons.wb_twilight;
        case 'qabliyah-dzuhur':
          return Icons.wb_sunny_outlined;
        case 'badiyah-dzuhur':
          return Icons.wb_sunny;
        case 'qabliyah-ashar':
          return Icons.wb_cloudy_outlined;
        case 'badiyah-maghrib':
          return Icons.wb_twilight;
        case 'qabliyah-isya':
          return Icons.nights_stay_outlined;
        case 'badiyah-isya':
          return Icons.nights_stay;
        case 'tarawih':
          return Icons.mosque_rounded;
        case 'istikharah':
          return Icons.self_improvement_rounded;
        default:
          return Icons.place;
      }
    }

    // Jika tidak ada data sunnah
    if (sunnahList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Data sholat sunnah belum tersedia',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: _hpad(context).add(EdgeInsets.only(bottom: _px(context, 16))),
      physics: const BouncingScrollPhysics(),
      itemCount: sunnahList.length,
      itemBuilder: (_, i) {
        final sunnahItem = sunnahList[i];
        final name = sunnahItem.nama as String;
        final slug = sunnahItem.slug as String;
        final deskripsi = sunnahItem.deskripsi as String;

        // Konversi slug ke dbKey format (replace - dengan _)
        final dbKey = slug.replaceAll('-', '_');

        // Build jadwalData dengan format yang sesuai
        final jadwalData = {
          'time': deskripsi,
          'icon': _getIconBySlug(slug),
          'dbKey': dbKey,
        };

        final sholatProgress = progressData[dbKey] as Map<String, dynamic>?;
        final isCompleted = sholatProgress?['completed'] as bool? ?? false;

        return SholatCard(
          name: name,
          jadwalData: jadwalData,
          isCompleted: isCompleted,
          status: sholatProgress?['status'] as String? ?? 'tepat_waktu',
          isJamaah: false, // sunnah tidak ada is_jamaah
          lokasi: '', // sunnah tidak ada lokasi
          jenis: 'sunnah',
          canTap: true,
          isAlarmActive: false,
          onTap: () async {
            if (!isLoggedIn) {
              _showLoginRequired();
              return;
            }

            // Jika bukan hari ini, tampilkan warning
            if (!_isToday && !isCompleted) {
              showMessageToast(
                context,
                message: 'Hanya bisa menambah progress untuk hari ini',
                type: ToastType.warning,
              );
              return;
            }

            // UPDATED: Logic untuk modal
            if (isCompleted) {
              // Jika sudah ada progress, tampilkan modal detail dengan opsi hapus
              _showDetailWithDeleteOption(
                context,
                name,
                jadwalData,
                'sunnah',
                sholatProgress,
                sholatProgress?['id'] as int?,
              );
            } else {
              // Jika belum ada progress dan hari ini, tampilkan modal input
              if (_isToday) {
                await _showSholatDetailModal(
                  context,
                  name,
                  jadwalData,
                  'sunnah',
                );
              } else {
                showMessageToast(
                  context,
                  message: 'Tidak ada data progress untuk tanggal ini',
                  type: ToastType.info,
                );
              }
            }
          },
        );
      },
    );
  }

  // ...existing code...

  /// Modal untuk detail sholat dengan opsi hapus (UPDATED)
  void _showDetailWithDeleteOption(
    BuildContext context,
    String name,
    Map<String, dynamic> jadwalData,
    String jenis,
    Map<String, dynamic>? sholatProgress,
    int? progressId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header dengan icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              (jenis == 'wajib'
                                      ? AppTheme.primaryBlue
                                      : AppTheme.accentGreen)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          jadwalData['icon'] as IconData,
                          color: jenis == 'wajib'
                              ? AppTheme.primaryBlue
                              : AppTheme.accentGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sholat $name',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              jadwalData['time'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge "Completed"
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Selesai',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Detail Progress
                  if (sholatProgress != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          // Status
                          _buildInfoRow(
                            'Status',
                            _formatStatus(
                              sholatProgress['status'] as String? ?? '',
                            ),
                            Icons.info_outline,
                          ),
                          if (jenis == 'wajib') ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Berjamaah',
                              sholatProgress['is_jamaah'] == true
                                  ? 'Ya'
                                  : 'Tidak',
                              Icons.groups,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Lokasi',
                              sholatProgress['lokasi'] as String? ?? '-',
                              Icons.location_on,
                            ),
                            if ((sholatProgress['keterangan'] as String? ?? '')
                                .isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Keterangan',
                                sholatProgress['keterangan'] as String? ?? '-',
                                Icons.note,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Button Hapus (hanya untuk hari ini)
                  if (_isToday)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(
                            context,
                            name,
                            jenis,
                            progressId,
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus Progress'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else
                    // Info jika bukan hari ini
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Progress hanya bisa dihapus untuk hari ini',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ...existing code...
