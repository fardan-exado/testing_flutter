import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/subscription/providers/paket_provider.dart';
import 'package:test_flutter/features/subscription/providers/pesanan_provider.dart';
import 'package:test_flutter/app/theme.dart';

class PaketPage extends ConsumerStatefulWidget {
  const PaketPage({super.key});

  @override
  ConsumerState<PaketPage> createState() => _PaketPageState();
}

class _PaketPageState extends ConsumerState<PaketPage> {
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  ProviderSubscription? _paketSub;
  ProviderSubscription? _pesananSub;
  MidtransSDK? _midtrans;

  @override
  void initState() {
    super.initState();
    // Initialize Midtrans asynchronously
    _initMidtrans();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paketProvider.notifier).loadPakets();
      ref.read(pesananProvider.notifier).checkStatusPremium();
    });
    _paketSub = ref.listenManual(paketProvider, (previous, next) {
      final route = ModalRoute.of(context);
      final isCurrent = route != null && route.isCurrent;
      if (!mounted || !isCurrent) return;

      if (next.error != null) {
        showMessageToast(context, message: next.error!, type: ToastType.error);
        ref.read(paketProvider.notifier).clearError();
      } else if (next.message != null) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.success,
        );
        ref.read(paketProvider.notifier).clearMessage();
      }
    });

    _pesananSub = ref.listenManual(pesananProvider, (previous, next) {
      final route = ModalRoute.of(context);
      final isCurrent = route != null && route.isCurrent;
      if (!mounted || !isCurrent) return;

      if (next.error != null) {
        showMessageToast(context, message: next.error!, type: ToastType.error);
        ref.read(pesananProvider.notifier).clearError();
      } else if (next.message != null) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.success,
        );
        ref.read(pesananProvider.notifier).clearMessage();
      }
    });
  }

  void _initMidtrans() async {
    _midtrans = await MidtransSDK.init(
      config: MidtransConfig(
        clientKey: dotenv.env['MIDTRANS_CLIENT_KEY'] ?? "",
        merchantBaseUrl: dotenv.env['MIDTRANS_MERCHANT_BASE_URL'] ?? "",
        enableLog: true,
        colorTheme: ColorTheme(
          colorPrimary: Theme.of(context).colorScheme.primary,
          colorPrimaryDark: Theme.of(context).colorScheme.primary,
          colorSecondary: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
    _midtrans!.setTransactionFinishedCallback((result) {
      print(result.transactionId);
      print(result.status);
      print(result.message);
      print(result.paymentType);
    });
  }

  @override
  void dispose() {
    _paketSub?.close();
    _pesananSub?.close();
    _midtrans?.removeTransactionFinishedCallback();
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
    final subscriptionState = ref.watch(paketProvider);
    final pesananState = ref.watch(pesananProvider);
    final pakets = subscriptionState.pakets;
    final isPremium = pesananState.isPremium;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue.withValues(alpha: 0.03),
              Colors.white,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(_px(context, 24)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(_px(context, 12)),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: _px(context, 20),
                            ),
                          ),
                        ),
                        SizedBox(width: _px(context, 16)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paket Premium',
                                style: TextStyle(
                                  fontSize: _ts(context, 20),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: _px(context, 4)),
                              Text(
                                'Upgrade untuk akses fitur premium',
                                style: TextStyle(
                                  fontSize: _ts(context, 12),
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/transaction-history',
                            );
                          },
                          icon: const Icon(Icons.history_rounded),
                          color: Colors.white,
                          tooltip: 'Riwayat Transaksi',
                        ),
                      ],
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
                        padding: _pageHPad(
                          context,
                        ).add(EdgeInsets.symmetric(vertical: _px(context, 24))),
                        physics: const BouncingScrollPhysics(),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: _contentMaxWidth(context),
                            ),
                            child: Column(
                              children: [
                                // Active Subscription Info or Free Plan
                                if (isPremium)
                                  _buildActiveSubscriptionCard(context)
                                else
                                  _buildFreePlanCard(context),

                                SizedBox(height: _px(context, 32)),

                                // Plans Grid
                                if (pakets.isEmpty)
                                  _buildEmptyState(context)
                                else
                                  _buildPlansGrid(context, pakets, isPremium),

                                SizedBox(height: _px(context, 24)),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSubscriptionCard(BuildContext context) {
    final pesananState = ref.watch(pesananProvider);
    final activeSubscription = pesananState.activeSubscription;

    if (activeSubscription == null) {
      return const SizedBox.shrink();
    }

    // Format dates
    final dibayarFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final kadaluarsaFormat = DateFormat('dd MMM yyyy', 'id_ID');

    DateTime? dibayarDate;
    DateTime? kadaluarsaDate;

    try {
      dibayarDate = DateTime.parse(activeSubscription.dibayarPada!);
      kadaluarsaDate = DateTime.parse(activeSubscription.kadaluarsaPada!);
    } catch (e) {
      dibayarDate = null;
      kadaluarsaDate = null;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_px(context, 20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
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
                  color: Colors.white.withValues(alpha: 0.25),
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
                        fontSize: _ts(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: _px(context, 2)),
                    Text(
                      activeSubscription.premiumPaket.nama,
                      style: TextStyle(
                        fontSize: _ts(context, 13),
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
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dibeli Pada',
                      style: TextStyle(
                        fontSize: _ts(context, 11),
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: _px(context, 4)),
                    Text(
                      dibayarDate != null
                          ? dibayarFormat.format(dibayarDate)
                          : activeSubscription.dibayarPada!,
                      style: TextStyle(
                        fontSize: _ts(context, 13),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: _px(context, 35),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Kadaluarsa',
                      style: TextStyle(
                        fontSize: _ts(context, 11),
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: _px(context, 4)),
                    Text(
                      kadaluarsaDate != null
                          ? kadaluarsaFormat.format(kadaluarsaDate)
                          : activeSubscription.kadaluarsaPada!,
                      style: TextStyle(
                        fontSize: _ts(context, 13),
                        fontWeight: FontWeight.w600,
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
      padding: EdgeInsets.all(_px(context, 24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(_px(context, 12)),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: _px(context, 40),
              color: AppTheme.primaryBlue,
            ),
          ),
          SizedBox(height: _px(context, 16)),
          Text(
            'Paket Gratis',
            style: TextStyle(
              fontSize: _ts(context, 20),
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(height: _px(context, 8)),
          Text(
            'Upgrade ke Premium untuk akses fitur Tahajud dan Monitoring',
            style: TextStyle(
              fontSize: _ts(context, 14),
              color: AppTheme.onSurfaceVariant,
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
      ),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return _buildPlanCard(context, plan, isPremium);
      },
    );
  }

  Widget _buildPlanCard(BuildContext context, plan, bool isPremium) {
    final cover = plan.coverPath != null && plan.coverPath!.isNotEmpty
        ? "${dotenv.env['STORAGE_URL']}/${plan.coverPath}"
        : null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header dengan gradient
          Container(
            padding: EdgeInsets.all(_px(context, 16)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.12),
                  AppTheme.accentGreen.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                if (cover != null)
                  SizedBox(
                    width: _px(context, 80),
                    height: _px(context, 60),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlue,
                                AppTheme.accentGreen,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.white,
                            size: _px(context, 20),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(_px(context, 10)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: _px(context, 24),
                    ),
                  ),
                SizedBox(width: _px(context, 10)),
                Flexible(
                  child: Text(
                    plan.nama,
                    style: TextStyle(
                      fontSize: _ts(context, 18),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Price Section
          Padding(
            padding: EdgeInsets.fromLTRB(
              _px(context, 20),
              _px(context, 20),
              _px(context, 20),
              _px(context, 16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _px(context, 12),
                    vertical: _px(context, 8),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withValues(alpha: 0.1),
                        AppTheme.accentGreen.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Durasi ${plan.durasi} Bulan',
                    style: TextStyle(
                      fontSize: _ts(context, 12),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: _px(context, 16)),
                Text(
                  currencyFormat.format(plan.harga),
                  style: TextStyle(
                    fontSize: _ts(context, 32),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: _px(context, 12)),
                Text(
                  plan.deskripsi,
                  style: TextStyle(
                    fontSize: _ts(context, 13),
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Buy Button
          Padding(
            padding: EdgeInsets.fromLTRB(
              _px(context, 20),
              _px(context, 8),
              _px(context, 20),
              _px(context, 20),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPremium
                    ? null
                    : () => _handleBuyPlan(context, plan.id),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: _px(context, 16)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: isPremium ? 0 : 3,
                  shadowColor: AppTheme.accentGreen.withValues(alpha: 0.4),
                  backgroundColor: isPremium
                      ? Colors.grey.shade200
                      : AppTheme.accentGreen,
                  foregroundColor: isPremium ? Colors.grey : Colors.white,
                ),
                child: Text(
                  isPremium ? 'Sudah Aktif' : 'Beli Sekarang',
                  style: TextStyle(
                    fontSize: _ts(context, 16),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(_px(context, 16)),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: _px(context, 56),
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: _px(context, 16)),
          Text(
            'Paket tidak tersedia',
            style: TextStyle(
              fontSize: _ts(context, 16),
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBuyPlan(BuildContext context, int planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembelian'),
        content: const Text(
          'Anda akan diarahkan ke halaman pembayaran. Lanjutkan?',
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
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (mounted) {
      showMessageToast(
        context,
        message: 'Membuat pesanan...',
        type: ToastType.info,
      );
    }

    // Buy package and get snap token
    final snapToken = await ref
        .read(pesananProvider.notifier)
        .buyPackage(planId);

    if (!mounted) return;

    if (snapToken != null && snapToken.isNotEmpty) {
      // Get the created order from pesanan provider
      // Refresh transaction history to get the latest order
      await ref.read(pesananProvider.notifier).getRiwayatPesanan();

      final pesananState = ref.read(pesananProvider);
      final riwayat = pesananState.riwayatPesanan;

      // Get the latest pending order (should be the one just created)
      final latestPendingOrder = riwayat.isNotEmpty
          ? riwayat.firstWhere(
              (p) => p.status == 'pending',
              orElse: () => riwayat.first,
            )
          : null;

      if (latestPendingOrder != null) {
        // Navigate to detail page with the order data
        Navigator.pushNamed(
          context,
          '/pesanan-detail',
          arguments: {'pesanan': latestPendingOrder, 'snapToken': snapToken},
        );
      } else {
        showMessageToast(
          context,
          message: 'Pesanan berhasil dibuat!',
          type: ToastType.success,
        );
      }
    } else {
      // Show error if snap token is not available
      final pesananState = ref.read(pesananProvider);
      print('[ERROR] No snap token received: ${pesananState.error}');

      showMessageToast(
        context,
        message:
            pesananState.error ?? 'Gagal membuat pesanan. Silakan coba lagi.',
        type: ToastType.error,
      );
    }
  }
}
