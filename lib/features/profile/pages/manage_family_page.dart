import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/profile/helpers/profile_responsive_helper.dart';
import 'package:test_flutter/features/profile/models/anak.dart';
import 'package:test_flutter/features/profile/models/relasi_orang_tua_anak.dart';
import 'package:test_flutter/features/profile/providers/family_provider.dart';
import 'package:test_flutter/features/profile/states/family_state.dart';

class ManageFamilyPage extends ConsumerStatefulWidget {
  const ManageFamilyPage({super.key});

  @override
  ConsumerState<ManageFamilyPage> createState() => _ManageFamilyPageState();
}

class _ManageFamilyPageState extends ConsumerState<ManageFamilyPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  ProviderSubscription? _familySub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load family data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyProvider.notifier).loadFamilyData();
    });

    // Setup manual listener for family state changes
    _familySub = ref.listenManual(familyProvider, (previous, next) {
      final route = ModalRoute.of(context);
      final isCurrent = route != null && route.isCurrent;
      if (!mounted || !isCurrent) return;

      if (next.status == FamilyStatus.success && next.message != null) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.success,
          duration: const Duration(seconds: 3),
        );
        ref.read(familyProvider.notifier).clearMessage();
        ref.read(familyProvider.notifier).resetStatus();
      } else if (next.status == FamilyStatus.error && next.message != null) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.error,
          duration: const Duration(seconds: 4),
        );
        ref.read(familyProvider.notifier).clearMessage();
      }
    });
  }

  @override
  void dispose() {
    _familySub?.close();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyProvider);
    final isLoading = familyState.status == FamilyStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade200],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ===== Header dengan Gradient =====
              Container(
                padding: EdgeInsets.all(
                  ProfileResponsiveHelper.px(context, 20),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        ProfileResponsiveHelper.px(context, 12),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: ProfileResponsiveHelper.px(context, 20),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Kelola Keluarga',
                          style: TextStyle(
                            fontSize: ProfileResponsiveHelper.ts(context, 20),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(
                        ProfileResponsiveHelper.px(context, 12),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          ref.read(familyProvider.notifier).loadFamilyData();
                        },
                        child: Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: ProfileResponsiveHelper.px(context, 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== TabBar =====
              SizedBox(height: ProfileResponsiveHelper.px(context, 16)),

              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: ProfileResponsiveHelper.px(context, 24),
                ),
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppTheme.primaryBlue,
                  unselectedLabelColor: AppTheme.onSurfaceVariant,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: ProfileResponsiveHelper.textSize(context, 13),
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: ProfileResponsiveHelper.textSize(context, 13),
                  ),
                  dividerColor: Colors.transparent,
                  tabs: familyState.isChild
                      ? const [
                          Tab(text: 'Orang Tua'),
                          Tab(text: 'Pengajuan Orang Tua'),
                        ]
                      : const [
                          Tab(text: 'Anak Aktif'),
                          Tab(text: 'Pengajuan Anak'),
                        ],
                ),
              ),

              // ===== TabBarView Content =====
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: familyState.isChild
                      ? [
                          // Tab 1: Orang Tua
                          _buildOrangTuaTab(context, familyState, isLoading),
                          // Tab 2: Pengajuan Orang Tua
                          _buildPengajuanOrangTuaTab(
                            context,
                            familyState,
                            isLoading,
                          ),
                        ]
                      : [
                          // Tab 1: Anak Aktif
                          _buildAnakAktifTab(context, familyState, isLoading),
                          // Tab 2: Pengajuan Anak
                          _buildPengajuanAnakTab(
                            context,
                            familyState,
                            isLoading,
                          ),
                        ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tab 1: Anak Aktif
  Widget _buildAnakAktifTab(
    BuildContext context,
    FamilyState familyState,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      padding: ProfileResponsiveHelper.getPageHorizontalPadding(context),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileResponsiveHelper.verticalGap(context, medium: 24),

          if (isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(
                  ProfileResponsiveHelper.px(context, 32),
                ),
                child: const CircularProgressIndicator(
                  color: Color(0xFF1E88E5),
                ),
              ),
            )
          else if (familyState.anakAktif.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(
                  ProfileResponsiveHelper.px(context, 32),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: ProfileResponsiveHelper.px(context, 64),
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: ProfileResponsiveHelper.px(context, 16)),
                    Text(
                      'Belum ada anak aktif',
                      style: TextStyle(
                        fontSize: ProfileResponsiveHelper.textSize(context, 16),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...familyState.anakAktif.map(
              (anak) => Container(
                margin: EdgeInsets.only(
                  bottom: ProfileResponsiveHelper.px(context, 12),
                ),
                child: _buildAnakCard(context, anak),
              ),
            ),

          ProfileResponsiveHelper.verticalGap(context, medium: 24),
        ],
      ),
    );
  }

  // Tab 2: Pengajuan Anak
  Widget _buildPengajuanAnakTab(
    BuildContext context,
    FamilyState familyState,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      padding: ProfileResponsiveHelper.getPageHorizontalPadding(context),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileResponsiveHelper.verticalGap(context, medium: 24),

          // Tambah Pengajuan Button
          SizedBox(
            width: double.infinity,
            height: ProfileResponsiveHelper.px(context, 60),
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : () => _showPengajuanDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                Icons.add,
                size: ProfileResponsiveHelper.getIconSize(context),
              ),
              label: Text(
                'Tambah Pengajuan',
                style: TextStyle(
                  fontSize: ProfileResponsiveHelper.textSize(context, 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          ProfileResponsiveHelper.verticalGap(context, medium: 20),

          if (isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(
                  ProfileResponsiveHelper.px(context, 32),
                ),
                child: const CircularProgressIndicator(
                  color: Color(0xFF1E88E5),
                ),
              ),
            )
          else if (familyState.pengajuanAnak.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(
                  ProfileResponsiveHelper.px(context, 32),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: ProfileResponsiveHelper.px(context, 64),
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: ProfileResponsiveHelper.px(context, 16)),
                    Text(
                      'Tidak ada pengajuan',
                      style: TextStyle(
                        fontSize: ProfileResponsiveHelper.textSize(context, 16),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...familyState.pengajuanAnak.map(
              (pengajuan) => Container(
                margin: EdgeInsets.only(
                  bottom: ProfileResponsiveHelper.px(context, 12),
                ),
                child: _buildPengajuanCard(context, pengajuan),
              ),
            ),

          ProfileResponsiveHelper.verticalGap(context, medium: 24),
        ],
      ),
    );
  }

  // Tab 1: Orang Tua (Child View)
  Widget _buildOrangTuaTab(
    BuildContext context,
    FamilyState familyState,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      padding: ProfileResponsiveHelper.getPageHorizontalPadding(context),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileResponsiveHelper.verticalGap(context, medium: 24),

          if (isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(
                  ProfileResponsiveHelper.px(context, 32),
                ),
                child: const CircularProgressIndicator(
                  color: Color(0xFF1E88E5),
                ),
              ),
            )
          else if (familyState.orangTua == null)
            Center(
              child: Padding(
                padding: EdgeInsets.all(
                  ProfileResponsiveHelper.px(context, 32),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_off_outlined,
                      size: ProfileResponsiveHelper.px(context, 64),
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: ProfileResponsiveHelper.px(context, 16)),
                    Text(
                      'Belum ada data orang tua',
                      style: TextStyle(
                        fontSize: ProfileResponsiveHelper.textSize(context, 16),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildOrangTuaCard(context, familyState.orangTua!),

          ProfileResponsiveHelper.verticalGap(context, medium: 24),
        ],
      ),
    );
  }

  // Tab 2: Pengajuan Orang Tua (Child View)
  Widget _buildPengajuanOrangTuaTab(
    BuildContext context,
    FamilyState familyState,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      padding: ProfileResponsiveHelper.getPageHorizontalPadding(context),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileResponsiveHelper.verticalGap(context, medium: 24),

          if (isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(
                  ProfileResponsiveHelper.px(context, 32),
                ),
                child: const CircularProgressIndicator(
                  color: Color(0xFF1E88E5),
                ),
              ),
            )
          else if (familyState.pengajuanOrangTua.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(
                  ProfileResponsiveHelper.px(context, 32),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: ProfileResponsiveHelper.px(context, 64),
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: ProfileResponsiveHelper.px(context, 16)),
                    Text(
                      'Tidak ada pengajuan dari orang tua',
                      style: TextStyle(
                        fontSize: ProfileResponsiveHelper.textSize(context, 16),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...familyState.pengajuanOrangTua.map(
              (pengajuan) => Container(
                margin: EdgeInsets.only(
                  bottom: ProfileResponsiveHelper.px(context, 12),
                ),
                child: _buildPengajuanOrangTuaCard(context, pengajuan),
              ),
            ),

          ProfileResponsiveHelper.verticalGap(context, medium: 24),
        ],
      ),
    );
  }

  // ===== Build Anak Card =====
  Widget _buildAnakCard(BuildContext context, Anak anak) {
    return Builder(
      builder: (context) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: ProfileResponsiveHelper.getCardPadding(context),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: ProfileResponsiveHelper.px(context, 50),
                  height: ProfileResponsiveHelper.px(context, 50),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: anak.avatar != null
                        ? Image.network(
                            anak.avatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              size: ProfileResponsiveHelper.px(context, 28),
                              color: const Color(0xFF1E88E5),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: ProfileResponsiveHelper.px(context, 28),
                            color: const Color(0xFF1E88E5),
                          ),
                  ),
                ),
                ProfileResponsiveHelper.horizontalGap(context),
                // Anak Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anak.name,
                        style: TextStyle(
                          fontSize: ProfileResponsiveHelper.textSize(
                            context,
                            16,
                          ),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: ProfileResponsiveHelper.px(context, 4)),
                      Text(
                        anak.email,
                        style: TextStyle(
                          fontSize: ProfileResponsiveHelper.textSize(
                            context,
                            12,
                          ),
                          color: const Color(0xFF4A5568),
                        ),
                      ),
                      SizedBox(height: ProfileResponsiveHelper.px(context, 6)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ProfileResponsiveHelper.px(context, 8),
                          vertical: ProfileResponsiveHelper.px(context, 4),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Status: Aktif',
                          style: TextStyle(
                            fontSize: ProfileResponsiveHelper.textSize(
                              context,
                              10,
                            ),
                            color: const Color(0xFF1E88E5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: ProfileResponsiveHelper.getIconSize(context),
                    color: const Color(0xFF4A5568),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteAnakConfirmation(context, anak);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(
                            width: ProfileResponsiveHelper.px(context, 8),
                          ),
                          const Text(
                            'Hapus',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== Build Pengajuan Card =====
  Widget _buildPengajuanCard(
    BuildContext context,
    RelasiOrangTuaAnak pengajuan,
  ) {
    return Builder(
      builder: (context) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: ProfileResponsiveHelper.getCardPadding(context),
            child: Row(
              children: [
                // Status Icon
                Container(
                  width: ProfileResponsiveHelper.px(context, 50),
                  height: ProfileResponsiveHelper.px(context, 50),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.hourglass_bottom,
                      size: ProfileResponsiveHelper.px(context, 28),
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                ),
                ProfileResponsiveHelper.horizontalGap(context),
                // Pengajuan Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pengajuan.anak?.email ?? '',
                        style: TextStyle(
                          fontSize: ProfileResponsiveHelper.textSize(
                            context,
                            16,
                          ),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: ProfileResponsiveHelper.px(context, 4)),
                      Text(
                        _getStatusDescription(pengajuan.status),
                        style: TextStyle(
                          fontSize: ProfileResponsiveHelper.textSize(
                            context,
                            12,
                          ),
                          color: const Color(0xFF4A5568),
                        ),
                      ),
                      SizedBox(height: ProfileResponsiveHelper.px(context, 6)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ProfileResponsiveHelper.px(context, 8),
                          vertical: ProfileResponsiveHelper.px(context, 4),
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            pengajuan.status,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Status: ${pengajuan.status}',
                          style: TextStyle(
                            fontSize: ProfileResponsiveHelper.textSize(
                              context,
                              10,
                            ),
                            color: _getStatusColor(pengajuan.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: ProfileResponsiveHelper.getIconSize(context),
                    color: const Color(0xFF4A5568),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeletePengajuanConfirmation(context, pengajuan.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(
                            width: ProfileResponsiveHelper.px(context, 8),
                          ),
                          const Text(
                            'Batalkan',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Tab 1: Orang Tua (Child View)
  Widget _buildOrangTuaCard(BuildContext context, RelasiOrangTuaAnak relasi) {
    final orangTua = relasi.orangTua;
    if (orangTua == null) return const SizedBox.shrink();

    return Builder(
      builder: (context) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: ProfileResponsiveHelper.getCardPadding(context),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: ProfileResponsiveHelper.px(context, 60),
                  height: ProfileResponsiveHelper.px(context, 60),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: orangTua.avatar != null
                        ? Image.network(
                            orangTua.avatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              size: ProfileResponsiveHelper.px(context, 32),
                              color: const Color(0xFF1E88E5),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: ProfileResponsiveHelper.px(context, 32),
                            color: const Color(0xFF1E88E5),
                          ),
                  ),
                ),
                ProfileResponsiveHelper.horizontalGap(context),
                // Orang Tua Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orangTua.name,
                        style: TextStyle(
                          fontSize: ProfileResponsiveHelper.textSize(
                            context,
                            18,
                          ),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: ProfileResponsiveHelper.px(context, 4)),
                      Text(
                        orangTua.email,
                        style: TextStyle(
                          fontSize: ProfileResponsiveHelper.textSize(
                            context,
                            14,
                          ),
                          color: const Color(0xFF4A5568),
                        ),
                      ),
                      SizedBox(height: ProfileResponsiveHelper.px(context, 8)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ProfileResponsiveHelper.px(context, 10),
                          vertical: ProfileResponsiveHelper.px(context, 4),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Status: ${relasi.status}',
                          style: TextStyle(
                            fontSize: ProfileResponsiveHelper.textSize(
                              context,
                              12,
                            ),
                            color: const Color(0xFF1E88E5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Tab 2: Pengajuan Orang Tua (Child View)
  Widget _buildPengajuanOrangTuaCard(
    BuildContext context,
    RelasiOrangTuaAnak pengajuan,
  ) {
    final orangTua = pengajuan.orangTua;
    if (orangTua == null) return const SizedBox.shrink();

    return Builder(
      builder: (context) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: ProfileResponsiveHelper.getCardPadding(context),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: ProfileResponsiveHelper.px(context, 50),
                      height: ProfileResponsiveHelper.px(context, 50),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.family_restroom,
                          size: ProfileResponsiveHelper.px(context, 28),
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                    ),
                    ProfileResponsiveHelper.horizontalGap(context),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orangTua.name,
                            style: TextStyle(
                              fontSize: ProfileResponsiveHelper.textSize(
                                context,
                                16,
                              ),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                          SizedBox(
                            height: ProfileResponsiveHelper.px(context, 4),
                          ),
                          Text(
                            orangTua.email,
                            style: TextStyle(
                              fontSize: ProfileResponsiveHelper.textSize(
                                context,
                                12,
                              ),
                              color: const Color(0xFF4A5568),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ProfileResponsiveHelper.px(context, 16)),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ProfileResponsiveHelper.px(context, 12),
                    vertical: ProfileResponsiveHelper.px(context, 6),
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      pengajuan.status,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Status: ${pengajuan.status}',
                    style: TextStyle(
                      fontSize: ProfileResponsiveHelper.textSize(context, 12),
                      color: _getStatusColor(pengajuan.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (pengajuan.status.toLowerCase() == 'pending')
                  Padding(
                    padding: EdgeInsets.only(
                      top: ProfileResponsiveHelper.px(context, 16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _showRejectConfirmation(context, pengajuan);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: ProfileResponsiveHelper.px(
                                  context,
                                  12,
                                ),
                              ),
                            ),
                            child: Text(
                              'Tolak',
                              style: TextStyle(
                                fontSize: ProfileResponsiveHelper.textSize(
                                  context,
                                  14,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: ProfileResponsiveHelper.px(context, 12),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _showApproveConfirmation(context, pengajuan);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: ProfileResponsiveHelper.px(
                                  context,
                                  12,
                                ),
                              ),
                            ),
                            child: Text(
                              'Setujui',
                              style: TextStyle(
                                fontSize: ProfileResponsiveHelper.textSize(
                                  context,
                                  14,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== Show Pengajuan Dialog =====
  void _showPengajuanDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Builder(
          builder: (context) => Text(
            'Ajukan Anak',
            style: TextStyle(
              fontSize: ProfileResponsiveHelper.textSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Builder(
          builder: (context) => SizedBox(
            width: ProfileResponsiveHelper.getContentMaxWidth(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Masukkan email anak yang ingin diajukan',
                  style: TextStyle(
                    fontSize: ProfileResponsiveHelper.textSize(context, 14),
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: ProfileResponsiveHelper.px(context, 16)),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    fontSize: ProfileResponsiveHelper.textSize(context, 14),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email Anak',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email_outlined),
                    labelStyle: TextStyle(
                      fontSize: ProfileResponsiveHelper.textSize(context, 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Builder(
              builder: (context) => Text(
                'Batal',
                style: TextStyle(
                  fontSize: ProfileResponsiveHelper.textSize(context, 14),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                ref
                    .read(familyProvider.notifier)
                    .pengajuanAnak(emailAnak: emailController.text.trim());
                Navigator.pop(context);
              }
            },
            child: Builder(
              builder: (context) => Text(
                'Ajukan',
                style: TextStyle(
                  fontSize: ProfileResponsiveHelper.textSize(context, 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Delete Anak Confirmation =====
  void _showDeleteAnakConfirmation(BuildContext context, Anak anak) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Builder(
          builder: (context) => Text(
            'Hapus Anak',
            style: TextStyle(
              fontSize: ProfileResponsiveHelper.textSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Builder(
          builder: (context) => Text(
            'Apakah Anda yakin ingin menghapus ${anak.name}?',
            style: TextStyle(
              fontSize: ProfileResponsiveHelper.textSize(context, 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Builder(
              builder: (context) => Text(
                'Batal',
                style: TextStyle(
                  fontSize: ProfileResponsiveHelper.textSize(context, 14),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(familyProvider.notifier).deleteAnak(relasiId: anak.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Builder(
              builder: (context) => Text(
                'Hapus',
                style: TextStyle(
                  fontSize: ProfileResponsiveHelper.textSize(context, 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Delete Pengajuan Confirmation =====
  void _showDeletePengajuanConfirmation(BuildContext context, int pengajuanId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Builder(
          builder: (context) => Text(
            'Batalkan Pengajuan',
            style: TextStyle(
              fontSize: ProfileResponsiveHelper.textSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Builder(
          builder: (context) => Text(
            'Apakah Anda yakin ingin membatalkan pengajuan ini?',
            style: TextStyle(
              fontSize: ProfileResponsiveHelper.textSize(context, 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Builder(
              builder: (context) => Text(
                'Batal',
                style: TextStyle(
                  fontSize: ProfileResponsiveHelper.textSize(context, 14),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(familyProvider.notifier)
                  .deletePengajuanAnak(pengajuanId: pengajuanId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Builder(
              builder: (context) => Text(
                'Batalkan',
                style: TextStyle(
                  fontSize: ProfileResponsiveHelper.textSize(context, 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Helper method to get status color =====
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800); // Orange
      case 'aktif':
      case 'active':
        return const Color(0xFF4CAF50); // Green
      case 'ditolak':
      case 'tidak_aktif':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ===== Helper method to get status description =====
  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu penerimaan';
      case 'aktif':
      case 'active':
        return 'Sudah disetujui';
      case 'ditolak':
      case 'tidak_aktif':
        return 'Ditolak';
      default:
        return 'Status tidak diketahui';
    }
  }

  // ===== Approve Confirmation =====
  void _showApproveConfirmation(
    BuildContext context,
    RelasiOrangTuaAnak pengajuan,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Builder(
          builder: (context) => Text(
            'Setujui Permintaan',
            style: TextStyle(
              fontSize: ProfileResponsiveHelper.textSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Builder(
          builder: (context) => Text(
            'Apakah Anda yakin ingin menyetujui permintaan dari ${pengajuan.orangTua?.name}?',
            style: TextStyle(
              fontSize: ProfileResponsiveHelper.textSize(context, 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Builder(
              builder: (context) => Text(
                'Batal',
                style: TextStyle(
                  fontSize: ProfileResponsiveHelper.textSize(context, 14),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(familyProvider.notifier)
                  .persetujuanAnak(
                    pengajuanId: pengajuan.id,
                    persetujuan: true,
                  );
              Navigator.pop(context);
            },
            child: Builder(
              builder: (context) => Text(
                'Setujui',
                style: TextStyle(
                  fontSize: ProfileResponsiveHelper.textSize(context, 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Reject Confirmation =====
  void _showRejectConfirmation(
    BuildContext context,
    RelasiOrangTuaAnak pengajuan,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Builder(
          builder: (context) => Text(
            'Tolak Permintaan',
            style: TextStyle(
              fontSize: ProfileResponsiveHelper.textSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Builder(
          builder: (context) => Text(
            'Apakah Anda yakin ingin menolak permintaan dari ${pengajuan.orangTua?.name}?',
            style: TextStyle(
              fontSize: ProfileResponsiveHelper.textSize(context, 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Builder(
              builder: (context) => Text(
                'Batal',
                style: TextStyle(
                  fontSize: ProfileResponsiveHelper.textSize(context, 14),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(familyProvider.notifier)
                  .persetujuanAnak(
                    pengajuanId: pengajuan.id,
                    persetujuan: false,
                  );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Builder(
              builder: (context) => Text(
                'Tolak',
                style: TextStyle(
                  fontSize: ProfileResponsiveHelper.textSize(context, 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
