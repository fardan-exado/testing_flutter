import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/features/sholat/providers/sholat_provider.dart';

class SholatCalendarModal extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const SholatCalendarModal({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  ConsumerState<SholatCalendarModal> createState() =>
      _SholatCalendarModalState();
}

class _SholatCalendarModalState extends ConsumerState<SholatCalendarModal> {
  late DateTime _selectedMonth;
  late DateTime _selectedDate;
  bool _isLoadingRiwayat = false;
  final Map<String, Map<String, dynamic>> _progressCache = {};

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      1,
    );
    _selectedDate = widget.initialDate;
    _loadRiwayatForMonth();
  }

  Future<void> _loadRiwayatForMonth() async {
    setState(() => _isLoadingRiwayat = true);
    try {
      // Load progress untuk semua hari di bulan yang dipilih
      final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final lastDay = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
      );

      final tasksWajib = <Future>[];
      final tasksSunnah = <Future>[];

      // Loop dari hari pertama sampai hari terakhir
      for (int day = firstDay.day; day <= lastDay.day; day++) {
        final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
        final formatter = DateFormat('yyyy-MM-dd');
        final dateKey = formatter.format(date);

        // Fetch wajib progress
        tasksWajib.add(
          ref
              .read(sholatProvider.notifier)
              .fetchProgressSholatByDate(jenis: 'wajib', tanggal: date)
              .then((data) {
                _progressCache['${dateKey}_wajib'] = data;
              })
              .catchError((e) {
                logger.warning('Error loading wajib progress for $dateKey: $e');
              }),
        );

        // Fetch sunnah progress
        tasksSunnah.add(
          ref
              .read(sholatProvider.notifier)
              .fetchProgressSholatByDate(jenis: 'sunnah', tanggal: date)
              .then((data) {
                _progressCache['${dateKey}_sunnah'] = data;
              })
              .catchError((e) {
                logger.warning(
                  'Error loading sunnah progress for $dateKey: $e',
                );
              }),
        );
      }

      await Future.wait([...tasksWajib, ...tasksSunnah]);
    } catch (e) {
      logger.warning('Error loading riwayat for month: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingRiwayat = false);
      }
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
      _progressCache.clear();
    });
    _loadRiwayatForMonth();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
      _progressCache.clear();
    });
    _loadRiwayatForMonth();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onDateSelected(date);
    Navigator.pop(context);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSelected(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
  }

  Map<String, int> _getProgressForDate(DateTime date) {
    final formatter = DateFormat('yyyy-MM-dd');
    final dateKey = formatter.format(date);

    int wajibCompleted = 0;
    int sunnahCompleted = 0;

    // Get wajib progress from cache
    final wajibData = _progressCache['${dateKey}_wajib'];
    if (wajibData != null) {
      if (wajibData.containsKey('total')) {
        wajibCompleted = wajibData['total'] as int? ?? 0;
      } else if (wajibData.containsKey('data')) {
        final data = wajibData['data'];
        if (data is List) {
          wajibCompleted = data.length;
        } else if (data is Map) {
          // Jika data adalah map dengan struktur { 'sholat_name': {...} }
          wajibCompleted = data.length;
        }
      }
    }

    // Get sunnah progress from cache
    final sunnahData = _progressCache['${dateKey}_sunnah'];
    if (sunnahData != null) {
      if (sunnahData.containsKey('total')) {
        sunnahCompleted = sunnahData['total'] as int? ?? 0;
      } else if (sunnahData.containsKey('data')) {
        final data = sunnahData['data'];
        if (data is List) {
          sunnahCompleted = data.length;
        } else if (data is Map) {
          // Jika data adalah map
          sunnahCompleted = data.length;
        }
      }
    }

    return {'wajib': wajibCompleted, 'sunnah': sunnahCompleted};
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: AppTheme.primaryBlue,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Sholat',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          'Pilih tanggal untuk melihat detail',
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
            ),
            const SizedBox(height: 24),

            // Month selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: const Icon(Icons.chevron_left),
                    color: AppTheme.primaryBlue,
                  ),
                  Text(
                    DateFormat('MMMM yyyy', 'id').format(_selectedMonth),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right),
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Calendar
            if (_isLoadingRiwayat)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCalendar(),
              ),

            const SizedBox(height: 16),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegend('Wajib', AppTheme.primaryBlue),
                  _buildLegend('Sunnah', AppTheme.accentGreen),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );

    // Get the weekday of the first day (1 = Monday, 7 = Sunday)
    final firstWeekday = firstDayOfMonth.weekday;

    // Calculate how many days from previous month to show
    final previousMonthDays = firstWeekday - 1;

    // Days in month
    final daysInMonth = lastDayOfMonth.day;

    // Total cells needed
    final totalCells = previousMonthDays + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        // Weekday headers
        Row(
          children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        ...List.generate(rows, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: List.generate(7, (dayIndex) {
                final cellIndex = weekIndex * 7 + dayIndex;
                final dayNumber = cellIndex - previousMonthDays + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox());
                }

                final date = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month,
                  dayNumber,
                );

                final progress = _getProgressForDate(date);
                final wajibCount = progress['wajib'] ?? 0;
                final sunnahCount = progress['sunnah'] ?? 0;
                final hasProgress = wajibCount > 0 || sunnahCount > 0;

                return Expanded(
                  child: _buildDayCell(
                    date,
                    dayNumber,
                    hasProgress,
                    wajibCount,
                    sunnahCount,
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDayCell(
    DateTime date,
    int dayNumber,
    bool hasProgress,
    int wajibCount,
    int sunnahCount,
  ) {
    final isToday = _isToday(date);
    final isSelected = _isSelected(date);
    final isFuture = date.isAfter(DateTime.now());

    return InkWell(
      onTap: isFuture ? null : () => _selectDate(date),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 52,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue
              : isToday
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected
              ? Border.all(color: AppTheme.primaryBlue, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day number
            Text(
              dayNumber.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : isFuture
                    ? Colors.grey.shade400
                    : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 2),

            // Progress indicators
            if (hasProgress && !isFuture)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (wajibCount > 0)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (sunnahCount > 0)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppTheme.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
