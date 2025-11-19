import 'package:flutter/material.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:test_flutter/features/profile/helpers/profile_responsive_helper.dart';

class FamilyMember {
  final String id;
  final String name;
  final int age;
  final String role;
  final String avatar;
  final bool isActive;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.age,
    required this.role,
    required this.avatar,
    this.isActive = true,
  });
}

class ManageFamilyPage extends StatefulWidget {
  const ManageFamilyPage({super.key});

  @override
  State<ManageFamilyPage> createState() => _ManageFamilyPageState();
}

class _ManageFamilyPageState extends State<ManageFamilyPage> {
  List<FamilyMember> familyMembers = [
    const FamilyMember(
      id: '1',
      name: 'Ahmad Fauzan',
      age: 35,
      role: 'Ayah',
      avatar: '👨‍💼',
    ),
    const FamilyMember(
      id: '2',
      name: 'Siti Aminah',
      age: 32,
      role: 'Ibu',
      avatar: '👩‍💼',
    ),
    const FamilyMember(
      id: '3',
      name: 'Ahmad',
      age: 15,
      role: 'Anak',
      avatar: '👦',
    ),
    const FamilyMember(
      id: '4',
      name: 'Fatimah',
      age: 12,
      role: 'Anak',
      avatar: '👧',
    ),
    const FamilyMember(
      id: '5',
      name: 'Ali',
      age: 8,
      role: 'Anak',
      avatar: '👶',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E88E5).withValues(alpha: 0.1),
              const Color(0xFF26A69A).withValues(alpha: 0.05),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ===== Header dengan Gradient =====
              Container(
                padding: ProfileResponsiveHelper.getHeaderPadding(context),
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
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: ProfileResponsiveHelper.getIconSize(
                            context,
                            small: 20,
                            medium: 22,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Kelola Keluarga',
                          style: TextStyle(
                            fontSize: ProfileResponsiveHelper.textSize(
                              context,
                              20,
                            ),
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
                        onTap: () => _showAddMemberDialog(context),
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: ProfileResponsiveHelper.getIconSize(
                            context,
                            small: 20,
                            medium: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== Content =====
              Expanded(
                child: SingleChildScrollView(
                  padding: ProfileResponsiveHelper.getPageHorizontalPadding(
                    context,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileResponsiveHelper.verticalGap(context, medium: 32),
                      // Header Info
                      Container(
                        width: double.infinity,
                        padding: ProfileResponsiveHelper.getCardPadding(
                          context,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E88E5), Color(0xFF26A69A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.family_restroom,
                                  color: Colors.white,
                                  size: ProfileResponsiveHelper.px(context, 32),
                                ),
                                ProfileResponsiveHelper.horizontalGap(context),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Anggota Keluarga',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize:
                                              ProfileResponsiveHelper.textSize(
                                                context,
                                                14,
                                              ),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${familyMembers.length} Orang',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              ProfileResponsiveHelper.textSize(
                                                context,
                                                20,
                                              ),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            ProfileResponsiveHelper.verticalGap(
                              context,
                              medium: 16,
                            ),
                            Text(
                              'Kelola anggota keluarga untuk monitoring ibadah yang lebih baik',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: ProfileResponsiveHelper.textSize(
                                  context,
                                  13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      ProfileResponsiveHelper.verticalGap(context, medium: 24),

                      // Anggota Keluarga Section
                      Text(
                        'Anggota Keluarga',
                        style: TextStyle(
                          fontSize: ProfileResponsiveHelper.textSize(
                            context,
                            18,
                          ),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      ProfileResponsiveHelper.verticalGap(context, medium: 16),

                      // Family Members Cards
                      ...familyMembers.map(
                        (member) => Container(
                          constraints: BoxConstraints(
                            maxWidth:
                                ProfileResponsiveHelper.getContentMaxWidth(
                                  context,
                                ),
                          ),
                          margin: EdgeInsets.only(
                            bottom: ProfileResponsiveHelper.px(context, 12),
                          ),
                          child: _buildMemberCard(member),
                        ),
                      ),

                      ProfileResponsiveHelper.verticalGap(context, medium: 24),

                      // Add Member Button
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: ProfileResponsiveHelper.getContentMaxWidth(
                            context,
                          ),
                        ),
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddMemberDialog(context),
                          icon: Icon(
                            Icons.person_add,
                            size: ProfileResponsiveHelper.getIconSize(
                              context,
                              small: 20,
                              medium: 24,
                            ),
                          ),
                          label: Text(
                            'Tambah Anggota Keluarga',
                            style: TextStyle(
                              fontSize: ProfileResponsiveHelper.textSize(
                                context,
                                16,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E88E5),
                            side: const BorderSide(
                              color: Color(0xFF1E88E5),
                              width: 2,
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: ProfileResponsiveHelper.px(context, 12),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      ProfileResponsiveHelper.verticalGap(context, medium: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(FamilyMember member) {
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
                    color: _getRoleColor(member.role).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      member.avatar,
                      style: TextStyle(
                        fontSize: ProfileResponsiveHelper.textSize(context, 24),
                      ),
                    ),
                  ),
                ),

                ProfileResponsiveHelper.horizontalGap(context),

                // Member Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
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
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ProfileResponsiveHelper.px(
                                context,
                                8,
                              ),
                              vertical: ProfileResponsiveHelper.px(context, 4),
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(member.role),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              member.role,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ProfileResponsiveHelper.textSize(
                                  context,
                                  10,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: ProfileResponsiveHelper.px(context, 8),
                          ),
                          Text(
                            '${member.age} tahun',
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
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: ProfileResponsiveHelper.getIconSize(
                      context,
                      small: 20,
                      medium: 24,
                    ),
                    color: const Color(0xFF4A5568),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditMemberDialog(context, member);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(context, member);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    if (member.role != 'Ayah' && member.role != 'Ibu')
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Ayah':
        return const Color(0xFF1E88E5);
      case 'Ibu':
        return const Color(0xFF26A69A);
      case 'Anak':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  void _showAddMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    String selectedRole = 'Anak';
    String selectedAvatar = '👶';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Builder(
            builder: (context) => Text(
              'Tambah Anggota Keluarga',
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
                  // Avatar Selection
                  Text(
                    'Pilih Avatar:',
                    style: TextStyle(
                      fontSize: ProfileResponsiveHelper.textSize(context, 14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ProfileResponsiveHelper.px(context, 8)),
                  Wrap(
                    spacing: ProfileResponsiveHelper.px(context, 8),
                    children: ['👦', '👧', '👶', '🧒', '👨', '👩'].map((
                      avatar,
                    ) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedAvatar = avatar;
                          });
                        },
                        child: Container(
                          width: ProfileResponsiveHelper.px(context, 40),
                          height: ProfileResponsiveHelper.px(context, 40),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedAvatar == avatar
                                  ? const Color(0xFF1E88E5)
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              avatar,
                              style: TextStyle(
                                fontSize: ProfileResponsiveHelper.textSize(
                                  context,
                                  20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: ProfileResponsiveHelper.px(context, 16)),

                  // Name Field
                  TextField(
                    controller: nameController,
                    style: TextStyle(
                      fontSize: ProfileResponsiveHelper.textSize(context, 14),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person_outline),
                      labelStyle: TextStyle(
                        fontSize: ProfileResponsiveHelper.textSize(context, 14),
                      ),
                    ),
                  ),

                  SizedBox(height: ProfileResponsiveHelper.px(context, 12)),

                  // Age Field
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: ProfileResponsiveHelper.textSize(context, 14),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Usia',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.cake_outlined),
                      labelStyle: TextStyle(
                        fontSize: ProfileResponsiveHelper.textSize(context, 14),
                      ),
                    ),
                  ),

                  SizedBox(height: ProfileResponsiveHelper.px(context, 12)),

                  // Role Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    style: TextStyle(
                      fontSize: ProfileResponsiveHelper.textSize(context, 14),
                      color: const Color(0xFF2D3748),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Peran',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.family_restroom),
                      labelStyle: TextStyle(
                        fontSize: ProfileResponsiveHelper.textSize(context, 14),
                      ),
                    ),
                    items: ['Anak', 'Ayah', 'Ibu', 'Kakek', 'Nenek'].map((
                      role,
                    ) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
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
                if (nameController.text.isNotEmpty &&
                    ageController.text.isNotEmpty) {
                  final newMember = FamilyMember(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    age: int.parse(ageController.text),
                    role: selectedRole,
                    avatar: selectedAvatar,
                  );

                  this.setState(() {
                    familyMembers.add(newMember);
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${nameController.text} berhasil ditambahkan!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Builder(
                builder: (context) => Text(
                  'Tambah',
                  style: TextStyle(
                    fontSize: ProfileResponsiveHelper.textSize(context, 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMemberDialog(BuildContext context, FamilyMember member) {
    final nameController = TextEditingController(text: member.name);
    final ageController = TextEditingController(text: member.age.toString());
    String selectedRole = member.role;
    String selectedAvatar = member.avatar;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Builder(
            builder: (context) => Text(
              'Edit Anggota Keluarga',
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
                  // Avatar Selection
                  Text(
                    'Pilih Avatar:',
                    style: TextStyle(
                      fontSize: ProfileResponsiveHelper.textSize(context, 14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ProfileResponsiveHelper.px(context, 8)),
                  Wrap(
                    spacing: ProfileResponsiveHelper.px(context, 8),
                    children: ['👦', '👧', '👶', '🧒', '👨', '👩'].map((
                      avatar,
                    ) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedAvatar = avatar;
                          });
                        },
                        child: Container(
                          width: ProfileResponsiveHelper.px(context, 40),
                          height: ProfileResponsiveHelper.px(context, 40),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedAvatar == avatar
                                  ? const Color(0xFF1E88E5)
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              avatar,
                              style: TextStyle(
                                fontSize: ProfileResponsiveHelper.textSize(
                                  context,
                                  20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: ProfileResponsiveHelper.px(context, 16)),

                  // Name Field
                  TextField(
                    controller: nameController,
                    style: TextStyle(
                      fontSize: ProfileResponsiveHelper.textSize(context, 14),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person_outline),
                      labelStyle: TextStyle(
                        fontSize: ProfileResponsiveHelper.textSize(context, 14),
                      ),
                    ),
                  ),

                  SizedBox(height: ProfileResponsiveHelper.px(context, 12)),

                  // Age Field
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: ProfileResponsiveHelper.textSize(context, 14),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Usia',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.cake_outlined),
                      labelStyle: TextStyle(
                        fontSize: ProfileResponsiveHelper.textSize(context, 14),
                      ),
                    ),
                  ),

                  SizedBox(height: ProfileResponsiveHelper.px(context, 12)),

                  // Role Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    style: TextStyle(
                      fontSize: ProfileResponsiveHelper.textSize(context, 14),
                      color: const Color(0xFF2D3748),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Peran',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.family_restroom),
                      labelStyle: TextStyle(
                        fontSize: ProfileResponsiveHelper.textSize(context, 14),
                      ),
                    ),
                    items: ['Anak', 'Ayah', 'Ibu', 'Kakek', 'Nenek'].map((
                      role,
                    ) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
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
                if (nameController.text.isNotEmpty &&
                    ageController.text.isNotEmpty) {
                  final updatedMember = FamilyMember(
                    id: member.id,
                    name: nameController.text,
                    age: int.parse(ageController.text),
                    role: selectedRole,
                    avatar: selectedAvatar,
                  );

                  this.setState(() {
                    final index = familyMembers.indexWhere(
                      (m) => m.id == member.id,
                    );
                    if (index != -1) {
                      familyMembers[index] = updatedMember;
                    }
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data anggota berhasil diperbarui!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Builder(
                builder: (context) => Text(
                  'Simpan',
                  style: TextStyle(
                    fontSize: ProfileResponsiveHelper.textSize(context, 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Builder(
          builder: (context) => Text(
            'Hapus Anggota',
            style: TextStyle(
              fontSize: ProfileResponsiveHelper.textSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Builder(
          builder: (context) => Text(
            'Apakah Anda yakin ingin menghapus ${member.name} dari keluarga?',
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
              setState(() {
                familyMembers.removeWhere((m) => m.id == member.id);
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${member.name} berhasil dihapus dari keluarga',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
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
}
