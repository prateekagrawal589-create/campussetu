import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/dark_tile.dart';
import '../../core/widgets/neu_card.dart';
import '../../core/widgets/neu_chip.dart';
import '../../core/widgets/neu_text_field.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});
  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  String _selectedType = 'All';
  bool _remoteOnly = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = {'type': _selectedType, 'remoteOnly': _remoteOnly, 'q': _searchCtrl.text};
    final asyncJobs = ref.watch(jobsProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Opportunities', style: AppTypography.soraDisplay(size: 26)),
              Text('Jobs, Internships & Hackathons', style: AppTypography.interBody(color: AppColors.inkSoft)),
              const SizedBox(height: 16),
              NeuTextField(hint: '🔍  Search role or company', controller: _searchCtrl, onChanged: (_) => setState(() {}), prefixIcon: Icon(Icons.search_rounded, color: AppColors.inkSoft, size: 20)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  ...['All', 'Internship', 'Job', 'Hackathon'].map((t) => Padding(padding: const EdgeInsets.only(right: 8), child: NeuChip(label: t, isSelected: _selectedType == t, onTap: () => setState(() => _selectedType = t)))),
                  NeuChip(label: '🌐 Remote', isSelected: _remoteOnly, onTap: () => setState(() => _remoteOnly = !_remoteOnly), selectedColor: AppColors.success),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: asyncJobs.when(
              data: (jobs) {
                var filtered = jobs;
                final q = _searchCtrl.text.toLowerCase();
                if (q.isNotEmpty) filtered = jobs.where((j) => (j['title'] as String? ?? '').toLowerCase().contains(q) || (j['company'] as String? ?? '').toLowerCase().contains(q)).toList();
                if (filtered.isEmpty) {
                  return Center(child: Padding(padding: EdgeInsets.all(32), child: NeuCard(padding: EdgeInsets.all(24), child: Column(children: [Icon(Icons.work_outline, size: 40, color: AppColors.inkSoft), SizedBox(height: 12), Text('No opportunities found', style: AppTypography.soraHeading3()), Text('Try different filters', style: AppTypography.interCaption())]))));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(jobsProvider(filter)),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _JobCard(job: filtered[i]).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Failed to load', style: AppTypography.interBody(color: AppColors.error)), Text(e.toString(), style: AppTypography.interCaption()), const SizedBox(height: 12), GestureDetector(onTap: () => ref.invalidate(jobsProvider(filter)), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppColors.cyanDeep, borderRadius: BorderRadius.circular(10)), child: Text('Retry', style: AppTypography.interLabel(color: Colors.white))))])),
            ),
          ),
        ]),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _JobCard({required this.job});
  static const _typeColors = {'Internship': AppColors.cyanDeep, 'Job': AppColors.success, 'Hackathon': AppColors.warning, 'Full-Time': AppColors.success, 'Part-Time': AppColors.info};

  @override
  Widget build(BuildContext context) {
    final title = (job['title'] ?? '').toString();
    final company = (job['company'] ?? '').toString();
    final location = (job['city'] ?? job['location'] ?? 'Remote').toString();
    final type = (job['type'] ?? 'Job').toString();
    final stipend = (job['stipend'] ?? job['salary'] ?? job['apply_url'] ?? '').toString();
    final isRemote = job['is_remote'] == true || job['isRemote'] == true;
    final applyLink = (job['apply_url'] ?? job['applyLink'] ?? '').toString();
    final isSponsored = job['is_sponsored'] == true || job['isSponsored'] == true;
    final color = _typeColors[type] ?? AppColors.inkSoft;

    if (isSponsored) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DarkTile(
          padding: const EdgeInsets.all(18),
          onTap: () { if (applyLink.isNotEmpty) launchUrl(Uri.parse(applyLink)); },
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.2), borderRadius: BorderRadius.circular(6)), child: Text('⭐ Featured', style: AppTypography.interBadge(color: AppColors.warning))), const Spacer(), Text(type, style: AppTypography.interBadge(color: AppColors.cyan))]),
            const SizedBox(height: 12),
            GlowText(title, style: AppTypography.soraHeading3(color: AppColors.cyan)),
            const SizedBox(height: 4),
            Text(company, style: AppTypography.interBody(color: Colors.white70)),
            const SizedBox(height: 8),
            Row(children: [Icon(Icons.location_on_outlined, size: 14, color: AppColors.inkSoft), SizedBox(width: 4), Text(location, style: AppTypography.interCaption(color: AppColors.inkSoft)), Spacer(), if (stipend.isNotEmpty) GlowText(stipend, style: AppTypography.monoCode(size: 13, color: AppColors.cyan))]),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeuCard(
        padding: const EdgeInsets.all(16),
        onTap: () { if (applyLink.isNotEmpty) launchUrl(Uri.parse(applyLink)); },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(company.isNotEmpty ? company[0].toUpperCase() : '?', style: AppTypography.soraHeading3(color: color)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTypography.interButton(color: AppColors.ink, size: 14)), Text(company, style: AppTypography.interCaption())])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(type, style: AppTypography.interBadge(color: color))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.location_on_outlined, size: 13, color: AppColors.inkSoft),
            const SizedBox(width: 4),
            Text(location, style: AppTypography.interCaption()),
            if (isRemote) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text('Remote', style: AppTypography.interBadge(color: AppColors.success)))],
            const Spacer(),
            if (stipend.isNotEmpty && stipend != location) Text(stipend, style: AppTypography.monoCode(size: 13, color: AppColors.ink, weight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Container(width: double.infinity, height: 40, decoration: BoxDecoration(gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text('Apply Now', style: AppTypography.interButton(color: Colors.white, size: 13))),
        ]),
      ),
    );
  }
}
