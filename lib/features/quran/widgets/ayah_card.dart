import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/features/quran/quran_provider.dart';

class AyahCard extends ConsumerWidget {
  final int surahNumber;
  final int verseNumber;
  final String arabicText;
  final String translation;
  final String verseEndSymbol;
  final String? transliteration; // Tambahkan parameter transliteration
  final VoidCallback onPlayVerse;
  final bool isTablet;
  final bool isDesktop;
  final bool isPlaying;
  final bool isGuest;

  const AyahCard({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    required this.arabicText,
    required this.translation,
    required this.verseEndSymbol,
    this.transliteration, // Parameter opsional
    required this.onPlayVerse,
    this.isTablet = false,
    this.isDesktop = false,
    this.isPlaying = false,
    this.isGuest = true,
  });

  void _showGuestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.login_rounded,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Login Required',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          'Silakan login terlebih dahulu untuk menggunakan fitur bookmark ayat.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Nanti',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Login',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookmarkModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentGreen.withValues(alpha: 0.2),
                    AppTheme.accentGreen.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_rounded,
                size: 32,
                color: AppTheme.accentGreen,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              'Bookmark This Ayah?',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Mark Surah $surahNumber, Ayah $verseNumber as your last reading position',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);

                      // Show loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('Saving bookmark...'),
                            ],
                          ),
                          duration: const Duration(seconds: 1),
                          backgroundColor: AppTheme.primaryBlue,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );

                      // Save bookmark
                      await ref
                          .read(quranProvider.notifier)
                          .addProgresQuran(
                            suratId: surahNumber.toString(),
                            ayat: verseNumber.toString(),
                          );

                      // Show success
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Surah $surahNumber, Ayah $verseNumber bookmarked!',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppTheme.accentGreen,
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'View',
                              textColor: Colors.white,
                              onPressed: () {
                                // Navigate to bookmark tab
                                DefaultTabController.of(context).animateTo(2);
                              },
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Bookmark',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quranState = ref.watch(quranProvider);

    // Check if this ayah is bookmarked in riwayat list
    final isBookmarked = quranState.riwayatProgres.any(
      (progres) =>
          progres.suratId == surahNumber && progres.ayat == verseNumber,
    );

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      padding: EdgeInsets.all(
        isDesktop
            ? 24
            : isTablet
            ? 22
            : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 22 : 20),
        border: Border.all(
          color: isBookmarked
              ? AppTheme.accentGreen
              : isPlaying
              ? AppTheme.accentGreen.withValues(alpha: 0.5)
              : AppTheme.primaryBlue.withValues(alpha: 0.1),
          width: isBookmarked
              ? 2
              : isPlaying
              ? 2
              : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isBookmarked
                ? AppTheme.accentGreen.withValues(alpha: 0.2)
                : isPlaying
                ? AppTheme.accentGreen.withValues(alpha: 0.15)
                : AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ayah number badge and actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 14 : 12,
                  vertical: isTablet ? 8 : 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isBookmarked
                        ? [
                            AppTheme.accentGreen.withValues(alpha: 0.2),
                            AppTheme.accentGreen.withValues(alpha: 0.1),
                          ]
                        : isPlaying
                        ? [
                            AppTheme.accentGreen.withValues(alpha: 0.2),
                            AppTheme.accentGreen.withValues(alpha: 0.1),
                          ]
                        : [
                            AppTheme.primaryBlue.withValues(alpha: 0.15),
                            AppTheme.accentGreen.withValues(alpha: 0.1),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBookmarked
                          ? Icons.bookmark
                          : isPlaying
                          ? Icons.graphic_eq
                          : Icons.circle,
                      size: isTablet ? 9 : 8,
                      color: isBookmarked
                          ? AppTheme.accentGreen
                          : isPlaying
                          ? AppTheme.accentGreen
                          : AppTheme.primaryBlue,
                    ),
                    SizedBox(width: isTablet ? 10 : 8),
                    Text(
                      isBookmarked
                          ? 'Bookmarked • $verseNumber'
                          : 'Ayat $verseNumber',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: isTablet ? 14 : 13,
                        fontWeight: FontWeight.w600,
                        color: isBookmarked
                            ? AppTheme.accentGreen
                            : isPlaying
                            ? AppTheme.accentGreen
                            : AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              Row(
                children: [
                  // Bookmark button
                  Container(
                    width: isTablet ? 42 : 40,
                    height: isTablet ? 42 : 40,
                    decoration: BoxDecoration(
                      color: isBookmarked
                          ? AppTheme.accentGreen.withValues(alpha: 0.15)
                          : isGuest
                          ? Colors.grey.withValues(alpha: 0.1)
                          : AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    ),
                    child: IconButton(
                      onPressed: isGuest
                          ? () => _showGuestDialog(context)
                          : () => _showBookmarkModal(context, ref),
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border_rounded,
                      ),
                      iconSize: isTablet ? 22 : 20,
                      color: isBookmarked
                          ? AppTheme.accentGreen
                          : isGuest
                          ? Colors.grey
                          : AppTheme.primaryBlue,
                      padding: EdgeInsets.zero,
                      tooltip: isGuest
                          ? 'Login to bookmark'
                          : isBookmarked
                          ? 'Bookmarked'
                          : 'Bookmark this ayah',
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: isTablet ? 20 : 16),

          // Arabic Text with end symbol on the LEFT (start of Arabic text)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              // Arabic text
              Flexible(
                child: Text(
                  arabicText,
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: isDesktop
                        ? 30
                        : isTablet
                        ? 28
                        : 26,
                    height: 2.0,
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
              ),
              SizedBox(width: isTablet ? 12 : 10),
              // Verse number on the left (which is the start in RTL)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 8,
                  vertical: isTablet ? 2 : 3,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.15),
                      AppTheme.accentGreen.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  verseEndSymbol,
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: isDesktop
                        ? 22
                        : isTablet
                        ? 20
                        : 18,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Transliteration (Latin)
          if (transliteration != null && transliteration!.isNotEmpty) ...[
            SizedBox(height: isTablet ? 16 : 12),

            Container(
              padding: EdgeInsets.all(isTablet ? 14 : 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.text_fields_rounded,
                    size: isTablet ? 18 : 16,
                    color: AppTheme.primaryBlue.withValues(alpha: 0.7),
                  ),
                  SizedBox(width: isTablet ? 10 : 8),
                  Expanded(
                    child: Text(
                      transliteration!,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: isDesktop
                            ? 16
                            : isTablet
                            ? 15
                            : 14,
                        height: 1.6,
                        color: AppTheme.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: isTablet ? 20 : 16),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.0),
                  AppTheme.primaryBlue.withValues(alpha: 0.2),
                  AppTheme.primaryBlue.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),

          SizedBox(height: isTablet ? 20 : 16),

          // Indonesian translation
          Text(
            translation,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isDesktop
                  ? 17
                  : isTablet
                  ? 16
                  : 15,
              height: 1.7,
              color: AppTheme.onSurface.withValues(alpha: 0.9),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}
