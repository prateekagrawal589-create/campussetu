import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/neu_card.dart';
import '../../core/widgets/neu_chip.dart';
import '../../core/widgets/neu_text_field.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});
  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _selectedSubject;
  final _searchCtrl = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final filter = {'subject': _selectedSubject, 'q': _searchCtrl.text};
    final asyncNotes = ref.watch(notesProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Notes Library', style: AppTypography.soraDisplay(size: 26)), Text('Academic resources by peers', style: AppTypography.interBody(color: AppColors.inkSoft))]),
                const Spacer(),
                NeuCard(padding: const EdgeInsets.all(12), onTap: () => _showUploadSheet(context), child: Row(children: [const Icon(Icons.upload_rounded, size: 18, color: AppColors.cyanDeep), const SizedBox(width: 6), Text('Upload', style: AppTypography.interLabel(color: AppColors.cyanDeep))])),
              ]),
              const SizedBox(height: 16),
              NeuTextField(hint: '🔍  Search notes...', controller: _searchCtrl, onChanged: (_) => setState(() {}), prefixIcon: Icon(Icons.search_rounded, color: AppColors.inkSoft, size: 20)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: [null, 'DSA', 'OS', 'DBMS', 'CN', 'ML', 'Maths']
                        .map((s) => Padding(padding: const EdgeInsets.only(right: 8), child: NeuChip(label: s ?? 'All', isSelected: _selectedSubject == s, onTap: () => setState(() => _selectedSubject = s))))
                        .toList()),
              ),
              const SizedBox(height: 16),
              NeuCard(
                padding: const EdgeInsets.all(4),
                borderRadius: 16,
                child: TabBar(
                  controller: _tabCtrl,
                  labelStyle: AppTypography.interButton(color: AppColors.cyanDeep),
                  unselectedLabelStyle: AppTypography.interButton(color: AppColors.inkSoft),
                  indicator: BoxDecoration(color: AppColors.cyanDeep.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  dividerColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  tabs: const [Tab(text: 'All Notes'), Tab(text: 'My Uploads')],
                ),
              ),
            ]),
          ),
          Expanded(
            child: TabBarView(controller: _tabCtrl, children: [
              asyncNotes.when(
                data: (notes) {
                  if (notes.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(32), child: NeuCard(padding: const EdgeInsets.all(24), child: Column(children: [Icon(Icons.menu_book_outlined, size: 40, color: AppColors.inkSoft), const SizedBox(height: 12), Text('No notes found', style: AppTypography.soraHeading3()), Text('Try different search', style: AppTypography.interCaption())]))));
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(notesProvider(filter)),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                      itemCount: notes.length,
                      itemBuilder: (ctx, i) {
                        final n = notes[i];
                        return _NoteTile(note: n).animate(delay: (i * 50).ms).fadeIn(duration: 300.ms).slideX(begin: -0.05);
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Failed', style: AppTypography.interBody(color: AppColors.error)), Text(e.toString(), style: AppTypography.interCaption()), const SizedBox(height: 12), GestureDetector(onTap: () => ref.invalidate(notesProvider(filter)), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppColors.cyanDeep, borderRadius: BorderRadius.circular(10)), child: Text('Retry', style: AppTypography.interLabel(color: Colors.white))))])),
              ),
              Center(child: Text('Your uploaded notes appear here', style: AppTypography.interBody(color: AppColors.inkSoft))),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(28), boxShadow: AppColors.neuRaisedShadows),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.shadowDark, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Upload Notes', style: AppTypography.soraHeading3()),
            const SizedBox(height: 16),
            const NeuTextField(hint: 'Note title', label: 'Title'),
            const SizedBox(height: 12),
            const NeuTextField(hint: 'e.g. Operating Systems', label: 'Subject'),
            const SizedBox(height: 16),
            NeuCard(padding: const EdgeInsets.all(20), child: Center(child: Column(children: [const Icon(Icons.cloud_upload_outlined, color: AppColors.cyanDeep, size: 36), const SizedBox(height: 8), Text('Tap to select PDF', style: AppTypography.interBody(color: AppColors.cyanDeep)), Text('Max 10 MB', style: AppTypography.interCaption())]))),
            const SizedBox(height: 20),
            Container(width: double.infinity, height: 54, decoration: BoxDecoration(gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: Text('Upload Notes', style: AppTypography.interButton(color: Colors.white))),
          ]),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final Map<String, dynamic> note;
  const _NoteTile({required this.note});
  @override
  Widget build(BuildContext context) {
    final title = (note['title'] ?? '').toString();
    final subject = (note['subject'] ?? '').toString();
    final downloads = (note['download_count'] ?? note['downloads'] ?? 0).toString();
    final size = note['file_size_mb'] != null ? '${note['file_size_mb']} MB' : (note['size'] ?? '').toString();
    final uploader = (note['uploader']?['name'] ?? note['uploaderName'] ?? '').toString();
    final fileUrl = (note['file_url'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeuCard(
        padding: const EdgeInsets.all(16),
        onTap: () { if (fileUrl.isNotEmpty) launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication); },
        child: Row(children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.cyanDeep.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.picture_as_pdf_rounded, color: AppColors.cyanDeep, size: 28)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(title, style: AppTypography.interButton(color: AppColors.ink, size: 13), maxLines: 2, overflow: TextOverflow.ellipsis)), Icon(Icons.verified_rounded, size: 16, color: AppColors.cyanDeep)]),
            const SizedBox(height: 4),
            Row(children: [NeuChip(label: subject), const SizedBox(width: 6), Expanded(child: Text(uploader, style: AppTypography.interCaption(), overflow: TextOverflow.ellipsis))]),
            const SizedBox(height: 6),
            Row(children: [Icon(Icons.download_outlined, size: 12, color: AppColors.inkSoft), const SizedBox(width: 4), Text('$downloads downloads', style: AppTypography.interCaption()), const Spacer(), Text(size, style: AppTypography.monoCode(size: 11, color: AppColors.inkSoft))]),
          ])),
        ]),
      ),
    );
  }
}
