import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/subscription/subscription_provider.dart';

class TransactionHistoryPage extends ConsumerStatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  ConsumerState<TransactionHistoryPage> createState() =>
      _TransactionHistoryPageState();
}

class _TransactionHistoryPageState
    extends ConsumerState<TransactionHistoryPage> {
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionProvider.notifier).loadTransactions();
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
    final subscriptionState = ref.watch(subscriptionProvider);
    final transactions = subscriptionState.transactions;

    // Listen to state changes
    ref.listen<SubscriptionState>(subscriptionProvider, (previous, next) {
      if (next.error != null) {
        showMessageToast(
          context,
          message: next.error!,
          type: ToastType.error,
        );
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
                      'Riwayat Transaksi',
                      style: TextStyle(
                        fontSize: _ts(context, 24),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  // Refresh Button
                  if (!subscriptionState.isLoading)
                    IconButton(
                      onPressed: () {
                        ref
                            .read(subscriptionProvider.notifier)
                            .loadTransactions();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      color: const Color(0xFF1E88E5),
                      tooltip: 'Refresh',
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: subscriptionState.isLoading && transactions.isEmpty
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
                                .read(subscriptionProvider.notifier)
                                .loadTransactions();
                          },
                          color: const Color(0xFF1E88E5),
                          child: SingleChildScrollView(
                            padding: _pageHPad(context),
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: _contentMaxWidth(context),
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(height: _px(context, 16)),
                                    ...transactions.map((transaction) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: _px(context, 12),
                                        ),
                                        child: _buildTransactionCard(
                                          context,
                                          transaction,
                                        ),
                                      );
                                    }).toList(),
                                    SizedBox(height: _px(context, 16)),
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
    );
  }

  Widget _buildTransactionCard(BuildContext context, transaction) {
    Color statusColor;
    IconData statusIcon;

    switch (transaction.status.toLowerCase()) {
      case 'success':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty_rounded;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'expired':
        statusColor = Colors.grey;
        statusIcon = Icons.timer_off_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
    }

    final isPending = transaction.status.toLowerCase() == 'pending';

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
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(_px(context, 16)),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: _px(context, 24),
                ),
                SizedBox(width: _px(context, 10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.getStatusText(),
                        style: TextStyle(
                          fontSize: _ts(context, 16),
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
                  DateFormat('dd MMM yy', 'id_ID')
                      .format(transaction.createdAt),
                  style: TextStyle(
                    fontSize: _ts(context, 12),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: EdgeInsets.all(_px(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan Name
                _buildDetailRow(
                  context,
                  'Paket',
                  transaction.planName,
                  Icons.workspace_premium_rounded,
                ),
                SizedBox(height: _px(context, 10)),

                // Amount
                _buildDetailRow(
                  context,
                  'Total',
                  currencyFormat.format(transaction.amount),
                  Icons.payments_rounded,
                ),
                SizedBox(height: _px(context, 10)),

                // Payment Method
                if (transaction.paymentType != null) ...[
                  _buildDetailRow(
                    context,
                    'Metode',
                    _getPaymentTypeLabel(transaction.paymentType!),
                    Icons.account_balance_wallet_rounded,
                  ),
                  SizedBox(height: _px(context, 10)),
                ],

                // VA Number (for bank transfer)
                if (transaction.vaNumber != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.credit_card_rounded,
                        size: _px(context, 18),
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: _px(context, 8)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nomor VA ${transaction.bankName ?? ''}',
                              style: TextStyle(
                                fontSize: _ts(context, 12),
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    transaction.vaNumber!,
                                    style: TextStyle(
                                      fontSize: _ts(context, 15),
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2D3748),
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: transaction.vaNumber!,
                                      ),
                                    );
                                    showMessageToast(
                                      context,
                                      message: 'Nomor VA disalin',
                                      type: ToastType.success,
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded),
                                  iconSize: _px(context, 18),
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
                  SizedBox(height: _px(context, 10)),
                ],

                // Expired time for pending
                if (isPending && transaction.expiredAt != null) ...[
                  Container(
                    padding: EdgeInsets.all(_px(context, 10)),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: _px(context, 18),
                          color: Colors.orange.shade700,
                        ),
                        SizedBox(width: _px(context, 8)),
                        Expanded(
                          child: Text(
                            'Bayar sebelum ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(transaction.expiredAt!)}',
                            style: TextStyle(
                              fontSize: _ts(context, 12),
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: _px(context, 10)),
                ],

                // Check Status Button for pending
                if (isPending)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleCheckStatus(context, transaction.orderId),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Cek Status Pembayaran'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: _px(context, 12),
                        ),
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

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: _px(context, 18),
          color: Colors.grey.shade600,
        ),
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

  String _getPaymentTypeLabel(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'bank_transfer':
        return 'Transfer Bank';
      case 'gopay':
        return 'GoPay';
      case 'qris':
        return 'QRIS';
      case 'credit_card':
        return 'Kartu Kredit';
      case 'cstore':
        return 'Alfamart/Indomaret';
      default:
        return paymentType;
    }
  }

  Future<void> _handleCheckStatus(BuildContext context, String orderId) async {
    await ref
        .read(subscriptionProvider.notifier)
        .checkTransactionStatus(orderId);
  }
}
