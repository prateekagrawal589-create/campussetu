import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/models/post_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/neu_card.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/router/app_router.dart';
import 'widgets/post_card.dart';
import 'widgets/create_post_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _refresh() async {
    ref.invalidate(currentUserProvider);
    ref.invalidate(feedProvider);
  }

  Future<void> _ensureToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null) ApiService().setToken(token);
    }
  }

  Future<void> _toggleLike(String postId) async {
    try {
      await _ensureToken();
      await ApiService().toggleLike(postId);
      ref.invalidate(feedProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _openComments(String postId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(postId: postId, onCommented: () => ref.invalidate(feedProvider)),
    );
  }

  Future<void> _sharePost(PostModel post) async {
    try {
      await Share.share(post.content, subject: 'CampusSetu Post');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: AppColors.bg,
              toolbarHeight: 64,
              flexibleSpace: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('CampusSetu', style: AppTypography.caveatBrand(size: 28, color: AppColors.ink)),
                      const Spacer(),
                      NeuCard(
                        padding: const EdgeInsets.all(10),
                        onTap: () => context.push(AppRoutes.notifications),
                        child: Icon(Icons.notifications_outlined, size: 22, color: AppColors.ink),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.profile),
                        child: userAsync.when(
                          data: (u) => UserAvatar(name: u.name, size: 38, showNeuBorder: true, isVerified: u.isVerified, imageUrl: u.photoUrl),
                          loading: () => const UserAvatar(name: '?', size: 38, showNeuBorder: true),
                          error: (_, __) => const UserAvatar(name: '?', size: 38, showNeuBorder: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: userAsync.when(
                      data: (u) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Namaste, ${u.name.split(' ').first}! 👋', style: AppTypography.caveatWarm(size: 22, color: AppColors.inkSoft)),
                          Text("What's happening today?", style: AppTypography.soraHeading2()),
                        ],
                      ),
                      loading: () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Namaste! 👋', style: AppTypography.caveatWarm(size: 22, color: AppColors.inkSoft)),
                          Text("What's happening today?", style: AppTypography.soraHeading2()),
                        ],
                      ),
                      error: (_, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Namaste! 👋', style: AppTypography.caveatWarm(size: 22, color: AppColors.inkSoft)),
                          Text("What's happening today?", style: AppTypography.soraHeading2()),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Feed', style: AppTypography.soraHeading3()),
                        NeuCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          onTap: () async {
                            final created = await showModalBottomSheet<bool>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const CreatePostSheet(),
                            );
                            if (created == true) ref.invalidate(feedProvider);
                          },
                          child: Row(children: [
                            Icon(Icons.add_rounded, size: 18, color: AppColors.cyanDeep),
                            const SizedBox(width: 6),
                            Text('Post', style: AppTypography.interLabel(color: AppColors.cyanDeep)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            feedAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: NeuCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(children: [
                          Icon(Icons.feed_outlined, size: 40, color: AppColors.inkSoft),
                          const SizedBox(height: 12),
                          Text('No posts yet', style: AppTypography.soraHeading3()),
                          const SizedBox(height: 6),
                          Text('Be the first to share something!', style: AppTypography.interBody(color: AppColors.inkSoft)),
                        ]),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => PostCard(
                      post: posts[index],
                      onLike: () => _toggleLike(posts[index].id),
                      onComment: () => _openComments(posts[index].id),
                      onShare: () => _sharePost(posts[index]),
                      onReport: () async {
                        try {
                          await _ensureToken();
                          await ApiService().submitReport({'target_type': 'post', 'target_id': posts[index].id, 'reason': 'reported'});
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reported')));
                        } catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      },
                    ).animate(delay: (index * 80).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                    childCount: posts.length,
                  ),
                );
              },
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate((_, __) => _PostShimmer(), childCount: 3),
              ),
              error: (e, _) => SliverToBoxAdapter(child: _ErrorCard(msg: e.toString(), onRetry: () => ref.invalidate(feedProvider))),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorCard({required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) => NeuCard(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text('Failed to load', style: AppTypography.interBody(color: AppColors.error)),
          const SizedBox(height: 4),
          Text(msg, style: AppTypography.interCaption(), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          GestureDetector(onTap: onRetry, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.cyanDeep, borderRadius: BorderRadius.circular(8)), child: Text('Retry', style: AppTypography.interLabel(color: Colors.white)))),
        ]),
      );
}

class _PostShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: NeuCard(padding: const EdgeInsets.all(16), child: Column(children: [Container(height: 14, color: AppColors.shadowDark.withOpacity(0.3)), const SizedBox(height: 8), Container(height: 14, color: AppColors.shadowDark.withOpacity(0.2)), const SizedBox(height: 12), Container(height: 80, decoration: BoxDecoration(color: AppColors.shadowDark.withOpacity(0.15), borderRadius: BorderRadius.circular(12)))])),
      );
}

class _CommentsSheet extends StatefulWidget {
  final String postId;
  final VoidCallback onCommented;
  const _CommentsSheet({required this.postId, required this.onCommented});
  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();
  List<CommentModel> _comments = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _ensureToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null) ApiService().setToken(token);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _ensureToken();
      final list = await ApiService().getComments(widget.postId);
      setState(() => _comments = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final author = m['author'] is Map ? Map<String, dynamic>.from(m['author'] as Map) : <String, dynamic>{};
        m['author'] = author;
        return CommentModel.fromJson(m);
      }).toList());
    } catch (_) {
      setState(() => _comments = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _ensureToken();
      await ApiService().addComment(widget.postId, text);
      _ctrl.clear();
      widget.onCommented();
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment added ✓'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(28), boxShadow: AppColors.neuRaisedShadows),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 16, right: 16, top: 16),
        child: Column(children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.shadowDark, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Text('Comments', style: AppTypography.soraHeading3()),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _comments.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.chat_bubble_outline, color: AppColors.inkSoft, size: 32), const SizedBox(height: 8), Text('No comments yet', style: AppTypography.interBody(color: AppColors.inkSoft)), Text('Be the first to comment!', style: AppTypography.interCaption())]))
                    : ListView.separated(
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.shadowDark),
                        itemBuilder: (_, i) {
                          final c = _comments[i];
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: AppColors.cyanDeep.withOpacity(0.15), child: Text(c.author.name.isNotEmpty ? c.author.name[0].toUpperCase() : '?', style: AppTypography.interButton(color: AppColors.cyanDeep))),
                            title: Text(c.author.name, style: AppTypography.interButton(size: 13)),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.content, style: AppTypography.interBody(size: 13)), const SizedBox(height: 2), Text(timeago.format(c.createdAt, locale: 'en_short'), style: AppTypography.monoTimestamp())]),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _ctrl, decoration: InputDecoration(hintText: 'Add a comment...', hintStyle: AppTypography.interBody(color: AppColors.inkSoft), filled: true, fillColor: AppColors.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)), maxLength: 500, buildCounter: (_, {required currentLength, required isFocused, maxLength}) => const SizedBox.shrink())),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _send,
              child: Container(width: 44, height: 44, decoration: BoxDecoration(gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(12)), child: _sending ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, color: Colors.white, size: 18)),
            ),
          ]),
        ]),
      ),
    );
  }
}


