import 'package:flutter/material.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/core/utils/format_helper.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/sholat/models/sholat/sholat.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';
import 'package:test_flutter/features/sholat/services/alarm_service.dart';
import 'package:test_flutter/features/sholat/providers/sholat_provider.dart';
import 'package:test_flutter/features/sholat/states/sholat_state.dart';
import 'package:test_flutter/features/sholat/widgets/sholat_calendar_modal.dart';

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
  bool _isLoadingProgress = false;

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

  // ---------- Responsive utils (berbasis ResponsiveHelper) ----------
  double _scale(BuildContext c) {
    if (ResponsiveHelper.isSmallScreen(c)) return .9;
    if (ResponsiveHelper.isMediumScreen(c)) return 1.0;
    if (ResponsiveHelper.isLargeScreen(c)) return 1.1;
    return 1.2; // extra large
  }

  double _px(BuildContext c, double base) => base * _scale(c);

  double _ts(BuildContext c, double base) =>
      ResponsiveHelper.adaptiveTextSize(c, base);

  EdgeInsets _hpad(BuildContext c) => EdgeInsets.symmetric(
    horizontal: ResponsiveHelper.getResponsivePadding(c).left,
  );

  double _maxWidth(BuildContext c) {
    if (ResponsiveHelper.isExtraLargeScreen(c)) return 980;
    if (ResponsiveHelper.isLargeScreen(c)) return 860;
    return double.infinity; // phone
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAlarmService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        _isInitialized = true;
        _initializeData();
        _listenToAuthChanges();
      }
    });
  }

  void _listenToAuthChanges() {
    ref.listen(authProvider, (previous, next) {
      final wasAuthenticated = previous?['status'] == AuthState.authenticated;
      final isNowAuthenticated = next['status'] == AuthState.authenticated;

      if (wasAuthenticated && !isNowAuthenticated) {
        logger.info('🔓 User logged out, clearing progress data from state');
        ref.read(sholatProvider.notifier).clearProgressData();
      }
    });
  }

  void _initializeAlarmService() {
    _alarmService.initialize();

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

  void _showCalendar() async {
    final authState = ref.read(authProvider);
    if (authState['status'] != AuthState.authenticated) {
      _showLoginRequired();
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SholatCalendarModal(
        initialDate: _selectedDate,
        onDateSelected: (date) async {
          setState(() {
            _selectedDate = date;
          });
          await _fetchProgressData();
        },
      ),
    );
  }

  Future<void> _showSholatDetailModal(
    BuildContext context,
    String sholatName,
    Map<String, dynamic> jadwalData,
    String jenis,
  ) async {
    String? status;
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
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      if (status == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '* Pilih salah satu status',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
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
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              status == null ||
                                  (jenis == 'wajib' && tempat.isEmpty) ||
                                  isLoading
                              ? null
                              : () async {
                                  setModalState(() => isLoading = true);

                                  try {
                                    final response = await ref
                                        .read(sholatProvider.notifier)
                                        .addProgressSholat(
                                          jenis: jenis,
                                          sholat: jadwalData['dbKey'] as String,
                                          status: status!,
                                          isJamaah: jenis == 'wajib'
                                              ? berjamaah
                                              : null,
                                          lokasi: jenis == 'wajib'
                                              ? tempat
                                              : null,
                                          keterangan: jenis == 'wajib'
                                              ? keterangan
                                              : null,
                                          sunnahId: jenis == 'sunnah'
                                              ? jadwalData['sunnahId'] as int?
                                              : null,
                                        );

                                    if (response != null && mounted) {
                                      Navigator.pop(context, true);
                                      await _fetchProgressData();
                                      if (mounted) {
                                        setState(() {});
                                      }
                                      _showCompletionFeedback(sholatName);
                                    }
                                  } catch (e) {
                                    logger.severe('Error saving progress: $e');

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
                                      setModalState(() => isLoading = false);
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

    if (result == true && mounted) {
      setState(() {});
    }
  }

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
                              await _fetchProgressData();
                              if (mounted) {
                                setState(() {});
                              }
                              showMessageToast(
                                context,
                                message: 'Progress berhasil dihapus',
                                type: ToastType.success,
                              );
                            }
                          } catch (e) {
                            logger.severe('Error deleting progress: $e');
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
    final feedbacks = [
      'Alhamdulillah! Sholat $prayerName tercatat',
      'Barakallahu fiik! Semoga diterima',
      'Masya Allah, istiqomah terus ya',
      'Semoga berkah sholat ${prayerName}nya',
      'Subhanallah, terus semangat beribadah',
    ];
    final msg = feedbacks[DateTime.now().millisecond % feedbacks.length];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(_px(context, 6)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: _px(context, 20),
              ),
            ),
            SizedBox(width: _px(context, 12)),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: _ts(context, 14),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
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

  bool get _isWajibTab => _tabController.index == 0;

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Map<String, dynamic> get _currentProgressData {
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState['status'] == AuthState.authenticated;

    if (!isLoggedIn) {
      return {};
    }

    final state = ref.watch(sholatProvider);
    final jenis = _isWajibTab ? 'wajib' : 'sunnah';

    if (_isToday) {
      logger.info('Getting progress for today: $_selectedDate');
      logger.info('Progress Wajib Hari Ini: ${state.progressWajibHariIni}');
      logger.info('Progress Sunnah Hari Ini: ${state.progressSunnahHariIni}');

      if (jenis == 'wajib') {
        final progressToday = state.progressWajibHariIni;
        final Map<String, dynamic> formattedProgress = {};

        final statistik =
            progressToday['statistik'] as Map<String, dynamic>? ?? {};
        final detail = progressToday['detail'] as List<dynamic>? ?? [];

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

        for (var item in detail) {
          final sholatWajibId = item['sholat_wajib_id'] as int;
          final sholatKey = wajibIdToKey[sholatWajibId];

          if (sholatKey != null) {
            final progressItem = {
              'id': item['id'],
              'completed': true,
              'status': item['status'] as String? ?? 'tepat_waktu',
              'is_jamaah': item['is_jamaah'] == 1,
              'lokasi': item['lokasi'] as String? ?? '',
              'keterangan': item['keterangan'] as String? ?? '',
            };

            formattedProgress[sholatKey] = progressItem;
            logger.info('$sholatKey: $progressItem');
          }
        }

        statistik.forEach((key, value) {
          if (!formattedProgress.containsKey(key)) {
            formattedProgress[key] = {
              'completed': false,
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
        final progressToday =
            state.progressSunnahHariIni as List<dynamic>? ?? [];
        final Map<String, dynamic> formattedProgress = {};

        logger.info('=== PARSING PROGRESS SUNNAH ===');
        logger.info('Progress data type: ${progressToday.runtimeType}');
        logger.info('Progress count: ${progressToday.length}');
        logger.info('Full progress data: $progressToday');

        for (var item in progressToday) {
          final sholatSunnah = item['sholat_sunnah'] as Map<String, dynamic>?;
          final progres = item['progres'] as bool? ?? false;

          logger.info('=== Processing item ===');
          logger.info('Item keys: ${item.keys.toList()}');
          logger.info('Item full data: $item');

          if (sholatSunnah != null) {
            final slug = sholatSunnah['slug'] as String;
            final dbKey = slug.replaceAll('-', '-');

            final progressId = item['id'] as int?;
            final progressStatus = item['status'] as String? ?? '';

            formattedProgress[dbKey] = {
              'id': progressId,
              'completed': progres,
              'status': progressStatus.isNotEmpty
                  ? progressStatus
                  : (progres ? 'tepat_waktu' : ''),
            };
            logger.info(
              '$dbKey: progres=$progres, id=$progressId, status=$progressStatus',
            );
          }
        }

        logger.info('=== FORMATTED SUNNAH PROGRESS: $formattedProgress ===');
        return formattedProgress;
      }
    } else {
      final formatter = DateFormat('yyyy-MM-dd');
      final dateKey = formatter.format(_selectedDate);

      logger.info('=== GETTING RIWAYAT DATA ===');
      logger.info('Date: $dateKey, Jenis: $jenis');

      if (jenis == 'wajib') {
        final riwayat = state.progressWajibRiwayat;
        final riwayatData = riwayat[dateKey];

        logger.info('Wajib riwayat data type: ${riwayatData.runtimeType}');
        logger.info('Wajib riwayat data: $riwayatData');

        final Map<String, dynamic> formattedProgress = {};

        final Map<int, String> wajibIdToKey = {
          1: 'shubuh',
          2: 'dzuhur',
          3: 'ashar',
          4: 'maghrib',
          5: 'isya',
        };

        if (riwayatData is List) {
          logger.info('=== PARSING WAJIB RIWAYAT (LIST) ===');
          logger.info('Progress count: ${riwayatData.length}');

          for (var item in riwayatData) {
            final sholatWajibId = item['sholat_wajib_id'] as int?;
            final sholatKey = sholatWajibId != null
                ? wajibIdToKey[sholatWajibId]
                : null;

            if (sholatKey != null) {
              formattedProgress[sholatKey] = {
                'id': item['id'],
                'completed': true,
                'status': item['status'] as String? ?? 'tepat_waktu',
                'is_jamaah': item['is_jamaah'] == 1,
                'lokasi': item['lokasi'] as String? ?? '',
                'keterangan': item['keterangan'] as String? ?? '',
              };
              logger.info('$sholatKey: ${formattedProgress[sholatKey]}');
            }
          }

          wajibIdToKey.forEach((id, key) {
            if (!formattedProgress.containsKey(key)) {
              formattedProgress[key] = {
                'completed': false,
                'status': 'tepat_waktu',
                'is_jamaah': false,
                'lokasi': '',
                'keterangan': '',
              };
              logger.info('$key: no progress');
            }
          });

          logger.info('=== FORMATTED WAJIB RIWAYAT: $formattedProgress ===');
          return formattedProgress;
        } else if (riwayatData is Map<String, dynamic>) {
          logger.info('=== PARSING WAJIB RIWAYAT (MAP) ===');

          if (riwayatData.containsKey('statistik')) {
            final statistik =
                riwayatData['statistik'] as Map<String, dynamic>? ?? {};
            final detail = riwayatData['detail'] as List<dynamic>? ?? [];

            logger.info('Statistik: $statistik');
            logger.info('Detail count: ${detail.length}');

            for (var item in detail) {
              final sholatWajibId = item['sholat_wajib_id'] as int?;
              final sholatKey = sholatWajibId != null
                  ? wajibIdToKey[sholatWajibId]
                  : null;

              if (sholatKey != null) {
                formattedProgress[sholatKey] = {
                  'id': item['id'],
                  'completed': true,
                  'status': item['status'] as String? ?? 'tepat_waktu',
                  'is_jamaah': item['is_jamaah'] == 1,
                  'lokasi': item['lokasi'] as String? ?? '',
                  'keterangan': item['keterangan'] as String? ?? '',
                };
                logger.info('$sholatKey: ${formattedProgress[sholatKey]}');
              }
            }

            statistik.forEach((key, value) {
              if (!formattedProgress.containsKey(key)) {
                formattedProgress[key] = {
                  'completed': false,
                  'status': 'tepat_waktu',
                  'is_jamaah': false,
                  'lokasi': '',
                  'keterangan': '',
                };
                logger.info('$key: no progress');
              }
            });
          } else {
            riwayatData.forEach((key, value) {
              if (value is bool) {
                formattedProgress[key] = {
                  'completed': value,
                  'status': 'tepat_waktu',
                  'is_jamaah': false,
                  'lokasi': '',
                  'keterangan': '',
                };
              } else if (value is Map) {
                formattedProgress[key] = value;
              }
            });
          }

          logger.info('=== FORMATTED WAJIB RIWAYAT: $formattedProgress ===');
          return formattedProgress;
        }

        wajibIdToKey.forEach((id, key) {
          formattedProgress[key] = {
            'completed': false,
            'status': 'tepat_waktu',
            'is_jamaah': false,
            'lokasi': '',
            'keterangan': '',
          };
        });

        return formattedProgress;
      } else {
        final riwayat = state.progressSunnahRiwayat;
        final riwayatData = riwayat[dateKey];

        logger.info('Sunnah riwayat data type: ${riwayatData.runtimeType}');
        logger.info('Sunnah riwayat data: $riwayatData');

        final Map<String, dynamic> formattedProgress = {};

        if (riwayatData is List) {
          logger.info('=== PARSING SUNNAH RIWAYAT (LIST) ===');
          logger.info('Progress count: ${riwayatData.length}');

          for (var item in riwayatData) {
            final sholatSunnahId = item['sholat_sunnah_id'] as int?;

            if (sholatSunnahId != null) {
              final jadwal = ref
                  .read(sholatProvider.notifier)
                  .getJadwalByDate(_selectedDate);
              final sunnahList = jadwal?.sunnah ?? [];

              final sunnahItem = sunnahList.firstWhere(
                (s) => s.id == sholatSunnahId,
                orElse: () =>
                    SholatSunnah(id: 0, nama: '', slug: '', deskripsi: ''),
              );

              if (sunnahItem.id != 0) {
                final dbKey = sunnahItem.slug.replaceAll('-', '-');

                formattedProgress[dbKey] = {
                  'id': item['id'],
                  'sholat_sunnah_id': sholatSunnahId,
                  'completed': true,
                  'status': item['status'] as String? ?? 'tepat_waktu',
                };
                logger.info(
                  '$dbKey: completed=true, id=${item['id']}, sholat_sunnah_id=$sholatSunnahId, status=${item['status']}',
                );
              }
            }
          }
        } else if (riwayatData is Map<String, dynamic>) {
          logger.info('=== PARSING SUNNAH RIWAYAT (MAP) ===');
          return riwayatData;
        }

        logger.info('=== FORMATTED SUNNAH RIWAYAT: $formattedProgress ===');
        return formattedProgress;
      }
    }
  }

  int get _completedCount {
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState['status'] == AuthState.authenticated;

    if (!isLoggedIn) {
      return 0;
    }

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
      final formatter = DateFormat('yyyy-MM-dd');
      final dateKey = formatter.format(_selectedDate);

      if (jenis == 'wajib') {
        final riwayat = state.progressWajibRiwayat;
        final riwayatData = riwayat[dateKey];

        if (riwayatData is List) {
          return riwayatData.length;
        } else if (riwayatData is Map<String, dynamic>) {
          if (riwayatData.containsKey('total')) {
            return riwayatData['total'] as int? ?? 0;
          }

          if (riwayatData.containsKey('detail')) {
            final detail = riwayatData['detail'] as List<dynamic>? ?? [];
            return detail.length;
          }

          return _currentProgressData.values
              .where((v) => v is Map && (v['completed'] == true))
              .length;
        } else {
          return _currentProgressData.values
              .where((v) => v is Map && (v['completed'] == true))
              .length;
        }
      } else {
        final riwayat = state.progressSunnahRiwayat;
        final riwayatData = riwayat[dateKey];

        if (riwayatData is List) {
          return riwayatData.where((item) => item['progres'] == true).length;
        } else {
          return _currentProgressData.values
              .where((v) => v is Map && (v['completed'] == true))
              .length;
        }
      }
    }
  }

  int get _totalCount {
    if (_isWajibTab) {
      return 5;
    } else {
      final jadwal = ref
          .read(sholatProvider.notifier)
          .getJadwalByDate(_selectedDate);
      final sunnahList = jadwal?.sunnah ?? [];
      return sunnahList.length;
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

  bool _isPrayerTimeArrived(String prayerName, dynamic jadwal) {
    if (jadwal == null) return false;
    if (!_isToday) return true;

    final now = TimeOfDay.now();
    String? prayerTimeStr;

    switch (prayerName) {
      case 'Shubuh':
        prayerTimeStr = jadwal.wajib.shubuh;
        break;
      case 'Dzuhur':
        prayerTimeStr = jadwal.wajib.dzuhur;
        break;
      case 'Ashar':
        prayerTimeStr = jadwal.wajib.ashar;
        break;
      case 'Maghrib':
        prayerTimeStr = jadwal.wajib.maghrib;
        break;
      case 'Isya':
        prayerTimeStr = jadwal.wajib.isya;
        break;
    }

    if (prayerTimeStr == null || prayerTimeStr == '--:--') return false;

    final prayerTime = _parseTime(prayerTimeStr);
    return !_isTimeBefore(now, prayerTime);
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      logger.warning('Error parsing time: $timeStr - $e');
    }
    return const TimeOfDay(hour: 0, minute: 0);
  }

  bool _isTimeBefore(TimeOfDay current, TimeOfDay target) {
    if (current.hour < target.hour) {
      return true;
    } else if (current.hour == target.hour) {
      return current.minute < target.minute;
    }
    return false;
  }

  Map<String, dynamic> _getCurrentPrayerInfo(dynamic jadwal) {
    if (jadwal == null) {
      return {
        'name': 'Dzuhur',
        'time': '11:37',
        'icon': Icons.wb_sunny,
        'color': Colors.amber,
        'nextName': 'Dzuhur',
        'nextTime': '2j 25m',
      };
    }

    // Pakai localTime dari state kalau ada
    final sholatState = ref.watch(sholatProvider);
    final localTime = sholatState.localTime;

    TimeOfDay now;
    if (localTime != null && localTime.isNotEmpty) {
      // format: "HH:mm:ss"
      now = _parseTime(localTime);
    } else {
      now = TimeOfDay.now();
    }

    final prayers = [
      {
        'name': 'Shubuh',
        'time': jadwal.wajib.shubuh ?? '00:00',
        'icon': Icons.wb_sunny_outlined,
        'color': Colors.orange,
      },
      {
        'name': 'Dzuhur',
        'time': jadwal.wajib.dzuhur ?? '00:00',
        'icon': Icons.wb_sunny,
        'color': Colors.amber,
      },
      {
        'name': 'Ashar',
        'time': jadwal.wajib.ashar ?? '00:00',
        'icon': Icons.wb_cloudy,
        'color': Colors.blue,
      },
      {
        'name': 'Maghrib',
        'time': jadwal.wajib.maghrib ?? '00:00',
        'icon': Icons.wb_twilight,
        'color': Colors.deepOrange,
      },
      {
        'name': 'Isya',
        'time': jadwal.wajib.isya ?? '00:00',
        'icon': Icons.nights_stay,
        'color': Colors.indigo,
      },
    ];

    final nowMinutes = now.hour * 60 + now.minute;

    // --- Cari sholat berikutnya (upcoming) ---
    int upcomingIndex = 0;
    int upcomingMinutes = 0;
    bool foundToday = false;

    for (int i = 0; i < prayers.length; i++) {
      final t = _parseTime(prayers[i]['time'] as String);
      final m = t.hour * 60 + t.minute;

      if (nowMinutes <= m) {
        upcomingIndex = i;
        upcomingMinutes = m;
        foundToday = true;
        break;
      }
    }

    if (!foundToday) {
      // Sudah lewat Isya → next-nya Shubuh besok
      upcomingIndex = 0;
      final shubuhTime = _parseTime(prayers[0]['time'] as String);
      upcomingMinutes = shubuhTime.hour * 60 + shubuhTime.minute;
    }

    final upcomingPrayer = prayers[upcomingIndex];

    // Hitung selisih menuju sholat upcoming
    int diff;
    if (foundToday) {
      diff = upcomingMinutes - nowMinutes; // hari yg sama
    } else {
      // wrap ke hari berikutnya (Shubuh besok)
      diff = (24 * 60 - nowMinutes) + upcomingMinutes;
    }

    final hours = diff ~/ 60;
    final minutes = diff % 60;

    return {
      // "Current" di UI = sholat yang akan datang
      'name': upcomingPrayer['name'],
      'time': upcomingPrayer['time'],
      'icon': upcomingPrayer['icon'],
      'color': upcomingPrayer['color'],

      // upcoming text: pakai nama yg sama
      'nextName': upcomingPrayer['name'],
      'nextTime': '${hours}j ${minutes}m',
    };
  }

  @override
  Widget build(BuildContext context) {
    final sholatState = ref.watch(sholatProvider);
    final jadwal = ref
        .read(sholatProvider.notifier)
        .getJadwalByDate(_selectedDate);

    ref.listen<Map<String, dynamic>>(authProvider, (previous, next) {
      if (previous?['status'] == AuthState.authenticated &&
          next['status'] != AuthState.authenticated) {
        logger.info('🔄 User logged out, clearing progress data...');
        ref
            .read(sholatProvider.notifier)
            .clearProgressData()
            .then((_) {
              logger.info('✓ Progress data cleared successfully');
            })
            .catchError((e) {
              logger.warning('Error clearing progress data: $e');
            });
      }
    });

    if (jadwal != null) {
      _updateAlarmTimes(jadwal);
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.primaryBlue,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue,
                AppTheme.primaryBlue.withValues(alpha: 0.9),
                AppTheme.accentGreen.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _maxWidth(context)),
                child: Column(
                  children: [
                    _buildHeader(context),
                    _buildLocationAndStatus(context, sholatState),
                    _buildCurrentPrayerTime(context, jadwal),
                    if (sholatState.status == SholatStatus.loading ||
                        _isLoadingProgress)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (sholatState.status == SholatStatus.error)
                      _buildErrorState(sholatState)
                    else
                      Expanded(child: _buildPrayerTimesList(context, jadwal)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: _hpad(
        context,
      ).add(EdgeInsets.symmetric(vertical: _px(context, 12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleBtn(
            context,
            icon: Icons.chevron_left_rounded,
            onTap: () async {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              final authState = ref.read(authProvider);
              if (authState['status'] == AuthState.authenticated) {
                await _fetchProgressData();
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _isToday ? 'Hari ini' : _dayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _ts(context, 18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formattedDate,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: _ts(context, 14),
                  ),
                ),
                Text(
                  _hijriDate,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: _ts(context, 13),
                  ),
                ),
              ],
            ),
          ),
          _circleBtn(
            context,
            icon: Icons.chevron_right_rounded,
            onTap: () async {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
              final authState = ref.read(authProvider);
              if (authState['status'] == AuthState.authenticated) {
                await _fetchProgressData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(
    BuildContext c, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: _px(c, 28)),
      ),
    );
  }

  Widget _buildLocationAndStatus(BuildContext context, SholatState state) {
    final small = ResponsiveHelper.isSmallScreen(context);
    final location = state.locationName ?? 'Lokasi tidak tersedia';

    return Padding(
      padding: _hpad(context),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _updateLocation,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _px(context, small ? 12 : 16),
                  vertical: _px(context, small ? 6 : 8),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: _px(context, small ? 16 : 18),
                    ),
                    SizedBox(width: _px(context, small ? 6 : 8)),
                    Flexible(
                      child: Text(
                        location,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _ts(context, small ? 12 : 14),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: _px(context, small ? 8 : 12)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _px(context, small ? 12 : 16),
              vertical: _px(context, small ? 6 : 8),
            ),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGreen.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: _px(context, small ? 14 : 16),
                ),
                SizedBox(width: _px(context, small ? 4 : 6)),
                Text(
                  'AlAdhan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _ts(context, small ? 12 : 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPrayerTime(BuildContext context, dynamic jadwal) {
    final small = ResponsiveHelper.isSmallScreen(context);
    final currentPrayer = _getCurrentPrayerInfo(jadwal);

    return Padding(
      padding: _hpad(
        context,
      ).add(EdgeInsets.symmetric(vertical: _px(context, 12))),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(_px(context, small ? 16 : 20)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waktu Sholat Sekarang',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: _ts(context, small ? 12 : 14),
                    ),
                  ),
                  SizedBox(height: _px(context, small ? 6 : 8)),
                  Row(
                    children: [
                      Text(
                        currentPrayer['name'] as String,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _ts(context, small ? 18 : 20),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.all(_px(context, 6)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (currentPrayer['color'] as Color).withValues(
                                alpha: 0.8,
                              ),
                              currentPrayer['color'] as Color,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          currentPrayer['icon'] as IconData,
                          color: Colors.white,
                          size: _px(context, small ? 16 : 20),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _px(context, small ? 2 : 4)),
                  Text(
                    currentPrayer['time'] as String,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _ts(context, small ? 28 : 32),
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: _px(context, small ? 6 : 8)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _px(context, 10),
                      vertical: _px(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${currentPrayer['nextName']} dalam ${currentPrayer['nextTime']}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: _ts(context, small ? 11 : 13),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: _px(context, small ? 12 : 16)),
          Container(
            padding: EdgeInsets.all(_px(context, small ? 16 : 20)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(_px(context, 8)),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.accentGreen,
                    size: _px(context, small ? 28 : 32),
                  ),
                ),
                SizedBox(height: _px(context, small ? 10 : 12)),
                Text(
                  '$_completedCount/$_totalCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _ts(context, small ? 20 : 24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'selesai',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: _ts(context, small ? 11 : 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(SholatState sholatState) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
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
      ),
    );
  }

  Widget _buildPrayerTimesList(BuildContext context, dynamic jadwal) {
    final small = ResponsiveHelper.isSmallScreen(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(
              top: _px(context, 16),
              bottom: _px(context, 8),
            ),
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
          _buildTabs(small),
          _buildInfoCards(context, jadwal, small),
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
      ),
    );
  }

  Widget _buildTabs(bool small) {
    return Container(
      margin: _hpad(context).add(EdgeInsets.only(bottom: _px(context, 8))),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.05),
                    AppTheme.accentGreen.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,

                // --- remove underline default ---
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
                overlayColor: WidgetStateProperty.all(Colors.transparent),

                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),

                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.onSurface,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: _ts(context, small ? 13 : 14),
                ),
                tabs: const [
                  Tab(text: 'Sholat Wajib'),
                  Tab(text: 'Sholat Sunnah'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showCalendar,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(_px(context, 12)),
                  child: Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: _px(context, 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context, dynamic jadwal, bool small) {
    return Container(
      margin: _hpad(context),
      padding: EdgeInsets.symmetric(vertical: _px(context, 10)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.08),
            AppTheme.accentGreen.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dark_mode_rounded,
            size: _px(context, small ? 14 : 16),
            color: AppTheme.primaryBlue,
          ),
          SizedBox(width: _px(context, small ? 6 : 8)),
          Text(
            'Imsak ${jadwal?.wajib.imsak ?? '04:03'}',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: _ts(context, small ? 12 : 14),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: _px(context, small ? 12 : 16)),
          Container(
            width: 1,
            height: _px(context, 16),
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
          ),
          SizedBox(width: _px(context, small ? 12 : 16)),
          Icon(
            Icons.wb_sunny,
            size: _px(context, small ? 14 : 16),
            color: AppTheme.accentGreen,
          ),
          SizedBox(width: _px(context, small ? 6 : 8)),
          Text(
            'Terbit ${jadwal?.wajib.sunrise ?? '05:25'}',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: _ts(context, small ? 12 : 14),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
        'color': Colors.orange,
        'dbKey': 'shubuh',
      },
      'Dzuhur': {
        'time': jadwal?.wajib.dzuhur ?? '--:--',
        'icon': Icons.wb_sunny,
        'color': Colors.amber,
        'dbKey': 'dzuhur',
      },
      'Ashar': {
        'time': jadwal?.wajib.ashar ?? '--:--',
        'icon': Icons.wb_cloudy,
        'color': Colors.blue,
        'dbKey': 'ashar',
      },
      'Maghrib': {
        'time': jadwal?.wajib.maghrib ?? '--:--',
        'icon': Icons.wb_twilight,
        'color': Colors.deepOrange,
        'dbKey': 'maghrib',
      },
      'Isya': {
        'time': jadwal?.wajib.isya ?? '--:--',
        'icon': Icons.nights_stay,
        'color': Colors.indigo,
        'dbKey': 'isya',
      },
    };

    return ListView.builder(
      padding: _hpad(context),
      physics: const BouncingScrollPhysics(),
      itemCount: wajibList.length,
      itemBuilder: (_, i) {
        final name = wajibList.keys.elementAt(i);
        final jadwalData = wajibList[name]!;
        final dbKey = jadwalData['dbKey'] as String;
        final time = jadwalData['time'] as String;
        final sholatProgress = progressData[dbKey] as Map<String, dynamic>?;
        final isCompleted = sholatProgress?['completed'] as bool? ?? false;

        final bool timeArrived = _isPrayerTimeArrived(name, jadwal);
        final iconColor = jadwalData['color'] as Color;

        return Container(
          margin: EdgeInsets.only(bottom: _px(context, 12)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCompleted
                  ? AppTheme.accentGreen.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
              width: isCompleted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isCompleted
                    ? AppTheme.accentGreen.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(_px(context, small ? 14 : 16)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    if (!isLoggedIn) {
                      _showLoginRequired();
                      return;
                    }

                    if (_isToday && !timeArrived && !isCompleted) {
                      showMessageToast(
                        context,
                        message: 'Waktu sholat $name belum tiba',
                        type: ToastType.warning,
                      );
                      return;
                    }

                    if (!_isToday && !isCompleted) {
                      showMessageToast(
                        context,
                        message: 'Hanya bisa menambah progress untuk hari ini',
                        type: ToastType.warning,
                      );
                      return;
                    }

                    if (isCompleted) {
                      _showDetailWithDeleteOption(
                        context,
                        name,
                        jadwalData,
                        'wajib',
                        sholatProgress,
                        sholatProgress?['id'] as int?,
                      );
                    } else {
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
                  child: Container(
                    width: _px(context, 24),
                    height: _px(context, 24),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.accentGreen
                          : Colors.transparent,
                      border: Border.all(
                        color: isCompleted
                            ? AppTheme.accentGreen
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: _px(context, 16),
                          )
                        : null,
                  ),
                ),
                SizedBox(width: _px(context, small ? 12 : 16)),
                Container(
                  width: _px(context, small ? 48 : 52),
                  height: _px(context, small ? 48 : 52),
                  decoration: BoxDecoration(
                    gradient: isCompleted
                        ? LinearGradient(
                            colors: [
                              AppTheme.accentGreen,
                              AppTheme.accentGreen.withValues(alpha: 0.8),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              iconColor.withValues(alpha: 0.2),
                              iconColor.withValues(alpha: 0.1),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : jadwalData['icon'] as IconData,
                    color: isCompleted ? Colors.white : iconColor,
                    size: _px(context, small ? 24 : 28),
                  ),
                ),
                SizedBox(width: _px(context, small ? 12 : 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: _ts(context, small ? 15 : 16),
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      SizedBox(height: _px(context, 4)),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: _ts(context, small ? 13 : 14),
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
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
                      final isEnabled = await _alarmService.isAlarmEnabled(
                        name,
                      );
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
                  child: Container(
                    padding: EdgeInsets.all(_px(context, small ? 10 : 12)),
                    decoration: BoxDecoration(
                      gradient: (_wajibAlarms[name] ?? false)
                          ? LinearGradient(
                              colors: [
                                AppTheme.primaryBlue,
                                AppTheme.primaryBlue.withValues(alpha: 0.8),
                              ],
                            )
                          : null,
                      color: (_wajibAlarms[name] ?? false)
                          ? null
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.alarm_rounded,
                      color: (_wajibAlarms[name] ?? false)
                          ? Colors.white
                          : Colors.grey.shade600,
                      size: _px(context, small ? 20 : 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSunnahTab(dynamic jadwal, bool small) {
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState['status'] == AuthState.authenticated;
    final progressData = _currentProgressData;

    final sunnahList = jadwal?.sunnah ?? [];

    IconData _getIconBySlug(String slug) {
      return FlutterIslamicIcons.prayingPerson;
    }

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
      padding: _hpad(context),
      physics: const BouncingScrollPhysics(),
      itemCount: sunnahList.length,
      itemBuilder: (_, i) {
        final sunnahItem = sunnahList[i];
        final name = sunnahItem.nama as String;
        final slug = sunnahItem.slug as String;
        final deskripsi = sunnahItem.deskripsi as String;
        final sunnahId = sunnahItem.id;

        final dbKey = slug.replaceAll('-', '-');

        final jadwalData = {
          'time': deskripsi,
          'icon': _getIconBySlug(slug),
          'dbKey': dbKey,
          'sunnahId': sunnahId,
        };

        final sholatProgress = progressData[dbKey] as Map<String, dynamic>?;
        final isCompleted = sholatProgress?['completed'] as bool? ?? false;

        return Container(
          margin: EdgeInsets.only(bottom: _px(context, 12)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCompleted
                  ? AppTheme.accentGreen.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
              width: isCompleted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isCompleted
                    ? AppTheme.accentGreen.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(_px(context, small ? 14 : 16)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    if (!isLoggedIn) {
                      _showLoginRequired();
                      return;
                    }

                    if (!_isToday && !isCompleted) {
                      showMessageToast(
                        context,
                        message: 'Hanya bisa menambah progress untuk hari ini',
                        type: ToastType.warning,
                      );
                      return;
                    }

                    if (isCompleted) {
                      _showDetailWithDeleteOption(
                        context,
                        name,
                        jadwalData,
                        'sunnah',
                        sholatProgress,
                        sholatProgress?['id'] as int?,
                      );
                    } else {
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
                  child: Container(
                    width: _px(context, 24),
                    height: _px(context, 24),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.accentGreen
                          : Colors.transparent,
                      border: Border.all(
                        color: isCompleted
                            ? AppTheme.accentGreen
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: _px(context, 16),
                          )
                        : null,
                  ),
                ),
                SizedBox(width: _px(context, small ? 12 : 16)),
                Container(
                  width: _px(context, small ? 48 : 52),
                  height: _px(context, small ? 48 : 52),
                  decoration: BoxDecoration(
                    gradient: isCompleted
                        ? LinearGradient(
                            colors: [
                              AppTheme.accentGreen,
                              AppTheme.accentGreen.withValues(alpha: 0.8),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              AppTheme.primaryBlue.withValues(alpha: 0.15),
                              AppTheme.accentGreen.withValues(alpha: 0.15),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : jadwalData['icon'] as IconData,
                    color: isCompleted ? Colors.white : AppTheme.primaryBlue,
                    size: _px(context, small ? 24 : 28),
                  ),
                ),
                SizedBox(width: _px(context, small ? 12 : 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: _ts(context, small ? 15 : 16),
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      SizedBox(height: _px(context, 4)),
                      Text(
                        deskripsi,
                        style: TextStyle(
                          fontSize: _ts(context, small ? 12 : 13),
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
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
