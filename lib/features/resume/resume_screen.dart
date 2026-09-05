import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/dark_tile.dart';
import '../../core/widgets/neu_card.dart';
import '../../core/widgets/neu_chip.dart';
import '../../core/widgets/neu_text_field.dart';

class ResumeScreen extends ConsumerStatefulWidget {
  const ResumeScreen({super.key});
  @override
  ConsumerState<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends ConsumerState<ResumeScreen> {
  int _selectedTemplate = 0;
  final Map<String, TextEditingController> _ctrls = {
    'name': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'linkedin': TextEditingController(),
    'education': TextEditingController(),
    'experience': TextEditingController(),
    'projects': TextEditingController(),
    'skills': TextEditingController(),
    'achievements': TextEditingController(),
  };
  final Map<String, bool> _done = {
    'personal': false, 'education': false, 'experience': false, 'projects': false, 'skills': false, 'achievements': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(profileProvider(null)).value;
      if (user != null) {
        _ctrls['name']!.text = user.name;
        _ctrls['email']!.text = user.email;
        _ctrls['skills']!.text = user.skills.join(', ');
        setState(() {
          _done['personal'] = user.name.isNotEmpty;
          _done['education'] = (user.college ?? '').isNotEmpty;
          _done['skills'] = user.skills.isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  int get _ats {
    int s = 30;
    if (_done['personal']!) s += 10;
    if (_done['education']!) s += 10;
    if (_done['experience']!) s += 15;
    if (_done['projects']!) s += 15;
    if (_done['skills']!) s += 10;
    if (_done['achievements']!) s += 10;
    return s.clamp(0, 100);
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    final name = _ctrls['name']!.text.isEmpty ? 'Your Name' : _ctrls['name']!.text;
    final email = _ctrls['email']!.text;
    final phone = _ctrls['phone']!.text;
    final isModern = _selectedTemplate == 0;
    final isClassic = _selectedTemplate == 1;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: isModern ? pw.BoxDecoration(color: PdfColor.fromHex('#1BA8C4'), borderRadius: pw.BorderRadius.circular(6)) : const pw.BoxDecoration(),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(name, style: pw.TextStyle(fontSize: isClassic ? 22 : 24, fontWeight: pw.FontWeight.bold, color: isModern ? PdfColors.white : PdfColors.black)),
            pw.SizedBox(height: 4),
            pw.Text('$email  ${phone.isNotEmpty ? ' | $phone' : ''}  ${_ctrls['linkedin']!.text}', style: pw.TextStyle(fontSize: 9, color: isModern ? PdfColors.white : PdfColors.grey700)),
          ]),
        ),
        pw.SizedBox(height: 16),
        if (_ctrls['education']!.text.isNotEmpty) ...[pw.Text('EDUCATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColor.fromHex('#1BA8C4'))), pw.Divider(), pw.Text(_ctrls['education']!.text, style: const pw.TextStyle(fontSize: 10)), pw.SizedBox(height: 10)],
        if (_ctrls['experience']!.text.isNotEmpty) ...[pw.Text('EXPERIENCE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColor.fromHex('#1BA8C4'))), pw.Divider(), pw.Text(_ctrls['experience']!.text, style: const pw.TextStyle(fontSize: 10)), pw.SizedBox(height: 10)],
        if (_ctrls['projects']!.text.isNotEmpty) ...[pw.Text('PROJECTS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColor.fromHex('#1BA8C4'))), pw.Divider(), pw.Text(_ctrls['projects']!.text, style: const pw.TextStyle(fontSize: 10)), pw.SizedBox(height: 10)],
        if (_ctrls['skills']!.text.isNotEmpty) ...[pw.Text('SKILLS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColor.fromHex('#1BA8C4'))), pw.Divider(), pw.Text(_ctrls['skills']!.text, style: const pw.TextStyle(fontSize: 10)), pw.SizedBox(height: 10)],
        if (_ctrls['achievements']!.text.isNotEmpty) ...[pw.Text('ACHIEVEMENTS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColor.fromHex('#1BA8C4'))), pw.Divider(), pw.Text(_ctrls['achievements']!.text, style: const pw.TextStyle(fontSize: 10))],
      ],
    ));

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  void _editSection(String key, String title, String hint, String ctrlKey) {
    final c = _ctrls[ctrlKey]!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(28), boxShadow: AppColors.neuRaisedShadows),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.shadowDark, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.soraHeading3()),
            const SizedBox(height: 12),
            NeuTextField(hint: hint, controller: c, maxLines: 5),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () { setState(() => _done[key] = c.text.trim().isNotEmpty); Navigator.pop(context); },
              child: Container(height: 50, decoration: BoxDecoration(gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(14)), alignment: Alignment.center, child: Text('Save', style: AppTypography.interButton(color: Colors.white))),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = [
      _Section(icon: Icons.person_outline, title: 'Personal Info', subtitle: _ctrls['name']!.text.isEmpty ? 'Add name, email, phone' : _ctrls['name']!.text, done: _done['personal']!, onTap: () => _editSection('personal', 'Personal Info', 'Name, email, phone, LinkedIn', 'name')),
      _Section(icon: Icons.school_outlined, title: 'Education', subtitle: _ctrls['education']!.text.isEmpty ? 'Add education' : '1 entry', done: _done['education']!, onTap: () => _editSection('education', 'Education', 'College, degree, year, CGPA', 'education')),
      _Section(icon: Icons.work_outline, title: 'Experience', subtitle: _ctrls['experience']!.text.isEmpty ? 'Add internships & jobs' : '1 entry', done: _done['experience']!, onTap: () => _editSection('experience', 'Experience', 'Company, role, duration, description', 'experience')),
      _Section(icon: Icons.code_outlined, title: 'Projects', subtitle: _ctrls['projects']!.text.isEmpty ? 'Add projects' : '1 entry', done: _done['projects']!, onTap: () => _editSection('projects', 'Projects', 'Project name, tech stack, link', 'projects')),
      _Section(icon: Icons.psychology_outlined, title: 'Skills', subtitle: _ctrls['skills']!.text.isEmpty ? 'Add skills' : _ctrls['skills']!.text, done: _done['skills']!, onTap: () => _editSection('skills', 'Skills', 'e.g. Flutter, Python, ML', 'skills')),
      _Section(icon: Icons.emoji_events_outlined, title: 'Achievements', subtitle: _ctrls['achievements']!.text.isEmpty ? 'Add certificates & awards' : '1 entry', done: _done['achievements']!, onTap: () => _editSection('achievements', 'Achievements', 'Certificates, awards', 'achievements')),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Resume Builder', style: AppTypography.soraHeading3()), backgroundColor: AppColors.bg, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: AppColors.ink), onPressed: () => context.pop())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text('Choose Template', style: AppTypography.soraHeading3()),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _selectedTemplate = i),
                child: _TemplateTile(name: ['Modern','Classic','Minimal'][i], isSelected: _selectedTemplate == i),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Resume Sections', style: AppTypography.soraHeading3()),
          const SizedBox(height: 12),
          ...sections.map((s) => _SectionCard(section: s).animate(delay: 50.ms).fadeIn(duration: 300.ms)),
          const SizedBox(height: 24),
          DarkTile(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [GlowText('ATS Score', style: AppTypography.soraHeading3(color: AppColors.cyan)), const Spacer(), Text('$_ats/100', style: AppTypography.monoDisplay(size: 28, color: AppColors.cyan))]),
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: _ats / 100, minHeight: 8, color: AppColors.cyan, backgroundColor: AppColors.cyanDeep.withOpacity(0.2))),
              const SizedBox(height: 12),
              Text(_ats < 70 ? 'Add Experience and Projects to improve your score' : 'Great! Your resume is ready to export', style: AppTypography.interBodySmall(color: AppColors.inkSoft)),
            ]),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _exportPdf,
            child: Container(
              width: double.infinity, height: 56,
              decoration: BoxDecoration(gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cyanGlowShadows),
              alignment: Alignment.center,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.download_rounded, color: Colors.white, size: 20), const SizedBox(width: 10), Text('Export as PDF', style: AppTypography.interButton(color: Colors.white, size: 16))]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section {
  final IconData icon;
  final String title, subtitle;
  final bool done;
  final VoidCallback onTap;
  const _Section({required this.icon, required this.title, required this.subtitle, this.done = false, required this.onTap});
}

class _SectionCard extends StatelessWidget {
  final _Section section;
  const _SectionCard({required this.section});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: NeuCard(
      padding: const EdgeInsets.all(16),
      onTap: section.onTap,
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: (section.done ? AppColors.success : AppColors.cyanDeep).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(section.icon, color: section.done ? AppColors.success : AppColors.cyanDeep, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(section.title, style: AppTypography.interButton(color: AppColors.ink, size: 14)), Text(section.subtitle, style: AppTypography.interCaption(), maxLines: 1, overflow: TextOverflow.ellipsis)])),
        Icon(section.done ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded, color: section.done ? AppColors.success : AppColors.inkSoft, size: section.done ? 20 : 14),
      ]),
    ),
  );
}

class _TemplateTile extends StatelessWidget {
  final String name;
  final bool isSelected;
  const _TemplateTile({required this.name, this.isSelected = false});
  @override
  Widget build(BuildContext context) => Container(
    width: 110,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: isSelected ? AppColors.cyanGlowShadows : AppColors.neuRaisedShadows, border: isSelected ? Border.all(color: AppColors.cyan, width: 2) : null, color: AppColors.bg),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.article_rounded, size: 40, color: isSelected ? AppColors.cyanDeep : AppColors.inkSoft), const SizedBox(height: 8), Text(name, style: AppTypography.interButton(color: isSelected ? AppColors.cyanDeep : AppColors.ink, size: 13)), if (isSelected) ...[const SizedBox(height: 4), const NeuChip(label: '✓ Selected')]]),
  );
}
