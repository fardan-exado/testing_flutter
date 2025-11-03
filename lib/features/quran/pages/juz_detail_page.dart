import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/data/models/quran/juz.dart';
import 'package:test_flutter/features/auth/auth_provider.dart';
import 'package:test_flutter/features/quran/widgets/ayah_card.dart';

class JuzDetailPage extends ConsumerStatefulWidget {
  final Juz juz;
  final List<Juz> allJuz;

  const JuzDetailPage({super.key, required this.juz, this.allJuz = const []});

  @override
  ConsumerState<JuzDetailPage> createState() => _JuzDetailPageState();
}

class _JuzDetailPageState extends ConsumerState<JuzDetailPage>
    with SingleTickerProviderStateMixin {
  int _currentJuzIndex = 0;

  late TabController _tabController;
  late PageController _pageController;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final Map<String, GlobalKey> _verseKeys = {};
  bool _showScrollIndex = false;
  int _currentScrollIndex = 1;

  // Cache untuk detail juz yang sudah dimuat
  final Map<int, List<JuzSurahData>> _juzDetailsCache = {};
  bool _isLoadingDetails = false;

  bool get _showTabs => widget.allJuz.isNotEmpty && widget.allJuz.length > 1;

  @override
  void initState() {
    super.initState();

    if (_showTabs) {
      final initialIndex = widget.allJuz.indexWhere(
        (j) => j.number == widget.juz.number,
      );

      _currentJuzIndex = initialIndex >= 0 ? initialIndex : 0;

      print('📖 Initializing with juz: ${widget.juz.number}');
      print('📖 Initial index: $_currentJuzIndex');
      print('📖 Total juz: ${widget.allJuz.length}');

      _tabController = TabController(
        length: widget.allJuz.length,
        vsync: this,
        initialIndex: _currentJuzIndex,
      );
      _pageController = PageController(initialPage: _currentJuzIndex);

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
      print('📖 Single juz mode: ${widget.juz.number}');
    }

    // Load initial juz details
    _loadJuzDetails(_currentJuz);
    _listenToScrollPosition();
  }

  void _listenToScrollPosition() {
    _itemPositionsListener.itemPositions.addListener(() {
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        // Get the first visible item
        final firstVisible = positions
            .where((pos) => pos.itemLeadingEdge >= 0)
            .toList();
        if (firstVisible.isNotEmpty) {
          firstVisible.sort(
            (a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge),
          );
          if (mounted) {
            setState(() {
              _currentScrollIndex = firstVisible.first.index + 1;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    if (_showTabs) {
      _tabController.dispose();
      _pageController.dispose();
    }
    super.dispose();
  }

  Juz get _currentJuz =>
      _showTabs ? widget.allJuz[_currentJuzIndex] : widget.juz;

  // Load detail juz dari multiple surah JSON files
  Future<List<JuzSurahData>> _loadJuzDetails(Juz juz) async {
    // Check cache first
    if (_juzDetailsCache.containsKey(juz.number)) {
      print('📦 Using cached data for juz ${juz.number}');
      return _juzDetailsCache[juz.number]!;
    }

    if (mounted) {
      setState(() => _isLoadingDetails = true);
    }

    final List<JuzSurahData> juzData = [];

    try {
      // Juz bisa mencakup beberapa surah
      for (
        int surahNum = juz.startSurah;
        surahNum <= juz.endSurah;
        surahNum++
      ) {
        final String jsonString = await rootBundle.loadString(
          'assets/quran/surah/$surahNum.json',
        );
        final Map<String, dynamic> surahData = json.decode(jsonString);

        // Determine verse range for this surah in the juz
        int startVerse;
        int endVerse;

        if (surahNum == juz.startSurah && surahNum == juz.endSurah) {
          // Juz starts and ends in the same surah
          startVerse = juz.startAyah;
          endVerse = juz.endAyah;
        } else if (surahNum == juz.startSurah) {
          // First surah of juz
          startVerse = juz.startAyah;
          endVerse = surahData['jumlahAyat'];
        } else if (surahNum == juz.endSurah) {
          // Last surah of juz
          startVerse = 1;
          endVerse = juz.endAyah;
        } else {
          // Middle surah (all verses)
          startVerse = 1;
          endVerse = surahData['jumlahAyat'];
        }

        // Filter ayahs based on verse range
        final List<dynamic> allAyahs = surahData['ayat'];
        final List<dynamic> filteredAyahs = allAyahs.where((ayah) {
          final verseNum = ayah['nomorAyat'] as int;
          return verseNum >= startVerse && verseNum <= endVerse;
        }).toList();

        juzData.add(
          JuzSurahData(
            surahNumber: surahNum,
            surahName: surahData['namaLatin'],
            surahNameArabic: surahData['nama'],
            startVerse: startVerse,
            endVerse: endVerse,
            ayahs: filteredAyahs,
          ),
        );

        print(
          '✅ Loaded Surah $surahNum: verses $startVerse-$endVerse (${filteredAyahs.length} ayahs)',
        );
      }

      // Cache the result
      _juzDetailsCache[juz.number] = juzData;

      print('✅ Loaded juz ${juz.number} details (${juzData.length} surahs)');
    } catch (e) {
      print('❌ Error loading juz ${juz.number} details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }

    return juzData;
  }

  int _getTotalVersesInJuz(List<JuzSurahData> juzData) {
    return juzData.fold(0, (sum, surah) => sum + surah.ayahs.length);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentJuzIndex = index;
    });
    _tabController.animateTo(index);

    // Load new juz details
    _loadJuzDetails(_currentJuz);

    print('📖 Changed to juz: ${_currentJuz.number}');
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
                        itemCount: widget.allJuz.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          final currentJuz = widget.allJuz[index];
                          return _buildAyahsList(
                            currentJuz,
                            isTablet,
                            isDesktop,
                          );
                        },
                      )
                    : _buildAyahsList(_currentJuz, isTablet, isDesktop),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet, bool isDesktop) {
    final juzData = _juzDetailsCache[_currentJuz.number];
    final totalVerses = juzData != null ? _getTotalVersesInJuz(juzData) : 0;

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
                Text(
                  'Juz ${_currentJuz.number}',
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
                Text(
                  totalVerses > 0
                      ? '$totalVerses Ayat • ${_currentJuz.startSurahName} - ${_currentJuz.endSurahName}'
                      : '${_currentJuz.startSurahName} - ${_currentJuz.endSurahName}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isTablet ? 14 : 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.1),
                  AppTheme.accentGreen.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${_currentJuz.number}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
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
        tabs: widget.allJuz.map((juz) {
          return Tab(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                        '${juz.number}',
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
                  Text('Juz ${juz.number}'),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAyahsList(Juz juz, bool isTablet, bool isDesktop) {
    _verseKeys.clear();

    // Check auth status
    final authState = ref.watch(authProvider);
    final isGuest = authState['status'] != AuthState.authenticated;

    // Get cached juz data
    final juzData = _juzDetailsCache[juz.number];

    if (_isLoadingDetails || juzData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryBlue),
            const SizedBox(height: 16),
            Text(
              'Loading juz ${juz.number}...',
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

    // Flatten structure: create list items (header + ayahs)
    final List<Widget> allItems = [];
    int totalAyahs = 0;

    for (final surahData in juzData) {
      // Add surah header
      allItems.add(_buildSurahHeader(surahData, isTablet, isDesktop));

      // Add ayahs
      for (final ayah in surahData.ayahs) {
        totalAyahs++;
        final verseNumber = ayah['nomorAyat'] as int;
        final verseKey = '${surahData.surahNumber}_$verseNumber';
        _verseKeys[verseKey] = GlobalKey();

        final arabicText = ayah['teksArab'] as String;
        final translation = ayah['teksIndonesia'] as String;
        final transliteration = ayah['teksLatin'] as String? ?? '';
        final verseEndSymbol = _toArabicNumber(verseNumber);

        allItems.add(
          AyahCard(
            surahNumber: surahData.surahNumber,
            key: _verseKeys[verseKey],
            verseNumber: verseNumber,
            arabicText: arabicText,
            translation: translation,
            transliteration: transliteration,
            verseEndSymbol: verseEndSymbol,
            onPlayVerse: () {
              print(
                '🎵 Play Surah ${surahData.surahNumber}, Ayah $verseNumber',
              );
            },
            isTablet: isTablet,
            isDesktop: isDesktop,
            isPlaying: false,
            isGuest: isGuest,
          ),
        );
      }
    }

    return Stack(
      children: [
        ScrollablePositionedList.builder(
          key: ValueKey('juz_${juz.number}'),
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 12 : 8,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: allItems.length,
          itemBuilder: (context, index) => allItems[index],
        ),

        // Fast scroll indicator
        _buildFastScrollIndicator(totalAyahs, isTablet),
      ],
    );
  }

  Widget _buildSurahHeader(
    JuzSurahData surahData,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.accentGreen.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${surahData.surahNumber}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surahData.surahName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                Text(
                  '${surahData.ayahs.length} Ayat • Ayat ${surahData.startVerse} - ${surahData.endVerse}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            surahData.surahNameArabic,
            style: TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  // Fast scroll indicator widget
  Widget _buildFastScrollIndicator(int totalVerses, bool isTablet) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 20,
      child: GestureDetector(
        onVerticalDragStart: (_) {
          setState(() => _showScrollIndex = true);
        },
        onVerticalDragUpdate: (details) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPosition = details.localPosition.dy;
          final percentage = (localPosition / box.size.height).clamp(0.0, 1.0);

          // For juz, we need to find the corresponding ayah based on totalVerses
          final targetAyahNumber = (percentage * totalVerses).round().clamp(
            1,
            totalVerses,
          );

          if (_itemScrollController.isAttached) {
            // Calculate the item index accounting for surah headers
            // Each surah has 1 header + N ayahs
            final juzData = _juzDetailsCache[_currentJuz.number];
            if (juzData != null) {
              int currentAyahCount = 0;
              int targetIndex = 0;

              for (int i = 0; i < juzData.length; i++) {
                final surah = juzData[i];
                final surahAyahCount = surah.ayahs.length;

                // Add 1 for surah header
                targetIndex++;

                if (currentAyahCount + surahAyahCount >= targetAyahNumber) {
                  // Target is in this surah
                  final ayahIndexInSurah =
                      targetAyahNumber - currentAyahCount - 1;
                  targetIndex += ayahIndexInSurah;
                  break;
                }

                currentAyahCount += surahAyahCount;
                targetIndex += surahAyahCount;
              }

              _itemScrollController.jumpTo(index: targetIndex, alignment: 0.1);

              // Update current scroll index to show ayah number
              if (mounted) {
                setState(() => _currentScrollIndex = targetAyahNumber);
              }
            }
          }
        },
        onVerticalDragEnd: (_) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              setState(() => _showScrollIndex = false);
            }
          });
        },
        child: Container(
          width: 60,
          margin: const EdgeInsets.only(right: 4, top: 50, bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                AppTheme.primaryBlue.withOpacity(0.08),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              bottomLeft: Radius.circular(30),
            ),
          ),
          child: Stack(
            children: [
              // Scroll indicator popup
              // if (_showScrollIndex)
              //   Positioned(
              //     right: 65,
              //     top: MediaQuery.of(context).size.height * 0.35,
              //     child: Container(
              //       padding: const EdgeInsets.symmetric(
              //         horizontal: 20,
              //         vertical: 16,
              //       ),
              //       decoration: BoxDecoration(
              //         gradient: LinearGradient(
              //           begin: Alignment.topLeft,
              //           end: Alignment.bottomRight,
              //           colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
              //         ),
              //         borderRadius: BorderRadius.circular(16),
              //         boxShadow: [
              //           BoxShadow(
              //             color: AppTheme.primaryBlue.withOpacity(0.5),
              //             blurRadius: 24,
              //             offset: const Offset(-4, 4),
              //             spreadRadius: 2,
              //           ),
              //         ],
              //       ),
              //       child: Column(
              //         mainAxisSize: MainAxisSize.min,
              //         children: [
              //           const Icon(
              //             Icons.bookmark_rounded,
              //             color: Colors.white,
              //             size: 24,
              //           ),
              //           const SizedBox(height: 4),
              //           Text(
              //             'Ayat',
              //             style: TextStyle(
              //               fontFamily: 'Poppins',
              //               fontSize: 12,
              //               fontWeight: FontWeight.w500,
              //               color: Colors.white.withOpacity(0.9),
              //             ),
              //           ),
              //           Text(
              //             '$_currentScrollIndex',
              //             style: const TextStyle(
              //               fontFamily: 'Poppins',
              //               fontSize: 28,
              //               fontWeight: FontWeight.bold,
              //               color: Colors.white,
              //               height: 1,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to convert number to Arabic numerals
  String _toArabicNumber(int number) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicNumbers[int.parse(digit)])
        .join('');
  }
}

// Helper class to store juz surah data
class JuzSurahData {
  final int surahNumber;
  final String surahName;
  final String surahNameArabic;
  final int startVerse;
  final int endVerse;
  final List<dynamic> ayahs;

  JuzSurahData({
    required this.surahNumber,
    required this.surahName,
    required this.surahNameArabic,
    required this.startVerse,
    required this.endVerse,
    required this.ayahs,
  });
}
