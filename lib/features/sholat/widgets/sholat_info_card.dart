import 'package:flutter/material.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';

/// Card untuk menampilkan waktu sholat tanpa fitur checklist dan alarm
/// Digunakan untuk Imsak dan Sunrise
class SholatInfoCard extends StatelessWidget {
  final String name;
  final String time;
  final IconData icon;
  final String jenis;

  const SholatInfoCard({
    super.key,
    required this.name,
    required this.time,
    required this.icon,
    required this.jenis,
  });

  double _px(BuildContext c, double base) {
    if (ResponsiveHelper.isSmallScreen(c)) return base;
    if (ResponsiveHelper.isMediumScreen(c)) return base * 1.1;
    if (ResponsiveHelper.isLargeScreen(c)) return base * 1.2;
    return base * 1.3;
  }

  double _ts(BuildContext c, double base) =>
      ResponsiveHelper.adaptiveTextSize(c, base * 1.1);

  @override
  Widget build(BuildContext context) {
    final small = ResponsiveHelper.isSmallScreen(context);
    final color = jenis == 'wajib'
        ? AppTheme.primaryBlue
        : AppTheme.accentGreen;

    return Container(
      margin: EdgeInsets.only(bottom: _px(context, 8)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _px(context, small ? 14 : 16),
          vertical: _px(context, small ? 12 : 14),
        ),
        child: Row(
          children: [
            // Icon (no checkbox)
            Container(
              width: _px(context, 40),
              height: _px(context, 40),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: _px(context, 20)),
            ),
            SizedBox(width: _px(context, 12)),
            // Prayer info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: _ts(context, small ? 14 : 15),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: _px(context, 2)),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: _ts(context, small ? 12 : 13),
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Info badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Info',
                style: TextStyle(
                  fontSize: _ts(context, 10),
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
