// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/artikel/models/artikel/artikel.dart';
import 'package:test_flutter/features/artikel/providers/artikel_provider.dart';
import 'package:test_flutter/features/artikel/states/artikel_state.dart';
import 'package:url_launcher/url_launcher.dart';

class ArtikelDetailPage extends ConsumerStatefulWidget {
  final int artikelId;

  const ArtikelDetailPage({super.key, required this.artikelId});

  @override
  ConsumerState<ArtikelDetailPage> createState() => _ArtikelDetailPageState();
}

class _ArtikelDetailPageState extends ConsumerState<ArtikelDetailPage> {
  // bool _isBookmarked = false;
  int _currentImageIndex = 0;
  final PageController _imagePageController = PageController();

  @override
  void initState() {
    super.initState();
    // Fetch artikel detail saat page dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(artikelProvider.notifier).fetchArtikelById(widget.artikelId);
    });
  }

  // Helper untuk build image URL
  String _buildImageUrl(String path) {
    final storage = dotenv.env['STORAGE_URL'] ?? '';
    return path.isNotEmpty && storage.isNotEmpty ? '$storage/$path' : '';
  }

  // Helper untuk format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hari ini';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu lalu';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
    }
  }

  /// Build category badge for detail page header
  Widget _buildCategoryBadgeDetail(bool isVideo, Artikel artikel) {
    final contentColor = isVideo ? Colors.red : AppTheme.primaryBlue;
    final storage = dotenv.env['STORAGE_URL'] ?? '';
    final iconPath = artikel.kategori.iconPath;
    final iconUrl =
        (iconPath != null && iconPath.isNotEmpty && storage.isNotEmpty)
        ? '$storage/$iconPath'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: contentColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: contentColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category Icon for non-video
          if (!isVideo && iconUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: SizedBox(
                width: 16,
                height: 12, // 4:3 ratio
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.network(
                    iconUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.category_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 12,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Icon(
                        Icons.category_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 12,
                      );
                    },
                  ),
                ),
              ),
            )
          else if (!isVideo)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.article_rounded, color: Colors.white, size: 18),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                Icons.play_circle_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          // Label
          Text(
            isVideo ? 'Video' : artikel.kategori.nama,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build category badge for video detail page (bottom right)
  Widget _buildCategoryBadgeVideoDetail(Artikel artikel) {
    final storage = dotenv.env['STORAGE_URL'] ?? '';
    final iconPath = artikel.kategori.iconPath;
    final iconUrl =
        (iconPath != null && iconPath.isNotEmpty && storage.isNotEmpty)
        ? '$storage/$iconPath'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category Icon
          if (iconUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SizedBox(
                width: 14,
                height: 10.5, // 4:3 ratio
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.network(
                    iconUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.category_rounded,
                        color: AppTheme.onSurface.withValues(alpha: 0.5),
                        size: 10,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Icon(
                        Icons.category_rounded,
                        color: AppTheme.onSurface.withValues(alpha: 0.3),
                        size: 10,
                      );
                    },
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.category_rounded,
                color: AppTheme.onSurface.withValues(alpha: 0.5),
                size: 12,
              ),
            ),
          // Label
          Text(
            artikel.kategori.nama,
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Launch YouTube video
  Future<void> _launchVideo(String videoUrl) async {
    if (videoUrl.isEmpty) {
      showMessageToast(context, message: 'Video tidak tersedia');
      return;
    }

    Uri? uri;
    try {
      uri = Uri.parse(videoUrl);
    } catch (e) {
      logger.fine('Invalid video URL: $videoUrl');
      showMessageToast(context, message: 'URL video tidak valid');
      return;
    }

    try {
      // Prefer launching in an external application
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // If it's a YouTube short link or youtube.com with query param, try to construct a watch URL
        if (uri.host.contains('youtu.be') || uri.host.contains('youtube.com')) {
          String? videoId;
          if (uri.host.contains('youtu.be')) {
            if (uri.pathSegments.isNotEmpty) videoId = uri.pathSegments.last;
          } else {
            // For youtube.com links prefer the 'v' query parameter
            videoId = uri.queryParameters['v'];
            // If no 'v' param, try to use last path segment (edge cases)
            if ((videoId == null || videoId.isEmpty) &&
                uri.pathSegments.isNotEmpty &&
                uri.pathSegments.last != 'watch') {
              videoId = uri.pathSegments.last;
            }
          }

          if (videoId != null && videoId.isNotEmpty) {
            final watchUri = Uri.parse(
              'https://www.youtube.com/watch?v=$videoId',
            );
            // Try external app first, then browser
            if (await launchUrl(watchUri, mode: LaunchMode.externalApplication))
              return;
            if (await launchUrl(watchUri, mode: LaunchMode.platformDefault))
              return;
          }
        }

        // Try opening the original URI in the platform default mode (usually browser)
        if (await launchUrl(uri, mode: LaunchMode.platformDefault)) return;

        // All attempts failed
        showMessageToast(
          context,
          message: 'Terjadi kesalahan saat membuka video.',
        );
      }
    } on PlatformException catch (e) {
      logger.fine('PlatformException: $e');
      showMessageToast(
        context,
        message: 'Terjadi kesalahan saat membuka video.',
      );
    } catch (e) {
      logger.fine('Error launching video URL: $e');
      showMessageToast(
        context,
        message: 'Terjadi kesalahan saat membuka video.',
      );
    }
  }

  // Open lightbox untuk melihat gambar fullscreen
  void _openImageLightbox(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ImageLightboxViewer(images: images, initialIndex: initialIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(artikelProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: _buildBody(detailState),
    );
  }

  Widget _buildBody(ArtikelState state) {
    switch (state.status) {
      case ArtikelStatus.loading:
        return _buildLoading();

      case ArtikelStatus.error:
        return _buildError(state.message ?? 'Terjadi kesalahan');

      case ArtikelStatus.loaded:
        if (state.selectedArtikel == null) {
          return _buildError('Artikel tidak ditemukan');
        }
        return _buildContent(state.selectedArtikel!);

      default:
        return _buildLoading();
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryBlue),
          const SizedBox(height: 16),
          Text(
            'Memuat artikel...',
            style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat artikel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(artikelProvider.notifier)
                    .fetchArtikelById(widget.artikelId);
              },
              icon: Icon(Icons.refresh_rounded),
              label: Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Artikel artikel) {
    final isVideo = artikel.tipe == 'video';
    final contentColor = isVideo ? Colors.red : AppTheme.primaryBlue;
    final coverUrl = _buildImageUrl(artikel.coverPath);
    final daftarGambar = artikel.daftarGambar
        ?.where((path) => path.isNotEmpty)
        .map(_buildImageUrl)
        .toList();

    return CustomScrollView(
      slivers: [
        // Enhanced App Bar dengan gambar/video
        _buildAppBar(artikel, coverUrl, contentColor, isVideo),

        // Content
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  contentColor.withValues(alpha: 0.02),
                  AppTheme.backgroundWhite,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    artikel.judul,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Enhanced Meta Info
                  _buildMetaInfo(artikel, contentColor, isVideo),
                  const SizedBox(height: 28),

                  // Excerpt/Summary
                  if (artikel.excerpt != null) ...[
                    _buildExcerpt(artikel, contentColor),
                    const SizedBox(height: 28),
                  ],

                  // Content Section
                  if (isVideo)
                    _buildVideoContent(artikel)
                  else
                    _buildArtikelContent(artikel, daftarGambar, contentColor),

                  const SizedBox(height: 32),

                  // Divider
                  Divider(
                    color: contentColor.withValues(alpha: 0.2),
                    thickness: 2,
                  ),
                  const SizedBox(height: 32),

                  // Related Articles Section
                  // _buildRelatedSection(contentColor),

                  // Bottom spacing
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(
    Artikel artikel,
    String coverUrl,
    Color contentColor,
    bool isVideo,
  ) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: contentColor,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: contentColor),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image
            if (coverUrl.isNotEmpty)
              Image.network(
                coverUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          contentColor.withValues(alpha: 0.3),
                          contentColor.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: contentColor,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          contentColor.withValues(alpha: 0.3),
                          contentColor.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      isVideo
                          ? Icons.play_circle_outline_rounded
                          : Icons.image_rounded,
                      size: 80,
                      color: contentColor.withValues(alpha: 0.5),
                    ),
                  );
                },
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      contentColor.withValues(alpha: 0.3),
                      contentColor.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Icon(
                  isVideo
                      ? Icons.play_circle_outline_rounded
                      : Icons.image_rounded,
                  size: 80,
                  color: contentColor.withValues(alpha: 0.5),
                ),
              ),

            // Video Play Button Overlay
            if (isVideo)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              )
            else
              // Gradient Overlay for Artikel
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),

            // Category Badge at bottom
            Positioned(
              bottom: 20,
              left: 20,
              child: _buildCategoryBadgeDetail(isVideo, artikel),
            ),

            // Category name for video
            if (isVideo)
              Positioned(
                bottom: 20,
                right: 20,
                child: _buildCategoryBadgeVideoDetail(artikel),
              ),
          ],
        ),
      ),
      // actions: [
      //   Container(
      //     margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      //     decoration: BoxDecoration(
      //       color: Colors.white.withValues(alpha: 0.9),
      //       shape: BoxShape.circle,
      //     ),
      //     child: IconButton(
      //       icon: Icon(Icons.share_rounded, color: contentColor),
      //       onPressed: () {
      //         showMessageToast(context, message: '');
      //       },
      //       padding: EdgeInsets.zero,
      //     ),
      //   ),
      // ],
    );
  }

  Widget _buildMetaInfo(Artikel artikel, Color contentColor, bool isVideo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            contentColor.withValues(alpha: 0.08),
            contentColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: contentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: contentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: contentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _formatDate(artikel.createdAt),
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isVideo) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_filled, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Video',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExcerpt(Artikel artikel, Color contentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            contentColor.withValues(alpha: 0.1),
            contentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: contentColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: contentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.format_quote_rounded,
              color: contentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              artikel.excerpt ?? '',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.onSurface,
                height: 1.6,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoContent(Artikel artikel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video Player Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.1),
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
                          Colors.red.withValues(alpha: 0.2),
                          Colors.red.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.play_circle_filled_rounded,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tonton Video',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          'Video pembelajaran islami',
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
              const SizedBox(height: 16),

              // Video Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withValues(alpha: 0.3),
                            Colors.red.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                      child: artikel.coverPath.isNotEmpty
                          ? Image.network(
                              _buildImageUrl(artikel.coverPath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.play_circle_outline_rounded,
                                  size: 80,
                                  color: Colors.red.withValues(alpha: 0.5),
                                );
                              },
                            )
                          : Icon(
                              Icons.play_circle_outline_rounded,
                              size: 80,
                              color: Colors.red.withValues(alpha: 0.5),
                            ),
                    ),
                    // Play overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.2),
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Watch Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (artikel.videoUrl != null) {
                      _launchVideo(artikel.videoUrl!);
                    }
                  },
                  icon: Icon(Icons.play_circle_filled_rounded),
                  label: Text('Tonton Video di YouTube'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArtikelContent(
    Artikel artikel,
    List<String>? daftarGambar,
    Color contentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Article Content
        if (artikel.konten != null && artikel.konten!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: contentColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Text(
              artikel.konten!,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.onSurface,
                height: 1.8,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],

        // Image Gallery
        if (daftarGambar != null && daftarGambar.isNotEmpty) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: contentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_library_rounded,
                  color: contentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Galeri Gambar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const Spacer(),
              // Hint untuk tap
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: contentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 14,
                      color: contentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ketuk untuk perbesar',
                      style: TextStyle(
                        fontSize: 11,
                        color: contentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Image Carousel with tap to open lightbox
          GestureDetector(
            onTap: () {
              _openImageLightbox(daftarGambar, _currentImageIndex);
            },
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: contentColor.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _imagePageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: daftarGambar.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          daftarGambar[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    contentColor.withValues(alpha: 0.2),
                                    contentColor.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.image_rounded,
                                size: 80,
                                color: contentColor.withValues(alpha: 0.5),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  // Zoom icon indicator
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  // Image Counter
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${daftarGambar.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dots Indicator
          if (daftarGambar.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                daftarGambar.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? contentColor
                        : contentColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  // Widget _buildRelatedSection(Color contentColor) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         children: [
  //           Container(
  //             padding: const EdgeInsets.all(10),
  //             decoration: BoxDecoration(
  //               gradient: LinearGradient(
  //                 colors: [
  //                   AppTheme.primaryBlue.withValues(alpha: 0.15),
  //                   AppTheme.accentGreen.withValues(alpha: 0.15),
  //                 ],
  //               ),
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             child: Icon(
  //               Icons.auto_stories_rounded,
  //               color: AppTheme.primaryBlue,
  //               size: 24,
  //             ),
  //           ),
  //           const SizedBox(width: 12),
  //           const Text(
  //             'Artikel Terkait',
  //             style: TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.bold,
  //               color: AppTheme.onSurface,
  //               letterSpacing: -0.3,
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 16),
  //       Center(
  //         child: Container(
  //           padding: const EdgeInsets.all(20),
  //           decoration: BoxDecoration(
  //             color: contentColor.withValues(alpha: 0.05),
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: Column(
  //             children: [
  //               Icon(
  //                 Icons.article_outlined,
  //                 size: 48,
  //                 color: contentColor.withValues(alpha: 0.5),
  //               ),
  //               const SizedBox(height: 8),
  //               Text(
  //                 'Artikel terkait akan ditampilkan di sini',
  //                 style: TextStyle(
  //                   color: AppTheme.onSurfaceVariant,
  //                   fontSize: 14,
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }
}

// ============================================================================
// IMAGE LIGHTBOX VIEWER WIDGET
// ============================================================================

class ImageLightboxViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageLightboxViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<ImageLightboxViewer> createState() => _ImageLightboxViewerState();
}

class _ImageLightboxViewerState extends State<ImageLightboxViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Image PageView
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_rounded,
                                size: 80,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Gagal memuat gambar',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            // Top Bar (Close button & counter)
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 16,
                    left: 8,
                    right: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),

                      // Image counter
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Download button (placeholder)
                      //   Container(
                      //     decoration: BoxDecoration(
                      //       color: Colors.black.withValues(alpha: 0.5),
                      //       shape: BoxShape.circle,
                      //     ),
                      //     child: IconButton(
                      //       icon: Icon(
                      //         Icons.download_rounded,
                      //         color: Colors.white,
                      //         size: 24,
                      //       ),
                      //       onPressed: () {
                      //         ScaffoldMessenger.of(context).showSnackBar(
                      //           const SnackBar(
                      //             content: Text(
                      //               'Fitur download akan segera hadir',
                      //             ),
                      //             duration: Duration(seconds: 2),
                      //           ),
                      //         );
                      //       },
                      //     ),
                      //   ),
                    ],
                  ),
                ),
              ),

            // Bottom navigation arrows
            if (_showControls && widget.images.length > 1)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous button
                    if (_currentIndex > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),

                    // Dots indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          widget.images.length > 5 ? 5 : widget.images.length,
                          (index) {
                            if (widget.images.length > 5) {
                              // Show dots pattern for many images
                              if (index == 4) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: Text(
                                    '...',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              }
                            }
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentIndex == index ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentIndex == index
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Next button
                    if (_currentIndex < widget.images.length - 1)
                      Container(
                        margin: const EdgeInsets.only(left: 20),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

            // Pinch to zoom hint
            if (_showControls)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pinch_rounded,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pinch untuk zoom',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
