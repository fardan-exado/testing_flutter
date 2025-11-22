import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/format_helper.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/komunitas/models/komunitas/komunitas.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';
import 'package:test_flutter/features/komunitas/komunitas_provider.dart';
import 'package:test_flutter/features/komunitas/komunitas_state.dart';
import 'package:test_flutter/features/komunitas/pages/detail_postingan_page.dart';
import 'package:test_flutter/features/komunitas/pages/tambah_postingan_page.dart';

class KomunitasPage extends ConsumerStatefulWidget {
  const KomunitasPage({super.key});

  @override
  ConsumerState<KomunitasPage> createState() => _KomunitasPageState();
}

class _KomunitasPageState extends ConsumerState<KomunitasPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = 'Semua';
  String _selectedCategoryId = '0';
  String _searchQuery = '';

  // Add debounce timer for search
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _init();
    _setupScrollListener();
    _setupStateListener();
  }

  void _init() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(komunitasProvider.notifier).init();
      ref.read(authProvider.notifier).checkAuthStatus();
    });
  }

  void _setupStateListener() {
    ref.listenManual<KomunitasState>(komunitasProvider, (previous, next) {
      if (!mounted) return;

      // Handle success state
      if (next.status == KomunitasStatus.success &&
          next.message != null &&
          next.message!.isNotEmpty) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.success,
        );
      }

      // Handle error state
      if (next.status == KomunitasStatus.error &&
          next.message != null &&
          next.message!.isNotEmpty) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.error,
        );
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreIfPossible();
      }
    });
  }

  void _loadMoreIfPossible() {
    final notifier = ref.read(komunitasProvider.notifier);
    final state = ref.read(komunitasProvider);

    if (notifier.canLoadMore &&
        state.status != KomunitasStatus.loadingMore &&
        state.status != KomunitasStatus.refreshing) {
      ref
          .read(komunitasProvider.notifier)
          .fetchPostingan(
            isLoadMore: true,
            kategoriId: _selectedCategoryId == '0' ? null : _selectedCategoryId,
            keyword: _searchQuery,
          );
    }
  }

  Future<void> _handleRefresh() async {
    logger.fine('Pull to refresh triggered');
    await ref
        .read(komunitasProvider.notifier)
        .refresh(
          kategoriId: _selectedCategoryId == '0' ? null : _selectedCategoryId,
          keyword: _searchQuery,
        );
  }

  // Handle search with debounce
  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);

    // Cancel previous timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Start new timer
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Fetch from API after user stops typing for 500ms
      ref
          .read(komunitasProvider.notifier)
          .fetchPostingan(
            isRefresh: true,
            kategoriId: _selectedCategoryId == '0' ? null : _selectedCategoryId,
            keyword: query,
          );
    });
  }

  // Handle category change
  Future<void> _onCategoryChanged(
    String kategoriId,
    String kategoriNama,
  ) async {
    setState(() {
      _selectedCategory = kategoriNama;
      _selectedCategoryId = kategoriId;
    });

    // Fetch postingan with selected category
    await ref
        .read(komunitasProvider.notifier)
        .fetchPostingan(
          isRefresh: true,
          kategoriId: kategoriId == '0' ? null : kategoriId,
          keyword: _searchQuery,
        );
  }

  // Update this method to return list of kategori maps
  List<Map<String, dynamic>> get _kategoriList {
    final kategori = ref.watch(komunitasProvider).kategori;
    return [
      {'id': '0', 'nama': 'Semua', 'icon': null},
      ...kategori.map((e) {
        final raw = e.iconPath ?? '';
        final isValid = raw.trim().isNotEmpty;
        final base = dotenv.env['STORAGE_URL'] ?? '';

        return {
          'id': e.id.toString(),
          'nama': e.nama,
          'icon_path': isValid && base.isNotEmpty ? '$base/$raw' : null,
        };
      }),
    ];
  }

  // Remove client-side filtering, use API data directly
  List<Map<String, dynamic>> get _postList {
    final List<KomunitasPostingan> postingan = ref
        .watch(komunitasProvider)
        .postinganList;

    return postingan.map((item) {
      final storage = dotenv.env['STORAGE_URL'] ?? '';
      final coverPath = item.coverPath ?? '';
      final iconPath = item.kategori?.iconPath;
      final galeriList = (item.daftarGambar ?? [])
          .where((e) => e.toString().isNotEmpty)
          .map((e) => '$storage/$e')
          .toList();

      // Get author name - use user?.name if not anonymous, else 'Anonymous'
      final authorName = item.isAnonymous
          ? 'Anonymous'
          : (item.user?.name ?? 'User');

      return {
        'id': (item.id),
        'judul': item.judul,
        'excerpt': item.excerpt,
        'authorId': (item.userId),
        'penulis': authorName,
        'kategoriId': (item.kategori?.id ?? 0),
        'kategoriNama': item.kategori?.nama ?? 'Umum',
        'kategoriIcon':
            (iconPath != null && iconPath.isNotEmpty && storage.isNotEmpty)
            ? '$storage/$iconPath'
            : null,
        'date': FormatHelper.formatTimeAgo(item.createdAt),
        'coverUrl':
            (coverPath != null && coverPath.isNotEmpty && storage.isNotEmpty)
            ? '$storage/$coverPath'
            : null,
        'galeri': galeriList,
        'likesCount': item.likesCount ?? 0,
        'komentarsCount': item.komentarsCount ?? 0,
      };
    }).toList();
  }

  Color _getCategoryColor(String? nama) {
    final category = (nama ?? 'Umum').toLowerCase();
    switch (category) {
      case 'ibadah':
        return const Color(0xFF3B82F6);
      case 'doa':
        return const Color(0xFF8B5CF6);
      case 'event':
        return const Color(0xFFF97316);
      case 'sharing':
        return const Color(0xFF10B981);
      case 'pertanyaan':
        return const Color(0xFFEF4444);
      case 'diskusi':
        return Colors.purple.shade400;
      default:
        return AppTheme.primaryBlue;
    }
  }

  IconData _getCategoryIcon(String? nama) {
    final category = (nama ?? 'Umum').toLowerCase();
    switch (category) {
      case 'ibadah':
        return Icons.auto_awesome_rounded;
      case 'doa':
        return Icons.spa_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'sharing':
        return Icons.share_rounded;
      case 'pertanyaan':
        return Icons.help_outline_rounded;
      case 'diskusi':
        return Icons.forum_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void _navigateToAddPost() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const TambahPostinganPage()),
    );

    if (result == true && mounted) {
      // Refresh list setelah berhasil membuat postingan
      ref.read(komunitasProvider.notifier).fetchPostingan(isRefresh: true);
    }
  }

  void _navigateToDetail(Map<String, dynamic> post) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => DetailPostinganPage(post: post)),
    );

    if (result == true && mounted) {
      // Refresh list jika ada perubahan dari detail page
      ref.read(komunitasProvider.notifier).fetchPostingan(isRefresh: true);
    }
  }

  // Show Report Modal
  void _showReportModal(int postinganId) {
    final TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.flag_rounded,
                color: Colors.red.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Laporkan Postingan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Berikan alasan pelaporan Anda',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reportController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Masukkan alasan pelaporan...',
                hintStyle: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppTheme.primaryBlue.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              reportController.dispose();
            },
            child: Text(
              'Batal',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final alasan = reportController.text.trim();

              if (alasan.isEmpty) {
                showMessageToast(
                  context,
                  message: 'Alasan pelaporan tidak boleh kosong',
                  type: ToastType.error,
                );
                return;
              }

              // Close dialog and dispose controller
              Navigator.pop(context);

              // Wait for dialog to close, then submit
              WidgetsBinding.instance.addPostFrameCallback((_) {
                reportController.dispose();
                _handleReportSubmit(postinganId, alasan);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.flag_rounded, size: 18),
            label: const Text('Laporkan'),
          ),
        ],
      ),
    );
  }

  // Handle Report Submit
  Future<void> _handleReportSubmit(int postinganId, String alasan) async {
    try {
      // Call report method
      await ref
          .read(komunitasProvider.notifier)
          .reportPostingan(postinganId, alasan);

      // Refresh list after successful report
      if (mounted) {
        await ref
            .read(komunitasProvider.notifier)
            .fetchPostingan(isRefresh: true);
      }
    } catch (e) {
      if (!mounted) return;
      showMessageToast(
        context,
        message: 'Gagal melaporkan postingan: $e',
        type: ToastType.error,
      );
    }
  }

  // Show Delete Confirmation
  void _showDeleteConfirmation(int postinganId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hapus Postingan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus postingan ini? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Close dialog first
              Navigator.pop(context);

              // Wait for dialog to close, then submit
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleDeleteSubmit(postinganId);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Handle Delete Submit
  Future<void> _handleDeleteSubmit(int postinganId) async {
    try {
      // Call delete method
      await ref.read(komunitasProvider.notifier).deletePostingan(postinganId);

      // Refresh list after successful delete
      if (mounted) {
        await ref
            .read(komunitasProvider.notifier)
            .fetchPostingan(isRefresh: true);
      }
    } catch (e) {
      if (!mounted) return;
      showMessageToast(
        context,
        message: 'Gagal menghapus postingan: $e',
        type: ToastType.error,
      );
    }
  }

  // Show Post Options
  void _showPostOptions(Map<String, dynamic> post) {
    final authState = ref.watch(authProvider);

    if (authState['status'] != AuthState.authenticated) {
      showMessageToast(
        context,
        message: 'Anda harus login terlebih dahulu',
        type: ToastType.error,
      );
      return;
    }

    final currentUser = authState['user'];
    final userId = currentUser['id'] ?? currentUser['user']['id'];
    final isMyPost = userId != null && post['authorId'] == userId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Report option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.flag_rounded,
                    color: Colors.red.shade600,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Laporkan Postingan',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Text(
                  'Laporkan konten yang tidak pantas',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showReportModal(post['id']);
                },
              ),

              // Delete option (only for own posts)
              if (isMyPost) ...[
                Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                  indent: 16,
                  endIndent: 16,
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade600,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Hapus Postingan',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: Text(
                    'Hapus postingan Anda secara permanen',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(post['id']);
                  },
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Responsiveness helpers =====
  double _maxWidth(BuildContext context) {
    if (ResponsiveHelper.isExtraLargeScreen(context)) return 1100;
    if (ResponsiveHelper.isLargeScreen(context)) return 980;
    if (ResponsiveHelper.isMediumScreen(context)) return 760;
    return double.infinity;
  }

  int _gridColumns(BuildContext context) {
    if (ResponsiveHelper.isExtraLargeScreen(context)) return 3;
    if (ResponsiveHelper.isLargeScreen(context)) return 2;
    return 1;
  }

  double _cardImageHeight(BuildContext context) {
    if (ResponsiveHelper.isExtraLargeScreen(context)) return 220;
    if (ResponsiveHelper.isLargeScreen(context)) return 200;
    if (ResponsiveHelper.isMediumScreen(context)) return 190;
    return 180;
  }

  @override
  Widget build(BuildContext context) {
    final pagePad = ResponsiveHelper.getResponsivePadding(context);
    final titleSize = ResponsiveHelper.adaptiveTextSize(context, 28);
    final subtitleSize = ResponsiveHelper.adaptiveTextSize(context, 15);
    final useGrid = _gridColumns(context) > 1;

    final komunitasState = ref.watch(komunitasProvider);
    final currentPage = komunitasState.currentPage;
    final lastPage = komunitasState.lastPage;

    final authState = ref.watch(authProvider);
    final isLoggedIn = authState['status'] == AuthState.authenticated;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue.withValues(alpha: 0.05),
              AppTheme.accentGreen.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header + Search + Category Filter
              Padding(
                padding: EdgeInsets.all(pagePad.horizontal / 2),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: _maxWidth(context)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                                    AppTheme.accentGreen.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.people_rounded,
                                color: AppTheme.primaryBlue,
                                size: ResponsiveHelper.adaptiveTextSize(
                                  context,
                                  26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Komunitas',
                                  style: TextStyle(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Bagikan dan diskusikan dengan orang lain',
                                  style: TextStyle(
                                    fontSize: subtitleSize,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged:
                                _onSearchChanged, // Use debounced handler
                            style: TextStyle(
                              fontSize: ResponsiveHelper.adaptiveTextSize(
                                context,
                                14,
                              ),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Cari postingan',
                              hintStyle: TextStyle(
                                color: AppTheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: AppTheme.primaryBlue,
                                size: ResponsiveHelper.adaptiveTextSize(
                                  context,
                                  22,
                                ),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged(''); // Clear and fetch
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category Filter
                        SizedBox(
                          height: 44,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _kategoriList.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final kategori = _kategoriList[index];
                              final kategoriId = kategori['id'] as String;
                              final kategoriNama = kategori['nama'] as String;
                              final kategoriIcon =
                                  kategori['icon_path'] as String?;
                              final isSelected =
                                  kategoriNama == _selectedCategory;
                              final categoryColor = _getCategoryColor(
                                kategoriNama,
                              );
                              final categoryIcon = _getCategoryIcon(
                                kategoriNama,
                              );

                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index == _kategoriList.length - 1
                                      ? 0
                                      : 10,
                                ),
                                child: GestureDetector(
                                  onTap: () => _onCategoryChanged(
                                    kategoriId,
                                    kategoriNama,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                              colors: [
                                                categoryColor,
                                                categoryColor.withValues(
                                                  alpha: 0.8,
                                                ),
                                              ],
                                            )
                                          : null,
                                      color: isSelected ? null : Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: isSelected
                                            ? categoryColor
                                            : categoryColor.withValues(
                                                alpha: 0.2,
                                              ),
                                        width: isSelected ? 0 : 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: categoryColor.withValues(
                                                  alpha: 0.3,
                                                ),
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
                                        if (kategoriIcon != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: Image.network(
                                                kategoriIcon,
                                                width: 18,
                                                height: 18,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) => Icon(
                                                  categoryIcon,
                                                  size: 18,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : categoryColor,
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: Icon(
                                              categoryIcon,
                                              size: 18,
                                              color: isSelected
                                                  ? Colors.white
                                                  : categoryColor,
                                            ),
                                          ),

                                        // Category Name
                                        Text(
                                          kategoriNama,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : AppTheme.onSurface,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            fontSize:
                                                ResponsiveHelper.adaptiveTextSize(
                                                  context,
                                                  14,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: _maxWidth(context)),
                    child: _buildContentArea(
                      komunitasState,
                      currentPage,
                      lastPage,
                      useGrid,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isLoggedIn ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildContentArea(
    KomunitasState komunitasState,
    int currentPage,
    int lastPage,
    bool useGrid,
  ) {
    final status = komunitasState.status;
    final isOffline = komunitasState.isOffline;

    if ((status == KomunitasStatus.loading ||
            status == KomunitasStatus.initial) &&
        currentPage == 1 &&
        komunitasState.postinganList.isEmpty) {
      return _buildLoadingState();
    }

    if (status == KomunitasStatus.error && _postList.isEmpty) {
      return _buildErrorState(komunitasState.message);
    }

    if (_postList.isEmpty && status != KomunitasStatus.loading) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.primaryBlue,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _emptyState(),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (isOffline) ...[_buildOfflineIndicator(), const SizedBox(height: 8)],
        Expanded(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppTheme.primaryBlue,
            backgroundColor: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.isSmallScreen(context) ? 12 : 20,
              ),
              child: useGrid
                  ? GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 100),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _gridColumns(context),
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        childAspectRatio:
                            ResponsiveHelper.isExtraLargeScreen(context)
                            ? 0.78
                            : ResponsiveHelper.isLargeScreen(context)
                            ? 0.8
                            : 0.85,
                      ),
                      itemCount:
                          _postList.length +
                          ((currentPage < lastPage &&
                                  !isOffline &&
                                  status != KomunitasStatus.loadingMore)
                              ? 1
                              : 0),
                      itemBuilder: (context, index) {
                        if (index >= _postList.length) {
                          return _buildLoadMoreIndicator();
                        }
                        final post = _postList[index];
                        return _buildEnhancedPostCard(
                          post,
                          imageHeight: _cardImageHeight(context),
                        );
                      },
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 100),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount:
                          _postList.length +
                          ((currentPage < lastPage &&
                                  !isOffline &&
                                  status != KomunitasStatus.loadingMore)
                              ? 1
                              : 0),
                      itemBuilder: (context, index) {
                        if (index >= _postList.length) {
                          return _buildLoadMoreIndicator();
                        }
                        final post = _postList[index];
                        return _buildEnhancedPostCard(
                          post,
                          imageHeight: _cardImageHeight(context),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.orange.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are offline. Some features may be unavailable.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: ResponsiveHelper.adaptiveTextSize(context, 14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _handleRefresh,
            child: Text(
              'Retry',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: ResponsiveHelper.adaptiveTextSize(context, 12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Memuat postingan...',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: ResponsiveHelper.adaptiveTextSize(context, 16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan tunggu sebentar...',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: ResponsiveHelper.adaptiveTextSize(context, 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? errorMessage) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: ResponsiveHelper.adaptiveTextSize(context, 18),
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Terjadi kesalahan saat memuat postingan',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: ResponsiveHelper.adaptiveTextSize(context, 14),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(komunitasProvider.notifier).fetchPostingan();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.adaptiveTextSize(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _navigateToAddPost,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: ResponsiveHelper.adaptiveTextSize(context, 30),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Memuat lebih banyak...',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: ResponsiveHelper.adaptiveTextSize(context, 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withValues(alpha: 0.1),
                AppTheme.accentGreen.withValues(alpha: 0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.forum_outlined,
            size: ResponsiveHelper.adaptiveTextSize(context, 64),
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'No Discussions Yet',
          style: TextStyle(
            fontSize: ResponsiveHelper.adaptiveTextSize(context, 18),
            color: AppTheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          ref.watch(authProvider)['status'] == AuthState.authenticated
              ? 'Start a new discussion by pressing the + button'
              : 'Login to start a new discussion',
          style: TextStyle(
            fontSize: ResponsiveHelper.adaptiveTextSize(context, 14),
            color: AppTheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Pull down to refresh',
          style: TextStyle(
            fontSize: ResponsiveHelper.adaptiveTextSize(context, 12),
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEnhancedPostCard(
    Map<String, dynamic> post, {
    required double imageHeight,
  }) {
    final authState = ref.watch(authProvider);
    final currentUser = authState['user'];

    final isMyPost =
        currentUser != null &&
        post['authorId'].toString() == currentUser['id'].toString();

    final categoryColor = _getCategoryColor(post['kategoriNama'] as String?);
    final kategoriIconUrl = post['kategoriIcon'] as String?;
    final coverUrl = post['coverUrl'] as String?;

    return GestureDetector(
      onTap: () => _navigateToDetail(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: categoryColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header penulis
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          categoryColor.withValues(alpha: 0.2),
                          categoryColor.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Text(
                        (post['penulis'] ?? 'G')[0].toUpperCase(),
                        style: TextStyle(
                          color: categoryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveHelper.adaptiveTextSize(
                            context,
                            16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              (post['penulis'] ?? 'guest') as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveHelper.adaptiveTextSize(
                                  context,
                                  15,
                                ),
                              ),
                            ),
                            if (isMyPost) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Anda',
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontSize: ResponsiveHelper.adaptiveTextSize(
                                      context,
                                      10,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: AppTheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (post['date'] ?? '') as String,
                              style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: ResponsiveHelper.adaptiveTextSize(
                                  context,
                                  12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // More Options Button
                  IconButton(
                    onPressed: () => _showPostOptions(post),
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: AppTheme.onSurfaceVariant,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Chip kategori
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (kategoriIconUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            kategoriIconUrl,
                            width: 16,
                            height: 16,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.category_rounded,
                              size: 16,
                              color: categoryColor,
                            ),
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.category_rounded,
                        size: 16,
                        color: categoryColor,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      (post['kategoriNama'] ?? 'Umum') as String,
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: ResponsiveHelper.adaptiveTextSize(
                          context,
                          12.5,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Judul + excerpt
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (post['judul'] ?? '') as String,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.adaptiveTextSize(context, 17),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (post['excerpt'] ?? '') as String,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.adaptiveTextSize(context, 14),
                      color: AppTheme.onSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Cover image
            if (coverUrl != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: imageHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              categoryColor.withValues(alpha: 0.1),
                              categoryColor.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_rounded,
                            size: ResponsiveHelper.adaptiveTextSize(
                              context,
                              44,
                            ),
                            color: categoryColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      Image.network(
                        coverUrl,
                        width: double.infinity,
                        height: imageHeight,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 12,
                              sigmaY: 12,
                            ),
                            child: child,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: imageHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  categoryColor.withValues(alpha: 0.1),
                                  categoryColor.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.broken_image_rounded,
                              size: ResponsiveHelper.adaptiveTextSize(
                                context,
                                44,
                              ),
                              color: categoryColor.withValues(alpha: 0.4),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Actions
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_border,
                        color: AppTheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post['likesCount'] ?? 0}',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: ResponsiveHelper.adaptiveTextSize(
                            context,
                            13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 22),
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: AppTheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post['komentarsCount'] ?? 0}',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: ResponsiveHelper.adaptiveTextSize(
                            context,
                            13.5,
                          ),
                        ),
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

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel(); // Cancel timer on dispose
    super.dispose();
  }
}
