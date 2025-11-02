import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_flutter/core/widgets/toast.dart';
import 'package:test_flutter/features/profile/profile_provider.dart';
import 'package:test_flutter/features/profile/profile_state.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    // Load profile data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = ref.read(profileProvider);
      final profile = profileState.profile;

      if (profile != null) {
        _nameController.text = profile['name'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();

      await ref
          .read(profileProvider.notifier)
          .updateProfile(
            name: name,
            email: email,
            phone: phone.isNotEmpty ? phone : null,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Watch profile state
    final profileState = ref.watch(profileProvider);
    final isLoading = profileState.status == ProfileStatus.loading;

    // Listen to state changes for showing messages
    ref.listen<ProfileState>(profileProvider, (previous, next) {
      if (next.status == ProfileStatus.success && next.message != null) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.success,
          duration: const Duration(seconds: 3),
        );
        ref.read(profileProvider.notifier).clearMessage();
        ref.read(profileProvider.notifier).resetStatus();

        // Navigate back with success result
        Navigator.pushReplacementNamed(context, '/profile');
      } else if (next.status == ProfileStatus.error && next.message != null) {
        showMessageToast(
          context,
          message: next.message!,
          type: ToastType.error,
          duration: const Duration(seconds: 4),
        );
        ref.read(profileProvider.notifier).clearMessage();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isLoading
              ? null
              : () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/profile',
                  (route) => false,
                ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 32.0 : 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Avatar Section (Commented out for future use)
                // Center(
                //   child: Stack(
                //     children: [
                //       Container(
                //         width: isTablet ? 120 : 100,
                //         height: isTablet ? 120 : 100,
                //         decoration: const BoxDecoration(
                //           shape: BoxShape.circle,
                //           gradient: LinearGradient(
                //             colors: [Color(0xFF1E88E5), Color(0xFF26A69A)],
                //             begin: Alignment.topLeft,
                //             end: Alignment.bottomRight,
                //           ),
                //         ),
                //         child: Icon(
                //           Icons.person,
                //           size: isTablet ? 60 : 50,
                //           color: Colors.white,
                //         ),
                //       ),
                //       Positioned(
                //         bottom: 0,
                //         right: 0,
                //         child: Container(
                //           width: isTablet ? 40 : 32,
                //           height: isTablet ? 40 : 32,
                //           decoration: BoxDecoration(
                //             color: const Color(0xFF1E88E5),
                //             shape: BoxShape.circle,
                //             border: Border.all(color: Colors.white, width: 2),
                //           ),
                //           child: Icon(
                //             Icons.camera_alt,
                //             size: isTablet ? 20 : 16,
                //             color: Colors.white,
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                // SizedBox(height: isTablet ? 32 : 24),

                // Info Section
                Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF1E88E5),
                        size: isTablet ? 24 : 20,
                      ),
                      SizedBox(width: isTablet ? 12 : 10),
                      Expanded(
                        child: Text(
                          'Perubahan akan disimpan ke server dan disinkronkan',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: const Color(0xFF1E88E5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 28 : 24),

                // Form Fields
                _buildTextField(
                  controller: _nameController,
                  label: 'Nama Lengkap',
                  icon: Icons.person_outline,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    if (value.length < 3) {
                      return 'Nama minimal 3 karakter';
                    }
                    return null;
                  },
                  isTablet: isTablet,
                ),

                SizedBox(height: isTablet ? 20 : 16),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Email tidak valid';
                    }
                    return null;
                  },
                  isTablet: isTablet,
                ),

                // SizedBox(height: isTablet ? 20 : 16),

                // _buildTextField(
                //   controller: _phoneController,
                //   label: 'Nomor Telepon (Opsional)',
                //   icon: Icons.phone_outlined,
                //   keyboardType: TextInputType.phone,
                //   enabled: !isLoading,
                //   validator: (value) {
                //     if (value != null && value.isNotEmpty) {
                //       if (value.length < 10) {
                //         return 'Nomor telepon minimal 10 digit';
                //       }
                //       if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                //         return 'Nomor telepon hanya boleh berisi angka';
                //       }
                //     }
                //     return null;
                //   },
                //   isTablet: isTablet,
                // ),

                SizedBox(height: isTablet ? 40 : 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: isTablet ? 56 : 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[500],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isLoading ? 0 : 2,
                    ),
                    child: isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: isTablet ? 20 : 18,
                                height: isTablet ? 20 : 18,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: isTablet ? 12 : 10),
                              Text(
                                'Menyimpan...',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save_outlined,
                                size: isTablet ? 22 : 20,
                              ),
                              SizedBox(width: isTablet ? 10 : 8),
                              Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                SizedBox(height: isTablet ? 20 : 16),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: isTablet ? 56 : 48,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E88E5),
                      side: BorderSide(
                        color: isLoading
                            ? Colors.grey[300]!
                            : const Color(0xFF1E88E5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    required bool isTablet,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      enabled: enabled,
      style: TextStyle(
        fontSize: isTablet ? 18 : 16,
        color: enabled ? const Color(0xFF2D3748) : Colors.grey[600],
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? const Color(0xFF1E88E5) : Colors.grey[400],
          size: isTablet ? 24 : 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 20 : 16,
        ),
        labelStyle: TextStyle(
          color: enabled ? const Color(0xFF4A5568) : Colors.grey[500],
          fontSize: isTablet ? 16 : 14,
        ),
      ),
    );
  }
}
