import 'package:flutter/material.dart';
import 'package:test_flutter/app/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddEditChildPage extends StatefulWidget {
  final Map<String, dynamic>? childData;

  const AddEditChildPage({super.key, this.childData});

  @override
  State<AddEditChildPage> createState() => _AddEditChildPageState();
}

class _AddEditChildPageState extends State<AddEditChildPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _ageController;
  File? _avatarFile;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();

  bool get isEdit => widget.childData != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.childData?['name'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.childData?['email'] ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.childData?['password'] ?? '',
    );
    _ageController = TextEditingController(
      text: widget.childData?['age']?.toString() ?? '',
    );
    _avatarUrl = widget.childData?['avatar'];
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();

        // Check file size (max 2MB)
        if (fileSize > 2 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ukuran file maksimal 2 MB'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        setState(() {
          _avatarFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _saveChild() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save to backend/database
      // For now, just return success
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(
                isEdit
                    ? 'Data anak berhasil diperbarui'
                    : 'Anak berhasil ditambahkan',
              ),
            ],
          ),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final isDesktop = size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.onSurface),
        ),
        title: Text(
          isEdit ? 'Edit Data Anak' : 'Tambah Anak',
          style: TextStyle(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 22 : 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isDesktop
              ? 32
              : isTablet
              ? 28
              : 24,
        ),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 600 : double.infinity,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.accentGreen],
                      ),
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isTablet ? 16 : 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              isTablet ? 14 : 12,
                            ),
                          ),
                          child: Icon(
                            isEdit
                                ? Icons.edit_rounded
                                : Icons.person_add_rounded,
                            color: Colors.white,
                            size: isTablet ? 32 : 28,
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'Edit Data Anak' : 'Tambah Anak Baru',
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                isEdit
                                    ? 'Perbarui informasi data anak'
                                    : 'Lengkapi form berikut untuk menambah anak',
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 13,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isTablet ? 32 : 24),

                  // Form Fields
                  Container(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama
                        _buildLabel('Nama Lengkap', isTablet),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: _buildInputDecoration(
                            'Masukkan nama lengkap',
                            Icons.person_outline_rounded,
                            isTablet,
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama harus diisi';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isTablet ? 20 : 16),

                        // Email
                        _buildLabel('Email', isTablet),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          decoration: _buildInputDecoration(
                            'Masukkan alamat email',
                            Icons.email_outlined,
                            isTablet,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email harus diisi';
                            }
                            if (!value.contains('@')) {
                              return 'Email tidak valid';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isTablet ? 20 : 16),

                        // Password (only for new child)
                        if (!isEdit) ...[
                          _buildLabel('Password', isTablet),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            decoration: _buildInputDecoration(
                              'Masukkan password',
                              Icons.lock_outline_rounded,
                              isTablet,
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password harus diisi';
                              }
                              if (value.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isTablet ? 20 : 16),
                        ],

                        // Avatar Upload
                        _buildLabel('Foto Profil (opsional)', isTablet),
                        SizedBox(height: 8),
                        InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(
                            isTablet ? 12 : 10,
                          ),
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(
                                isTablet ? 12 : 10,
                              ),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Preview Image
                                Container(
                                  width: isTablet ? 80 : 70,
                                  height: isTablet ? 80 : 70,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(
                                      isTablet ? 10 : 8,
                                    ),
                                    image: _avatarFile != null
                                        ? DecorationImage(
                                            image: FileImage(_avatarFile!),
                                            fit: BoxFit.cover,
                                          )
                                        : _avatarUrl != null &&
                                              _avatarUrl!.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(_avatarUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child:
                                      (_avatarFile == null &&
                                          (_avatarUrl == null ||
                                              _avatarUrl!.isEmpty))
                                      ? Icon(
                                          Icons.person_outline_rounded,
                                          size: isTablet ? 36 : 32,
                                          color: Colors.grey.shade400,
                                        )
                                      : null,
                                ),
                                SizedBox(width: isTablet ? 16 : 14),
                                // Upload Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.cloud_upload_rounded,
                                            color: AppTheme.primaryBlue,
                                            size: isTablet ? 22 : 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            _avatarFile != null
                                                ? 'Foto dipilih'
                                                : 'Pilih Foto',
                                            style: TextStyle(
                                              fontSize: isTablet ? 16 : 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Ukuran: 512x512 px',
                                        style: TextStyle(
                                          fontSize: isTablet ? 13 : 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Maksimal: 2 MB',
                                        style: TextStyle(
                                          fontSize: isTablet ? 13 : 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (_avatarFile != null) ...[
                                        SizedBox(height: 6),
                                        Text(
                                          _avatarFile!.path.split('/').last,
                                          style: TextStyle(
                                            fontSize: isTablet ? 12 : 11,
                                            color: AppTheme.accentGreen,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Clear button if image selected
                                if (_avatarFile != null ||
                                    (_avatarUrl != null &&
                                        _avatarUrl!.isNotEmpty))
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _avatarFile = null;
                                        _avatarUrl = null;
                                      });
                                    },
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: Colors.red,
                                      size: isTablet ? 22 : 20,
                                    ),
                                    tooltip: 'Hapus foto',
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isTablet ? 20 : 16),

                        // Usia
                        _buildLabel('Usia (tahun)', isTablet),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _ageController,
                          decoration: _buildInputDecoration(
                            'Masukkan usia',
                            Icons.cake_rounded,
                            isTablet,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Usia harus diisi';
                            }
                            final age = int.tryParse(value);
                            if (age == null || age <= 0) {
                              return 'Usia tidak valid';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isTablet ? 32 : 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveChild,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 18 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isTablet ? 14 : 12,
                          ),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: isTablet ? 24 : 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            isEdit ? 'Simpan Perubahan' : 'Tambah Anak',
                            style: TextStyle(
                              fontSize: isTablet ? 17 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

  Widget _buildLabel(String text, bool isTablet) {
    return Text(
      text,
      style: TextStyle(
        fontSize: isTablet ? 15 : 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.onSurface,
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String hint,
    IconData icon,
    bool isTablet,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: isTablet ? 22 : 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 14,
        vertical: isTablet ? 16 : 14,
      ),
    );
  }
}
