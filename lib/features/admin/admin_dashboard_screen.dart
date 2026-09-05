// lib/features/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/dark_tile.dart';
import '../../core/widgets/neu_card.dart';
import '../../core/router/app_router.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.bg,
              elevation: 0,
              title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Admin Panel', style: AppTypography.soraDisplay(size: 22)),
                Text('CampusSetu', style: AppTypography.interCaption(color: AppColors.cyanDeep)),
              ]),
              actions: [
                GestureDetector(
                  onTap: () => context.go(AppRoutes.welcome),
                  child: NeuCard(
                    margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Key Metrics ──────────────────────────────
                  Text('Platform Overview', style: AppTypography.soraHeading3()),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _MetricCard(label: 'Students', value: '12,487', icon: Icons.people_rounded, color: AppColors.cyanDeep)),
                    const SizedBox(width: 10),
                    Expanded(child: _MetricCard(label: 'Active Today', value: '3,291', icon: Icons.trending_up_rounded, color: AppColors.success)),
                  ]).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _MetricCard(label: 'Posts', value: '48,203', icon: Icons.feed_rounded, color: AppColors.warning)),
                    const SizedBox(width: 10),
                    Expanded(child: _MetricCard(label: 'Reports', value: '7', icon: Icons.flag_rounded, color: AppColors.error)),
                  ]).animate(delay: 100.ms).fadeIn(duration: 500.ms),

                  const SizedBox(height: 24),

                  // ── Pending Actions ───────────────────────────
                  Text('Pending Actions', style: AppTypography.soraHeading3()),
                  const SizedBox(height: 12),
                  ...[
                    _Action(title: 'Review Flagged Posts', badge: '7', color: AppColors.error, icon: Icons.flag_outlined),
                    _Action(title: 'Verify College Badges', badge: '23', color: AppColors.warning, icon: Icons.verified_outlined),
                    _Action(title: 'Pending Ad Approvals', badge: '4', color: AppColors.cyanDeep, icon: Icons.campaign_outlined),
                    _Action(title: 'Note Verifications', badge: '11', color: AppColors.success, icon: Icons.menu_book_outlined),
                  ].map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: NeuCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () {},
                      child: Row(children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: a.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(a.icon, color: a.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text(a.title, style: AppTypography.interButton(color: AppColors.ink))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: a.color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(a.badge, style: AppTypography.interBadge(color: a.color)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft, size: 18),
                      ]),
                    ),
                  )).toList(),

                  const SizedBox(height: 24),

                  // ── Quick Actions ─────────────────────────────
                  DarkTile(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      GlowText('Quick Actions', style: AppTypography.soraHeading3(color: AppColors.cyan)),
                      const SizedBox(height: 16),
                      Row(children: [
                        _QuickAction(icon: Icons.campaign_outlined, label: 'Broadcast', color: AppColors.cyan),
                        _QuickAction(icon: Icons.block_outlined, label: 'Ban User', color: AppColors.error),
                        _QuickAction(icon: Icons.star_outline, label: 'Feature', color: AppColors.gold),
                        _QuickAction(icon: Icons.download_outlined, label: 'Export', color: AppColors.success),
                      ]),
                    ]),
                  ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 10),
        Text(value, style: AppTypography.monoCode(size: 22, weight: FontWeight.w700, color: AppColors.ink)),
        Text(label, style: AppTypography.interCaption()),
      ]),
    );
  }
}

class _Action {
  final String title, badge;
  final Color color;
  final IconData icon;
  const _Action({required this.title, required this.badge, required this.color, required this.icon});
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickAction({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Column(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.interCaption(color: color)),
        ]),
      ),
    );
  }
}
