import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/neu_card.dart';
import '../../core/widgets/neu_text_field.dart';
import '../../core/widgets/neu_chip.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/widgets/premium_badge.dart';
import '../../core/models/user_model.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});
  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedState;
  String? _selectedBranch;
  int? _selectedYear;
  final Map<String, String> _connectionStates = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = DiscoverParams(search: _searchCtrl.text, state: _selectedState, branch: _selectedBranch, year: _selectedYear);
    final asyncUsers = ref.watch(discoverProvider(params));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Connect', style: AppTypography.soraDisplay(size: 26)),
              const SizedBox(height: 4),
              Text('Find students across India', style: AppTypography.interBody(color: AppColors.inkSoft)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: NeuTextField(
                    hint: '🔍  Search name, college, skill...',
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.inkSoft, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                NeuCard(padding: const EdgeInsets.all(14), onTap: _showFilters, child: const Icon(Icons.tune_rounded, color: AppColors.cyanDeep, size: 20)),
              ]),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  if (_selectedState != null) NeuChip(label: _selectedState!, isSelected: true, onTap: () => setState(() => _selectedState = null), icon: Icons.location_on_outlined),
                  if (_selectedYear != null) ...[
                    const SizedBox(width: 8),
                    NeuChip(label: 'Year $_selectedYear', isSelected: true, onTap: () => setState(() => _selectedYear = null)),
                  ],
                  if (_selectedBranch != null) ...[
                    const SizedBox(width: 8),
                    NeuChip(label: _selectedBranch!, isSelected: true, onTap: () => setState(() => _selectedBranch = null)),
                  ],
                ]),
              ),
            ]),
          ),
          Expanded(
            child: asyncUsers.when(
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: NeuCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(children: [
                          Icon(Icons.people_outline, size: 40, color: AppColors.inkSoft),
                          const SizedBox(height: 12),
                          Text('No students found', style: AppTypography.soraHeading3()),
                          Text('Try different filters', style: AppTypography.interCaption()),
                        ]),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(discoverProvider(params)),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    itemCount: users.length,
                    itemBuilder: (ctx, i) => _StudentCard(
                      student: users[i],
                      connectionState: _connectionStates[users[i].id],
                      onConnect: () async {
                        try {
                          await ApiService().sendConnectionRequest(users[i].id);
                          setState(() => _connectionStates[users[i].id] = 'pending');
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent')));
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      },
                    ).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Failed to load', style: AppTypography.interBody(color: AppColors.error)),
                  Text(e.toString(), style: AppTypography.interCaption(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  GestureDetector(onTap: () => ref.invalidate(discoverProvider(params)), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppColors.cyanDeep, borderRadius: BorderRadius.circular(10)), child: Text('Retry', style: AppTypography.interLabel(color: Colors.white)))),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _FilterSheet(
          selectedState: _selectedState,
          selectedYear: _selectedYear,
          selectedBranch: _selectedBranch,
          onApply: (state, year, branch) {
            setState(() {
              _selectedState = state;
              _selectedYear = year;
              _selectedBranch = branch;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final UserModel student;
  final String? connectionState;
  final VoidCallback onConnect;
  const _StudentCard({required this.student, required this.connectionState, required this.onConnect});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: NeuCard(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              UserAvatar(name: student.name, size: 50, isVerified: student.isVerified, isPremium: student.isPremium, imageUrl: student.photoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Flexible(child: Text(student.name, style: AppTypography.interButton(color: AppColors.ink, size: 15))), if (student.isPremium) ...[const SizedBox(width: 6), const PremiumBadge(isSmall: true)]]),
                  const SizedBox(height: 2),
                  Text('${student.college ?? '—'} • ${student.branch ?? '—'}', style: AppTypography.interBodySmall(), overflow: TextOverflow.ellipsis),
                  Text('${student.city ?? ''}, ${student.state ?? ''} • Year ${student.yearOfStudy ?? '-'}', style: AppTypography.interCaption()),
                ]),
              ),
              _ConnectButton(state: connectionState, onTap: onConnect),
            ]),
            if (student.skills.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 6, runSpacing: 6, children: student.skills.take(4).map((s) => NeuChip(label: s)).toList()),
            ],
            const SizedBox(height: 8),
            Text('${student.connectionsCount} connections', style: AppTypography.interCaption(color: AppColors.cyanDeep)),
          ]),
        ),
      );
}

class _ConnectButton extends StatelessWidget {
  final String? state;
  final VoidCallback onTap;
  const _ConnectButton({this.state, required this.onTap});
  @override
  Widget build(BuildContext context) {
    if (state == 'accepted') return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text('Connected', style: AppTypography.interCaption(color: AppColors.success).copyWith(fontWeight: FontWeight.w600)));
    if (state == 'pending') return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text('Pending', style: AppTypography.interCaption(color: AppColors.warning).copyWith(fontWeight: FontWeight.w600)));
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(12)), child: Text('Connect', style: AppTypography.interCaption(color: Colors.white).copyWith(fontWeight: FontWeight.w700))));
  }
}

class _FilterSheet extends StatefulWidget {
  final String? selectedState;
  final int? selectedYear;
  final String? selectedBranch;
  final Function(String?, int?, String?) onApply;
  const _FilterSheet({required this.selectedState, required this.selectedYear, required this.selectedBranch, required this.onApply});
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _state;
  int? _year;
  String? _branch;
  @override
  void initState() {
    super.initState();
    _state = widget.selectedState;
    _year = widget.selectedYear;
    _branch = widget.selectedBranch;
  }

  static const _states = ['Delhi', 'Maharashtra', 'Kerala', 'Tamil Nadu', 'Karnataka', 'Goa', 'Uttar Pradesh', 'West Bengal', 'Rajasthan', 'Gujarat'];

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 16 + 72),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(28), boxShadow: AppColors.neuRaisedShadows),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.shadowDark, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Filter Students', style: AppTypography.soraHeading3()),
              const SizedBox(height: 4),
              Text('Filters apply instantly on search + Discover API', style: AppTypography.interCaption()),
              const SizedBox(height: 16),
              Text('State', style: AppTypography.interLabel()),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _states.map((s) => NeuChip(label: s, isSelected: _state == s, onTap: () => setState(() => _state = _state == s ? null : s))).toList()),
              const SizedBox(height: 16),
              Text('Year of Study', style: AppTypography.interLabel()),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [1, 2, 3, 4, 5].map((y) => NeuChip(label: 'Year $y', isSelected: _year == y, onTap: () => setState(() => _year = _year == y ? null : y))).toList()),
              const SizedBox(height: 16),
              Text('Branch', style: AppTypography.interLabel()),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: ['Computer Science', 'Electronics', 'Mechanical', 'Data Science', 'Economics', 'MBA'].map((b) => NeuChip(label: b, isSelected: _branch == b, onTap: () => setState(() => _branch = _branch == b ? null : b))).toList()),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: GestureDetector(onTap: () => widget.onApply(null, null, null), child: const NeuCard(padding: EdgeInsets.symmetric(vertical: 14), child: Center(child: Text('Clear'))))),
                const SizedBox(width: 12),
                Expanded(child: GestureDetector(onTap: () => widget.onApply(_state, _year, _branch), child: Container(height: 50, decoration: BoxDecoration(gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: Text('Apply', style: AppTypography.interButton(color: Colors.white))))),
              ]),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      );
}
