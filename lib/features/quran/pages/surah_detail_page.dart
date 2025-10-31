import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/storage_helper.dart';
import 'package:test_flutter/data/models/quran/surah.dart';
import 'package:test_flutter/features/quran/services/quran_audio_service.dart';
import 'package:test_flutter/features/quran/services/quran_download_manager.dart';
import 'package:test_flutter/features/quran/widgets/ayah_card.dart';
import 'package:test_flutter/features/quran/widgets/modern_audio_player.dart';
import 'package:test_flutter/features/quran/widgets/download_audio_sheet.dart';

class SurahDetailPage extends StatefulWidget {
  final Surah surah;
  final List<Surah> allSurahs;
  final int? initialAyat;

  const SurahDetailPage({
    super.key,
    required this.surah,
    this.allSurahs = const [],
    this.initialAyat,
  });

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage>
    with SingleTickerProviderStateMixin {
  bool _isLoadingAudio = false;
  bool _isDownloaded = false;
  int _selectedQoriId = 1;
  int _currentPlayingVerse = 0;
  String? _qariName;
  int _currentSurahIndex = 0;
  bool _isGuest = true; // Default to guest until checked

  late TabController _tabController;
  late PageController _pageController;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};

  // Cache untuk detail surah yang sudah dimuat
  final Map<int, Map<String, dynamic>> _surahDetailsCache = {};
  bool _isLoadingDetails = false;

  bool get _showTabs =>
      widget.allSurahs.isNotEmpty && widget.allSurahs.length > 1;

  @override
  void initState() {
    super.initState();

    // Debug: Print allSurahs info
    print('📋 allSurahs length: ${widget.allSurahs.length}');
    print('📋 _showTabs: $_showTabs');

    if (_showTabs) {
      final initialIndex = widget.allSurahs.indexWhere(
        (s) => s.nomor == widget.surah.nomor,
      );

      _currentSurahIndex = initialIndex >= 0 ? initialIndex : 0;

      print('📖 Initializing with surah: ${widget.surah.namaLatin}');
      print('📖 Initial index: $_currentSurahIndex');
      print('📖 Total surahs: ${widget.allSurahs.length}');

      _tabController = TabController(
        length: widget.allSurahs.length,
        vsync: this,
        initialIndex: _currentSurahIndex,
      );
      _pageController = PageController(initialPage: _currentSurahIndex);

      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          _pageController.animateToPage(
            _tabController.index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    } else {
      print('📖 Single surah mode: ${widget.surah.namaLatin}');
      print('📖 Reason: allSurahs.length = ${widget.allSurahs.length}');
    }

    // Check authentication status
    _checkAuthStatus();

    // Load initial surah details
    _loadSurahDetails(_currentSurah.nomor);
    _loadSelectedQori();
    _checkDownloadStatus();
    _listenToCurrentVerse();
  }

  Future<void> _checkAuthStatus() async {
    final token = await StorageHelper.getToken();
    if (mounted) {
      setState(() {
        _isGuest = token == null || token.isEmpty;
      });
    }
  }

  @override
  void dispose() {
    QuranAudioService.stop();
    if (_showTabs) {
      _tabController.dispose();
      _pageController.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Surah get _currentSurah =>
      _showTabs ? widget.allSurahs[_currentSurahIndex] : widget.surah;

  // Load detail surah dari JSON file
  Future<Map<String, dynamic>?> _loadSurahDetails(int surahNumber) async {
    // Check cache first
    if (_surahDetailsCache.containsKey(surahNumber)) {
      return _surahDetailsCache[surahNumber];
    }

    setState(() => _isLoadingDetails = true);

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/quran/surah/$surahNumber.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Cache the result
      _surahDetailsCache[surahNumber] = jsonData;

      print('✅ Loaded surah $surahNumber details from JSON');

      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }

      return jsonData;
    } catch (e) {
      print('❌ Error loading surah $surahNumber details: $e');

      if (mounted) {
        setState(() => _isLoadingDetails = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading surah details: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _loadSelectedQori() async {
    final prefs = await SharedPreferences.getInstance();
    final savedQoriId = prefs.getInt('selected_qori_${_currentSurah.nomor}');

    if (savedQoriId != null) {
      setState(() {
        _selectedQoriId = savedQoriId;
      });
      print(
        '📖 Loaded saved qori ID: $savedQoriId for ${_currentSurah.namaLatin}',
      );
    }

    await _checkDownloadStatus();
  }

  Future<void> _saveSelectedQori(int qoriId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_qori_${_currentSurah.nomor}', qoriId);
    print('💾 Saved qori ID: $qoriId for ${_currentSurah.namaLatin}');
  }

  Future<void> _checkDownloadStatus() async {
    final isDownloaded = await QuranDownloadManager.isDownloaded(
      _currentSurah.nomor,
      _selectedQoriId,
    );

    if (mounted) {
      setState(() {
        _isDownloaded = isDownloaded;
      });
    }

    if (isDownloaded) {
      final localPath = await QuranDownloadManager.getLocalPath(
        _currentSurah.nomor,
        _selectedQoriId,
      );

      final file = File(localPath);
      final exists = await file.exists();

      if (!exists) {
        setState(() {
          _isDownloaded = false;
          _qariName = null;
        });
      } else {
        final qariName = await QuranDownloadManager.getQoriName(
          _selectedQoriId,
        );
        setState(() {
          _qariName = qariName;
        });
        print('✅ Loaded qari name: $qariName');
      }
    }
  }

  void _listenToCurrentVerse() {
    QuranAudioService.currentVerseStream.listen((verseNumber) {
      if (mounted && verseNumber != _currentPlayingVerse) {
        setState(() {
          _currentPlayingVerse = verseNumber;
        });
        _scrollToVerse(verseNumber);
      }
    });
  }

  void _scrollToVerse(int verseNumber) {
    final key = _verseKeys[verseNumber];
    print(
      '🔍 Scrolling to verse $verseNumber, key exists: ${key != null}, context exists: ${key?.currentContext != null}',
    );

    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
      print('✅ Scrolled to verse $verseNumber');
    } else {
      print('⚠️ Context null for verse $verseNumber');
    }
  }

  void _scrollToVerseWithJump(int verseNumber) {
    print('🎯 Jump to verse $verseNumber');

    // Estimate card height (average ~350px per card including margin)
    final estimatedCardHeight = 350.0;
    final estimatedOffset = (verseNumber - 1) * estimatedCardHeight;

    // Check if scroll controller is attached
    if (!_scrollController.hasClients) {
      print('❌ ScrollController not attached yet');
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _scrollToVerseWithJump(verseNumber);
      });
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final targetOffset = estimatedOffset.clamp(0.0, maxScroll);

    print('📍 Jumping to offset: $targetOffset (max: $maxScroll)');

    // Jump instantly without animation
    _scrollController.jumpTo(targetOffset);

    // After jump, try to use precise positioning WITHOUT animation
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;

      final key = _verseKeys[verseNumber];
      if (key != null && key.currentContext != null) {
        print('✅ Fine-tuning position');
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: Duration.zero, // NO animation
          alignment: 0.1,
        );
      } else {
        print('⚠️ Context null, retrying...');
        // Quick retry
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && key != null && key.currentContext != null) {
            Scrollable.ensureVisible(
              key.currentContext!,
              duration: Duration.zero, // NO animation
              alignment: 0.1,
            );
            print('✅ Scrolled to verse $verseNumber');
          }
        });
      }
    });
  }

  Future<void> _playPause() async {
    try {
      final isCurrentlyPlaying = QuranAudioService.isPlaying;

      if (isCurrentlyPlaying) {
        await QuranAudioService.pause();
        return;
      }

      setState(() => _isLoadingAudio = true);

      if (_isDownloaded) {
        final localPath = await QuranDownloadManager.getLocalPath(
          _currentSurah.nomor,
          _selectedQoriId,
        );

        final qoriName =
            await QuranDownloadManager.getQoriName(_selectedQoriId) ??
            'Unknown Qori';

        await QuranAudioService.playFromFile(
          localPath,
          _currentSurah.namaLatin,
          qoriName,
          _currentSurah.nama,
          _currentSurah.jumlahAyat,
        );
      } else {
        _showDownloadDialog();
        setState(() => _isLoadingAudio = false);
        return;
      }
    } catch (e) {
      print('❌ Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  void _showDownloadDialog() {
    // Check if user is guest
    if (_isGuest) {
      _showGuestDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DownloadAudioSheet(
        surah: _currentSurah,
        selectedQoriId: _selectedQoriId,
        onDownloadComplete: (int qoriId) async {
          setState(() {
            _selectedQoriId = qoriId;
          });
          await _saveSelectedQori(qoriId);
          await _checkDownloadStatus();
        },
      ),
    );
  }

  void _showGuestDialog() {
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
          'Silakan login terlebih dahulu untuk menggunakan fitur download audio dan bookmark.',
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

  Future<void> _seekTo(double value) async {
    final duration = QuranAudioService.duration;
    final position = Duration(
      milliseconds: (value * duration.inMilliseconds).round(),
    );
    await QuranAudioService.seek(position);
  }

  Future<void> _deleteDownload() async {
    // Check if user is guest
    if (_isGuest) {
      _showGuestDialog();
      return;
    }

    final success = await QuranDownloadManager.deleteSurah(
      _currentSurah.nomor,
      _selectedQoriId,
    );

    if (success && mounted) {
      setState(() {
        _isDownloaded = false;
        _qariName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Download deleted successfully'),
            ],
          ),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentSurahIndex = index;
    });
    _tabController.animateTo(index);

    // Load new surah details
    _loadSurahDetails(_currentSurah.nomor);
    _loadSelectedQori();
    _checkDownloadStatus();

    print('📖 Changed to surah: ${_currentSurah.namaLatin}');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue.withOpacity(0.03),
              AppTheme.backgroundWhite,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isTablet, isDesktop),
              if (_showTabs) _buildTabBar(),
              Expanded(
                child: _showTabs
                    ? PageView.builder(
                        controller: _pageController,
                        itemCount: widget.allSurahs.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          final currentSurah = widget.allSurahs[index];
                          return _buildAyahsList(
                            currentSurah,
                            isTablet,
                            isDesktop,
                            _isGuest,
                          );
                        },
                      )
                    : _buildAyahsList(
                        _currentSurah,
                        isTablet,
                        isDesktop,
                        _isGuest,
                      ),
              ),
              ModernAudioPlayer(
                isLoading: _isLoadingAudio,
                onPlayPause: _playPause,
                onSeek: _seekTo,
                isDownloaded: _isDownloaded,
                onDownload: _showDownloadDialog,
                onDelete: _deleteDownload,
                qariName: _qariName,
                surahName: _currentSurah.namaLatin,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 14 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop
                ? 48
                : isTablet
                ? 44
                : 40,
            height: isDesktop
                ? 48
                : isTablet
                ? 44
                : 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.1),
                  AppTheme.accentGreen.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppTheme.primaryBlue,
              iconSize: isTablet ? 20 : 18,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _currentSurah.namaLatin,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: isDesktop
                              ? 22
                              : isTablet
                              ? 21
                              : 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (_isDownloaded) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download_done_rounded,
                              size: 14,
                              color: AppTheme.accentGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Downloaded',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${_currentSurah.jumlahAyat} Ayat • ${_currentSurah.tempatTurun == 'Mekah' ? 'Makkiyah' : 'Madaniyyah'}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isTablet ? 14 : 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _currentSurah.nama,
            style: TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: isDesktop
                  ? 28
                  : isTablet
                  ? 26
                  : 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.accentGreen,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: AppTheme.onSurfaceVariant,
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        tabs: widget.allSurahs.map((surah) {
          return Tab(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.1),
                          AppTheme.accentGreen.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${surah.nomor}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(surah.namaLatin),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAyahsList(
    Surah surah,
    bool isTablet,
    bool isDesktop,
    bool isGuest,
  ) {
    // Get cached details
    final surahDetails = _surahDetailsCache[surah.nomor];

    if (_isLoadingDetails || surahDetails == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryBlue),
            const SizedBox(height: 16),
            Text(
              'Loading ayahs...',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final List<dynamic> ayahs = surahDetails['ayat'] ?? [];
    final totalVerses = ayahs.length;

    // Initialize verse keys if not already done for this surah
    if (_verseKeys.isEmpty || _verseKeys.length != totalVerses) {
      _verseKeys.clear();
      for (int i = 1; i <= totalVerses; i++) {
        _verseKeys[i] = GlobalKey();
      }
    }

    // Check if should show Bismillah
    // Show Bismillah for all surahs except Al-Fatihah (1) and At-Taubah (9)
    final showBismillah = surah.nomor != 1 && surah.nomor != 9;

    // Schedule instant jump after ListView is built
    if (widget.initialAyat != null &&
        widget.initialAyat! > 0 &&
        widget.initialAyat! <= totalVerses) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Immediate jump without delay
        if (mounted) {
          print('🔍 Jumping to ayat ${widget.initialAyat}');
          _scrollToVerseWithJump(widget.initialAyat!);
        }
      });
    }

    return ListView.builder(
      key: ValueKey('surah_${surah.nomor}'),
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 20,
        vertical: isTablet ? 12 : 8,
      ),
      physics: const BouncingScrollPhysics(),
      cacheExtent: 10000, // Force ListView to render more items offscreen
      itemCount: showBismillah ? totalVerses + 1 : totalVerses,
      itemBuilder: (context, index) {
        // Show Bismillah as first item
        if (showBismillah && index == 0) {
          return _buildBismillahCard(isTablet, isDesktop);
        }

        // Adjust index if Bismillah is shown
        final ayahIndex = showBismillah ? index - 1 : index;
        final ayah = ayahs[ayahIndex];
        final verseNumber = ayah['nomorAyat'] as int;
        final arabicText = ayah['teksArab'] as String;
        final translation = ayah['teksIndonesia'] as String;
        final transliteration = ayah['teksLatin'] as String? ?? '';

        // Generate verse end symbol
        final verseEndSymbol = _toArabicNumber(verseNumber);
        final isCurrentlyPlaying = _currentPlayingVerse == verseNumber;

        return AyahCard(
          surahNumber: surah.nomor,
          key: _verseKeys[verseNumber],
          verseNumber: verseNumber,
          arabicText: arabicText,
          translation: translation,
          transliteration: transliteration,
          verseEndSymbol: verseEndSymbol,
          onPlayVerse: () {},
          isTablet: isTablet,
          isDesktop: isDesktop,
          isPlaying: isCurrentlyPlaying,
          isGuest: isGuest,
        );
      },
    );
  }

  // Build Bismillah card
  Widget _buildBismillahCard(bool isTablet, bool isDesktop) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      padding: EdgeInsets.all(
        isDesktop
            ? 32
            : isTablet
            ? 28
            : 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.08),
            AppTheme.accentGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 22 : 20),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: isTablet ? 8 : 6),
          // Bismillah text
          Text(
            'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
            style: TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: isDesktop
                  ? 28
                  : isTablet
                  ? 26
                  : 24,
              height: 2.0,
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),

          SizedBox(height: isTablet ? 16 : 12),

          // Translation
          Text(
            'Dengan nama Allah Yang Maha Pengasih lagi Maha Penyayang',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isDesktop
                  ? 15
                  : isTablet
                  ? 14
                  : 13,
              color: AppTheme.onSurface.withOpacity(0.75),
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper function to convert number to Arabic numerals (without ۝ symbol)
  String _toArabicNumber(int number) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicNumbers[int.parse(digit)])
        .join('');
  }
}
