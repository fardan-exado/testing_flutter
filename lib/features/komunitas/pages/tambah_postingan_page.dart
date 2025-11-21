import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';

import 'package:test_flutter/features/komunitas/komunitas_provider.dart';
import 'package:test_flutter/features/komunitas/komunitas_state.dart';

class TambahPostinganPage extends ConsumerStatefulWidget {
  const TambahPostinganPage({super.key});

  @override
  ConsumerState<TambahPostinganPage> createState() =>
      _TambahPostinganPageState();
}

class _TambahPostinganPageState extends ConsumerState<TambahPostinganPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulCtrl = TextEditingController();
  final TextEditingController _kontenCtrl = TextEditingController();

  /// kategoriId yang dipilih (WAJIB sesuai backend)
  int? _selectedKategoriId;
  String _selectedKategoriNama = 'Ibadah';

  /// Cover image (WAJIB)
  XFile? _coverImage;

  /// Daftar gambar tambahan (opsional)
  List<XFile> _additionalImages = [];

  /// Anonymous mode (true/false)
  bool _isAnonymous = false;

  final Map<String, Uint8List> _imageBytesCache = {};

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, .25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();

    // Load kategori when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(komunitasProvider.notifier).fetchKategori();
    });
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _kontenCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  // ===== Helpers UI kategori =====
  Color _getCategoryColor(String nama) {
    switch (nama.toLowerCase()) {
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

  IconData _getCategoryIcon(String nama) {
    switch (nama.toLowerCase()) {
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

  // Get kategori list from provider
  List<Map<String, dynamic>> get _kategoriList {
    final kategori = ref.watch(komunitasProvider).kategori;
    if (kategori.isEmpty) {
      return [];
    }
    final storage = dotenv.env['STORAGE_URL'] ?? '';
    return kategori.map((e) {
      return {
        'id': e.id,
        'nama': e.nama,
        'icon_path': e.iconPath!.isNotEmpty && storage.isNotEmpty
            ? '$storage/${e.iconPath}'
            : null,
      };
    }).toList();
  }

  // Initialize selected kategori when data is loaded
  void _initializeKategori() {
    if (_selectedKategoriId == null && _kategoriList.isNotEmpty) {
      final firstKat = _kategoriList.first;
      setState(() {
        _selectedKategoriId = firstKat['id'];
        _selectedKategoriNama = firstKat['nama'] as String;
      });
    }
  }

  // ===== Gambar Cover =====
  Future<void> _pickCoverImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _coverImage = image);
        logger.info('[TambahPostingan] picked cover image');
      }
    } catch (e) {
      logger.warning('[TambahPostingan] pick cover image error: $e');
      if (mounted) {
        showMessageToast(
          context,
          message: 'Gagal memilih gambar cover: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _removeCoverImage() {
    setState(() => _coverImage = null);
  }

  // ===== Gambar Tambahan =====
  Future<void> _pickAdditionalImages() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() => _additionalImages.addAll(images));
        logger.info(
          '[TambahPostingan] picked ${images.length} additional images',
        );
      }
    } catch (e) {
      logger.warning('[TambahPostingan] pick additional images error: $e');
      if (mounted) {
        showMessageToast(
          context,
          message: 'Gagal memilih gambar: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _removeAdditionalImage(int index) {
    setState(() => _additionalImages.removeAt(index));
  }

  // ===== Submit =====
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final judul = _judulCtrl.text.trim();
    final konten = _kontenCtrl.text.trim();

    if (_coverImage == null) {
      showMessageToast(
        context,
        message: 'Gambar cover wajib diisi.',
        type: ToastType.error,
      );
      return;
    }

    if (_selectedKategoriId == null) {
      showMessageToast(
        context,
        message: 'Kategori wajib dipilih.',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      logger.fine(
        '[TambahPostingan] Creating postingan with kategoriId: $_selectedKategoriId, anonymous: $_isAnonymous',
      );

      // Menggunakan provider untuk create postingan
      await ref
          .read(komunitasProvider.notifier)
          .createPostingan(
            kategoriId: _selectedKategoriId!,
            judul: judul,
            cover: _coverImage!,
            konten: konten,
            daftarGambar: _additionalImages.isNotEmpty
                ? _additionalImages
                : null,
            isAnonymous: _isAnonymous,
          );

      // Check if success
      final state = ref.read(komunitasProvider);
      if (state.status == KomunitasStatus.success) {
        if (mounted) {
          showMessageToast(
            context,
            message: 'Postingan berhasil dibuat!',
            type: ToastType.success,
          );

          // Return with result
          Navigator.pop(context, true);
        }
      } else if (state.status == KomunitasStatus.error) {
        if (mounted) {
          showMessageToast(
            context,
            message: state.message ?? 'Gagal membuat postingan',
            type: ToastType.error,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e, st) {
      logger.severe('[TambahPostingan] submit error: $e', e, st);
      if (mounted) {
        showMessageToast(
          context,
          message: 'Gagal membuat postingan: $e',
          type: ToastType.error,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _handleBack() {
    if (_submitting) return;

    // Check if there's unsaved data
    final hasData =
        _judulCtrl.text.trim().isNotEmpty ||
        _kontenCtrl.text.trim().isNotEmpty ||
        _coverImage != null ||
        _additionalImages.isNotEmpty;

    if (hasData) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Batalkan Postingan?'),
          content: const Text(
            'Data yang sudah diisi akan hilang. Apakah Anda yakin ingin keluar?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Keluar'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  // ===== Responsive =====
  double _maxWidth(BuildContext context) {
    if (ResponsiveHelper.isExtraLargeScreen(context)) return 900;
    if (ResponsiveHelper.isLargeScreen(context)) return 820;
    if (ResponsiveHelper.isMediumScreen(context)) return 680;
    return double.infinity;
  }

  double _editorHeight(BuildContext context) {
    if (ResponsiveHelper.isExtraLargeScreen(context)) return 280;
    if (ResponsiveHelper.isLargeScreen(context)) return 260;
    if (ResponsiveHelper.isMediumScreen(context)) return 240;
    return 200;
  }

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveHelper.getResponsivePadding(context);
    final labelSize = ResponsiveHelper.adaptiveTextSize(context, 18);
    final inputSize = ResponsiveHelper.adaptiveTextSize(context, 15);
    final hintSize = ResponsiveHelper.adaptiveTextSize(context, 14);

    // Watch provider state for loading indicator
    final provState = ref.watch(komunitasProvider);
    final isProviderLoading = provState.status == KomunitasStatus.loading;

    // Get available categories
    final availableKategori = _kategoriList;

    // Initialize kategori when data is loaded
    if (availableKategori.isNotEmpty && _selectedKategoriId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeKategori();
      });
    }

    final catColor = _getCategoryColor(_selectedKategoriNama);
    final catIcon = _getCategoryIcon(_selectedKategoriNama);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBlue.withValues(alpha: .05),
              AppTheme.accentGreen.withValues(alpha: .03),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Container(
                padding: EdgeInsets.all(pad.left.clamp(12, 20)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: _maxWidth(context)),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlue.withValues(alpha: .1),
                                AppTheme.accentGreen.withValues(alpha: .1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: _submitting ? null : _handleBack,
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: AppTheme.primaryBlue,
                            iconSize: ResponsiveHelper.adaptiveTextSize(
                              context,
                              22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Buat Postingan',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.adaptiveTextSize(
                                    context,
                                    20,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onSurface,
                                  letterSpacing: -.3,
                                ),
                              ),
                              Text(
                                'Bagikan cerita, pengalaman, atau pertanyaanmu',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.adaptiveTextSize(
                                    context,
                                    13,
                                  ),
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_submitting || isProviderLoading)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Body
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: _maxWidth(context)),
                    child: availableKategori.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  'Memuat kategori...',
                                  style: TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: ResponsiveHelper.adaptiveTextSize(
                                      context,
                                      14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  ResponsiveHelper.isSmallScreen(context)
                                  ? 16
                                  : 20,
                              vertical: ResponsiveHelper.isSmallScreen(context)
                                  ? 16
                                  : 20,
                            ),
                            physics: const BouncingScrollPhysics(),
                            child: FadeTransition(
                              opacity: _fade,
                              child: SlideTransition(
                                position: _slide,
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Anonymous Toggle
                                      _CardBlock(
                                        borderColor: Colors.grey.withValues(
                                          alpha: .15,
                                        ),
                                        shadowColor: Colors.grey.withValues(
                                          alpha: .08,
                                        ),
                                        child: Row(
                                          children: [
                                            _IconBadge(
                                              color: _isAnonymous
                                                  ? Colors.grey.shade600
                                                  : AppTheme.primaryBlue,
                                              icon: _isAnonymous
                                                  ? Icons.visibility_off_rounded
                                                  : Icons.person_rounded,
                                              size:
                                                  ResponsiveHelper.adaptiveTextSize(
                                                    context,
                                                    22,
                                                  ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Mode Posting',
                                                    style: TextStyle(
                                                      fontSize: labelSize,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppTheme.onSurface,
                                                      letterSpacing: -.3,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _isAnonymous
                                                        ? 'Postingan akan ditampilkan sebagai Anonim'
                                                        : 'Postingan akan menggunakan nama Anda',
                                                    style: TextStyle(
                                                      fontSize:
                                                          ResponsiveHelper.adaptiveTextSize(
                                                            context,
                                                            13,
                                                          ),
                                                      color: AppTheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Switch(
                                              value: _isAnonymous,
                                              onChanged: _submitting
                                                  ? null
                                                  : (val) => setState(
                                                      () => _isAnonymous = val,
                                                    ),
                                              activeColor: AppTheme.accentGreen,
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // Kategori
                                      _CardBlock(
                                        borderColor: catColor.withValues(
                                          alpha: .12,
                                        ),
                                        shadowColor: catColor.withValues(
                                          alpha: .08,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                _IconBadge(
                                                  color: catColor,
                                                  icon: catIcon,
                                                  size:
                                                      ResponsiveHelper.adaptiveTextSize(
                                                        context,
                                                        22,
                                                      ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Kategori',
                                                  style: TextStyle(
                                                    fontSize: labelSize,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.onSurface,
                                                    letterSpacing: -.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: catColor.withValues(
                                                  alpha: .05,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: catColor.withValues(
                                                    alpha: .2,
                                                  ),
                                                ),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<int>(
                                                  value: _selectedKategoriId,
                                                  isExpanded: true,
                                                  icon: Icon(
                                                    Icons
                                                        .arrow_drop_down_rounded,
                                                    color: catColor,
                                                  ),
                                                  style: TextStyle(
                                                    color: AppTheme.onSurface,
                                                    fontSize: inputSize,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  items: availableKategori.map<DropdownMenuItem<int>>((
                                                    k,
                                                  ) {
                                                    final nama =
                                                        k['nama'] as String;
                                                    final id = k['id'] as int;
                                                    final kategoriIcon =
                                                        k['icon'] as String?;
                                                    final categoryColor =
                                                        _getCategoryColor(nama);
                                                    final categoryIcon =
                                                        _getCategoryIcon(nama);

                                                    return DropdownMenuItem<
                                                      int
                                                    >(
                                                      value: id,
                                                      child: Row(
                                                        children: [
                                                          if (kategoriIcon !=
                                                              null)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    right: 8,
                                                                  ),
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      4,
                                                                    ),
                                                                child: Image.network(
                                                                  kategoriIcon,
                                                                  width: 18,
                                                                  height: 18,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorBuilder:
                                                                      (
                                                                        _,
                                                                        __,
                                                                        ___,
                                                                      ) => Icon(
                                                                        categoryIcon,
                                                                        size:
                                                                            18,
                                                                        color:
                                                                            categoryColor,
                                                                      ),
                                                                ),
                                                              ),
                                                            )
                                                          else
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    right: 8,
                                                                  ),
                                                              child: Icon(
                                                                categoryIcon,
                                                                size: 18,
                                                                color:
                                                                    categoryColor,
                                                              ),
                                                            ),
                                                          Text(nama),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                  onChanged: _submitting
                                                      ? null
                                                      : (val) {
                                                          if (val == null) {
                                                            return;
                                                          }
                                                          final match = availableKategori
                                                              .firstWhere(
                                                                (e) =>
                                                                    e['id'] ==
                                                                    val,
                                                                orElse: () =>
                                                                    availableKategori
                                                                        .first,
                                                              );
                                                          setState(() {
                                                            _selectedKategoriId =
                                                                val;
                                                            _selectedKategoriNama =
                                                                (match['nama']
                                                                    as String?) ??
                                                                'Ibadah';
                                                          });
                                                        },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // Judul
                                      _CardBlock(
                                        borderColor: AppTheme.primaryBlue
                                            .withValues(alpha: .1),
                                        shadowColor: AppTheme.primaryBlue
                                            .withValues(alpha: .08),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                _IconBadge(
                                                  color: AppTheme.primaryBlue,
                                                  icon: Icons.title_rounded,
                                                  size:
                                                      ResponsiveHelper.adaptiveTextSize(
                                                        context,
                                                        22,
                                                      ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Judul',
                                                  style: TextStyle(
                                                    fontSize: labelSize,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.onSurface,
                                                    letterSpacing: -.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            TextFormField(
                                              controller: _judulCtrl,
                                              enabled: !_submitting,
                                              validator: (v) =>
                                                  (v == null ||
                                                      v.trim().isEmpty)
                                                  ? 'Judul wajib diisi'
                                                  : null,
                                              decoration: InputDecoration(
                                                hintText:
                                                    'Masukkan judul yang informatif...',
                                                hintStyle: TextStyle(
                                                  fontSize: hintSize,
                                                  color: AppTheme
                                                      .onSurfaceVariant
                                                      .withValues(alpha: .6),
                                                ),
                                                filled: true,
                                                fillColor: AppTheme.primaryBlue
                                                    .withValues(alpha: .05),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: AppTheme
                                                            .primaryBlue,
                                                        width: 2,
                                                      ),
                                                    ),
                                                errorBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: Colors.red.shade400,
                                                    width: 1,
                                                  ),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.all(16),
                                              ),
                                              maxLines: 2,
                                              style: TextStyle(
                                                fontSize: inputSize,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // Cover Image (WAJIB)
                                      _CardBlock(
                                        borderColor: Colors.orange.withValues(
                                          alpha: .12,
                                        ),
                                        shadowColor: Colors.orange.withValues(
                                          alpha: .08,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                _IconBadge(
                                                  color: Colors.orange.shade600,
                                                  icon: Icons.image_rounded,
                                                  size:
                                                      ResponsiveHelper.adaptiveTextSize(
                                                        context,
                                                        22,
                                                      ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'Gambar Cover',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  labelSize,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: AppTheme
                                                                  .onSurface,
                                                              letterSpacing:
                                                                  -.3,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .red
                                                                      .shade100,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        4,
                                                                      ),
                                                                ),
                                                            child: Text(
                                                              'WAJIB',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .red
                                                                    .shade700,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Gambar utama untuk postingan',
                                                        style: TextStyle(
                                                          fontSize:
                                                              ResponsiveHelper.adaptiveTextSize(
                                                                context,
                                                                12,
                                                              ),
                                                          color: AppTheme
                                                              .onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (_coverImage == null)
                                                  TextButton.icon(
                                                    onPressed: _submitting
                                                        ? null
                                                        : _pickCoverImage,
                                                    icon: const Icon(
                                                      Icons.add_photo_alternate,
                                                      size: 18,
                                                    ),
                                                    label: const Text('Pilih'),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: Colors
                                                          .orange
                                                          .shade700,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (_coverImage != null) ...[
                                              const SizedBox(height: 12),
                                              Container(
                                                height: 200,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.orange
                                                        .withValues(alpha: .2),
                                                  ),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child: SizedBox(
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                        child: _thumb(
                                                          _coverImage!,
                                                          size: 200,
                                                        ),
                                                      ),
                                                    ),
                                                    // Badge COVER
                                                    Positioned(
                                                      bottom: 8,
                                                      left: 8,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 6,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .orange
                                                              .shade600,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                              blurRadius: 4,
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Text(
                                                          'COVER',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // Change/Remove buttons
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Row(
                                                        children: [
                                                          GestureDetector(
                                                            onTap: _submitting
                                                                ? null
                                                                : _pickCoverImage,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    8,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: AppTheme
                                                                    .primaryBlue,
                                                                shape: BoxShape
                                                                    .circle,
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .black
                                                                        .withValues(
                                                                          alpha:
                                                                              0.3,
                                                                        ),
                                                                    blurRadius:
                                                                        4,
                                                                  ),
                                                                ],
                                                              ),
                                                              child: const Icon(
                                                                Icons.edit,
                                                                color: Colors
                                                                    .white,
                                                                size: 18,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          GestureDetector(
                                                            onTap: _submitting
                                                                ? null
                                                                : _removeCoverImage,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    8,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    Colors.red,
                                                                shape: BoxShape
                                                                    .circle,
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .black
                                                                        .withValues(
                                                                          alpha:
                                                                              0.3,
                                                                        ),
                                                                    blurRadius:
                                                                        4,
                                                                  ),
                                                                ],
                                                              ),
                                                              child: const Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .white,
                                                                size: 18,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // Konten
                                      _CardBlock(
                                        borderColor: AppTheme.accentGreen
                                            .withValues(alpha: .1),
                                        shadowColor: AppTheme.accentGreen
                                            .withValues(alpha: .08),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                _IconBadge(
                                                  color: AppTheme.accentGreen,
                                                  icon: Icons.article_rounded,
                                                  size:
                                                      ResponsiveHelper.adaptiveTextSize(
                                                        context,
                                                        22,
                                                      ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Konten',
                                                  style: TextStyle(
                                                    fontSize: labelSize,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.onSurface,
                                                    letterSpacing: -.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              height: _editorHeight(context),
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentGreen
                                                    .withValues(alpha: .05),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppTheme.accentGreen
                                                      .withValues(alpha: .1),
                                                ),
                                              ),
                                              child: TextFormField(
                                                controller: _kontenCtrl,
                                                enabled: !_submitting,
                                                validator: (v) =>
                                                    (v == null ||
                                                        v.trim().isEmpty)
                                                    ? 'Konten wajib diisi'
                                                    : null,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Tulis isi postinganmu di sini…',
                                                  hintStyle: TextStyle(
                                                    fontSize: hintSize,
                                                    color: AppTheme
                                                        .onSurfaceVariant
                                                        .withValues(alpha: .6),
                                                    height: 1.5,
                                                  ),
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      const EdgeInsets.all(16),
                                                ),
                                                maxLines: null,
                                                expands: true,
                                                textAlignVertical:
                                                    TextAlignVertical.top,
                                                style: TextStyle(
                                                  fontSize: inputSize,
                                                  height: 1.6,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // Additional Images (opsional)
                                      _CardBlock(
                                        borderColor: Colors.purple.withValues(
                                          alpha: .12,
                                        ),
                                        shadowColor: Colors.purple.withValues(
                                          alpha: .08,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                _IconBadge(
                                                  color: Colors.purple.shade600,
                                                  icon: Icons
                                                      .photo_library_rounded,
                                                  size:
                                                      ResponsiveHelper.adaptiveTextSize(
                                                        context,
                                                        22,
                                                      ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Gambar Tambahan',
                                                        style: TextStyle(
                                                          fontSize: labelSize,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppTheme
                                                              .onSurface,
                                                          letterSpacing: -.3,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Opsional - Tambahkan lebih banyak foto',
                                                        style: TextStyle(
                                                          fontSize:
                                                              ResponsiveHelper.adaptiveTextSize(
                                                                context,
                                                                12,
                                                              ),
                                                          color: AppTheme
                                                              .onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                TextButton.icon(
                                                  onPressed: _submitting
                                                      ? null
                                                      : _pickAdditionalImages,
                                                  icon: const Icon(
                                                    Icons.add_photo_alternate,
                                                    size: 18,
                                                  ),
                                                  label: const Text('Pilih'),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.purple.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (_additionalImages
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                height: 120,
                                                child: ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount:
                                                      _additionalImages.length,
                                                  itemBuilder: (context, i) {
                                                    return Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            right: 12,
                                                          ),
                                                      width: 120,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.purple
                                                              .withValues(
                                                                alpha: .2,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                            child: _thumb(
                                                              _additionalImages[i],
                                                            ),
                                                          ),
                                                          // Remove button
                                                          Positioned(
                                                            top: 4,
                                                            right: 4,
                                                            child: GestureDetector(
                                                              onTap: _submitting
                                                                  ? null
                                                                  : () =>
                                                                        _removeAdditionalImage(
                                                                          i,
                                                                        ),
                                                              child: Container(
                                                                padding:
                                                                    const EdgeInsets.all(
                                                                      4,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .red,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Colors
                                                                          .black
                                                                          .withValues(
                                                                            alpha:
                                                                                0.3,
                                                                          ),
                                                                      blurRadius:
                                                                          4,
                                                                    ),
                                                                  ],
                                                                ),
                                                                child: const Icon(
                                                                  Icons.close,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 16,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 22),

                                      // Submit Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppTheme.primaryBlue,
                                                AppTheme.accentGreen,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryBlue
                                                    .withValues(alpha: .3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _submitting
                                                ? null
                                                : _submit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding: EdgeInsets.symmetric(
                                                vertical:
                                                    ResponsiveHelper.isSmallScreen(
                                                      context,
                                                    )
                                                    ? 14
                                                    : 16,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: _submitting
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.publish_rounded,
                                                        color: Colors.white,
                                                        size:
                                                            ResponsiveHelper.adaptiveTextSize(
                                                              context,
                                                              22,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Publikasikan',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize:
                                                              ResponsiveHelper.adaptiveTextSize(
                                                                context,
                                                                16,
                                                              ),
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
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== Image thumb (Web/Mobile) ======
  Widget _thumb(XFile file, {double size = 120}) {
    if (!kIsWeb) {
      return Image.file(
        File(file.path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _thumbError(size),
      );
    }
    final cached = _imageBytesCache[file.path];
    if (cached != null) {
      return Image.memory(
        cached,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _thumbError(size),
      );
    }
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes().then((b) {
        _imageBytesCache[file.path] = b;
        return b;
      }),
      builder: (context, snap) {
        if (snap.hasData) {
          return Image.memory(
            snap.data!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _thumbError(size),
          );
        }
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }

  Widget _thumbError(double size) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.broken_image, color: Colors.grey.shade400),
  );
}

// ===== Reusable UI =====
class _CardBlock extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color shadowColor;
  const _CardBlock({
    required this.child,
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.isSmallScreen(context) ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -5,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;
  const _IconBadge({
    required this.color,
    required this.icon,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.isSmallScreen(context) ? 8 : 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}
