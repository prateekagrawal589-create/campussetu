import 'package:dio/dio.dart';
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

class _ConnectScreenState extends ConsumerState<ConnectScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String? _selectedState;
  String? _selectedBranch;
  int? _selectedYear;
  final Map<String, String> _connectionStates = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendRequest(UserModel user) async {
    try {
      await ApiService().sendConnectionRequest(user.id);
      setState(() => _connectionStates[user.id] = 'pending');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent ✓'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final existingStatus = (e.response?.data?['status'] ?? 'pending').toString();
        setState(() => _connectionStates[user.id] = existingStatus);
        if (mounted) {
          final msg = existingStatus == 'pending' ? 'Request already sent' : 'Already $existingStatus';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.warning, behavior: SnackBarBehavior.floating));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.message}'), backgroundColor: AppColors.error));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Connect', style: AppTypography.soraDisplay(size: 26)),
              Text('Find students across India', style: AppTypography.interBody(color: AppColors.inkSoft)),
              const SizedBox(height: 14),
              NeuCard(
                padding: const EdgeInsets.all(4),
                borderRadius: 16,
                child: TabBar(
                  controller: _tabCtrl,
                  labelStyle: AppTypography.interButton(color: AppColors.cyanDeep, size: 13),
                  unselectedLabelStyle: AppTypography.interButton(color: AppColors.inkSoft, size: 13),
                  indicator: BoxDecoration(color: AppColors.cyanDeep.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  dividerColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  tabs: const [Tab(text: 'Discover'), Tab(text: 'Requests')],
                ),
              ),
            ]),
          ),
          Expanded(
            child: TabBarView(controller: _tabCtrl, children: [
              _DiscoverTab(
                searchCtrl: _searchCtrl,
                selectedState: _selectedState,
                selectedBranch: _selectedBranch,
                selectedYear: _selectedYear,
                connectionStates: _connectionStates,
                onSearchChanged: () => setState(() {}),
                onShowFilters: _showFilters,
                onClearState: () => setState(() => _selectedState = null),
                onClearYear: () => setState(() => _selectedYear = null),
                onClearBranch: () => setState(() => _selectedBranch = null),
                onSendRequest: _sendRequest,
              ),
              const _RequestsTab(),
            ]),
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
            setState(() { _selectedState = state; _selectedYear = year; _selectedBranch = branch; });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class _DiscoverTab extends ConsumerWidget {
  final TextEditingController searchCtrl;
  final String? selectedState, selectedBranch;
  final int? selectedYear;
  final Map<String, String> connectionStates;
  final VoidCallback onSearchChanged, onShowFilters, onClearState, onClearYear, onClearBranch;
  final Future<void> Function(UserModel) onSendRequest;
  const _DiscoverTab({required this.searchCtrl, required this.selectedState, required this.selectedBranch, required this.selectedYear, required this.connectionStates, required this.onSearchChanged, required this.onShowFilters, required this.onClearState, required this.onClearYear, required this.onClearBranch, required this.onSendRequest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = DiscoverParams(search: searchCtrl.text, state: selectedState, branch: selectedBranch, year: selectedYear);
    final asyncUsers = ref.watch(discoverProvider(params));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(children: [
          Row(children: [
            Expanded(child: NeuTextField(hint: '🔍  Search name, college, skill...', controller: searchCtrl, onChanged: (_) => onSearchChanged(), prefixIcon: Icon(Icons.search_rounded, color: AppColors.inkSoft, size: 20))),
            const SizedBox(width: 10),
            NeuCard(padding: const EdgeInsets.all(14), onTap: onShowFilters, child: const Icon(Icons.tune_rounded, color: AppColors.cyanDeep, size: 20)),
          ]),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              if (selectedState != null) NeuChip(label: selectedState!, isSelected: true, onTap: onClearState, icon: Icons.location_on_outlined),
              if (selectedYear != null) ...[const SizedBox(width: 8), NeuChip(label: 'Year $selectedYear', isSelected: true, onTap: onClearYear)],
              if (selectedBranch != null) ...[const SizedBox(width: 8), NeuChip(label: selectedBranch!, isSelected: true, onTap: onClearBranch)],
            ]),
          ),
        ]),
      ),
      Expanded(
        child: asyncUsers.when(
          data: (users) {
            if (users.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(32), child: NeuCard(padding: EdgeInsets.all(24), child: Column(children: [Icon(Icons.people_outline, size: 40, color: AppColors.inkSoft), SizedBox(height: 12), Text('No students found', style: AppTypography.soraHeading3()), Text('Try different filters', style: AppTypography.interCaption())]))));
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(discoverProvider(params)),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                itemCount: users.length,
                itemBuilder: (ctx, i) => _StudentCard(student: users[i], connectionState: connectionStates[users[i].id], onConnect: () => onSendRequest(users[i])).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Failed to load', style: AppTypography.interBody(color: AppColors.error)), Text(e.toString(), style: AppTypography.interCaption(), textAlign: TextAlign.center), const SizedBox(height: 12), GestureDetector(onTap: () => ref.invalidate(discoverProvider(params)), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppColors.cyanDeep, borderRadius: BorderRadius.circular(10)), child: Text('Retry', style: AppTypography.interLabel(color: Colors.white))))])),
        ),
      ),
    ]);
  }
}

class _RequestsTab extends StatefulWidget {
  const _RequestsTab();
  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  List<dynamic> _pending = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService().getPendingRequests();
      if (mounted) setState(() => _pending = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(String connectionId, String status) async {
    try {
      await ApiService().respondToConnection(connectionId, status);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status == 'accepted' ? 'Accepted ✓' : 'Rejected'), backgroundColor: status == 'accepted' ? AppColors.success : AppColors.inkSoft, behavior: SnackBarBehavior.floating));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Failed to load requests', style: AppTypography.interBody(color: AppColors.error)), const SizedBox(height: 8), ElevatedButton(onPressed: _load, child: const Text('Retry'))]));
    if (_pending.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 100),
          children: [NeuCard(padding: EdgeInsets.all(24), child: Column(children: [Icon(Icons.inbox_outlined, size: 40, color: AppColors.inkSoft), SizedBox(height: 12), Text('No pending requests', style: AppTypography.soraHeading3()), Text('When someone sends you a request, it will appear here.\nYou can Accept or Reject.', style: AppTypography.interCaption(), textAlign: TextAlign.center)]))],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        itemCount: _pending.length,
        itemBuilder: (ctx, i) {
          final item = _pending[i] as Map<String, dynamic>;
          final requester = item['requester'] is Map ? Map<String, dynamic>.from(item['requester'] as Map) : <String, dynamic>{};
          final name = (requester['name'] ?? 'Unknown').toString();
          final college = (requester['college'] ?? '').toString();
          final city = (requester['city'] ?? '').toString();
          final state = (requester['state'] ?? '').toString();
          final id = item['id']?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NeuCard(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  UserAvatar(name: name, size: 48, imageUrl: requester['photo_url']?.toString()),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: AppTypography.interButton(size: 14)), Text(college.isEmpty ? '$city, $state' : college, style: AppTypography.interCaption(), overflow: TextOverflow.ellipsis)])),
                  Icon(Icons.mail_outline_rounded, color: AppColors.cyanDeep, size: 20),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: GestureDetector(onTap: () => _respond(id, 'rejected'), child: NeuCard(padding: const EdgeInsets.symmetric(vertical: 10), child: Center(child: Text('Reject', style: AppTypography.interButton(color: AppColors.error, size: 13)))))),
                  const SizedBox(width: 10),
                  Expanded(child: GestureDetector(onTap: () => _respond(id, 'accepted'), child: Container(height: 44, decoration: BoxDecoration(gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text('Accept', style: AppTypography.interButton(color: Colors.white, size: 13))))),
                ]),
              ]),
            ),
          ).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms);
        },
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
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(bottom: 12), child: NeuCard(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [UserAvatar(name: student.name, size: 50, isVerified: student.isVerified, isPremium: student.isPremium, imageUrl: student.photoUrl), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Flexible(child: Text(student.name, style: AppTypography.interButton(color: AppColors.ink, size: 15))), if (student.isPremium) ...[SizedBox(width: 6), PremiumBadge(isSmall: true)]]), SizedBox(height: 2), Text('${student.college ?? '—'} • ${student.branch ?? '—'}', style: AppTypography.interBodySmall(), overflow: TextOverflow.ellipsis), Text('${student.city ?? ''}, ${student.state ?? ''} • Year ${student.yearOfStudy ?? '-'}', style: AppTypography.interCaption())])), _ConnectButton(state: connectionState, onTap: onConnect)]), if (student.skills.isNotEmpty) ...[SizedBox(height: 12), Wrap(spacing: 6, runSpacing: 6, children: student.skills.take(4).map((s) => NeuChip(label: s)).toList())], SizedBox(height: 8), Text('${student.connectionsCount} connections', style: AppTypography.interCaption(color: AppColors.cyanDeep))])));
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
  String? _state; int? _year; String? _branch;
  @override
  void initState() { super.initState(); _state = widget.selectedState; _year = widget.selectedYear; _branch = widget.selectedBranch; }
  static const _states = ['Delhi', 'Maharashtra', 'Kerala', 'Tamil Nadu', 'Karnataka', 'Goa', 'Uttar Pradesh', 'West Bengal', 'Rajasthan', 'Gujarat'];
  @override
  Widget build(BuildContext context) => SafeArea(top: false, child: Container(margin: EdgeInsets.fromLTRB(16, 16, 16, 16 + 72), padding: EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(28), boxShadow: AppColors.neuRaisedShadows), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.shadowDark, borderRadius: BorderRadius.circular(2)))), SizedBox(height: 16), Text('Filter Students', style: AppTypography.soraHeading3()), SizedBox(height: 4), Text('Filters apply instantly on search + Discover API', style: AppTypography.interCaption()), SizedBox(height: 16), Text('State', style: AppTypography.interLabel()), SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: _states.map((s) => NeuChip(label: s, isSelected: _state == s, onTap: () => setState(() => _state = _state == s ? null : s))).toList()), SizedBox(height: 16), Text('Year of Study', style: AppTypography.interLabel()), SizedBox(height: 8), Wrap(spacing: 8, children: [1, 2, 3, 4, 5].map((y) => NeuChip(label: 'Year $y', isSelected: _year == y, onTap: () => setState(() => _year = _year == y ? null : y))).toList()), SizedBox(height: 16), Text('Branch', style: AppTypography.interLabel()), SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: ['Computer Science', 'Electronics', 'Mechanical', 'Data Science', 'Economics', 'MBA'].map((b) => NeuChip(label: b, isSelected: _branch == b, onTap: () => setState(() => _branch = _branch == b ? null : b))).toList()), SizedBox(height: 24), Row(children: [Expanded(child: GestureDetector(onTap: () => widget.onApply(null, null, null), child: NeuCard(padding: EdgeInsets.symmetric(vertical: 14), child: Center(child: Text('Clear'))))), SizedBox(width: 12), Expanded(child: GestureDetector(onTap: () => widget.onApply(_state, _year, _branch), child: Container(height: 50, decoration: BoxDecoration(gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: Text('Apply', style: AppTypography.interButton(color: Colors.white)))))]), SizedBox(height: 8)]))));
}
