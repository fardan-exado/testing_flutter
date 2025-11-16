import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/subscription/providers/subscription_provider.dart';
// import 'package:test_flutter/features/subscription/subscription_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'transaction_history_page.dart';

class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  ProviderSubscription? _subscriptionSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionProvider.notifier).loadPakets();
      ref.read(subscriptionProvider.notifier).loadActiveSubscription();
    });
    // 🔥 Setup manual listener untuk subscription state
    _subscriptionSub = ref.listenManual(subscriptionProvider, (previous, next) {
      final route = ModalRoute.of(context);
      final isCurrent = route != null && route.isCurrent;
      if (!mounted || !isCurrent) return;

      if (next.error != null) {
        showMessageToast(context, message: next.error!, type: ToastType.error);
        ref.read(subscriptionProvider.notifier).clearError();
      } else if (next.message != null) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.success,
        );
        ref.read(subscriptionProvider.notifier).clearMessage();
      }
    });
  }

  @override
  void dispose() {
    _subscriptionSub?.close();
    super.dispose();
  }

  // Helper methods
  double _px(BuildContext c, double base) {
    if (ResponsiveHelper.isSmallScreen(c)) return base * 0.9;
    if (ResponsiveHelper.isMediumScreen(c)) return base;
    if (ResponsiveHelper.isLargeScreen(c)) return base * 1.1;
    return base * 1.2;
  }

  double _ts(BuildContext c, double base) =>
      ResponsiveHelper.adaptiveTextSize(c, base);

  EdgeInsets _pageHPad(BuildContext c) => EdgeInsets.symmetric(
    horizontal: ResponsiveHelper.getResponsivePadding(c).left,
  );

  double _contentMaxWidth(BuildContext c) {
    if (ResponsiveHelper.isExtraLargeScreen(c)) return 1200;
    if (ResponsiveHelper.isLargeScreen(c)) return 1000;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final pakets = subscriptionState.pakets;
    final activeSubscription = subscriptionState.activeSubscription;
    final isPremium = subscriptionState.isPremium;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: Colors.white,
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
                  Expanded(
                    child: Text(
                      'Paket Premium',
                      style: TextStyle(
                        fontSize: _ts(context, 24),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  // Transaction History Button
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/transaction-history');
                    },
                    icon: const Icon(Icons.history_rounded),
                    color: const Color(0xFF1E88E5),
                    tooltip: 'Riwayat Transaksi',
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: subscriptionState.isLoading && pakets.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E88E5),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: _pageHPad(context),
                      physics: const BouncingScrollPhysics(),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: _contentMaxWidth(context),
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: _px(context, 24)),

                              // Active Subscription Info
                              if (isPremium && activeSubscription != null)
                                _buildActiveSubscriptionCard(
                                  context,
                                  activeSubscription,
                                )
                              else
                                _buildFreePlanCard(context),

                              SizedBox(height: _px(context, 32)),

                              // Plans Grid
                              if (pakets.isEmpty)
                                _buildEmptyState(context)
                              else
                                _buildPlansGrid(context, pakets, isPremium),

                              SizedBox(height: _px(context, 32)),

                              // Features Comparison
                              _buildFeaturesInfo(context),

                              SizedBox(height: _px(context, 32)),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSubscriptionCard(BuildContext context, subscription) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_px(context, 20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(_px(context, 10)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: _px(context, 28),
                ),
              ),
              SizedBox(width: _px(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Premium Aktif',
                      style: TextStyle(
                        fontSize: _ts(context, 18),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subscription.planName ?? 'Premium Plan',
                      style: TextStyle(
                        fontSize: _ts(context, 14),
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: _px(context, 16)),
          Container(
            padding: EdgeInsets.all(_px(context, 12)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Berlaku Hingga',
                      style: TextStyle(
                        fontSize: _ts(context, 12),
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      'TBD',
                      style: TextStyle(
                        fontSize: _ts(context, 16),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Sisa Hari',
                      style: TextStyle(
                        fontSize: _ts(context, 12),
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      'TBD',
                      style: TextStyle(
                        fontSize: _ts(context, 16),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreePlanCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_px(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: _px(context, 48),
            color: Colors.grey.shade400,
          ),
          SizedBox(height: _px(context, 12)),
          Text(
            'Paket Gratis',
            style: TextStyle(
              fontSize: _ts(context, 18),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: _px(context, 8)),
          Text(
            'Upgrade ke Premium untuk akses fitur Tahajud dan Monitoring',
            style: TextStyle(
              fontSize: _ts(context, 14),
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlansGrid(BuildContext context, plans, bool isPremium) {
    final isTablet = ResponsiveHelper.isMediumScreen(context);
    final isDesktop =
        ResponsiveHelper.isLargeScreen(context) ||
        ResponsiveHelper.isExtraLargeScreen(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : (isTablet ? 2 : 1),
        crossAxisSpacing: _px(context, 16),
        mainAxisSpacing: _px(context, 16),
        childAspectRatio: isDesktop ? 0.75 : (isTablet ? 0.8 : 0.9),
      ),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return _buildPlanCard(context, plan, isPremium);
      },
    );
  }

  Widget _buildPlanCard(BuildContext context, plan, bool isPremium) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isPopular
              ? const Color(0xFF1E88E5)
              : Colors.grey.shade300,
          width: plan.isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(_px(context, 16)),
            decoration: BoxDecoration(
              color: plan.isPopular
                  ? const Color(0xFF1E88E5).withValues(alpha: 0.1)
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (plan.isPopular)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _px(context, 10),
                      vertical: _px(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '⭐ Paling Populer',
                      style: TextStyle(
                        fontSize: _ts(context, 11),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (plan.isPopular) SizedBox(height: _px(context, 8)),
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: _ts(context, 24),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: _px(context, 4)),
                Text(
                  plan.description,
                  style: TextStyle(
                    fontSize: _ts(context, 13),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Price
          Padding(
            padding: EdgeInsets.all(_px(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currencyFormat.format(plan.price),
                      style: TextStyle(
                        fontSize: _ts(context, 28),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E88E5),
                      ),
                    ),
                    if (plan.discount != null) ...[
                      SizedBox(width: _px(context, 8)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _px(context, 6),
                          vertical: _px(context, 2),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          plan.discount!,
                          style: TextStyle(
                            fontSize: _ts(context, 11),
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: _px(context, 4)),
                Text(
                  '${plan.durationDays} hari',
                  style: TextStyle(
                    fontSize: _ts(context, 14),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Features
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _px(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fitur:',
                    style: TextStyle(
                      fontSize: _ts(context, 14),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: _px(context, 8)),
                  ...plan.features.map<Widget>((feature) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: _px(context, 6)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: _px(context, 18),
                            color: const Color(0xFF26A69A),
                          ),
                          SizedBox(width: _px(context, 8)),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: _ts(context, 13),
                                color: const Color(0xFF4A5568),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Buy Button
          Padding(
            padding: EdgeInsets.all(_px(context, 16)),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPremium
                    ? null
                    : () => _handleBuyPlan(context, plan.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: plan.isPopular
                      ? const Color(0xFF1E88E5)
                      : const Color(0xFF26A69A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: EdgeInsets.symmetric(vertical: _px(context, 14)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isPremium ? 'Sudah Premium' : 'Beli Paket',
                  style: TextStyle(
                    fontSize: _ts(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_px(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ Fitur Premium',
            style: TextStyle(
              fontSize: _ts(context, 20),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: _px(context, 16)),
          _buildFeatureItem(
            context,
            Icons.nightlight_rounded,
            'Tahajud Tracker',
            'Catat dan pantau sholat tahajud dengan detail lengkap',
            const Color(0xFF1E88E5),
          ),
          SizedBox(height: _px(context, 12)),
          _buildFeatureItem(
            context,
            Icons.family_restroom_rounded,
            'Monitoring Anak',
            'Monitor aktivitas ibadah anak-anak dalam keluarga',
            const Color(0xFF26A69A),
          ),
          SizedBox(height: _px(context, 12)),
          _buildFeatureItem(
            context,
            Icons.notifications_active_rounded,
            'Notifikasi Premium',
            'Dapatkan pengingat dan notifikasi khusus',
            const Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(_px(context, 10)),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: _px(context, 24)),
        ),
        SizedBox(width: _px(context, 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: _ts(context, 16),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: _px(context, 4)),
              Text(
                description,
                style: TextStyle(
                  fontSize: _ts(context, 13),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: _px(context, 64),
            color: Colors.grey.shade400,
          ),
          SizedBox(height: _px(context, 16)),
          Text(
            'Paket tidak tersedia',
            style: TextStyle(
              fontSize: _ts(context, 16),
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBuyPlan(BuildContext context, String planId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembelian'),
        content: const Text(
          'Anda akan diarahkan ke halaman pembayaran Midtrans. Lanjutkan?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Create transaction and get payment URL
    final snapUrl = await ref
        .read(subscriptionProvider.notifier)
        .createTransaction(planId);

    if (snapUrl != null && mounted) {
      // Open payment URL
      final uri = Uri.parse(snapUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Show info dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Pembayaran Dibuka'),
              content: const Text(
                'Silakan selesaikan pembayaran di browser. '
                'Setelah pembayaran berhasil, kembali ke aplikasi dan cek status transaksi di riwayat.',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}
