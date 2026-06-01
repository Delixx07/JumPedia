import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../widgets/sdg_button.dart';

/// ═══════════════════════════════════════
/// PROFILE SCREEN — JumPedia
/// ═══════════════════════════════════════
/// Menampilkan detail profil, statistik, dan preferensi notifikasi.
/// User bisa mengupdate username dan memilih avatar dari assets.

final _userProfileProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final uid = ref.watch(currentUserUidProvider);
  if (uid == null) return Stream.value(null);
  return UserService().streamUser(uid);
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _usernameController = TextEditingController();
  bool _isSaving = false;
  String? _selectedAvatar;

  final List<String> _availableAvatars = [
    'panda.png',
    'cat.png',
    'hedgehog.png',
    'hen.png',
    'lion.png',
    'owl.png',
    'penguin.png',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(String uid) async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final userService = UserService();
      
      // Update username jika berubah
      await userService.updateUsername(uid, newUsername);
      
      // Update avatar jika berubah
      if (_selectedAvatar != null) {
        await userService.updateAvatarPath(uid, _selectedAvatar!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(_userProfileProvider);
    final authUser = FirebaseAuth.instance.currentUser;
    final isAnonymous = authUser?.isAnonymous ?? true;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgTop, AppColors.bgMid],
          ),
        ),
        child: SafeArea(
          child: userAsync.when(
            data: (user) {
              // Jika user tidak ada di database ATAU user adalah Guest (Anonymous)
              if (user == null || isAnonymous) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_circle_outlined, size: 80, color: AppColors.primary),
                        const SizedBox(height: 16),
                        const Text(
                          'Fitur Khusus Akun Google',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textHi, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Simpan progres bermain dan kustomisasi profil Anda dengan masuk menggunakan Google.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textLo),
                        ),
                        const SizedBox(height: 32),
                        SdgButton(
                          text: 'Login with Google Sekarang',
                          icon: Icons.login,
                          onPressed: () => context.go('/login'),
                        ),
                        const SizedBox(height: 12),
                        SdgButton(
                          text: 'Kembali ke Beranda',
                          icon: Icons.home,
                          style: SdgButtonStyle.secondary,
                          onPressed: () => context.go('/home'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Set initial value for controller if empty
              if (_usernameController.text.isEmpty && !_isSaving) {
                _usernameController.text = user.username;
              }
              
              final currentAvatar = _selectedAvatar ?? user.avatarPath;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // ─── Header & Back ────────────────
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textHi),
                        ),
                        const Expanded(
                          child: Text(
                            'My Profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textHi,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Spacer agar teks tengah
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ─── Avatar Selection ─────────────
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.bgMid,
                            backgroundImage: AssetImage('assets/images/avatars/$currentAvatar'),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showAvatarPicker(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ─── User Info Cards ──────────────
                    _buildSectionTitle('Account Info'),
                    const SizedBox(height: 12),
                    
                    // Email (Read-only)
                    _buildInfoTile(
                      label: 'Email Address',
                      value: authUser?.email ?? (authUser?.isAnonymous == true ? 'Guest Account' : 'No Email'),
                      icon: Icons.email_outlined,
                      isReadOnly: true,
                    ),
                    
                    const SizedBox(height: 12),

                    // Username (Editable)
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: AppColors.textHi),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: const TextStyle(color: AppColors.primary),
                        hintText: 'Enter your username',
                        hintStyle: const TextStyle(color: AppColors.textLo),
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.bgMid,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ─── Statistics ───────────────────
                    _buildSectionTitle('Game Statistics'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgMid,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sports_esports, color: AppColors.accent),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Total Games Played',
                              style: TextStyle(color: AppColors.textLo),
                            ),
                          ),
                          Text(
                            '${user.totalGamesPlayed}',
                            style: const TextStyle(
                              color: AppColors.textHi,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ─── Preferences ──────────────────
                    _buildSectionTitle('Preferences'),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text(
                        'Educational Notifications',
                        style: TextStyle(color: AppColors.textHi, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Receive daily SDG 4 fun facts',
                        style: TextStyle(color: AppColors.textLo, fontSize: 12),
                      ),
                      value: user.notificationsEnabled,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        UserService().updateNotificationPreference(user.uid, val);
                      },
                    ),

                    const SizedBox(height: 40),

                    // ─── Save Button ──────────────────
                    SdgButton(
                      text: 'Save Changes',
                      icon: Icons.check_circle_outline,
                      isLoading: _isSaving,
                      onPressed: () => _saveProfile(user.uid),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.danger))),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
    bool isReadOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgMid.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textLo, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textLo, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isReadOnly ? AppColors.textLo : AppColors.textHi,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Your Avatar',
                style: TextStyle(
                  color: AppColors.textHi,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableAvatars.length,
                  itemBuilder: (context, index) {
                    final avatar = _availableAvatars[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedAvatar = avatar);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (_selectedAvatar ?? '') == avatar
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage('assets/images/avatars/$avatar'),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
