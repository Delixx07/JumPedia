import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../widgets/sdg_button.dart';

/// Settings Screen — Update profil, delete account, dev-only reset.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _updateUsername() async {
    final uid = ref.read(currentUserUidProvider);
    if (uid == null || _usernameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final userService = UserService();
      // CRUD: UPDATE
      await userService.updateUsername(uid, _usernameController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgMid,
        title: const Text('Delete Account?', style: TextStyle(color: AppColors.textHi)),
        content: const Text('All your data will be permanently deleted.', style: TextStyle(color: AppColors.textLo)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.deleteAccount();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [AppColors.bgTop, AppColors.bgMid],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconButton(onPressed: () => context.go('/home'), icon: const Icon(Icons.arrow_back_ios, color: AppColors.textHi)),
                  const Text('Settings', style: TextStyle(color: AppColors.textHi, fontSize: 24, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 32),

                // Update Username
                const Text('Update Username', style: TextStyle(color: AppColors.textHi, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: AppColors.textHi),
                  decoration: InputDecoration(
                    hintText: 'New username',
                    hintStyle: const TextStyle(color: AppColors.textLo),
                    filled: true,
                    fillColor: AppColors.bgMid,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                SdgButton(text: 'Save', icon: Icons.save, onPressed: _updateUsername, isLoading: _isLoading),
                const SizedBox(height: 32),

                // Dev-only: Reset High Score
                if (AppConfig.isDev) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.bug_report, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('Developer Tools', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 12),
                        SdgButton(
                          text: 'Reset High Score',
                          icon: Icons.restore,
                          style: SdgButtonStyle.danger,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('High score reset (dev only)')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Sign Out
                SdgButton(text: 'Sign Out', icon: Icons.logout, style: SdgButtonStyle.secondary, onPressed: _signOut),
                const SizedBox(height: 16),

                // Delete Account
                SdgButton(text: 'Delete Account', icon: Icons.delete_forever, style: SdgButtonStyle.danger, onPressed: _deleteAccount),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
