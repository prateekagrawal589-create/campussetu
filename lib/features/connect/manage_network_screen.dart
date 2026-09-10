import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/app_router.dart';

class ManageNetworkScreen extends StatefulWidget {
  const ManageNetworkScreen({super.key});
  @override
  State<ManageNetworkScreen> createState() => _ManageNetworkScreenState();
}

class _ManageNetworkScreenState extends State<ManageNetworkScreen> {
  int _connectionsCount = 0;
  @override
  void initState() { super.initState(); _loadCount(); }
  Future<void> _loadCount() async {
    try {
      final list = await ApiService().getMyConnections();
      if (mounted) setState(() => _connectionsCount = list.length);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F2F2),
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1D24)), onPressed: () => context.pop()),
      title: Text('Manage my network', style: AppTypography.soraHeading3()),
    ),
    body: ListView(
      children: [
        _tile(Icons.people_rounded, 'Connections', '$_connectionsCount', onTap: () => context.push(AppRoutes.connections)),
        _tile(Icons.person_rounded, 'Following & followers', null, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')))),
        _tile(Icons.groups_rounded, 'Groups', null, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')))),
        _tile(Icons.calendar_month_rounded, 'Events', null, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')))),
        _tile(Icons.business_rounded, 'Pages', '7', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')))),
        _tile(Icons.newspaper_rounded, 'Newsletters', null, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')))),
      ],
    ),
  );

  Widget _tile(IconData icon, String title, String? badge, {VoidCallback? onTap}) => InkWell(
    onTap: onTap,
    child: Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(children: [
        Icon(icon, size: 20, color: const Color(0xFF1A1D24)),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1D24)))),
        if (badge != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF0A66C2), borderRadius: BorderRadius.circular(12)), child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
      ]),
    ),
  );
}
