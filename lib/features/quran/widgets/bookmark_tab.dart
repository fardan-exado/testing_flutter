import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/connection/connection_provider.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/quran/quran_provider.dart';
import 'package:test_flutter/features/quran/quran_state.dart';
import 'package:test_flutter/features/quran/services/quran_service.dart';
import 'package:test_flutter/features/quran/pages/surah_detail_page.dart';

class BookmarkTab extends ConsumerStatefulWidget {
  const BookmarkTab({super.key});

  @override
  ConsumerState<BookmarkTab> createState() => _BookmarkTabState();
}

class _BookmarkTabState extends ConsumerState<BookmarkTab> {
  @override
  void initState() {
    super.initState();
    // Load progress on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgress();
    });
  }

  Future<void> _loadProgress() async {
    // First load from cache
    await ref.read(quranProvider.notifier).init();

    // Then try to sync from API (will fail silently if offline)
    final connectionState = ref.read(connectionProvider);
    if (connectionState.isOnline) {
      try {
        await ref.read(quranProvider.notifier).fetchRiwayat();
      } catch (e) {
        print('📱 Offline mode: Using cache');
      }
    } else {
      print('📱 No internet: Using cache');
    }
  }

  Future<void> _refreshProgress() async {
    final connectionState = ref.read(connectionProvider);

    if (!connectionState.isOnline) {
      if (mounted) {
        showMessageToast(
          context,
          message: 'No internet connection',
          type: ToastType.warning,
        );
      }
      return;
    }

    try {
      await ref.read(quranProvider.notifier).fetchRiwayat();

      if (mounted) {
        showMessageToast(
          context,
          message: 'Riwayat updated',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showMessageToast(
          context,
          message: 'Failed to update: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;

    final quranState = ref.watch(quranProvider);
    final riwayat = quranState.riwayatProgres;

    return RefreshIndicator(
      onRefresh: _refreshProgress,
      color: AppTheme.accentGreen,
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop
              ? 32.0
              : isTablet
              ? 28.0
              : 24.0,
          vertical: isTablet ? 12 : 8,
        ),
        children: [
          // Riwayat Content
          if (quranState.status == QuranStatus.loading && riwayat.isEmpty)
            _buildLoadingState(isTablet)
          else if (riwayat.isEmpty)
            _buildEmptyState(isTablet, isDesktop)
          else
            ..._buildRiwayatList(riwayat, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isTablet) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(color: AppTheme.accentGreen),
            const SizedBox(height: 16),
            Text(
              'Loading progress...',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isTablet ? 15 : 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet, bool isDesktop) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: isDesktop
                    ? 64
                    : isTablet
                    ? 56
                    : 48,
                color: AppTheme.primaryBlue.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada bookmark',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isDesktop
                    ? 22
                    : isTablet
                    ? 20
                    : 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai membaca untuk menandai kemajuan Anda di Quran.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isTablet ? 15 : 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRiwayatList(
    List<dynamic> riwayat,
    bool isTablet,
    bool isDesktop,
  ) {
    return riwayat.map((progress) {
      final surahId = progress.suratId as int;
      final ayahNumber = progress.ayat as int;
      final createdAt = progress.createdAt as String?;
      final surah = QuranService.getSurahById(surahId);

      if (surah == null) return const SizedBox.shrink();

      final surahName = QuranService.getSurahNameLatin(surahId);

      // Format tanggal
      String formattedDate = '';
      if (createdAt != null) {
        try {
          final date = DateTime.parse(createdAt);
          formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
        } catch (e) {
          formattedDate = '';
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SurahDetailPage(
                  surah: surah.copyWith(namaLatin: surahName),
                  allSurahs: QuranService.getAllSurahs(),
                  initialAyat: ayahNumber,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
              border: Border.all(
                color: AppTheme.accentGreen.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGreen.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(
                isDesktop
                    ? 20
                    : isTablet
                    ? 18
                    : 16,
              ),
              child: Row(
                children: [
                  // Surah Number Badge
                  Container(
                    width: isDesktop
                        ? 52
                        : isTablet
                        ? 48
                        : 44,
                    height: isDesktop
                        ? 52
                        : isTablet
                        ? 48
                        : 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentGreen,
                          AppTheme.accentGreen.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    ),
                    child: Center(
                      child: Text(
                        '$surahId',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: isDesktop
                              ? 20
                              : isTablet
                              ? 18
                              : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 14),

                  // Surah Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surahName,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: isDesktop
                                ? 18
                                : isTablet
                                ? 17
                                : 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Ayah $ayahNumber',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: isTablet ? 12 : 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${surah.jumlahAyat} Ayat',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: isTablet ? 13 : 12,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (formattedDate.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: isTablet ? 14 : 12,
                                color: AppTheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: isTablet ? 11 : 10,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Delete Button
                  IconButton(
                    onPressed: () => _showDeleteDialog(progress.id as int),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red.shade400,
                    iconSize: isTablet ? 24 : 22,
                  ),

                  // Arabic Name
                  Text(
                    surah.nama,
                    style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: isDesktop
                          ? 24
                          : isTablet
                          ? 22
                          : 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Future<void> _showDeleteDialog(int progresId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Hapus Bookmark',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus bookmark ini?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(quranProvider.notifier).deleteProgresQuran(progresId);

      final message = ref.read(quranProvider).message;
      if (message != null && mounted) {
        showMessageToast(context, message: message, type: ToastType.success);
        ref.read(quranProvider.notifier).clearMessage();
      }
    }
  }
}
