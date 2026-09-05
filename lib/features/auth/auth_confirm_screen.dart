// lib/features/auth/auth_confirm_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/dark_tile.dart';
import '../../core/widgets/neu_card.dart';
import '../../core/router/app_router.dart';

class AuthConfirmScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AuthConfirmScreen({super.key, required this.userData});

  @override
  State<AuthConfirmScreen> createState() => _AuthConfirmScreenState();
}

class _AuthConfirmScreenState extends State<AuthConfirmScreen> {
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    // No artificial delay — show continue instantly for fastest signup
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userData['name'] ?? 'User';
    final email = widget.userData['email'] ?? '';
    final photoUrl = widget.userData['photo_url'] ?? '';
    final profileComplete = widget.userData['profile_complete'] ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Top Label ──────────────────────────────
              Text(
                'Signing you in',
                style: AppTypography.soraHeading2(),
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 8),
              Text(
                'Verifying your account…',
                style: AppTypography.interBody(color: AppColors.inkSoft),
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

              const Spacer(),

              // ── Dark Auth Card ─────────────────────────
              DarkTile(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    // ── Authenticating animation ─────────
                    if (_authenticating) ...[
                      _AuthOrb(photoUrl: photoUrl),
                      const SizedBox(height: 24),
                      GlowText(
                        'Authenticating...',
                        style: AppTypography.interButton(color: AppColors.cyan, size: 16),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 180,
                        child: LinearProgressIndicator(
                          color: AppColors.cyan,
                          backgroundColor: AppColors.cyanDeep.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ] else ...[
                      // ── Account card ─────────────────
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage:
                                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                            backgroundColor: AppColors.cyanDeep.withOpacity(0.2),
                            child: photoUrl.isEmpty
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: AppTypography.soraHeading2(color: AppColors.cyan),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GlowText(
                                  name,
                                  style: AppTypography.soraHeading3(color: AppColors.cyan),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: AppTypography.interBodySmall(
                                      color: AppColors.inkSoft),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 24),
                        ],
                      )
                          .animate()
                          .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut)
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 28),

                      // ── Continue button ───────────────
                      GestureDetector(
                        onTap: () {
                          if (profileComplete) {
                            context.go(AppRoutes.home);
                          } else {
                            context.go(AppRoutes.profileSetup);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: AppColors.cyanGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppColors.cyanGlowShadows,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Continue as $name',
                            style: AppTypography.interButton(color: AppColors.darkTile, size: 15),
                          ),
                        ),
                      )
                          .animate()
                          .slideY(begin: 0.3, duration: 400.ms, delay: 100.ms, curve: Curves.easeOut)
                          .fadeIn(duration: 400.ms, delay: 100.ms),
                    ],
                  ],
                ),
              ).animate().scale(
                    begin: const Offset(0.9, 0.9),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),

              const Spacer(),

              // ── Use different account ──────────────────
              GestureDetector(
                onTap: () => context.go(AppRoutes.welcome),
                child: Text(
                  'Use a different account',
                  style: AppTypography.interBody(color: AppColors.cyanDeep, size: 14)
                      .copyWith(decoration: TextDecoration.underline),
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Auth Orb with spinning ring ────────────────────────────
class _AuthOrb extends StatefulWidget {
  final String photoUrl;
  const _AuthOrb({required this.photoUrl});

  @override
  State<_AuthOrb> createState() => _AuthOrbState();
}

class _AuthOrbState extends State<_AuthOrb> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Spinning outer ring
          RotationTransition(
            turns: _ctrl,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    AppColors.cyan.withOpacity(0.0),
                    AppColors.cyan,
                    AppColors.cyan.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Avatar center
          CircleAvatar(
            radius: 40,
            backgroundImage:
                widget.photoUrl.isNotEmpty ? NetworkImage(widget.photoUrl) : null,
            backgroundColor: AppColors.darkTileAlt,
            child: widget.photoUrl.isEmpty
                ? const Icon(Icons.person_rounded, color: AppColors.cyan, size: 36)
                : null,
          ),
        ],
      ),
    );
  }
}
