import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/utils/responsive_helper.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/sedekah/sedekah_provider.dart';
import 'package:test_flutter/features/sedekah/sedekah_state.dart';

class TambahSedekahPage extends ConsumerStatefulWidget {
  const TambahSedekahPage({super.key});

  @override
  ConsumerState<TambahSedekahPage> createState() => _TambahSedekahPageState();
}

class _TambahSedekahPageState extends ConsumerState<TambahSedekahPage> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Responsive utils
  double _scale(BuildContext c) {
    if (ResponsiveHelper.isSmallScreen(c)) return .9;
    if (ResponsiveHelper.isMediumScreen(c)) return 1.0;
    if (ResponsiveHelper.isLargeScreen(c)) return 1.1;
    return 1.2;
  }

  double _px(BuildContext c, double base) => base * _scale(c);
  double _ts(BuildContext c, double base) =>
      ResponsiveHelper.adaptiveTextSize(c, base);

  double _maxWidth(BuildContext c) {
    if (ResponsiveHelper.isExtraLargeScreen(c)) return 820;
    if (ResponsiveHelper.isLargeScreen(c)) return 680;
    return double.infinity;
  }

  EdgeInsets _hpad(BuildContext c) => EdgeInsets.symmetric(
    horizontal: ResponsiveHelper.getResponsivePadding(c).left,
  );

  @override
  void initState() {
    super.initState();
    _setupStateListener();
  }

  void _setupStateListener() {
    ref.listenManual<SedekahState>(sedekahProvider, (previous, next) {
      if (!mounted) return;

      // Handle success state
      if (next.status == SedekahStatus.success &&
          next.message != null &&
          next.message!.isNotEmpty) {
        // Show success toast first
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.success,
          duration: const Duration(seconds: 3),
        );

        // Clear message
        ref.read(sedekahProvider.notifier).clearMessage();

        // Navigate back after a short delay
        Navigator.pushReplacementNamed(context, '/zakat');
      }

      // Handle error state
      if (next.status == SedekahStatus.error &&
          next.message != null &&
          next.message!.isNotEmpty) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.error,
          duration: const Duration(seconds: 4),
        );

        // Clear message after showing
        ref.read(sedekahProvider.notifier).clearMessage();
      }
    });
  }

  @override
  void dispose() {
    _typeController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryBlue,
            onPrimary: Colors.white,
            onSurface: AppTheme.onSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final tanggal = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final amount = _amountController.text.replaceAll('.', '');
    final type = _typeController.text.trim();
    final note = _noteController.text.trim();

    try {
      // Use the provider's addSedekah method
      await ref
          .read(sedekahProvider.notifier)
          .addSedekah(
            jenisSedekah: type,
            tanggal: tanggal,
            jumlah: int.parse(amount),
            keterangan: note.isNotEmpty ? note : null,
          );
    } catch (e) {
      // Error handling is done in the listener
    }
  }

  void _handleBack() {
    final sedekahState = ref.read(sedekahProvider);
    final isLoading = sedekahState.status == SedekahStatus.loading;

    if (isLoading) return;

    // Check if there's unsaved data
    final hasData =
        _typeController.text.trim().isNotEmpty ||
        _amountController.text.trim().isNotEmpty ||
        _noteController.text.trim().isNotEmpty;

    if (hasData) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Batalkan Input?'),
          content: const Text(
            'Data yang sudah diisi akan hilang. Apakah Anda yakin ingin keluar?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/zakat'),
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/zakat');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Keluar'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/zakat');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider state
    final sedekahState = ref.watch(sedekahProvider);
    final isLoading = sedekahState.status == SedekahStatus.loading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue.withValues(alpha: 0.03),
              AppTheme.backgroundWhite,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _maxWidth(context)),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(_px(context, 16)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlue.withValues(alpha: 0.1),
                                AppTheme.accentGreen.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: isLoading ? null : _handleBack,
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tambah Sedekah',
                                style: TextStyle(
                                  fontSize: _ts(context, 20),
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onSurface,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Catat sedekah Anda',
                                style: TextStyle(
                                  fontSize: _ts(context, 13),
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isLoading)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: _hpad(
                        context,
                      ).add(EdgeInsets.symmetric(vertical: _px(context, 18))),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Jenis Sedekah - Text Input
                            _buildLabel(context, 'Jenis Sedekah'),
                            SizedBox(height: _px(context, 10)),
                            _buildInputContainer(
                              context,
                              child: TextFormField(
                                controller: _typeController,
                                enabled: !isLoading,
                                decoration: InputDecoration(
                                  hintText:
                                      'Contoh: Sedekah Jumat, Infaq Masjid',
                                  hintStyle: TextStyle(
                                    fontSize: _ts(context, 14),
                                    color: AppTheme.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.category_rounded,
                                    color: AppTheme.primaryBlue,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: _px(context, 20),
                                    vertical: _px(context, 14),
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: _ts(context, 15),
                                  fontWeight: FontWeight.w500,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Masukkan jenis sedekah'
                                    : null,
                              ),
                            ),

                            SizedBox(height: _px(context, 20)),

                            // Tanggal
                            _buildLabel(context, 'Tanggal Sedekah'),
                            SizedBox(height: _px(context, 10)),
                            InkWell(
                              onTap: isLoading ? null : _pickDate,
                              borderRadius: BorderRadius.circular(16),
                              child: _buildInputContainer(
                                context,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: _px(context, 20),
                                    vertical: _px(context, 14),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        color: AppTheme.primaryBlue,
                                        size: _px(context, 22),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        DateFormat(
                                          'dd MMMM yyyy',
                                          'id_ID',
                                        ).format(_selectedDate),
                                        style: TextStyle(
                                          fontSize: _ts(context, 15),
                                          color: AppTheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.arrow_drop_down_rounded,
                                        color: AppTheme.onSurfaceVariant,
                                        size: _px(context, 24),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: _px(context, 20)),

                            // Nominal
                            _buildLabel(context, 'Nominal Sedekah'),
                            SizedBox(height: _px(context, 10)),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.accentGreen.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentGreen.withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _amountController,
                                enabled: !isLoading,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize: _ts(context, 15),
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentGreen,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    fontSize: _ts(context, 15),
                                    color: AppTheme.onSurfaceVariant.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.payments_rounded,
                                    color: AppTheme.accentGreen,
                                  ),
                                  prefixText: 'Rp ',
                                  prefixStyle: TextStyle(
                                    color: AppTheme.onSurface,
                                    fontSize: _ts(context, 15),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: _px(context, 20),
                                    vertical: _px(context, 14),
                                  ),
                                ),
                                onChanged: (value) {
                                  final clean = value.replaceAll('.', '');
                                  if (clean.isNotEmpty && clean != '0') {
                                    try {
                                      final f = NumberFormat('#,###', 'id_ID');
                                      final formatted = f.format(
                                        int.parse(clean),
                                      );
                                      _amountController.value =
                                          TextEditingValue(
                                            text: formatted,
                                            selection: TextSelection.collapsed(
                                              offset: formatted.length,
                                            ),
                                          );
                                    } catch (e) {
                                      // Handle parsing errors silently
                                    }
                                  }
                                },
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Masukkan nominal sedekah';
                                  }
                                  final clean = v.replaceAll('.', '');
                                  if (int.tryParse(clean) == null ||
                                      int.parse(clean) <= 0) {
                                    return 'Nominal harus lebih dari 0';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            SizedBox(height: _px(context, 20)),

                            // Catatan
                            _buildLabel(context, 'Catatan (Opsional)'),
                            SizedBox(height: _px(context, 10)),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.primaryBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _noteController,
                                enabled: !isLoading,
                                maxLines: 4,
                                style: TextStyle(
                                  fontSize: _ts(context, 14),
                                  height: 1.5,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Tambahkan catatan untuk mengingatkan tujuan sedekah ini...',
                                  hintStyle: TextStyle(
                                    fontSize: _ts(context, 14),
                                    color: AppTheme.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.only(
                                      bottom: _px(context, 60),
                                      top: _px(context, 12),
                                    ),
                                    child: const Icon(
                                      Icons.note_alt_rounded,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: _px(context, 20),
                                    vertical: _px(context, 14),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: _px(context, 28)),

                            // Save Button
                            SizedBox(
                              height: _px(context, 54),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryBlue,
                                      AppTheme.accentGreen,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: isLoading ? null : _save,
                                  icon: isLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white.withValues(
                                                    alpha: 0.9,
                                                  ),
                                                ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.save_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                  label: Text(
                                    isLoading
                                        ? 'Menyimpan...'
                                        : 'Simpan Sedekah',
                                    style: TextStyle(
                                      fontSize: _ts(context, 16),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    disabledBackgroundColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: _ts(context, 15),
        fontWeight: FontWeight.w600,
        color: AppTheme.onSurface,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildInputContainer(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
