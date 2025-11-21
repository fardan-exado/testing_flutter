import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/app/router.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/artikel/models/artikel/artikel.dart';
import 'package:test_flutter/features/artikel/models/kategori/kategori_artikel.dart';
import 'package:test_flutter/features/artikel/providers/artikel_provider.dart';
import 'package:test_flutter/features/artikel/states/artikel_state.dart';
import 'dart:async';

class ArtikelPage extends ConsumerStatefulWidget {
  const ArtikelPage({super.key});

  @override
  ConsumerState<ArtikelPage> createState() => _ArtikelPageState();
}

class _ArtikelPageState extends ConsumerState<ArtikelPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  int? _selectedCategoryId;
  String? _selectedType; // Add this: 'artikel', 'video', or null for all
  bool _isSearching = false;

  // Debounce timer untuk search
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // Responsive helpers
  double _scale(BuildContext c) {
    if (ResponsiveHelper.isSmallScreen(c)) return .9;
    if (ResponsiveHelper.isMediumScreen(c)) return 1.0;
    if (ResponsiveHelper.isLargeScreen(c)) return 1.1;
    return 1.2;
  }

  double _px(BuildContext c, double base) => base * _scale(c);
  double _ts(BuildContext c, double base) =>
      ResponsiveHelper.adaptiveTextSize(c, base);

  @override
  void initState() {
    super.initState();

    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(artikelProvider.notifier).init();
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Trigger load more when near bottom
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final notifier = ref.read(artikelProvider.notifier);
    if (notifier.canLoadMore) {
      await notifier.fetchArtikel(
        isLoadMore: true,
        kategoriId: _selectedCategoryId,
        keyword: _searchQuery,
      );
    }
  }

  Future<void> _refreshData() async {
    await ref
        .read(artikelProvider.notifier)
        .refresh(kategoriId: _selectedCategoryId, keyword: _searchQuery);
  }

  void _onCategorySelected(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });

    // Always fetch from database when category changes (forceRefresh: true)
    ref
        .read(artikelProvider.notifier)
        .fetchArtikel(
          kategoriId: categoryId,
          keyword: _searchQuery,
          isRefresh: true,
        );
  }

  void _onSearchChanged(String query) {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    setState(() {
      _isSearching = query.isNotEmpty;
    });

    // Set new debounce timer
    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _searchQuery = query;
    });

    // Fetch with search query from database
    await ref
        .read(artikelProvider.notifier)
        .fetchArtikel(
          kategoriId: _selectedCategoryId,
          keyword: query,
          isRefresh: true,
        );
  }

  void _onSearchSubmitted(String query) {
    // Cancel debounce timer and perform search immediately
    _debounceTimer?.cancel();
    _performSearch(query.trim());

    setState(() {
      _isSearching = false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();

    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });

    // Fetch without search query
    ref
        .read(artikelProvider.notifier)
        .fetchArtikel(
          kategoriId: _selectedCategoryId,
          keyword: '',
          isRefresh: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final artikelState = ref.watch(artikelProvider);
    final categories = artikelState.kategori;
    final artikels = artikelState.artikelList;
    final status = artikelState.status;
    final isOffline = artikelState.isOffline;

    // Listen to state changes for showing messages
    ref.listen<ArtikelState>(artikelProvider, (previous, next) {
      if (next.message != null) {
        showMessageToast(
          context,
          message: next.message!,
          type: next.isOffline ? ToastType.warning : ToastType.info,
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.accentGreen.withValues(alpha: 0.03),
              AppTheme.backgroundWhite,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Header
              Container(
                padding: EdgeInsets.all(_px(context, 24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        // Back button
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: const Color(0xFF2D3748),
                          tooltip: 'Kembali',
                        ),
                        SizedBox(width: _px(context, 8)),

                        // Icon badge
                        Container(
                          padding: EdgeInsets.all(_px(context, 12)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accentGreen.withValues(alpha: 0.15),
                                AppTheme.primaryBlue.withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _selectedType == 'video'
                                ? Icons.play_circle_outline_rounded
                                : Icons.article_rounded,
                            color: AppTheme.accentGreen,
                            size: _px(context, 24),
                          ),
                        ),
                        SizedBox(width: _px(context, 16)),

                        // Title and subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _selectedType == 'video'
                                          ? 'Video Islami'
                                          : 'Artikel Islami',
                                      style: TextStyle(
                                        fontSize: _ts(context, 22),
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.onSurface,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isOffline) ...[
                                    SizedBox(width: _px(context, 8)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.cloud_off,
                                            size: 12,
                                            color: Colors.orange.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Offline',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: _px(context, 2)),
                              Text(
                                'Pelajari Islam lebih dalam',
                                style: TextStyle(
                                  fontSize: _ts(context, 14),
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Refresh button
                        if (status != ArtikelStatus.loading &&
                            status != ArtikelStatus.refreshing)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.accentGreen.withValues(alpha: 0.1),
                                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: _refreshData,
                              icon: const Icon(Icons.refresh_rounded),
                              color: AppTheme.accentGreen,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: _px(context, 20)),

                    // Enhanced Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.accentGreen.withValues(alpha: 0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentGreen.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onSubmitted: _onSearchSubmitted,
                        decoration: InputDecoration(
                          hintText: _selectedType == 'video'
                              ? 'Cari video...'
                              : 'Cari artikel...',
                          hintStyle: TextStyle(
                            color: AppTheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppTheme.accentGreen,
                            size: _px(context, 24),
                          ),
                          suffixIcon: _isSearching || _searchQuery.isNotEmpty
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_searchQuery.isNotEmpty)
                                      IconButton(
                                        icon: Icon(
                                          Icons.clear_rounded,
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                        onPressed: _clearSearch,
                                        tooltip: 'Hapus',
                                      ),
                                  ],
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: _px(context, 20),
                            vertical: _px(context, 16),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: _px(context, 20)),

                    SizedBox(height: _px(context, 16)),
                    // Category Filter
                    if (categories.isNotEmpty)
                      SizedBox(
                        height: _px(context, 44),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length + 1,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              final isSelected = _selectedCategoryId == null;
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: _px(context, 10),
                                ),
                                child: _buildCategoryChip(
                                  context,
                                  label: 'Semua Kategori',
                                  isSelected: isSelected,
                                  kategori: null,
                                  onTap: () => _onCategorySelected(null),
                                ),
                              );
                            }

                            final category = categories[index - 1];
                            final isSelected =
                                category.id == _selectedCategoryId;

                            return Padding(
                              padding: EdgeInsets.only(
                                right: index == categories.length
                                    ? 0
                                    : _px(context, 10),
                              ),
                              child: _buildCategoryChip(
                                context,
                                label: category.nama,
                                isSelected: isSelected,
                                kategori: category,
                                onTap: () => _onCategorySelected(category.id),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // Articles List
              Expanded(child: _buildContent(context, status, artikels)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required KategoriArtikel? kategori,
  }) {
    // Build icon URL from storage + icon_path
    final storage = dotenv.env['STORAGE_URL'] ?? '';
    final iconPath = kategori?.iconPath;
    final iconUrl =
        (iconPath != null && iconPath.isNotEmpty && storage.isNotEmpty)
        ? '$storage/$iconPath'
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _px(context, 16),
          vertical: _px(context, 8),
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.accentGreen,
                    AppTheme.accentGreen.withValues(alpha: 0.8),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentGreen
                : AppTheme.accentGreen.withValues(alpha: 0.2),
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category Icon
            if (kategori != null)
              Padding(
                padding: EdgeInsets.only(right: _px(context, 6)),
                child: SizedBox(
                  width: _px(context, 28),
                  height: _px(context, 21), // 4:3 ratio (landscape)
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: iconUrl.isNotEmpty
                        ? Image.network(
                            iconUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultCategoryIcon(isSelected);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildDefaultCategoryIcon(isSelected);
                            },
                          )
                        : _buildDefaultCategoryIcon(isSelected),
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.only(right: _px(context, 6)),
                child: Icon(
                  Icons.grid_view_rounded,
                  color: isSelected ? Colors.white : AppTheme.accentGreen,
                  size: _px(context, 18),
                ),
              ),
            // Label
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: _ts(context, 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method untuk build default category icon
  Widget _buildDefaultCategoryIcon(bool isSelected) {
    return Container(
      color: isSelected
          ? Colors.white.withValues(alpha: 0.3)
          : AppTheme.accentGreen.withValues(alpha: 0.1),
      child: Icon(
        Icons.category_rounded,
        color: isSelected
            ? Colors.white.withValues(alpha: 0.7)
            : AppTheme.accentGreen.withValues(alpha: 0.5),
        size: _px(context, 14),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ArtikelStatus status,
    List<Artikel> artikels,
  ) {
    // Initial loading state
    if (status == ArtikelStatus.loading && artikels.isEmpty) {
      return _buildLoadingState(context);
    }

    // Error state (only if no cached data)
    if (status == ArtikelStatus.error && artikels.isEmpty) {
      return _buildErrorState(context);
    }

    // Empty state
    if (artikels.isEmpty) {
      return _buildEmptyState(context);
    }

    // Content with pull-to-refresh and pagination
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.accentGreen,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: _px(context, 20)),
        itemCount: artikels.length + 1, // +1 for load more indicator
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemBuilder: (context, index) {
          // Show articles
          if (index < artikels.length) {
            return _buildArtikelCard(context, artikels[index]);
          }

          // Show load more indicator at bottom
          return _buildLoadMoreIndicator(context);
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.accentGreen,
            strokeWidth: 3,
          ),
          SizedBox(height: _px(context, 16)),
          Text(
            'Memuat artikel...',
            style: TextStyle(
              fontSize: _ts(context, 16),
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_px(context, 24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(_px(context, 24)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withValues(alpha: 0.1),
                    Colors.red.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: _px(context, 64),
                color: Colors.red,
              ),
            ),
            SizedBox(height: _px(context, 24)),
            Text(
              'Gagal Memuat Artikel',
              style: TextStyle(
                fontSize: _ts(context, 20),
                color: AppTheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _px(context, 8)),
            Text(
              'Periksa koneksi internet Anda\ndan coba lagi',
              style: TextStyle(
                fontSize: _ts(context, 14),
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _px(context, 24)),
            ElevatedButton.icon(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: _px(context, 24),
                  vertical: _px(context, 14),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                'Coba Lagi',
                style: TextStyle(
                  fontSize: _ts(context, 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(_px(context, 24)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentGreen.withValues(alpha: 0.1),
                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.article_outlined,
              size: _px(context, 64),
              color: AppTheme.accentGreen,
            ),
          ),
          SizedBox(height: _px(context, 24)),
          Text(
            'Tidak ada artikel ditemukan',
            style: TextStyle(
              fontSize: _ts(context, 18),
              color: AppTheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: _px(context, 8)),
          Text(
            _searchQuery.isNotEmpty
                ? 'Coba kata kunci lain'
                : 'Coba ubah kategori atau filter',
            style: TextStyle(
              fontSize: _ts(context, 14),
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator(BuildContext context) {
    final state = ref.watch(artikelProvider);

    // Loading more
    if (state.status == ArtikelStatus.loadingMore) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: _px(context, 20)),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: _px(context, 20),
              height: _px(context, 20),
              child: CircularProgressIndicator(
                color: AppTheme.accentGreen,
                strokeWidth: 2.5,
              ),
            ),
            SizedBox(width: _px(context, 12)),
            Text(
              'Memuat lebih banyak...',
              style: TextStyle(
                fontSize: _ts(context, 14),
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // No more data
    if (state.currentPage >= state.lastPage) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: _px(context, 20)),
        alignment: Alignment.center,
        child: Text(
          'Semua artikel telah ditampilkan',
          style: TextStyle(
            fontSize: _ts(context, 14),
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Can load more (but not loading)
    return const SizedBox(height: 20);
  }

  /// Build type badge with category icon for artikel card
  Widget _buildTypeBadge(BuildContext context, Artikel artikel, bool isVideo) {
    final storage = dotenv.env['STORAGE_URL'] ?? '';
    final iconPath = artikel.kategori.iconPath;
    final iconUrl =
        (iconPath != null && iconPath.isNotEmpty && storage.isNotEmpty)
        ? '$storage/$iconPath'
        : '';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _px(context, 12),
        vertical: _px(context, 6),
      ),
      decoration: BoxDecoration(
        color: isVideo ? Colors.red : AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: (isVideo ? Colors.red : AppTheme.primaryBlue).withValues(
              alpha: 0.4,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category Icon
          if (!isVideo && iconUrl.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: _px(context, 6)),
              child: SizedBox(
                width: _px(context, 16),
                height: _px(context, 12), // 4:3 ratio
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.network(
                    iconUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.category_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: _px(context, 12),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Icon(
                        Icons.category_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: _px(context, 12),
                      );
                    },
                  ),
                ),
              ),
            )
          else if (!isVideo)
            Padding(
              padding: EdgeInsets.only(right: _px(context, 6)),
              child: Icon(
                Icons.article_rounded,
                color: Colors.white,
                size: _px(context, 16),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(right: _px(context, 6)),
              child: Icon(
                Icons.play_circle_outline_rounded,
                color: Colors.white,
                size: _px(context, 16),
              ),
            ),
          // Label
          Text(
            isVideo ? 'Video' : artikel.kategori.nama,
            style: TextStyle(
              color: Colors.white,
              fontSize: _ts(context, 12),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build category badge with icon for video at bottom left
  Widget _buildCategoryBadgeForVideo(BuildContext context, Artikel artikel) {
    final storage = dotenv.env['STORAGE_URL'] ?? '';
    final iconPath = artikel.kategori.iconPath;
    final iconUrl =
        (iconPath != null && iconPath.isNotEmpty && storage.isNotEmpty)
        ? '$storage/$iconPath'
        : '';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _px(context, 10),
        vertical: _px(context, 5),
      ),
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
              padding: EdgeInsets.only(right: _px(context, 4)),
              child: SizedBox(
                width: _px(context, 14),
                height: _px(context, 10.5), // 4:3 ratio
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.network(
                    iconUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.category_rounded,
                        color: AppTheme.onSurface.withValues(alpha: 0.5),
                        size: _px(context, 10),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Icon(
                        Icons.category_rounded,
                        color: AppTheme.onSurface.withValues(alpha: 0.3),
                        size: _px(context, 10),
                      );
                    },
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(right: _px(context, 4)),
              child: Icon(
                Icons.category_rounded,
                color: AppTheme.onSurface.withValues(alpha: 0.5),
                size: _px(context, 12),
              ),
            ),
          // Label
          Text(
            artikel.kategori.nama,
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: _ts(context, 11),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtikelCard(BuildContext context, Artikel artikel) {
    final isVideo = artikel.tipe == 'video';

    // Fix: Build proper image URL
    final storage = dotenv.env['STORAGE_URL'] ?? '';
    final coverPath = artikel.coverPath;
    final coverUrl = coverPath.isNotEmpty && storage.isNotEmpty
        ? '$storage/$coverPath'
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.articleDetail,
          arguments: artikel.id,
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: _px(context, 20)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isVideo ? Colors.red : AppTheme.primaryBlue).withValues(
              alpha: 0.1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: (isVideo ? Colors.red : AppTheme.primaryBlue).withValues(
                alpha: 0.08,
              ),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article/Video Image with Overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: coverUrl.isNotEmpty
                      ? Image.network(
                          coverUrl,
                          width: double.infinity,
                          height: _px(context, 200),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: double.infinity,
                              height: _px(context, 200),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    (isVideo
                                            ? Colors.red
                                            : AppTheme.primaryBlue)
                                        .withValues(alpha: 0.1),
                                    (isVideo
                                            ? Colors.red
                                            : AppTheme.primaryBlue)
                                        .withValues(alpha: 0.05),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: isVideo
                                      ? Colors.red
                                      : AppTheme.primaryBlue,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            // Debug: Print error
                            debugPrint('Image load error: $error');
                            debugPrint('Image URL: $coverUrl');

                            return Container(
                              width: double.infinity,
                              height: _px(context, 200),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    (isVideo
                                            ? Colors.red
                                            : AppTheme.primaryBlue)
                                        .withValues(alpha: 0.2),
                                    (isVideo
                                            ? Colors.red
                                            : AppTheme.primaryBlue)
                                        .withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isVideo
                                        ? Icons.play_circle_outline_rounded
                                        : Icons.image_rounded,
                                    size: _px(context, 64),
                                    color:
                                        (isVideo
                                                ? Colors.red
                                                : AppTheme.primaryBlue)
                                            .withValues(alpha: 0.4),
                                  ),
                                  SizedBox(height: _px(context, 8)),
                                  Text(
                                    'Gambar tidak tersedia',
                                    style: TextStyle(
                                      color: AppTheme.onSurfaceVariant,
                                      fontSize: _ts(context, 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Container(
                          width: double.infinity,
                          height: _px(context, 200),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                (isVideo ? Colors.red : AppTheme.primaryBlue)
                                    .withValues(alpha: 0.2),
                                (isVideo ? Colors.red : AppTheme.primaryBlue)
                                    .withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                          child: Icon(
                            isVideo
                                ? Icons.play_circle_outline_rounded
                                : Icons.image_rounded,
                            size: _px(context, 64),
                            color: (isVideo ? Colors.red : AppTheme.primaryBlue)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                ),

                // Video Play Button Overlay
                if (isVideo)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.all(_px(context, 16)),
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
                            size: _px(context, 40),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Gradient Overlay (only for non-video)
                if (!isVideo)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Type Badge
                Positioned(
                  top: _px(context, 16),
                  left: _px(context, 16),
                  child: _buildTypeBadge(context, artikel, isVideo),
                ),

                // Category Badge for Video
                if (isVideo)
                  Positioned(
                    bottom: _px(context, 16),
                    left: _px(context, 16),
                    child: _buildCategoryBadgeForVideo(context, artikel),
                  ),

                // Bookmark Icon
                Positioned(
                  top: _px(context, 16),
                  right: _px(context, 16),
                  child: Container(
                    padding: EdgeInsets.all(_px(context, 8)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bookmark_border_rounded,
                      color: isVideo ? Colors.red : AppTheme.primaryBlue,
                      size: _px(context, 20),
                    ),
                  ),
                ),
              ],
            ),

            // Article/Video Content
            Padding(
              padding: EdgeInsets.all(_px(context, 18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    artikel.judul,
                    style: TextStyle(
                      fontSize: _ts(context, 18),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: _px(context, 10)),

                  // Summary/Excerpt
                  Text(
                    artikel.excerpt ?? '',
                    style: TextStyle(
                      fontSize: _ts(context, 14),
                      color: AppTheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: _px(context, 16)),

                  // Divider
                  Divider(
                    color: (isVideo ? Colors.red : AppTheme.primaryBlue)
                        .withValues(alpha: 0.1),
                    height: 1,
                  ),
                  SizedBox(height: _px(context, 12)),

                  // Meta Info
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _px(context, 10),
                          vertical: _px(context, 6),
                        ),
                        decoration: BoxDecoration(
                          color: (isVideo ? Colors.red : AppTheme.primaryBlue)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: _px(context, 16),
                              color: isVideo
                                  ? Colors.red
                                  : AppTheme.primaryBlue,
                            ),
                            SizedBox(width: _px(context, 4)),
                            Text(
                              _formatDate(artikel.createdAt),
                              style: TextStyle(
                                fontSize: _ts(context, 13),
                                color: isVideo
                                    ? Colors.red
                                    : AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: _px(context, 16),
                        color: isVideo ? Colors.red : AppTheme.primaryBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
