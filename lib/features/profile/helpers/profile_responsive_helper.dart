import 'package:flutter/material.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';

/// Helper class untuk responsive sizing di profile pages
class ProfileResponsiveHelper {
  /// Scale factor berdasarkan ukuran screen
  static double getScale(BuildContext context) {
    if (ResponsiveHelper.isSmallScreen(context)) return 0.9;
    if (ResponsiveHelper.isMediumScreen(context)) return 1.0;
    if (ResponsiveHelper.isLargeScreen(context)) return 1.1;
    return 1.2;
  }

  /// Pixel size dengan scaling
  static double px(BuildContext context, double base) {
    return base * getScale(context);
  }

  /// Text size dengan adaptive sizing
  static double textSize(BuildContext context, double base) {
    return ResponsiveHelper.adaptiveTextSize(context, base);
  }

  /// Max width untuk content area
  static double getContentMaxWidth(BuildContext context) {
    if (ResponsiveHelper.isExtraLargeScreen(context)) return 720;
    if (ResponsiveHelper.isLargeScreen(context)) return 640;
    return double.infinity;
  }

  /// Horizontal padding untuk page
  static EdgeInsets getPageHorizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: ResponsiveHelper.getResponsivePadding(context).left,
    );
  }

  /// Standard padding untuk card/container
  static EdgeInsets getCardPadding(BuildContext context) {
    final scale = getScale(context);
    if (scale >= 1.1) return EdgeInsets.all(24 * scale);
    if (scale >= 1.0) return EdgeInsets.all(20 * scale);
    return EdgeInsets.all(16 * scale);
  }

  /// Gap/spacing vertikal
  static SizedBox verticalGap(
    BuildContext context, {
    double small = 16,
    double medium = 20,
    double large = 28,
  }) {
    final scale = getScale(context);
    return SizedBox(height: medium * scale);
  }

  /// Gap/spacing horizontal
  static SizedBox horizontalGap(
    BuildContext context, {
    double small = 12,
    double medium = 16,
    double large = 20,
  }) {
    final scale = getScale(context);
    return SizedBox(width: medium * scale);
  }

  /// Header padding
  static EdgeInsets getHeaderPadding(BuildContext context) {
    final scale = getScale(context);
    if (scale >= 1.1) return EdgeInsets.all(24 * scale);
    return EdgeInsets.all(20 * scale);
  }

  /// Container/button padding
  static EdgeInsets getContainerPadding(BuildContext context) {
    final scale = getScale(context);
    if (scale >= 1.1) return EdgeInsets.all(20 * scale);
    return EdgeInsets.all(16 * scale);
  }

  /// Icon size
  static double getIconSize(
    BuildContext context, {
    double small = 20,
    double medium = 22,
    double large = 24,
  }) {
    final scale = getScale(context);
    if (scale >= 1.1) return large * scale;
    if (scale >= 1.0) return medium * scale;
    return small * scale;
  }

  /// Button/container border radius
  static BorderRadius getBorderRadius({double? value}) {
    return BorderRadius.circular(value ?? 14);
  }

  // --- Helpers berbasis ResponsiveHelper ---
  static double scale(BuildContext c) {
    if (ResponsiveHelper.isSmallScreen(c)) return .9;
    if (ResponsiveHelper.isMediumScreen(c)) return 1.0;
    if (ResponsiveHelper.isLargeScreen(c)) return 1.1;
    return 1.2;
  }

  static double ts(BuildContext c, double base) =>
      ResponsiveHelper.adaptiveTextSize(c, base);

  static double contentMaxWidth(BuildContext c) {
    if (ResponsiveHelper.isExtraLargeScreen(c)) return 720;
    if (ResponsiveHelper.isLargeScreen(c)) return 640;
    return double.infinity;
  }

  static EdgeInsets pageHPad(BuildContext c) => EdgeInsets.symmetric(
    horizontal: ResponsiveHelper.getResponsivePadding(c).left,
  );
}
