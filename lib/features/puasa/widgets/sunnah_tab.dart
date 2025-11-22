import 'package:flutter/material.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/features/puasa/models/puasa.dart';

class SunnahTab extends StatelessWidget {
  final List<PuasaSunnah> puasaSunnahList;
  final Function(Map<String, dynamic>) onPuasaTap;

  const SunnahTab({
    super.key,
    required this.puasaSunnahList,
    required this.onPuasaTap,
  });

  // Color mapping for different types of sunnah fasting
  static const Map<String, Color> colorMap = {
    'puasa-senin-kamis': AppTheme.primaryBlue,
    'puasa-ayyamul-bidh': AppTheme.primaryBlueDark,
    'puasa-daud': AppTheme.primaryBlueLight,
    'puasa-6-syawal': AppTheme.accentGreenDark,
    'puasa-muharram': AppTheme.errorColor,
    'puasa-syaban': AppTheme.accentGreen,
  };

  // Icon mapping for different types of sunnah fasting
  static const Map<String, IconData> iconMap = {
    'puasa-senin-kamis': Icons.calendar_today,
    'puasa-ayyamul-bidh': Icons.brightness_3,
    'puasa-daud': Icons.swap_horiz,
    'puasa-6-syawal': Icons.star,
    'puasa-muharram': Icons.event_note,
    'puasa-syaban': Icons.nightlight_round,
  };

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;

    if (puasaSunnahList.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data puasa sunnah',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop
            ? 32.0
            : isTablet
            ? 28.0
            : 24.0,
      ),
      itemCount: puasaSunnahList.length,
      itemBuilder: (context, index) {
        final puasa = puasaSunnahList[index];
        return _buildPuasaCard(puasa, isWajib: false);
      },
    );
  }

  Widget _buildPuasaCard(PuasaSunnah puasa, {required bool isWajib}) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;
        final isDesktop = screenWidth > 1024;

        // Get color and icon from mapping
        final color = colorMap[puasa.slug] ?? AppTheme.primaryBlue;
        final icon = iconMap[puasa.slug] ?? Icons.favorite;

        final puasaMap = {
          'id': puasa.id,
          'name': puasa.nama,
          'description': puasa.deskripsi ?? 'Puasa sunnah',
          'color': color,
          'icon': icon,
          'type': puasa.slug,
        };

        return Container(
          margin: EdgeInsets.only(bottom: isTablet ? 18 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 22 : 20),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(
              isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: isDesktop
                          ? 56
                          : isTablet
                          ? 54
                          : 50,
                      height: isDesktop
                          ? 56
                          : isTablet
                          ? 54
                          : 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.15),
                            color.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Icon(icon, color: color, size: isTablet ? 26 : 24),
                    ),
                    SizedBox(width: isTablet ? 18 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  puasa.nama,
                                  style: TextStyle(
                                    fontSize: isDesktop
                                        ? 18
                                        : isTablet
                                        ? 17
                                        : 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                              ),
                              SizedBox(width: isTablet ? 10 : 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 8 : 6,
                                  vertical: isTablet ? 4 : 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isWajib
                                        ? [
                                            AppTheme.errorColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            AppTheme.errorColor.withValues(
                                              alpha: 0.1,
                                            ),
                                          ]
                                        : [
                                            AppTheme.accentGreen.withValues(
                                              alpha: 0.15,
                                            ),
                                            AppTheme.accentGreen.withValues(
                                              alpha: 0.1,
                                            ),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color:
                                        (isWajib
                                                ? AppTheme.errorColor
                                                : AppTheme.accentGreen)
                                            .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  isWajib ? 'WAJIB' : 'SUNNAH',
                                  style: TextStyle(
                                    fontSize: isTablet ? 11 : 10,
                                    fontWeight: FontWeight.bold,
                                    color: isWajib
                                        ? AppTheme.errorColor
                                        : AppTheme.accentGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 6 : 4),
                          Text(
                            puasa.deskripsi ?? 'Puasa sunnah',
                            style: TextStyle(
                              fontSize: isTablet ? 15 : 14,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 18 : 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => onPuasaTap(puasaMap),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : 14,
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      'Lihat Detail & Tracking',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 15 : 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
