import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/features/subscription/pages/paket_page.dart';
import 'package:test_flutter/features/subscription/providers/pesanan_provider.dart';

class PremiumGate extends ConsumerWidget {
  final Widget child;
  final String featureName;

  const PremiumGate({
    super.key,
    required this.child,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(pesananProvider);
    final isPremium = subscriptionState.isPremium;

    // If premium, show the feature
    if (isPremium) {
      return child;
    }

    // If not premium, show locked screen
    return _PremiumLockedScreen(featureName: featureName);
  }
}

class _PremiumLockedScreen extends StatelessWidget {
  final String featureName;

  const _PremiumLockedScreen({required this.featureName});

  double _px(BuildContext c, double base) {
    if (ResponsiveHelper.isSmallScreen(c)) return base * 0.9;
    if (ResponsiveHelper.isMediumScreen(c)) return base;
    if (ResponsiveHelper.isLargeScreen(c)) return base * 1.1;
    return base * 1.2;
  }

  double _ts(BuildContext c, double base) =>
      ResponsiveHelper.adaptiveTextSize(c, base);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsivePadding(context).left,
                vertical: _px(context, 16),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: const Color(0xFF2D3748),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    featureName,
                    style: TextStyle(
                      fontSize: _ts(context, 24),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(_px(context, 24)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lock Icon
                      Container(
                        padding: EdgeInsets.all(_px(context, 24)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1E88E5).withValues(alpha: 0.2),
                              const Color(0xFF26A69A).withValues(alpha: 0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: _px(context, 64),
                          color: const Color(0xFF1E88E5),
                        ),
                      ),

                      SizedBox(height: _px(context, 32)),

                      // Title
                      Text(
                        '🌟 Fitur Premium',
                        style: TextStyle(
                          fontSize: _ts(context, 28),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: _px(context, 16)),

                      // Description
                      Text(
                        'Fitur $featureName hanya tersedia untuk pengguna premium',
                        style: TextStyle(
                          fontSize: _ts(context, 16),
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: _px(context, 32)),

                      // Features List
                      Container(
                        padding: EdgeInsets.all(_px(context, 20)),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dengan Premium Anda Mendapat:',
                              style: TextStyle(
                                fontSize: _ts(context, 16),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                            SizedBox(height: _px(context, 16)),
                            _buildFeatureItem(
                              context,
                              '✅',
                              'Akses Tahajud Tracker',
                            ),
                            _buildFeatureItem(
                              context,
                              '✅',
                              'Monitoring Anak Unlimited',
                            ),
                            _buildFeatureItem(
                              context,
                              '✅',
                              'Notifikasi Premium',
                            ),
                            _buildFeatureItem(context, '✅', 'Laporan Detail'),
                            _buildFeatureItem(context, '✅', 'Priority Support'),
                          ],
                        ),
                      ),

                      SizedBox(height: _px(context, 32)),

                      // Upgrade Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/plan',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: _px(context, 16),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.workspace_premium_rounded,
                                size: _px(context, 24),
                              ),
                              SizedBox(width: _px(context, 10)),
                              Text(
                                'Upgrade ke Premium',
                                style: TextStyle(
                                  fontSize: _ts(context, 18),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: _px(context, 16)),

                      // Cancel Button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Kembali',
                          style: TextStyle(
                            fontSize: _ts(context, 16),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String emoji, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: _px(context, 10)),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: _ts(context, 18))),
          SizedBox(width: _px(context, 12)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: _ts(context, 15),
                color: const Color(0xFF4A5568),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
