import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/garden_provider.dart';
import '../../models/forum_post.dart';
import '../../services/api/supabase_service.dart';
import '../../services/database_service.dart';
import '../../services/image_service.dart';
import '../../core/utils/error_utils.dart';

import '../../widgets/app_card.dart';
import '../../widgets/plant_image.dart';


String _generateUUID() {
  final random = Random();
  final List<int> values = List<int>.generate(16, (i) {
    if (i == 6) {
      return (random.nextInt(16) & 0x0f) | 0x40; // version 4
    } else if (i == 8) {
      return (random.nextInt(16) & 0x3f) | 0x80; // variant
    } else {
      return random.nextInt(256);
    }
  });

  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < 16; i++) {
    if (i == 4 || i == 6 || i == 8 || i == 10) {
      buffer.write('-');
    }
    buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}




class ThreadConnectorPainter extends CustomPainter {
  final bool isLast;
  final Color color;

  ThreadConnectorPainter({required this.isLast, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final double startX = size.width / 2;
    final double endY = 26.0; // Aligns perfectly with the avatar vertical center!
    const double curveRadius = 8.0;

    final path = Path();
    path.moveTo(startX, 0);

    if (isLast) {
      // Draw vertical line down to the curve start
      path.lineTo(startX, endY - curveRadius);
      // Curve to the right
      path.quadraticBezierTo(startX, endY, startX + curveRadius, endY);
      // Horizontal line to the right edge
      path.lineTo(size.width, endY);
    } else {
      // Draw vertical line all the way down
      path.lineTo(startX, size.height);
      // Draw horizontal branch starting from startX to the right edge
      path.moveTo(startX, endY);
      path.lineTo(size.width, endY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ThreadConnectorPainter oldDelegate) {
    return oldDelegate.isLast != isLast || oldDelegate.color != color;
  }
}


class ForumScreen extends StatefulWidget {
  final String? autoAttachDiagnosisName;
  final String? autoAttachImagePath;

  const ForumScreen({
    super.key,
    this.autoAttachDiagnosisName,
    this.autoAttachImagePath,
  });

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'General',
    'ID Help',
    'Disease Diagnosis',
    'Tips & Tricks',
    'Marketplace'
  ];

  // Pagination state
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMorePosts = true;
  int _currentPage = 0;
  static const int _pageSize = 10;
  List<ForumPost> _posts = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
    // Listen for scroll-to-bottom to load more posts
    _scrollController.addListener(() {
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoadingMore &&
          _hasMorePosts) {
        _loadMorePosts();
      }
    });
    // Auto-attach diagnosis from Result screen if available
    if (widget.autoAttachDiagnosisName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCreatePostSheet(
          context,
          prefilledTitle: 'Help needed: ${widget.autoAttachDiagnosisName}',
          prefilledContent: 'My plant was diagnosed with ${widget.autoAttachDiagnosisName}. I would appreciate a second opinion or treatment feedback from the community!',
          prefilledTags: ['#diagnosis', '#help', '#${widget.autoAttachDiagnosisName!.toLowerCase().replaceAll(' ', '')}'],
          autoAttachImagePath: widget.autoAttachImagePath,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMorePosts = true;
    });

    // 1. Instant local load from SQLite so offline or re-opened app shows cached posts & replies immediately
    final localPosts = await DatabaseService.getForumPosts();
    if (localPosts.isNotEmpty && mounted) {
      setState(() {
        _posts = localPosts;
        _isLoading = false;
      });
    }

    // 2. Fetch fresh posts from Supabase in background
    final freshPosts = await SupabaseService().fetchForumPostsPaginated(
      page: 0,
      pageSize: _pageSize,
    );
    if (mounted) {
      setState(() {
        if (freshPosts.isNotEmpty) {
          _posts = freshPosts;
        } else if (_posts.isEmpty) {
          _posts = localPosts.isNotEmpty ? localPosts : ForumPost.defaultPosts;
        }
        _isLoading = false;
        _hasMorePosts = _posts.length >= _pageSize;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts) return;
    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;
    final morePosts = await SupabaseService().fetchForumPostsPaginated(
      page: nextPage,
      pageSize: _pageSize,
    );
    setState(() {
      _posts.addAll(morePosts);
      _currentPage = nextPage;
      _hasMorePosts = morePosts.length >= _pageSize;
      _isLoadingMore = false;
    });
  }

  void _showReportDialog(BuildContext ctx, ForumPost post, GardenProvider gardenProvider) {
    String selectedReason = 'Spam';
    final reasons = ['Spam', 'Inappropriate Content', 'Misinformation', 'Harassment', 'Other'];
    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A2420),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.flag_rounded, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 8),
              Text('Report Post', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why are you reporting this post?',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: selectedReason,
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedReason = v);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: reasons.map((r) => RadioListTile<String>(
                    value: r,
                    title: Text(r, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    activeColor: const Color(0xFF22C55E),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await SupabaseService().reportForumPost(
                  postId: post.id,
                  reporterName: gardenProvider.username,
                  reason: selectedReason,
                );
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Post reported. Our team will review it shortly.'),
                      backgroundColor: Color(0xFF22C55E),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              child: const Text('Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthBarrierDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: AppCard(
            borderRadius: 30,
            
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing icon container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    size: 40,
                    color: AppTheme.primaryGreen,
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Join Our Green Circle',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
                const SizedBox(height: 12),
                
                // Description text
                Text(
                  'You must be signed in to $action.\nJoin today to earn XP, unlock gardening badges, customize your virtual greenhouse, and share expert insights with others!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                const SizedBox(height: 28),
                
                // Action Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Primary Sign In / Register Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // 1. Log out guest user so auth barrier reactivates
                          Provider.of<GardenProvider>(context, listen: false).logoutUser();
                          
                          // 2. Return to the root route where MainNavigationShell will swap to AuthScreen
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Sign In / Register',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Secondary Cancel Button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Keep Exploring',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _getAvatarBgColor(String name) {
    final hash = name.hashCode;
    final hues = [120, 160, 200, 280, 320]; // tailored premium hues (Green, Teal, Blue, Purple, Pink)
    final hue = hues[hash.abs() % hues.length];
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.4).toColor();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  }

  void _showImageLightbox(BuildContext context, List<String> paths, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (context) {
        final controller = PageController(initialPage: initialIndex);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Image ${controller.hasClients ? (controller.page?.round() ?? initialIndex) + 1 : initialIndex + 1} of ${paths.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              body: PageView.builder(
                controller: controller,
                itemCount: paths.length,
                onPageChanged: (idx) {
                  setDialogState(() {});
                },
                itemBuilder: (context, index) {
                  final path = paths[index];
                  final isAsset = path.startsWith('assets/') || !path.contains('/');
                  return InteractiveViewer(
                    clipBehavior: Clip.none,
                    maxScale: 4.0,
                    minScale: 0.5,
                    child: Center(
                      child: isAsset
                          ? Image.asset(path, fit: BoxFit.contain)
                          : buildPlantImage(path, fit: BoxFit.contain),
                    ),
                  );
                },
              ),
            );
          }
        );
      },
    );
  }

  // ── Owner / Admin Content Management Methods ──────────────────────────

  /// Recursively removes the comment with [commentId] from [list] (including
  /// nested reply trees). Returns true if found and removed.
  bool _deleteCommentRecursive(List<ForumComment> list, String commentId) {
    for (int i = 0; i < list.length; i++) {
      if (list[i].id == commentId) {
        list.removeAt(i);
        return true;
      }
      if (list[i].replies.isNotEmpty) {
        if (_deleteCommentRecursive(list[i].replies, commentId)) return true;
      }
    }
    return false;
  }

  /// Shows a bottom sheet pre-filled with the post's current data for editing.
  void _showEditPostSheet(BuildContext context, ForumPost post) {
    final titleController = TextEditingController(text: post.title);
    final contentController = TextEditingController(text: post.content);
    final tagsController = TextEditingController(text: post.tags.join(', '));
    String category = post.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
              child: AppCard(
                borderRadius: 30,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_rounded, color: AppTheme.primaryGreen, size: 20),
                            SizedBox(width: 8),
                            Text('Edit Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    // Category picker
                    Row(
                      children: [
                        const Text('Category:  ', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: category,
                          dropdownColor: AppTheme.bgDarkEnd,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          items: _categories.where((c) => c != 'All').map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setSheetState(() => category = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Title field
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Post title...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Content field
                    TextField(
                      controller: contentController,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Post content...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tags field
                    TextField(
                      controller: tagsController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Tags (comma separated, e.g. #tomato, #help)',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                        prefixIcon: const Icon(Icons.tag_rounded, color: AppTheme.primaryGreen, size: 18),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Save button
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Title and content cannot be empty.'), backgroundColor: AppTheme.dangerRed),
                                );
                                return;
                              }
                              setSheetState(() => isSubmitting = true);
                              final newTitle = titleController.text.trim();
                              final newContent = contentController.text.trim();
                              final newTags = tagsController.text
                                  .split(',')
                                  .map((t) => t.trim())
                                  .where((t) => t.isNotEmpty)
                                  .toList();
                              final finalTags = newTags.isNotEmpty ? newTags : ['#general'];
                              // Update in-place so the list view reflects changes instantly
                              setState(() {
                                post.title = newTitle;
                                post.content = newContent;
                                post.category = category;
                                post.tags = finalTags;
                              });
                              await SupabaseService().updateForumPost(
                                post.id,
                                title: newTitle,
                                content: newContent,
                                category: category,
                                tags: finalTags,
                              );
                              setSheetState(() => isSubmitting = false);
                              if (sheetCtx.mounted) {
                                Navigator.pop(sheetCtx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Post updated successfully ✏️'),
                                      backgroundColor: AppTheme.primaryGreen,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Shows a confirmation dialog and permanently deletes a post on confirm.
  void _showDeletePostConfirmation(BuildContext context, ForumPost post) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2420),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text('Delete Post', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'This will permanently remove the post and all its comments. This cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() => _posts.removeWhere((p) => p.id == post.id));
              await SupabaseService().deleteForumPost(post.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post deleted.'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Shows an edit dialog for a single comment, updating it in-place on save.
  void _showEditCommentDialog(
    BuildContext context,
    ForumComment comment,
    StateSetter setModalState,
  ) {
    final controller = TextEditingController(text: comment.content);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2420),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: AppTheme.primaryGreen, size: 20),
            SizedBox(width: 8),
            Text('Edit Comment', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'Edit your comment...',
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final newContent = controller.text.trim();
              if (newContent.isEmpty) return;
              // Update in-place so the comments sheet reflects the change instantly
              setModalState(() => comment.content = newContent);
              setState(() {});
              Navigator.pop(dialogCtx);
              SupabaseService().updateForumComment(comment.id, newContent);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Comment updated ✏️'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog and permanently deletes a comment on confirm.
  void _showDeleteCommentConfirmation(
    BuildContext context,
    ForumPost post,
    ForumComment comment,
    StateSetter setModalState,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2420),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text('Delete Comment', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'This comment and all its replies will be permanently deleted.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              setModalState(() => _deleteCommentRecursive(post.comments, comment.id));
              setState(() {});
              SupabaseService().deleteForumComment(comment.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Comment deleted.'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Post Creation ────────────────────────────────────────────────────────

  void _showCreatePostSheet(
    BuildContext context, {
    String prefilledTitle = '',
    String prefilledContent = '',
    List<String> prefilledTags = const [],
    String? autoAttachImagePath,
  }) {
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
    final isGuest = gardenProvider.isGuest;
    if (isGuest) {
      _showAuthBarrierDialog(context, 'create community posts');
      return;
    }

    final titleController = TextEditingController(text: prefilledTitle);
    final contentController = TextEditingController(text: prefilledContent);
    final tagsController = TextEditingController(text: prefilledTags.join(', '));
    // Pre-select Disease Diagnosis when coming from the result/scan screen.
    // Capture a locally-promoted non-null path so Dart's flow analysis can
    // confirm nullability without requiring the `!` operator.
    final String? effectiveAutoPath =
        (autoAttachImagePath != null && autoAttachImagePath.isNotEmpty)
            ? autoAttachImagePath
            : null;
    final bool hasAutoAttach = effectiveAutoPath != null;
    String category = hasAutoAttach ? 'Disease Diagnosis' : 'General';
    List<File> attachedImages = [];
    if (effectiveAutoPath != null) {
      final f = File(effectiveAutoPath); // promoted — no ! needed
      if (f.existsSync()) {
        attachedImages.add(f);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: AppCard(
                borderRadius: 30,
                
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Create Community Post',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    
                    // Category & Image Picker Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('Category:  ', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold)),
                            DropdownButton<String>(
                              value: category,
                              dropdownColor: AppTheme.bgDarkEnd,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              items: _categories.where((c) => c != 'All').map((c) {
                                return DropdownMenuItem(value: c, child: Text(c));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    category = val;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () async {
                                final ImagePicker picker = ImagePicker();
                                final List<XFile> images = await picker.pickMultiImage();
                                if (images.isNotEmpty) {
                                  setModalState(() {
                                    attachedImages.addAll(images.map((img) => File(img.path)));
                                  });
                                }
                              },
                              icon: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primaryGreen, size: 24),
                              tooltip: 'Attach Photos',
                            ),
                            IconButton(
                              onPressed: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? image = await picker.pickImage(source: ImageSource.camera);
                                if (image != null) {
                                  setModalState(() {
                                    attachedImages.add(File(image.path));
                                  });
                                }
                              },
                              icon: const Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryGreen, size: 22),
                              tooltip: 'Take Photo',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Auto-Attach Diagnosis Banner ─────────────────────────
                    if (hasAutoAttach && attachedImages.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.science_rounded,
                                size: 16,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Diagnosis Image Attached',
                                    style: TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Your scan result has been automatically attached to help the community assist you.',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Attached images preview strip
                    if (attachedImages.isNotEmpty) ...[
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: attachedImages.length,
                          itemBuilder: (context, idx) {
                            final file = attachedImages[idx];
                            // First image is auto-attached diagnosis image
                            final isAutoAttached = hasAutoAttach && idx == 0;
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: isAutoAttached
                                        ? Border.all(
                                            color: AppTheme.primaryGreen
                                                .withValues(alpha: 0.6),
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: buildPlantImageFile(file,
                                        fit: BoxFit.cover),
                                  ),
                                ),
                                // Auto-attach badge
                                if (isAutoAttached)
                                  Positioned(
                                    left: 4,
                                    bottom: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen
                                            .withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'AUTO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        attachedImages.removeAt(idx);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Post Title Input
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Enter an engaging title...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description Input
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Share your questions, guides, marketplace items, or photos...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tags Input
                    TextField(
                      controller: tagsController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Tags (comma separated, e.g. #tomato, #help)',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                        prefixIcon: const Icon(Icons.tag_rounded, color: AppTheme.primaryGreen, size: 18),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                     ElevatedButton(
                      onPressed: isSubmitting ? null : () async {
                        if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill out both title and content.'), backgroundColor: AppTheme.dangerRed),
                          );
                          return;
                        }

                        setModalState(() {
                          isSubmitting = true;
                        });

                        try {
                          // Compress and upload all attached images
                          final List<String> uploadedUrls = [];
                          for (int i = 0; i < attachedImages.length; i++) {
                            final file = attachedImages[i];
                            try {
                              final bytes = await file.readAsBytes();
                              final compressedBytes = await ImageService.compressBytes(bytes);
                              final publicUrl = await ImageService.uploadImage(
                                bucketName: 'community_posts',
                                bytes: compressedBytes,
                                fileName: 'post_img_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                folderName: 'posts',
                              );
                              if (publicUrl != null) {
                                uploadedUrls.add(publicUrl);
                              } else {
                                final base64String = base64Encode(compressedBytes);
                                uploadedUrls.add('data:image/jpeg;base64,$base64String');
                              }
                            } catch (e) {
                              debugPrint("⚠️ Failed to upload post image $i, using local: $e");
                              try {
                                final bytes = await file.readAsBytes();
                                final base64String = base64Encode(bytes);
                                uploadedUrls.add('data:image/jpeg;base64,$base64String');
                              } catch (_) {
                                uploadedUrls.add(file.path);
                              }
                            }
                          }

                          final rawTags = tagsController.text
                              .split(',')
                              .map((t) => t.trim())
                              .where((t) => t.isNotEmpty)
                              .toList();

                          final newPost = ForumPost(
                            id: _generateUUID(),
                            authorName: gardenProvider.username,
                            authorTitle: gardenProvider.userRankTitle,
                            authorAvatar: gardenProvider.avatarUrl.isNotEmpty ? gardenProvider.avatarUrl : null,
                            isVerifiedExpert: false,
                            category: category,
                            title: titleController.text.trim(),
                            content: contentController.text.trim(),
                            tags: rawTags.isNotEmpty ? rawTags : ['#general'],
                            upvotes: 0,
                            isUpvoted: false,
                            comments: [],
                            attachedImagePaths: uploadedUrls,
                            dateTime: DateTime.now(),
                          );

                          setState(() {
                            _posts.insert(0, newPost);
                          });

                          await SupabaseService().createForumPost(newPost);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Post published to Community Forum! 📣'),
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppErrorUtils.getUserFriendlyMessage(e, defaultPrefix: 'Failed to publish post')),
                                backgroundColor: AppTheme.dangerRed,
                              ),
                            );
                          }
                        } finally {
                          setModalState(() {
                            isSubmitting = false;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Publish Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _addReplyRecursive(List<ForumComment> list, String targetId, ForumComment newReply) {
    for (var comment in list) {
      if (comment.id == targetId) {
        comment.replies.add(newReply);
        return true;
      }
      if (comment.replies.isNotEmpty) {
        final success = _addReplyRecursive(comment.replies, targetId, newReply);
        if (success) return true;
      }
    }
    return false;
  }

  void _showCommentsModal(BuildContext context, ForumPost post) {
    final commentController = TextEditingController();
    ForumComment? replyingToComment;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
          final isGuest = gardenProvider.isGuest;

            Widget buildCommentCard(ForumComment comment, {int depth = 0, String? parentAuthorName}) {
              final initials = _getInitials(comment.authorName);
              final avatarBg = _getAvatarBgColor(comment.authorName);
              final timeStr = _formatTimeAgo(comment.dateTime);
              final isOriginalAuthor = comment.authorName == post.authorName;
              final isReply = depth > 0;

              final bool hasCustomAvatar = comment.authorAvatar != null && comment.authorAvatar!.isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isReply ? Colors.white.withValues(alpha: 0.015) : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (hasCustomAvatar)
                          ClipOval(
                            child: buildPlantImage(
                              comment.authorAvatar!,
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: avatarBg,
                            child: Text(
                              initials,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    comment.authorName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12.5),
                                  ),
                                  if (comment.isVerifiedExpert) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified_rounded, size: 13, color: AppTheme.primaryGreen),
                                  ],
                                  if (isOriginalAuthor) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3), width: 0.5),
                                      ),
                                      child: const Text(
                                        'AUTHOR',
                                        style: TextStyle(color: AppTheme.primaryGreen, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                comment.authorTitle,
                                style: const TextStyle(color: Colors.white38, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          timeStr,
                          style: const TextStyle(color: Colors.white24, fontSize: 9.5),
                        ),
                        // Comment options — Edit & Delete for owner or admin
                        if (!isGuest &&
                            (gardenProvider.username == comment.authorName ||
                                gardenProvider.isAdmin))
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              iconSize: 16,
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 16),
                              color: const Color(0xFF1A2420),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditCommentDialog(context, comment, setModalState);
                                } else if (value == 'delete') {
                                  _showDeleteCommentConfirmation(context, post, comment, setModalState);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_rounded, color: Color(0xFF22C55E), size: 16),
                                      SizedBox(width: 8),
                                      Text('Edit', style: TextStyle(color: Colors.white, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 16),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.white, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // High-fidelity rich text mention matching premium social platforms
                    Text.rich(
                      TextSpan(
                        children: [
                          if (isReply && parentAuthorName != null) ...[
                            TextSpan(
                              text: '@$parentAuthorName ',
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                          TextSpan(
                            text: comment.content,
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (isGuest) {
                              _showAuthBarrierDialog(context, 'upvote comments');
                              return;
                            }
                            setModalState(() {
                              if (comment.isUpvoted) {
                                comment.upvotes--;
                                comment.isUpvoted = false;
                              } else {
                                comment.upvotes++;
                                comment.isUpvoted = true;
                              }
                            });
                            setState(() {});
                            SupabaseService().updateForumCommentUpvotes(comment.id, comment.upvotes);
                          },
                          child: Row(
                            children: [
                              Icon(
                                comment.isUpvoted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: comment.isUpvoted ? Colors.redAccent : Colors.white38,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${comment.upvotes}',
                                style: TextStyle(
                                  color: comment.isUpvoted ? Colors.redAccent : Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            if (isGuest) {
                              _showAuthBarrierDialog(context, 'reply to comments');
                              return;
                            }
                            setModalState(() {
                              replyingToComment = comment;
                            });
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.reply_rounded, color: AppTheme.primaryGreen, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Reply',
                                style: TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            Widget buildCommentThread(ForumComment comment, {int depth = 0, String? parentAuthorName, bool isLastInParent = true}) {
              if (depth == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildCommentCard(comment, depth: 0),
                    if (comment.replies.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(comment.replies.length, (index) {
                          final reply = comment.replies[index];
                          final isLastReply = index == comment.replies.length - 1;
                          return buildCommentThread(
                            reply,
                            depth: 1,
                            parentAuthorName: comment.authorName,
                            isLastInParent: isLastReply,
                          );
                        }),
                      ),
                  ],
                );
              } else if (depth == 1 || depth == 2) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 24.0,
                        child: CustomPaint(
                          painter: ThreadConnectorPainter(
                            isLast: isLastInParent,
                            color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            buildCommentCard(comment, depth: depth, parentAuthorName: parentAuthorName),
                            if (comment.replies.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: List.generate(comment.replies.length, (index) {
                                  final reply = comment.replies[index];
                                  final isLastReply = index == comment.replies.length - 1;
                                  return buildCommentThread(
                                    reply,
                                    depth: depth + 1,
                                    parentAuthorName: comment.authorName,
                                    isLastInParent: isLastReply,
                                  );
                                }),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // depth > 2: Cap visual indentation, render without left curves, align with parent (stays at depth 2)
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildCommentCard(comment, depth: depth, parentAuthorName: parentAuthorName),
                    if (comment.replies.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(comment.replies.length, (index) {
                          final reply = comment.replies[index];
                          final isLastReply = index == comment.replies.length - 1;
                          return buildCommentThread(
                            reply,
                            depth: depth + 1,
                            parentAuthorName: comment.authorName,
                            isLastInParent: isLastReply,
                          );
                        }),
                      ),
                  ],
                );
              }
            }

            List<Widget> commentThreads = [];
            for (var comment in post.comments) {
              commentThreads.add(buildCommentThread(comment));
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return AppCard(
                  borderRadius: 30,
                  
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Discussion (${post.comments.length + post.comments.fold<int>(0, (sum, c) => sum + c.replies.length)})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                      ),
                      const Divider(color: Colors.white12, height: 24),
                      Expanded(
                        child: post.comments.isEmpty
                            ? const Center(
                                child: Text('No comments yet. Write the first response!', style: TextStyle(color: Colors.white24, fontSize: 13)),
                              )
                            : ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.only(bottom: 12),
                                children: commentThreads,
                              ),
                      ),
                      if (replyingToComment != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Replying to @${replyingToComment!.authorName}',
                                style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    replyingToComment = null;
                                  });
                                },
                                child: const Icon(Icons.close_rounded, size: 16, color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                          top: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: isGuest
                                    ? () => _showAuthBarrierDialog(context, 'comment on posts')
                                    : null,
                                child: TextField(
                                  controller: commentController,
                                  enabled: !isGuest,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: isGuest
                                        ? '🔒 Sign in or register to join the conversation...'
                                        : (replyingToComment != null
                                            ? 'Replying to @${replyingToComment!.authorName}...'
                                            : 'Write a supportive comment...'),
                                    hintStyle: TextStyle(
                                      color: isGuest ? Colors.white30 : Colors.white24,
                                      fontSize: 12,
                                      fontWeight: isGuest ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.04),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide.none),
                                    suffixIcon: isGuest
                                        ? const Icon(Icons.lock_outline_rounded, color: Colors.white30, size: 18)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.primaryGradient,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                onPressed: () async {
                                  if (isGuest) {
                                    _showAuthBarrierDialog(context, 'comment on posts');
                                    return;
                                  }
                                  if (commentController.text.trim().isEmpty) return;

                                  final newCommentObj = ForumComment(
                                    id: _generateUUID(),
                                    authorName: gardenProvider.username,
                                    authorTitle: gardenProvider.userRankTitle,
                                    authorAvatar: gardenProvider.avatarUrl.isNotEmpty ? gardenProvider.avatarUrl : null,
                                    content: commentController.text.trim(),
                                    dateTime: DateTime.now(),
                                  );
                                  final parentId = replyingToComment?.id;

                                  setModalState(() {
                                    if (replyingToComment != null) {
                                      _addReplyRecursive(post.comments, replyingToComment!.id, newCommentObj);
                                      replyingToComment = null;
                                    } else {
                                      post.comments.add(newCommentObj);
                                    }
                                  });

                                  setState(() {});
                                  commentController.clear();
                                  await SupabaseService().createForumComment(post.id, parentId, newCommentObj);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtered Post list
    final filteredPosts = _posts.where((post) {
      final matchesCat = _selectedCategory == 'All' || post.category == _selectedCategory;
      final matchesSearch = post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          post.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          post.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Forum'),
        actions: [
          IconButton(
            onPressed: () => _showCreatePostSheet(context),
            icon: const Icon(Icons.add_comment_rounded, size: 28, color: AppTheme.primaryGreen),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkBgGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Search & Filter Bars ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search posts, questions or tags...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 12.5),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white12, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Categories Chip List
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategory == cat;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white60,
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryGreen,
                              checkmarkColor: Colors.white,
                              backgroundColor: Colors.white.withValues(alpha: 0.04),
                              shadowColor: Colors.transparent,
                              surfaceTintColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.primaryGreen : Colors.white12,
                                  width: 1.0,
                                ),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ── Forum Posts List ──────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                      )
                    : filteredPosts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        itemCount: filteredPosts.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Load-more footer spinner
                          if (index == filteredPosts.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryGreen,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          final post = filteredPosts[index];
                          final dateStr = DateFormat('MMM dd, hh:mm a').format(post.dateTime);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: AppCard(
                              padding: const EdgeInsets.all(18),
                              borderRadius: 24,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Author details row
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: post.isVerifiedExpert ? AppTheme.primaryGreen : Colors.white12,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: (post.authorAvatar != null && post.authorAvatar!.isNotEmpty)
                                            ? ClipOval(
                                                child: buildPlantImage(
                                                  post.authorAvatar!,
                                                  width: 36,
                                                  height: 36,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : CircleAvatar(
                                                radius: 18,
                                                backgroundColor: post.isVerifiedExpert 
                                                    ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                                                    : Colors.white.withValues(alpha: 0.04),
                                                child: Icon(
                                                  post.isVerifiedExpert ? Icons.verified_user_rounded : Icons.person_rounded,
                                                  size: 16,
                                                  color: post.isVerifiedExpert ? AppTheme.primaryGreen : Colors.white60,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  post.authorName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5),
                                                ),
                                                if (post.isVerifiedExpert) ...[
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.verified_rounded, size: 14, color: AppTheme.primaryGreen),
                                                ],
                                              ],
                                            ),
                                            Text(
                                              post.authorTitle,
                                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(color: Colors.white24, fontSize: 10),
                                      ),
                                      const SizedBox(width: 4),
                                      // Post options menu — Edit & Delete for owner/admin; Report for others
                                      Consumer<GardenProvider>(
                                        builder: (ctx, gp, _) {
                                          final canModify = !gp.isGuest &&
                                              (gp.username == post.authorName || gp.isAdmin);
                                          return PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 18),
                                            color: const Color(0xFF1A2420),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            onSelected: (value) {
                                              if (value == 'edit') _showEditPostSheet(context, post);
                                              if (value == 'delete') _showDeletePostConfirmation(context, post);
                                              if (value == 'report') _showReportDialog(context, post, gp);
                                            },
                                            itemBuilder: (_) => [
                                              if (canModify) ...[
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit_rounded, color: Color(0xFF22C55E), size: 16),
                                                      SizedBox(width: 8),
                                                      Text('Edit Post', style: TextStyle(color: Colors.white, fontSize: 13)),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 16),
                                                      SizedBox(width: 8),
                                                      Text('Delete Post', style: TextStyle(color: Colors.white, fontSize: 13)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              if (!gp.isGuest && !canModify)
                                                const PopupMenuItem(
                                                  value: 'report',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.flag_rounded, color: Color(0xFFEF4444), size: 16),
                                                      SizedBox(width: 8),
                                                      Text('Report Post', style: TextStyle(color: Colors.white, fontSize: 13)),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.white10, height: 24),

                                  // Post title & Category Tag
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                          
                                        ),
                                        child: Text(
                                          post.category.toUpperCase(),
                                          style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          post.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Post Content
                                  Text(
                                    post.content,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.45),
                                  ),
                                  const SizedBox(height: 12),

                                  // Post Attached Images
                                  if (post.attachedImagePaths.isNotEmpty) ...[
                                    if (post.attachedImagePaths.length == 1) ...[
                                      GestureDetector(
                                        onTap: () => _showImageLightbox(context, post.attachedImagePaths, 0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            height: 200,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              
                                            ),
                                            child: post.attachedImagePaths.first.startsWith('assets/') || !post.attachedImagePaths.first.contains('/')
                                                ? Image.asset(post.attachedImagePaths.first, fit: BoxFit.cover)
                                                : buildPlantImage(post.attachedImagePaths.first, fit: BoxFit.cover),
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      SizedBox(
                                        height: 150,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: post.attachedImagePaths.length,
                                          itemBuilder: (context, imgIdx) {
                                            final imgPath = post.attachedImagePaths[imgIdx];
                                            final isAsset = imgPath.startsWith('assets/') || !imgPath.contains('/');
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 12.0),
                                              child: GestureDetector(
                                                onTap: () => _showImageLightbox(context, post.attachedImagePaths, imgIdx),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(16),
                                                  child: Container(
                                                    width: 220,
                                                    decoration: BoxDecoration(
                                                      
                                                    ),
                                                    child: isAsset
                                                        ? Image.asset(imgPath, fit: BoxFit.cover)
                                                        : buildPlantImage(imgPath, fit: BoxFit.cover),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                  ],

                                  // Post Tags
                                  Row(
                                    children: post.tags.map((tag) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 10.0),
                                        child: Text(
                                          tag,
                                          style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const Divider(color: Colors.white10, height: 24),

                                  // Interaction details
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Upvote Button
                                      GestureDetector(
                                        onTap: () {
                                          final isGuest = Provider.of<GardenProvider>(context, listen: false).isGuest;
                                          if (isGuest) {
                                            _showAuthBarrierDialog(context, 'upvote community posts');
                                            return;
                                          }
                                          setState(() {
                                            if (post.isUpvoted) {
                                              post.upvotes--;
                                              post.isUpvoted = false;
                                            } else {
                                              post.upvotes++;
                                              post.isUpvoted = true;
                                            }
                                          });
                                          SupabaseService().updateForumPostUpvotes(post.id, post.upvotes);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: post.isUpvoted 
                                                ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                                                : Colors.white.withValues(alpha: 0.03),
                                            borderRadius: BorderRadius.circular(100),
                                            border: Border.all(
                                              color: post.isUpvoted 
                                                  ? AppTheme.primaryGreen.withValues(alpha: 0.4)
                                                  : Colors.white12,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                post.isUpvoted ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                                                color: post.isUpvoted ? AppTheme.primaryGreen : Colors.white60,
                                                size: 15,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${post.upvotes}',
                                                style: TextStyle(
                                                  color: post.isUpvoted ? AppTheme.primaryGreen : Colors.white70,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Comments Button
                                      GestureDetector(
                                        onTap: () => _showCommentsModal(context, post),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.03),
                                            borderRadius: BorderRadius.circular(100),
                                            border: Border.all(color: Colors.white12, width: 1.0),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.mode_comment_outlined, color: Colors.white60, size: 15),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${post.comments.length} Comments',
                                                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fade(delay: (index * 50).ms, duration: 450.ms).slideY(begin: 0.05);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 60,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No posts found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white60),
            ),
            const SizedBox(height: 8),
            const Text(
              'Be the first to share gardening questions or knowledge. Tap the plus button at the top right to write a new post!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white30, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
