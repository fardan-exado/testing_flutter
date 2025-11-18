import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/subscription/models/pesanan.dart';

class PesananDetailPage extends StatefulWidget {
  final Pesanan pesanan;
  final String? snapToken;

  const PesananDetailPage({super.key, required this.pesanan, this.snapToken});

  @override
  State<PesananDetailPage> createState() => _PesananDetailPageState();
}

class _PesananDetailPageState extends State<PesananDetailPage> {
  MidtransSDK? _midtrans;
  bool _isInitializingPayment = false;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Initialize Midtrans SDK when page loads
    if (widget.snapToken != null) {
      _initMidtrans();
    }
  }

  Future<void> _initMidtrans() async {
    try {
      print('[DEBUG] Initializing Midtrans SDK...');
      _midtrans = await MidtransSDK.init(
        config: MidtransConfig(
          clientKey: dotenv.env['MIDTRANS_CLIENT_KEY'] ?? "",
          merchantBaseUrl: dotenv.env['MIDTRANS_MERCHANT_BASE_URL'] ?? "",
          enableLog: true,
          colorTheme: ColorTheme(
            colorPrimary: AppTheme.primaryBlue,
            colorPrimaryDark: AppTheme.primaryBlue,
            colorSecondary: AppTheme.accentGreen,
          ),
        ),
      );

      print('[DEBUG] Midtrans SDK initialized successfully');

      _midtrans?.setTransactionFinishedCallback((result) async {
        print('[DEBUG] Transaction finished: ${result.status}');

        if (mounted) {
          showMessageToast(
            context,
            message: 'Status pembayaran: ${result.status}',
            type: ToastType.info,
          );

          // Navigate back to refresh status
          Navigator.pop(context);
        }
      });
    } catch (e) {
      print('[ERROR] Error initializing Midtrans: $e');
    }
  }

  @override
  void dispose() {
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
    if (ResponsiveHelper.isExtraLargeScreen(c)) return 900;
    if (ResponsiveHelper.isLargeScreen(c)) return 800;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
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
              // Header - Matching Transaction History Style
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
                                'Detail Pesanan',
                                style: TextStyle(
                                  fontSize: _ts(context, 20),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: _px(context, 4)),
                              Text(
                                widget.pesanan.orderId,
                                style: TextStyle(
                                  fontSize: _ts(context, 12),
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: _pageHPad(
                    context,
                  ).add(EdgeInsets.symmetric(vertical: _px(context, 24))),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: _contentMaxWidth(context),
                      ),
                      child: Column(
                        children: [
                          // Status Card
                          _buildStatusCard(context),
                          SizedBox(height: _px(context, 24)),

                          // Paket Info Card
                          _buildPaketInfoCard(context),
                          SizedBox(height: _px(context, 24)),

                          // Order Details Card
                          _buildOrderDetailsCard(context),
                          SizedBox(height: _px(context, 24)),

                          // Payment Information Card
                          _buildPaymentInfoCard(context),
                          SizedBox(height: _px(context, 24)),

                          // Action Buttons
                          _buildActionButtons(context),
                          SizedBox(height: _px(context, 16)),
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

  Widget _buildStatusCard(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (widget.pesanan.status.toLowerCase()) {
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
        statusLabel = widget.pesanan.status;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_px(context, 20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.15),
            statusColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: _px(context, 60),
            height: _px(context, 60),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(statusIcon, color: statusColor, size: _px(context, 30)),
          ),
          SizedBox(width: _px(context, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Pesanan',
                  style: TextStyle(
                    fontSize: _ts(context, 12),
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: _px(context, 4)),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: _ts(context, 18),
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaketInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_px(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
          Text(
            'Informasi Paket',
            style: TextStyle(
              fontSize: _ts(context, 16),
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(height: _px(context, 16)),
          _buildDetailRow(
            context,
            'Nama Paket',
            widget.pesanan.premiumPaket.nama,
            Icons.workspace_premium_rounded,
          ),
          SizedBox(height: _px(context, 12)),
          _buildDetailRow(
            context,
            'Durasi',
            '${widget.pesanan.premiumPaket.durasi} Bulan',
            Icons.calendar_month_rounded,
          ),
          SizedBox(height: _px(context, 12)),
          Text(
            'Deskripsi',
            style: TextStyle(
              fontSize: _ts(context, 12),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: _px(context, 4)),
          Text(
            widget.pesanan.premiumPaket.deskripsi,
            style: TextStyle(
              fontSize: _ts(context, 13),
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_px(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
          Text(
            'Detail Pesanan',
            style: TextStyle(
              fontSize: _ts(context, 16),
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(height: _px(context, 16)),
          _buildDetailRow(
            context,
            'ID Pesanan',
            widget.pesanan.id.toString(),
            Icons.tag_rounded,
          ),
          SizedBox(height: _px(context, 12)),
          _buildDetailRow(
            context,
            'Order ID',
            widget.pesanan.orderId,
            Icons.receipt_rounded,
          ),
          SizedBox(height: _px(context, 12)),
          _buildDetailRow(
            context,
            'Total Harga',
            currencyFormat.format(widget.pesanan.hargaTotal),
            Icons.payments_rounded,
          ),
          SizedBox(height: _px(context, 12)),
          _buildDetailRow(
            context,
            'Dibeli Pada',
            _formatDate(widget.pesanan.dibayarPada),
            Icons.event_rounded,
          ),
          SizedBox(height: _px(context, 12)),
          _buildDetailRow(
            context,
            'Kadaluarsa Pada',
            _formatDate(widget.pesanan.kadaluarsaPada),
            Icons.event_busy_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_px(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
          Text(
            'Informasi Pembayaran',
            style: TextStyle(
              fontSize: _ts(context, 16),
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(height: _px(context, 16)),
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
                      'ID Transaksi Midtrans',
                      style: TextStyle(
                        fontSize: _ts(context, 12),
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: _px(context, 4)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.pesanan.midtransId,
                            style: TextStyle(
                              fontSize: _ts(context, 13),
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: widget.pesanan.midtransId),
                            );
                            showMessageToast(
                              context,
                              message: 'ID Transaksi disalin',
                              type: ToastType.success,
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                          iconSize: _px(context, 18),
                          color: AppTheme.primaryBlue,
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
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(_px(context, 12)),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jumlah Pembayaran',
                      style: TextStyle(
                        fontSize: _ts(context, 13),
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      currencyFormat.format(widget.pesanan.hargaTotal),
                      style: TextStyle(
                        fontSize: _ts(context, 16),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
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

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text:
                      'Order ID: ${widget.pesanan.orderId}\n'
                      'Total: ${currencyFormat.format(widget.pesanan.hargaTotal)}\n'
                      'Status: ${widget.pesanan.status}',
                ),
              );
              showMessageToast(
                context,
                message: 'Detail pesanan disalin',
                type: ToastType.success,
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Salin Info'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              side: BorderSide(color: AppTheme.primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: _px(context, 12)),
            ),
          ),
        ),
        SizedBox(width: _px(context, 12)),
        // Show "Bayar Sekarang" button if status is pending and snapToken is available
        if (widget.pesanan.status == 'pending' && widget.snapToken != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isInitializingPayment ? null : () => _handlePayNow(),
              icon: _isInitializingPayment
                  ? SizedBox(
                      width: _px(context, 16),
                      height: _px(context, 16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.payment_rounded),
              label: Text(
                _isInitializingPayment ? 'Memproses...' : 'Bayar Sekarang',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: _px(context, 12)),
                elevation: 3,
              ),
            ),
          )
        else
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Kembali'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: _px(context, 12)),
                elevation: 0,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handlePayNow() async {
    if (widget.snapToken == null || widget.snapToken!.isEmpty) {
      showMessageToast(
        context,
        message: 'Snap token tidak tersedia',
        type: ToastType.error,
      );
      return;
    }

    // Set loading state
    setState(() {
      _isInitializingPayment = true;
    });

    try {
      // Wait a bit to ensure SDK is fully initialized
      if (_midtrans == null) {
        print('[DEBUG] Waiting for Midtrans SDK initialization...');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (_midtrans == null) {
        showMessageToast(
          context,
          message: 'Sistem pembayaran belum siap, coba lagi',
          type: ToastType.error,
        );
        return;
      }

      print('[DEBUG] Starting payment with snap token: ${widget.snapToken}');
      await _midtrans!.startPaymentUiFlow(token: widget.snapToken!);
      print('[DEBUG] Payment flow started successfully');
    } catch (e) {
      print('[ERROR] Error starting payment: $e');
      if (mounted) {
        showMessageToast(
          context,
          message: 'Error membuka pembayaran: $e',
          type: ToastType.error,
        );
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isInitializingPayment = false;
        });
      }
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: _px(context, 2)),
              Text(
                value,
                style: TextStyle(
                  fontSize: _ts(context, 14),
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
