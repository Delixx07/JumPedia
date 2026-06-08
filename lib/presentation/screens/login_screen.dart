import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ui_language_provider.dart';

/// ═══════════════════════════════════════
/// LOGIN SCREEN — JumPedia
/// ═══════════════════════════════════════
/// Style minimal & clean light mode:
/// - Background biru muda pastel
/// - Mascot besar di tengah
/// - Heading 2 baris ("Pilih cara / kamu masuk")
/// - Stack tombol: Google (primary biru solid) + Tamu (outline putih)
///
/// Mascot saat ini pakai placeholder. Saat asset gambar tersedia,
/// ganti `_MascotPlaceholder()` dengan `Image.asset('assets/...png')`.

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoadingGoogle = false;
  bool _isLoadingGuest = false;
  String? _errorMessage;

  bool get _anyLoading => _isLoadingGoogle || _isLoadingGuest;

  Future<void> _handleGoogleSignIn() async {
    if (_anyLoading) return;
    setState(() {
      _isLoadingGoogle = true;
      _errorMessage = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      final credential = await authService.signInWithGoogle();
      if (credential != null && mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            ref.read(uiStringsProvider).signInFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
  }

  Future<void> _handleGuestSignIn() async {
    if (_anyLoading) return;
    setState(() {
      _isLoadingGuest = true;
      _errorMessage = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      final credential = await authService.signInAsGuest();
      if (credential != null && mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            ref.read(uiStringsProvider).guestSignInFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isLoadingGuest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(uiStringsProvider);
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // ─── Mascot ─────────────────────
                      // Anchor ke atas agar mascot terletak lebih tinggi
                      // dengan ruang nafas di bawah sebelum heading.
                      const Expanded(
                        flex: 6,
                        child: Align(
                          alignment: Alignment.center,
                          child: _MascotPlaceholder(),
                        ),
                      ),

                      // ─── Heading ────────────────────
                      Text(
                        s.loginLine1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textHi,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        s.loginLine2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textHi,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ─── Buttons ────────────────────
                      _LoginButton(
                        primary: true,
                        icon: Icons.g_mobiledata,
                        iconSize: 30,
                        label: s.continueGoogle,
                        isLoading: _isLoadingGoogle,
                        disabled: _anyLoading && !_isLoadingGoogle,
                        onPressed: _handleGoogleSignIn,
                      ),
                      const SizedBox(height: 12),
                      _LoginButton(
                        primary: false,
                        icon: Icons.person_outline_rounded,
                        iconSize: 20,
                        label: s.playAsGuest,
                        isLoading: _isLoadingGuest,
                        disabled: _anyLoading && !_isLoadingGuest,
                        onPressed: _handleGuestSignIn,
                      ),

                      // ─── Error ──────────────────────
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        _ErrorBanner(message: _errorMessage!),
                      ],

                      const SizedBox(height: 18),

                      // ─── Footer note ────────────────
                      Text(
                        s.guestNoProgress,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textLo,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// MASCOT
// ═══════════════════════════════════════
/// Bubble biru gradient di belakang + mascot 3D di tengahnya (keduanya
/// center-aligned di Stack). Layout rapi & simetris.
class _MascotPlaceholder extends StatelessWidget {
  const _MascotPlaceholder();

  static const double _bubbleSize = 320;
  // Mascot sedikit lebih besar dari bubble agar tangan & jubah sedikit
  // overflow dari rim — tapi tubuh utama tetap berada di tengah bubble.
  static const double _mascotSize = 480;

  @override
  Widget build(BuildContext context) {
    // Bubble di-jadiin parent visible. Mascot dibungkus OverflowBox supaya
    // bisa di-set jauh lebih besar dari _bubbleSize tanpa di-clamp parent
    // — overflow keluar bubble & layar diperbolehkan.
    return SizedBox(
      width: _bubbleSize,
      height: _bubbleSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Bubble di belakang.
          Container(
            width: _bubbleSize,
            height: _bubbleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Mascot 3D — OverflowBox membebaskan dari constraint parent
          // (_bubbleSize), jadi _mascotSize bisa berapapun bahkan > layar.
          OverflowBox(
            minWidth: 0,
            minHeight: 0,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: Image.asset(
              'assets/images/mascot_login.png',
              width: _mascotSize,
              height: _mascotSize,
              fit: BoxFit.contain,
              cacheWidth: (_mascotSize * 1.6).round(),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
// LOGIN BUTTON
// ═══════════════════════════════════════
class _LoginButton extends StatelessWidget {
  final bool primary;
  final IconData icon;
  final double iconSize;
  final String label;
  final bool isLoading;
  final bool disabled;
  final VoidCallback onPressed;

  const _LoginButton({
    required this.primary,
    required this.icon,
    required this.iconSize,
    required this.label,
    required this.isLoading,
    required this.disabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? AppColors.primary : Colors.white;
    final fg = primary ? Colors.white : AppColors.textHi;
    final border = primary ? Colors.transparent : AppColors.border;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: (disabled || isLoading) ? null : onPressed,
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: border, width: 1.2),
            ),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: fg,
                        strokeWidth: 2.4,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: fg, size: iconSize),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: fg,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// ERROR BANNER
// ═══════════════════════════════════════
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgMid,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
