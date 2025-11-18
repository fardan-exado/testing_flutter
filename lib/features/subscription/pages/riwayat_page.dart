import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/subscription/pages/detail_pesanan_page.dart';
import 'package:test_flutter/features/subscription/providers/pesanan_provider.dart';
import 'package:test_flutter/features/subscription/states/pesanan_state.dart';

class RiwayatPage extends ConsumerStatefulWidget {
  const RiwayatPage({super.key});

  @override
  ConsumerState<RiwayatPage> createState() =>
      _RiwayatPageState();
}

class _RiwayatPageState
    extends ConsumerState<RiwayatPage> {
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pesananProvider.notifier).getRiwayatPesanan();
    });
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
    if (ResponsiveHelper.isExtraLargeScreen(c)) return 900;
    if (ResponsiveHelper.isLargeScreen(c)) return 800;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final pesananState = ref.watch(pesananProvider);
    final transactions = pesananState.riwayatPesanan;

    // Listen to state changes
    ref.listen<PesananState>(pesananProvider, (previous, next) {
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBlue.withValues(alpha: 0.12),
              AppTheme.accentGreen.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header - Matching Plan Page Style
              Container(
                padding: EdgeInsets.all(_px(context, 24)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                                'Riwayat Transaksi',
                                style: TextStyle(
                                  fontSize: _ts(context, 20),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: _px(context, 4)),
                              Text(
                                'Kelola pembelian paket premium Anda',
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
                            ref
                                .read(pesananProvider.notifier)
                                .getRiwayatPesanan();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          color: Colors.white,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: pesananState.isLoading && transactions.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1E88E5),
                        ),
                      )
                    : transactions.isEmpty
                    ? _buildEmptyState(context)
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ref
                              .read(pesananProvider.notifier)
                              .getRiwayatPesanan();
                        },
                        color: const Color(0xFF1E88E5),
                        child: SingleChildScrollView(
                          padding: _pageHPad(context).add(
                            EdgeInsets.symmetric(vertical: _px(context, 24)),
                          ),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: _contentMaxWidth(context),
                              ),
                              child: Column(
                                children: [
                                  if (pesananState.isLoading)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: _px(context, 32),
                                      ),
                                      child: const SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF1E88E5),
                                          strokeWidth: 3,
                                        ),
                                      ),
                                    )
                                  else
                                    ...transactions.map((transaction) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: _px(context, 16),
                                        ),
                                        child: _buildTransactionCard(
                                          context,
                                          transaction,
                                        ),
                                      );
                                    }).toList(),
                                  SizedBox(height: _px(context, 8)),
                                ],
                              ),
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

  Widget _buildTransactionCard(BuildContext context, transaction) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (transaction.status.toLowerCase()) {
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Lunas';
        break;
      case 'success':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Berhasil';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty_rounded;
        statusLabel = 'Menunggu Pembayaran';
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Gagal';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.block_rounded;
        statusLabel = 'Dibatalkan';
        break;
      case 'expired':
        statusColor = Colors.grey;
        statusIcon = Icons.timer_off_rounded;
        statusLabel = 'Kadaluarsa';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
        statusLabel = transaction.status;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background matching plan_page style
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(_px(context, 16)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  statusColor.withValues(alpha: 0.15),
                  statusColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              border: Border(
                bottom: BorderSide(
                  color: statusColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: _px(context, 50),
                  height: _px(context, 50),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: _px(context, 24),
                  ),
                ),
                SizedBox(width: _px(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: _ts(context, 15),
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        transaction.orderId,
                        style: TextStyle(
                          fontSize: _ts(context, 12),
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat(
                    'dd MMM yy',
                    'id_ID',
                  ).format(DateTime.parse(transaction.createdAt)),
                  style: TextStyle(
                    fontSize: _ts(context, 12),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: EdgeInsets.all(_px(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Paket Name
                _buildDetailRow(
                  context,
                  'Paket',
                  transaction.premiumPaket.nama,
                  Icons.workspace_premium_rounded,
                ),
                SizedBox(height: _px(context, 12)),

                // Total Amount
                _buildDetailRow(
                  context,
                  'Total',
                  currencyFormat.format(transaction.hargaTotal),
                  Icons.payments_rounded,
                ),
                SizedBox(height: _px(context, 12)),

                // Durasi
                if (transaction.premiumPaket.durasi != null) ...[
                  _buildDetailRow(
                    context,
                    'Durasi',
                    '${transaction.premiumPaket.durasi} bulan',
                    Icons.calendar_month_rounded,
                  ),
                  SizedBox(height: _px(context, 12)),
                ],

                // Purchase Date (dibayar_pada)
                if (transaction.dibayarPada != null) ...[
                  _buildDetailRow(
                    context,
                    'Dibeli Pada',
                    _formatDate(transaction.dibayarPada),
                    Icons.event_rounded,
                  ),
                  SizedBox(height: _px(context, 12)),
                ],

                // Expiry Date (kadaluarsa_pada)
                if (transaction.kadaluarsaPada != null) ...[
                  _buildDetailRow(
                    context,
                    'Kadaluarsa Pada',
                    _formatDate(transaction.kadaluarsaPada),
                    Icons.event_busy_rounded,
                  ),
                  SizedBox(height: _px(context, 12)),
                ],

                // Midtrans ID
                if (transaction.midtransId != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.payment_rounded,
                        size: _px(context, 18),
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: _px(context, 8)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ID Transaksi',
                              style: TextStyle(
                                fontSize: _ts(context, 12),
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    transaction.midtransId!,
                                    style: TextStyle(
                                      fontSize: _ts(context, 13),
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF2D3748),
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: transaction.midtransId!,
                                      ),
                                    );
                                    showMessageToast(
                                      context,
                                      message: 'ID Transaksi disalin',
                                      type: ToastType.success,
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded),
                                  iconSize: _px(context, 16),
                                  color: const Color(0xFF1E88E5),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _px(context, 16)),
                ],

                // Detail Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleDetailPesanan(context, transaction),
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('Detail Pesanan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: _px(context, 12)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: _px(context, 18), color: Colors.grey.shade600),
        SizedBox(width: _px(context, 8)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: _ts(context, 12),
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: _ts(context, 15),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: _px(context, 64),
            color: Colors.grey.shade400,
          ),
          SizedBox(height: _px(context, 16)),
          Text(
            'Belum Ada Transaksi',
            style: TextStyle(
              fontSize: _ts(context, 18),
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: _px(context, 8)),
          Text(
            'Riwayat transaksi Anda akan muncul di sini',
            style: TextStyle(
              fontSize: _ts(context, 14),
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleDetailPesanan(BuildContext context, transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPesananPage(pesanan: transaction),
      ),
    );
  }
}
