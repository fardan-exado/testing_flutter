import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/data/models/sholat/sholat.dart';
import 'package:test_flutter/features/home/home_provider.dart';
import 'package:test_flutter/features/home/home_state.dart';

class PrayerTimeDisplay extends ConsumerStatefulWidget {
  const PrayerTimeDisplay({super.key});

  @override
  ConsumerState<PrayerTimeDisplay> createState() => _PrayerTimeDisplayState();
}

class _PrayerTimeDisplayState extends ConsumerState<PrayerTimeDisplay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Timer untuk update countdown setiap detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double _t(BuildContext context, double base) =>
      ResponsiveHelper.adaptiveTextSize(context, base);

  double _px(BuildContext context, double base) {
    final scale = ResponsiveHelper.isSmallScreen(context)
        ? 0.9
        : ResponsiveHelper.isMediumScreen(context)
        ? 1.0
        : ResponsiveHelper.isLargeScreen(context)
        ? 1.1
        : 1.2;
    return base * scale;
  }

  double _icon(BuildContext context, double base) => _px(context, base);

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final status = homeState.status;
    final sholat = homeState.jadwalSholat;

    // if (status == HomeStatus.loading) {
    //   return _buildLoadingState(context);
    // }

    if (status == HomeStatus.error && sholat == null) {
      return _buildErrorState(context, ref);
    }

    if (sholat != null) {
      return _buildPrayerTimeContent(context, ref, sholat);
    }

    return const SizedBox.shrink();
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Icon(
          Icons.location_off,
          color: Colors.white70,
          size: _icon(context, 40),
        ),
        SizedBox(height: _px(context, 12)),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.getScreenWidth(context) * 0.04,
          ),
          child: Text(
            'Gagal memuat jadwal sholat',
            style: TextStyle(color: Colors.white70, fontSize: _t(context, 14)),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: _px(context, 8)),
        TextButton(
          onPressed: () {
            ref
                .read(homeProvider.notifier)
                .fetchJadwalSholat(
                  forceRefresh: true,
                  useCurrentLocation: true,
                );
          },
          child: Text(
            'Coba Lagi',
            style: TextStyle(
              color: Colors.white,
              fontSize: _t(context, 14),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerTimeContent(
    BuildContext context,
    WidgetRef ref,
    Sholat sholat,
  ) {
    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final notifier = ref.read(homeProvider.notifier);
    final currentPrayerName = notifier.getCurrentPrayerName();
    final nextPrayerTime = notifier.getCurrentPrayerTime();
    final timeLeft = notifier.getTimeUntilNextPrayer();

    if (currentPrayerName == null || nextPrayerTime == null) {
      return _buildInvalidDataState(context, ref, currentTime);
    }

    return Column(
      children: [
        Text(
          currentTime,
          style: TextStyle(
            color: Colors.white,
            fontSize: _t(context, 56),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: _px(context, 4)),
        Text(
          '$currentPrayerName pukul $nextPrayerTime',
          style: TextStyle(
            color: Colors.white,
            fontSize: _t(context, 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (timeLeft != null && timeLeft.isNotEmpty)
          Text(
            timeLeft,
            style: TextStyle(color: Colors.white70, fontSize: _t(context, 14)),
          ),
      ],
    );
  }

  Widget _buildInvalidDataState(
    BuildContext context,
    WidgetRef ref,
    String currentTime,
  ) {
    return Column(
      children: [
        Text(
          currentTime,
          style: TextStyle(
            color: Colors.white,
            fontSize: _t(context, 56),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: _px(context, 8)),
        Text(
          'Jadwal sholat tidak tersedia',
          style: TextStyle(color: Colors.white70, fontSize: _t(context, 14)),
        ),
        SizedBox(height: _px(context, 8)),
        TextButton(
          onPressed: () {
            ref
                .read(homeProvider.notifier)
                .fetchJadwalSholat(
                  forceRefresh: true,
                  useCurrentLocation: true,
                );
          },
          child: Text(
            'Muat Ulang',
            style: TextStyle(color: Colors.white, fontSize: _t(context, 12)),
          ),
        ),
      ],
    );
  }
}
