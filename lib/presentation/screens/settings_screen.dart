import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
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
          const SnackBar(content: Text('Username berhasil diupdate!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Hapus Akun?', style: TextStyle(color: Colors.white)),
        content: const Text('Semua data akan dihapus permanen.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
            colors: [Color(0xFF0D1B2A), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconButton(onPressed: () => context.go('/home'), icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
                  const Text('Pengaturan', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 32),

                // Update Username
                const Text('Update Username', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Username baru',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.person, color: Colors.greenAccent),
                  ),
                ),
                const SizedBox(height: 12),
                SdgButton(text: 'Simpan', icon: Icons.save, onPressed: _updateUsername, isLoading: _isLoading),
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
                              const SnackBar(content: Text('High score direset (dev only)')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Sign Out
                SdgButton(text: 'Keluar', icon: Icons.logout, style: SdgButtonStyle.secondary, onPressed: _signOut),
                const SizedBox(height: 16),

                // Delete Account
                SdgButton(text: 'Hapus Akun', icon: Icons.delete_forever, style: SdgButtonStyle.danger, onPressed: _deleteAccount),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
