import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/features/home/home_provider.dart';
import 'package:test_flutter/features/home/home_state.dart';

class PrayerTimesRow extends ConsumerWidget {
  const PrayerTimesRow({super.key});

  double _scaleFactor(BuildContext context) {
    if (ResponsiveHelper.isSmallScreen(context)) return .9;
    if (ResponsiveHelper.isMediumScreen(context)) return 1.0;
    if (ResponsiveHelper.isLargeScreen(context)) return 1.1;
    return 1.2;
  }

  double _px(BuildContext context, double base) => base * _scaleFactor(context);

  double _t(BuildContext context, double base) =>
      ResponsiveHelper.adaptiveTextSize(context, base);

  double _icon(BuildContext context, double base) => _px(context, base);

  double _hpad(BuildContext context) {
    if (ResponsiveHelper.isExtraLargeScreen(context)) return 48;
    if (ResponsiveHelper.isLargeScreen(context)) return 32;
    return ResponsiveHelper.getScreenWidth(context) * 0.04;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final status = homeState.status;
    final sholat = homeState.jadwalSholat;

    if (status == HomeStatus.loading || sholat == null) {
      return SizedBox(
        height: _px(context, 100),
        child: Center(
          child: Text(
            'Memuat jadwal sholat...',
            style: TextStyle(color: Colors.white70, fontSize: _t(context, 14)),
          ),
        ),
      );
    }

    final notifier = ref.read(homeProvider.notifier);
    final activePrayerName = notifier.getActivePrayerName();

    // Cek apakah sudah lewat semua waktu sholat (setelah Isya, hari yang sama)
    final showAllActive = notifier.isAfterAllPrayers();

    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 700;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _hpad(context)),
      child: _ResponsivePrayerRow(
        itemHeight: isCompact ? _px(context, 85) : _px(context, 100),
        isCompact: isCompact,
        children: [
          _buildPrayerTimeWidget(
            context,
            'Shubuh',
            sholat.wajib.shubuh,
            Icons.nightlight_round,
            showAllActive || activePrayerName == 'Shubuh',
            isCompact: isCompact,
          ),
          _buildPrayerTimeWidget(
            context,
            'Dzuhur',
            sholat.wajib.dzuhur,
            Icons.wb_sunny_rounded,
            showAllActive || activePrayerName == 'Dzuhur',
            isCompact: isCompact,
          ),
          _buildPrayerTimeWidget(
            context,
            'Ashar',
            sholat.wajib.ashar,
            Icons.wb_twilight_rounded,
            showAllActive || activePrayerName == 'Ashar',
            isCompact: isCompact,
          ),
          _buildPrayerTimeWidget(
            context,
            'Maghrib',
            sholat.wajib.maghrib,
            Icons.wb_sunny_outlined,
            showAllActive || activePrayerName == 'Maghrib',
            isCompact: isCompact,
          ),
          _buildPrayerTimeWidget(
            context,
            'Isya',
            sholat.wajib.isya,
            Icons.dark_mode_rounded,
            showAllActive || activePrayerName == 'Isya',
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeWidget(
    BuildContext context,
    String name,
    String? time,
    IconData icon,
    bool isActive, {
    bool isCompact = false,
  }) {
    final box = isCompact ? _px(context, 38) : _px(context, 44);
    final ic = isCompact ? _icon(context, 18) : _icon(context, 20);
    final nameFs = isCompact ? _t(context, 11) : _t(context, 12);
    final timeFs = isCompact ? _t(context, 10) : _t(context, 11);
    final gap = isCompact ? _px(context, 4) : _px(context, 6);

    final display = (time != null && time.trim().isNotEmpty) ? time : '--:--';

    return SizedBox(
      width: box + _px(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: nameFs,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: gap),
          Container(
            width: box,
            height: box,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: .3)
                  : Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
              border: isActive
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1,
                    )
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: ic),
          ),
          SizedBox(height: gap),
          Text(
            display,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: timeFs,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ResponsivePrayerRow extends StatelessWidget {
  final List<Widget> children;
  final double itemHeight;
  final bool isCompact;

  const _ResponsivePrayerRow({
    required this.children,
    required this.itemHeight,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = ResponsiveHelper.getScreenWidth(context);

    if (w < 340 || (isCompact && w < 400)) {
      return SizedBox(
        height: itemHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: children.length,
          separatorBuilder: (_, __) => SizedBox(width: isCompact ? 8 : 10),
          itemBuilder: (_, i) => children[i],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: children,
    );
  }
}
