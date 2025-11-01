import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/features/sholat/sholat_state.dart';

class SholatHeader extends ConsumerWidget {
  final SholatState sholatState;
  final DateTime selectedDate;
  final String formattedDate;
  final String dayName;
  final String hijriDate;
  final bool isToday;
  final int completedCount;
  final int totalCount;
  final bool isWajibTab;
  final dynamic jadwal;
  final Color progressColor;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onLocationUpdate;

  const SholatHeader({
    super.key,
    required this.sholatState,
    required this.selectedDate,
    required this.formattedDate,
    required this.dayName,
    required this.hijriDate,
    required this.isToday,
    required this.completedCount,
    required this.totalCount,
    required this.isWajibTab,
    required this.jadwal,
    required this.progressColor,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onLocationUpdate,
  });

  double _px(BuildContext c, double base) {
    if (ResponsiveHelper.isSmallScreen(c)) return base;
    if (ResponsiveHelper.isMediumScreen(c)) return base * 1.1;
    if (ResponsiveHelper.isLargeScreen(c)) return base * 1.2;
    return base * 1.3;
  }

  double _ts(BuildContext c, double base) =>
      ResponsiveHelper.adaptiveTextSize(c, base * 1.1);

  EdgeInsets _hpad(BuildContext c) => EdgeInsets.symmetric(
    horizontal: ResponsiveHelper.getResponsivePadding(c).left,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final small = ResponsiveHelper.isSmallScreen(context);

    return Container(
      margin: _hpad(
        context,
      ).add(EdgeInsets.only(top: _px(context, 12), bottom: _px(context, 16))),
      padding: EdgeInsets.all(_px(context, small ? 16 : 20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [progressColor, progressColor.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: progressColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDateNavigation(context, small),
          SizedBox(height: _px(context, 16)),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          SizedBox(height: _px(context, 16)),
          _buildPrayerInfo(context, small),
        ],
      ),
    );
  }

  Widget _buildDateNavigation(BuildContext context, bool small) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildNavigationButton(
          context,
          icon: Icons.chevron_left_rounded,
          onTap: onPreviousDay,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                isToday ? 'Hari ini' : dayName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _ts(context, small ? 14 : 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: _px(context, 2)),
              Text(
                formattedDate,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: _ts(context, small ? 12 : 13),
                ),
              ),
              Text(
                hijriDate,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: _ts(context, small ? 11 : 12),
                ),
              ),
            ],
          ),
        ),
        _buildNavigationButton(
          context,
          icon: Icons.chevron_right_rounded,
          onTap: onNextDay,
        ),
      ],
    );
  }

  Widget _buildNavigationButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(_px(context, 8)),
          child: Icon(icon, color: Colors.white, size: _px(context, 20)),
        ),
      ),
    );
  }

  Widget _buildPrayerInfo(BuildContext context, bool small) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onLocationUpdate,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: _px(context, 4)),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: _px(context, 14),
                      ),
                      SizedBox(width: _px(context, 4)),
                      Flexible(
                        child: Text(
                          sholatState.locationName ?? 'Memuat lokasi...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: _ts(context, small ? 11 : 12),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: _px(context, 4)),
                      Icon(
                        Icons.refresh,
                        size: _px(context, 12),
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: _px(context, 4)),
              // Info Kemenag
              Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: _px(context, 12),
                  ),
                  SizedBox(width: _px(context, 4)),
                  Text(
                    'Waktu dari Kemenag RI',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: _ts(context, small ? 10 : 11),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              SizedBox(height: _px(context, 8)),
              Text(
                _getCurrentPrayerName(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _ts(context, small ? 16 : 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getCurrentPrayerTime(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _ts(context, small ? 22 : 26),
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              SizedBox(height: _px(context, 4)),
              Text(
                jadwal != null
                    ? '${_getNextPrayerName()} ${_getTimeUntilNextPrayer()}'
                    : 'Memuat...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: _ts(context, small ? 10 : 11),
                ),
              ),
            ],
          ),
        ),
        _buildProgressCircle(context, small),
      ],
    );
  }

  Widget _buildProgressCircle(BuildContext context, bool small) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _px(context, small ? 90 : 100),
      height: _px(context, small ? 90 : 100),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 3,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$completedCount',
              style: TextStyle(
                color: Colors.white,
                fontSize: _ts(context, small ? 32 : 36),
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            SizedBox(height: _px(context, 2)),
            Text(
              '/ $totalCount',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: _ts(context, small ? 14 : 16),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: _px(context, 4)),
            Text(
              isWajibTab ? 'Wajib' : 'Sunnah',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: _ts(context, small ? 10 : 11),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentPrayerName() {
    if (jadwal == null) return 'Memuat...';

    final now = TimeOfDay.now();
    final prayers = {
      'Subuh': jadwal.wajib.shubuh,
      'Dzuhur': jadwal.wajib.dzuhur,
      'Ashar': jadwal.wajib.ashar,
      'Maghrib': jadwal.wajib.maghrib,
      'Isya': jadwal.wajib.isya,
    };

    String currentPrayer = 'Subuh';
    for (var entry in prayers.entries) {
      final time = _parseTime(entry.value ?? '00:00');
      if (_isTimeBefore(now, time)) {
        break;
      }
      currentPrayer = entry.key;
    }

    return currentPrayer;
  }

  String _getCurrentPrayerTime() {
    if (jadwal == null) return '--:--';

    final currentName = _getCurrentPrayerName();
    switch (currentName) {
      case 'Subuh':
        return jadwal.wajib.shubuh ?? '--:--';
      case 'Dzuhur':
        return jadwal.wajib.dzuhur ?? '--:--';
      case 'Ashar':
        return jadwal.wajib.ashar ?? '--:--';
      case 'Maghrib':
        return jadwal.wajib.maghrib ?? '--:--';
      case 'Isya':
        return jadwal.wajib.isya ?? '--:--';
      default:
        return '--:--';
    }
  }

  String _getNextPrayerName() {
    if (jadwal == null) return 'Memuat...';

    final now = TimeOfDay.now();
    final prayers = {
      'Subuh': jadwal.wajib.shubuh,
      'Dzuhur': jadwal.wajib.dzuhur,
      'Ashar': jadwal.wajib.ashar,
      'Maghrib': jadwal.wajib.maghrib,
      'Isya': jadwal.wajib.isya,
    };

    for (var entry in prayers.entries) {
      final time = _parseTime(entry.value ?? '00:00');
      if (_isTimeBefore(now, time)) {
        return entry.key;
      }
    }

    return 'Subuh (Besok)';
  }

  String _getTimeUntilNextPrayer() {
    if (jadwal == null) return '';

    final now = TimeOfDay.now();
    final nextPrayerName = _getNextPrayerName();

    String? nextTimeStr;
    switch (nextPrayerName.replaceAll(' (Besok)', '')) {
      case 'Subuh':
        nextTimeStr = jadwal.wajib.shubuh;
        break;
      case 'Dzuhur':
        nextTimeStr = jadwal.wajib.dzuhur;
        break;
      case 'Ashar':
        nextTimeStr = jadwal.wajib.ashar;
        break;
      case 'Maghrib':
        nextTimeStr = jadwal.wajib.maghrib;
        break;
      case 'Isya':
        nextTimeStr = jadwal.wajib.isya;
        break;
    }

    if (nextTimeStr == null) return '';

    final nextTime = _parseTime(nextTimeStr);
    int minutesDiff =
        (nextTime.hour * 60 + nextTime.minute) - (now.hour * 60 + now.minute);

    if (minutesDiff < 0) {
      minutesDiff += 24 * 60; // Add 24 hours
    }

    final hours = minutesDiff ~/ 60;
    final minutes = minutesDiff % 60;

    if (hours > 0) {
      return 'dalam ${hours}j ${minutes}m';
    } else {
      return 'dalam ${minutes}m';
    }
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
      // Fallback
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
}
