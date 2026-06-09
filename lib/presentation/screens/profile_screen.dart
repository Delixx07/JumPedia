import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/i18n/app_strings.dart';
import '../../models/achievement_model.dart';
import '../../models/user_model.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ui_language_provider.dart';
import '../widgets/state_views.dart';
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
          SnackBar(
            content: Text(ref.read(uiStringsProvider).profileUpdated),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ref.read(uiStringsProvider).error}: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(_userProfileProvider);
    final s = ref.watch(uiStringsProvider);
    final authUser = FirebaseAuth.instance.currentUser;
    final isAnonymous = authUser?.isAnonymous ?? true;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
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
                        Text(
                          s.googleOnlyTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textHi, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.googleOnlyDesc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textLo),
                        ),
                        const SizedBox(height: 32),
                        SdgButton(
                          text: s.loginWithGoogleNow,
                          icon: Icons.login,
                          onPressed: () => context.go('/login'),
                        ),
                        const SizedBox(height: 12),
                        SdgButton(
                          text: s.backToHome,
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
                        Expanded(
                          child: Text(
                            s.myProfile,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                          onTap: () => _showAvatarPicker(context, s.chooseAvatar),
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
                    _buildSectionTitle(s.accountInfo),
                    const SizedBox(height: 12),

                    // Email (Read-only)
                    _buildInfoTile(
                      label: s.emailAddress,
                      value: authUser?.email ?? (authUser?.isAnonymous == true ? s.guestAccount : s.noEmail),
                      icon: Icons.email_outlined,
                      isReadOnly: true,
                    ),
                    
                    const SizedBox(height: 12),

                    // Username (Editable)
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: AppColors.textHi),
                      decoration: InputDecoration(
                        labelText: s.username,
                        labelStyle: const TextStyle(color: AppColors.primary),
                        hintText: s.enterUsername,
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
                    _buildSectionTitle(s.gameStatistics),
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
                          Expanded(
                            child: Text(
                              s.totalGamesPlayed,
                              style: const TextStyle(color: AppColors.textLo),
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

                    // ─── Achievements / Lencana ───────
                    _buildSectionTitle(s.myAchievements),
                    const SizedBox(height: 12),
                    _AchievementsSection(s: s),

                    const SizedBox(height: 32),

                    // ─── Preferences ──────────────────
                    _buildSectionTitle(s.preferences),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text(
                        s.eduNotifications,
                        style: const TextStyle(color: AppColors.textHi, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        s.eduNotificationsDesc,
                        style: const TextStyle(color: AppColors.textLo, fontSize: 12),
                      ),
                      value: user.notificationsEnabled,
                      activeThumbColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        UserService().updateNotificationPreference(user.uid, val);
                      },
                    ),

                    const SizedBox(height: 40),

                    // ─── Save Button ──────────────────
                    SdgButton(
                      text: s.saveChanges,
                      icon: Icons.check_circle_outline,
                      isLoading: _isSaving,
                      onPressed: () => _saveProfile(user.uid),
                    ),
                  ],
                ),
              );
            },
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(message: '${s.error}: $e'),
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

  void _showAvatarPicker(BuildContext context, String title) {
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
              Text(
                title,
                style: const TextStyle(
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

/// Section lencana: grid badge terbuka/terkunci + progress.
/// Status unlock dari Firestore; jumlah fakta dihitung dari koleksi user.
class _AchievementsSection extends ConsumerWidget {
  final AppStrings s;
  const _AchievementsSection({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedAsync = ref.watch(unlockedAchievementsProvider);

    final unlocked = unlockedAsync.maybeWhen(
      data: (set) => set,
      orElse: () => const <String>{},
    );

    final all = AchievementCatalog.all;
    final unlockedCount = all.where((a) => unlocked.contains(a.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.achievementsProgress(unlockedCount, all.length),
          style: const TextStyle(color: AppColors.textLo, fontSize: 12),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: all.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, i) {
            final def = all[i];
            final isUnlocked = unlocked.contains(def.id);
            return _AchievementBadge(
              def: def,
              s: s,
              isUnlocked: isUnlocked,
              onTap: () => _showDetail(context, def, isUnlocked),
            );
          },
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, AchievementDef def, bool isUnlocked) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isUnlocked ? def.color : AppColors.textLo)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked ? def.icon : Icons.lock_rounded,
                size: 40,
                color: isUnlocked ? def.color : AppColors.textLo,
              ),
            ),
            const SizedBox(height: 16),
            Text(def.title(s),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textHi,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(def.description(s),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textLo)),
            if (!isUnlocked) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.textLo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s.achievementLocked,
                    style: const TextStyle(
                        color: AppColors.textLo,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final AchievementDef def;
  final AppStrings s;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _AchievementBadge({
    required this.def,
    required this.s,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked ? def.color : AppColors.textLo;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isUnlocked ? 0.15 : 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: isUnlocked ? 0.6 : 0.25),
                width: 1.5,
              ),
            ),
            child: Icon(
              isUnlocked ? def.icon : Icons.lock_rounded,
              color: isUnlocked ? color : AppColors.textLo.withValues(alpha: 0.6),
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            def.title(s),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? AppColors.textHi : AppColors.textLo,
            ),
          ),
        ],
      ),
    );
  }
}
