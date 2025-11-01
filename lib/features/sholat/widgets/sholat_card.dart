import 'package:flutter/material.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';

class SholatCard extends StatelessWidget {
  final String name;
  final Map<String, dynamic> jadwalData;
  final bool isCompleted;
  final String status; // tepat_waktu, terlambat, tidak_sholat
  final bool isJamaah;
  final String lokasi;
  final String jenis;
  final bool canTap;
  final bool isAlarmActive;
  final VoidCallback? onTap;
  final VoidCallback? onAlarmTap;

  const SholatCard({
    super.key,
    required this.name,
    required this.jadwalData,
    required this.isCompleted,
    required this.status,
    required this.isJamaah,
    required this.lokasi,
    required this.jenis,
    required this.canTap,
    required this.isAlarmActive,
    this.onTap,
    this.onAlarmTap,
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
    final time = jadwalData['time'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: _px(context, 8)),
      decoration: BoxDecoration(
        color: isCompleted
            ? color.withValues(alpha: 0.04)
            : (canTap ? Colors.white : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? color.withValues(alpha: 0.15)
              : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canTap ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _px(context, small ? 14 : 16),
              vertical: _px(context, small ? 12 : 14),
            ),
            child: Row(
              children: [
                _buildCheckbox(context, color),
                SizedBox(width: _px(context, 12)),
                _buildIcon(context, color),
                SizedBox(width: _px(context, 12)),
                Expanded(child: _buildPrayerInfo(context, small, time, canTap)),
                if (jenis == 'wajib') _buildAlarmButton(context, canTap),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context, Color color) {
    return Container(
      width: _px(context, 22),
      height: _px(context, 22),
      decoration: BoxDecoration(
        color: isCompleted ? color : Colors.transparent,
        border: Border.all(
          color: isCompleted ? color : Colors.grey.shade400,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: isCompleted
          ? Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: _px(context, 14),
            )
          : null,
    );
  }

  Widget _buildIcon(BuildContext context, Color color) {
    return Container(
      width: _px(context, 40),
      height: _px(context, 40),
      decoration: BoxDecoration(
        color: isCompleted
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        jadwalData['icon'] as IconData,
        color: color,
        size: _px(context, 20),
      ),
    );
  }

  Widget _buildPrayerInfo(
    BuildContext context,
    bool small,
    String time,
    bool canTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: _ts(context, small ? 14 : 15),
            fontWeight: FontWeight.w600,
            color: canTap ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        SizedBox(height: _px(context, 2)),
        Text(
          time,
          style: TextStyle(
            fontSize: _ts(context, small ? 12 : 13),
            color: canTap ? AppTheme.onSurfaceVariant : Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isCompleted) ...[
          SizedBox(height: _px(context, 4)),
          Wrap(
            spacing: 4,
            children: [
              // Status Badge
              if (status == 'tepat_waktu')
                _buildBadge(
                  context,
                  'Tepat Waktu',
                  Icons.check_circle,
                  Colors.green,
                )
              else if (status == 'terlambat')
                _buildBadge(
                  context,
                  'Terlambat',
                  Icons.access_time,
                  Colors.orange,
                )
              else if (status == 'tidak_sholat')
                _buildBadge(context, 'Tidak Sholat', Icons.cancel, Colors.red),
              // Jamaah Badge (hanya untuk wajib)
              if (isJamaah && jenis == 'wajib')
                _buildBadge(context, 'Jamaah', Icons.groups, Colors.blue),
              // Lokasi Badge (hanya untuk wajib)
              if (lokasi.isNotEmpty && jenis == 'wajib')
                _buildBadge(context, lokasi, Icons.location_on, Colors.purple),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAlarmButton(BuildContext context, bool canTap) {
    return Material(
      color: isAlarmActive
          ? AppTheme.primaryBlue.withValues(alpha: 0.1)
          : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: canTap ? onAlarmTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(_px(context, 8)),
          child: Icon(
            isAlarmActive && canTap
                ? Icons.alarm_on_rounded
                : Icons.alarm_rounded,
            color: isAlarmActive && canTap
                ? AppTheme.primaryBlue
                : Colors.grey.shade400,
            size: _px(context, 18),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
