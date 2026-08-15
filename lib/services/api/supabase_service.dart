import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../models/diagnosis_report.dart';
import '../../models/forum_post.dart';
import '../../models/shop_product.dart';
import '../database_service.dart';
import '../image_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;

  bool get isConfigured => _isInitialized;

  /// Initializes Supabase lazily and signs in anonymously
  Future<void> init(String url, String anonKey) async {
    if (url.isEmpty || anonKey.isEmpty) return;
    try {
      // If already initialized with different keys, we should re-initialize.
      // But supabase_flutter doesn't support easy re-initialization directly without closing/resetting.
      // We can use Supabase.initialize if not already initialized.
      if (!_isInitialized) {
        // kIsWeb / some environments don't support Platform.environment —
        // wrap in a try/catch so initialization never fails because of this.
        bool isTesting = false;
        try {
          isTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
        } catch (_) {}
        await Supabase.initialize(
          url: url,
          anonKey: anonKey,
          authOptions: FlutterAuthClientOptions(
            autoRefreshToken: !isTesting,
          ),
        );
        _isInitialized = true;
        debugPrint("⚡ Supabase Service initialized successfully!");
        
        // Auto-seed the database if it is empty to ensure maximum user-experience & premium completeness!
        await seedDatabaseIfEmpty();
      }
    } catch (e) {
      debugPrint("⚠️ Supabase initialization failed/skipped: $e");
      // It might already be initialized. If so, we set _isInitialized to true.
      if (e.toString().contains("has already been initialized")) {
        _isInitialized = true;
      }
    }
  }

  SupabaseClient get client {
    if (!_isInitialized) {
      throw Exception("Supabase is not configured. Please add your credentials in Settings.");
    }
    return Supabase.instance.client;
  }

  /// Look up a disease report in Supabase (case-insensitive check)
  Future<DiagnosisReport?> fetchDiseaseReport({
    required String plantName,
    required String diseaseName,
    required String reportId,
    required String imagePath,
  }) async {
    if (!_isInitialized) return null;

    try {
      final response = await client
          .from('plant_diseases')
          .select()
          .ilike('plant_name', plantName.trim())
          .ilike('disease_name', diseaseName.trim())
          .maybeSingle();

      if (response == null) {
        debugPrint("🔍 Supabase cache miss for: $plantName - $diseaseName");
        return null;
      }

      debugPrint("🔍 Supabase cache hit! Loading expert data for: $plantName - $diseaseName");
      
      // Convert columns from list/JSON dynamic to List<String>
      final symptoms = List<String>.from(response['symptoms'] ?? []);
      final treatment = List<String>.from(response['treatment'] ?? []);
      final prevention = List<String>.from(response['prevention'] ?? []);

      return DiagnosisReport(
        id: reportId,
        source: "Official Pathology Report",
        plantName: response['plant_name'] ?? plantName,
        diseaseName: response['disease_name'] ?? diseaseName,
        confidence: response['confidence'] != null ? (response['confidence'] as num).toDouble() : 0.97,
        severity: response['severity'] ?? "Moderate",
        description: response['description'] ?? "",
        symptoms: symptoms,
        treatment: treatment,
        prevention: prevention,
        imagePath: imagePath,
        dateTime: DateTime.now(),
        isOfflineResult: false,
      );
    } catch (e) {
      debugPrint("⚠️ Supabase lookup failed: $e");
      return null;
    }
  }

  /// Save a new disease report to Supabase for future use (caching)
  Future<void> saveDiseaseReport(DiagnosisReport report) async {
    if (!_isInitialized) return;

    try {
      // Upsert based on plant_name and disease_name unique index
      await client.from('plant_diseases').upsert({
        'plant_name': report.plantName.trim(),
        'disease_name': report.diseaseName.trim(),
        'severity': report.severity,
        'description': report.description,
        'symptoms': report.symptoms,
        'treatment': report.treatment,
        'prevention': report.prevention,
      }, onConflict: 'plant_name, disease_name');
      
      debugPrint("💾 Successfully cached diagnosis to Supabase: ${report.plantName} - ${report.diseaseName}");
    } catch (e) {
      debugPrint("⚠️ Failed to cache report in Supabase: $e");
    }
  }

  /// Seed database automatically with standard items from treatment_data.json if empty
  Future<void> seedDatabaseIfEmpty() async {
    if (!_isInitialized) return;

    try {
      // Check if table is empty
      final countResponse = await client
          .from('plant_diseases')
          .select('id')
          .limit(1);

      if (countResponse.isNotEmpty) {
        debugPrint("📚 Supabase plant database already seeded. Skipping initial seeding.");
        return;
      }

      debugPrint("🚚 Seeding Supabase database with default plant disease templates from assets...");
      final jsonString = await rootBundle.loadString(AppConstants.treatmentDataPath);
      final Map<String, dynamic> dataMap = json.decode(jsonString);

      final List<Map<String, dynamic>> recordsToInsert = [];
      dataMap.forEach((key, val) {
        recordsToInsert.add({
          'plant_name': val['species'] ?? '',
          'disease_name': val['name'] ?? '',
          'severity': val['severity'] ?? 'Moderate',
          'description': val['description'] ?? '',
          'symptoms': List<String>.from(val['symptoms'] ?? []),
          'treatment': List<String>.from(val['treatment'] ?? []),
          'prevention': List<String>.from(val['prevention'] ?? []),
        });
      });

      // Insert all records in bulk
      if (recordsToInsert.isNotEmpty) {
        await client.from('plant_diseases').insert(recordsToInsert);
        debugPrint("🌱 Successfully seeded ${recordsToInsert.length} plant records into Supabase!");
      }
    } catch (e) {
      debugPrint("⚠️ Supabase auto-seeding encountered an issue: $e");
    }

    // Seed the shop products table too
    await seedShopProductsIfEmpty();
  }

  /// Fetch all forum posts with their comments and nested replies
  Future<List<ForumPost>> fetchForumPosts() async {
    if (!_isInitialized) return [];

    try {
      // Fetch all posts from Supabase (ordered by created_at descending)
      final postsData = await client
          .from('forum_posts')
          .select()
          .order('created_at', ascending: false);

      // Fetch all comments from Supabase
      final commentsData = await client
          .from('forum_comments')
          .select()
          .order('created_at', ascending: true);

      // Reconstruct Comments Hierarchy
      final Map<String, ForumComment> commentMap = {};
      final List<ForumComment> allComments = [];

      for (var c in commentsData) {
        final commentId = c['id'] as String;
        final commentObj = ForumComment(
          id: commentId,
          authorName: c['author_name'] ?? 'Gardener',
          authorTitle: c['author_title'] ?? 'Gardener',
          isVerifiedExpert: c['is_verified_expert'] ?? false,
          content: c['content'] ?? '',
          dateTime: DateTime.tryParse(c['created_at'] ?? '') ?? DateTime.now(),
          upvotes: c['upvotes'] ?? 0,
          replies: [],
        );
        commentMap[commentId] = commentObj;
        allComments.add(commentObj);
      }

      // Distribute comments to their parents (either replies or top-level comments of a post)
      final Map<String, List<ForumComment>> postCommentsMap = {};

      for (int i = 0; i < commentsData.length; i++) {
        final cData = commentsData[i];
        final commentObj = allComments[i];
        final postId = cData['post_id'] as String;
        final parentId = cData['parent_comment_id'] as String?;

        if (parentId != null && commentMap.containsKey(parentId)) {
          commentMap[parentId]!.replies.add(commentObj);
        } else {
          postCommentsMap.putIfAbsent(postId, () => []).add(commentObj);
        }
      }

      // Reconstruct Post objects
      final List<ForumPost> posts = [];
      for (var p in postsData) {
        final postId = p['id'] as String;
        final tagsDynamic = p['tags'] ?? [];
        final List<String> tags = List<String>.from(tagsDynamic);
        final attachedImagesDynamic = p['attached_image_paths'] ?? [];
        final List<String> attachedImages = List<String>.from(attachedImagesDynamic);

        posts.add(ForumPost(
          id: postId,
          authorName: p['author_name'] ?? 'Gardener',
          authorTitle: p['author_title'] ?? 'Gardener',
          authorAvatar: p['author_avatar'] as String? ?? p['author_avatar_url'] as String?,
          isVerifiedExpert: p['is_verified_expert'] ?? false,
          category: p['category'] ?? 'General',
          title: p['title'] ?? '',
          content: p['content'] ?? '',
          tags: tags,
          upvotes: p['upvotes'] ?? 0,
          comments: postCommentsMap[postId] ?? [],
          attachedImagePaths: attachedImages,
          diagnosisName: p['diagnosis_name'],
          dateTime: DateTime.tryParse(p['created_at'] ?? '') ?? DateTime.now(),
        ));
      }

      // Fetch user's upvoted posts and comments directly from Supabase cloud database
      final upvotedPostIds = await fetchUserUpvotedPostIds();
      final upvotedCommentIds = await fetchUserUpvotedCommentIds();

      for (var post in posts) {
        post.isUpvoted = upvotedPostIds.contains(post.id);
        _applyCommentUpvoteState(post.comments, upvotedCommentIds);
      }

      return posts;
    } catch (e) {
      debugPrint("⚠️ Failed to fetch forum posts from Supabase: $e");
      return [];
    }
  }

  /// Fetches the set of post IDs upvoted by the currently logged-in user from Supabase.
  Future<Set<String>> fetchUserUpvotedPostIds() async {
    final prefs = await SharedPreferences.getInstance();
    final localIds = (prefs.getStringList('pref_upvoted_post_ids') ?? []).toSet();

    if (!_isInitialized) return localIds;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return localIds;

    try {
      final response = await client
          .from('forum_post_likes')
          .select('post_id')
          .eq('user_id', userId);
      final Set<String> cloudIds = (response as List).map<String>((row) => row['post_id'] as String).toSet();
      final combined = cloudIds.union(localIds);
      await prefs.setStringList('pref_upvoted_post_ids', combined.toList());
      return combined;
    } catch (e) {
      debugPrint("⚠️ Could not fetch user upvoted post IDs from Supabase table: $e");
      return localIds;
    }
  }

  /// Fetches the set of comment IDs upvoted by the currently logged-in user from Supabase.
  Future<Set<String>> fetchUserUpvotedCommentIds() async {
    final prefs = await SharedPreferences.getInstance();
    final localIds = (prefs.getStringList('pref_upvoted_comment_ids') ?? []).toSet();

    if (!_isInitialized) return localIds;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return localIds;

    try {
      final response = await client
          .from('forum_comment_likes')
          .select('comment_id')
          .eq('user_id', userId);
      final Set<String> cloudIds = (response as List).map<String>((row) => row['comment_id'] as String).toSet();
      final combined = cloudIds.union(localIds);
      await prefs.setStringList('pref_upvoted_comment_ids', combined.toList());
      return combined;
    } catch (e) {
      debugPrint("⚠️ Could not fetch user upvoted comment IDs from Supabase table: $e");
      return localIds;
    }
  }

  /// Toggles post upvote in Supabase database. Ensures one-like-per-user enforcement.
  Future<Map<String, dynamic>> togglePostUpvote(String postId, bool currentIsUpvoted, int currentUpvotes) async {
    final bool newIsUpvoted = !currentIsUpvoted;
    final int newUpvotes = newIsUpvoted ? currentUpvotes + 1 : (currentUpvotes - 1).clamp(0, 99999);

    if (!_isInitialized) {
      return {'isUpvoted': newIsUpvoted, 'upvotes': newUpvotes};
    }

    final userId = client.auth.currentUser?.id;

    try {
      if (userId != null) {
        if (newIsUpvoted) {
          await client.from('forum_post_likes').upsert({
            'user_id': userId,
            'post_id': postId,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id,post_id');
        } else {
          await client
              .from('forum_post_likes')
              .delete()
              .eq('user_id', userId)
              .eq('post_id', postId);
        }
      }

      await client.from('forum_posts').update({'upvotes': newUpvotes}).eq('id', postId);

      // Local prefs cache update for smooth UI
      final prefs = await SharedPreferences.getInstance();
      List<String> upvotedPostIds = prefs.getStringList('pref_upvoted_post_ids') ?? [];
      if (newIsUpvoted) {
        if (!upvotedPostIds.contains(postId)) upvotedPostIds.add(postId);
      } else {
        upvotedPostIds.remove(postId);
      }
      await prefs.setStringList('pref_upvoted_post_ids', upvotedPostIds);

      debugPrint("👍 Post $postId upvote toggled in Supabase cloud: isUpvoted=$newIsUpvoted, upvotes=$newUpvotes");
    } catch (e) {
      debugPrint("⚠️ Error toggling post upvote in Supabase cloud: $e");
      await updateForumPostUpvotes(postId, newUpvotes);
    }

    return {'isUpvoted': newIsUpvoted, 'upvotes': newUpvotes};
  }

  /// Toggles comment upvote in Supabase database. Ensures one-like-per-user enforcement.
  Future<Map<String, dynamic>> toggleCommentUpvote(String commentId, bool currentIsUpvoted, int currentUpvotes) async {
    final bool newIsUpvoted = !currentIsUpvoted;
    final int newUpvotes = newIsUpvoted ? currentUpvotes + 1 : (currentUpvotes - 1).clamp(0, 99999);

    if (!_isInitialized) {
      return {'isUpvoted': newIsUpvoted, 'upvotes': newUpvotes};
    }

    final userId = client.auth.currentUser?.id;

    try {
      if (userId != null) {
        if (newIsUpvoted) {
          await client.from('forum_comment_likes').upsert({
            'user_id': userId,
            'comment_id': commentId,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id,comment_id');
        } else {
          await client
              .from('forum_comment_likes')
              .delete()
              .eq('user_id', userId)
              .eq('comment_id', commentId);
        }
      }

      await client.from('forum_comments').update({'upvotes': newUpvotes}).eq('id', commentId);

      // Local prefs cache update for smooth UI
      final prefs = await SharedPreferences.getInstance();
      List<String> upvotedCommentIds = prefs.getStringList('pref_upvoted_comment_ids') ?? [];
      if (newIsUpvoted) {
        if (!upvotedCommentIds.contains(commentId)) upvotedCommentIds.add(commentId);
      } else {
        upvotedCommentIds.remove(commentId);
      }
      await prefs.setStringList('pref_upvoted_comment_ids', upvotedCommentIds);

      debugPrint("💖 Comment $commentId upvote toggled in Supabase cloud: isUpvoted=$newIsUpvoted, upvotes=$newUpvotes");
    } catch (e) {
      debugPrint("⚠️ Error toggling comment upvote in Supabase cloud: $e");
      await updateForumCommentUpvotes(commentId, newUpvotes);
    }

    return {'isUpvoted': newIsUpvoted, 'upvotes': newUpvotes};
  }

  static void _applyCommentUpvoteState(List<ForumComment> comments, Set<String> upvotedCommentIds) {
    for (var c in comments) {
      c.isUpvoted = upvotedCommentIds.contains(c.id);
      if (c.replies.isNotEmpty) {
        _applyCommentUpvoteState(c.replies, upvotedCommentIds);
      }
    }
  }

  /// Create a new forum post directly in Supabase
  Future<void> createForumPost(ForumPost post) async {
    if (!_isInitialized) return;
    try {
      final userId = client.auth.currentUser?.id;
      final Map<String, dynamic> data = {
        'id': post.id,
        'author_name': post.authorName,
        'author_title': post.authorTitle,
        'author_avatar': post.authorAvatar,
        'is_verified_expert': post.isVerifiedExpert,
        'category': post.category,
        'title': post.title,
        'content': post.content,
        'tags': post.tags,
        'upvotes': post.upvotes,
        'attached_image_paths': post.attachedImagePaths,
        'diagnosis_name': post.diagnosisName,
        'created_at': post.dateTime.toUtc().toIso8601String(),
      };
      if (userId != null) {
        data['user_id'] = userId;
      }
      await client.from('forum_posts').upsert(data, onConflict: 'id');
      debugPrint("💬 Forum post ${post.id} synced directly to Supabase.");
    } catch (e) {
      debugPrint("⚠️ Failed to create forum post in Supabase: $e");
      rethrow;
    }
  }

  /// Create a new forum comment/reply directly in Supabase
  Future<void> createForumComment(String postId, String? parentCommentId, ForumComment comment) async {
    if (!_isInitialized) return;
    try {
      final userId = client.auth.currentUser?.id;

      // 1. If commenting on a default curated post (e.g. 'def_post_1'), ensure the post is synced to Supabase first
      if (postId.startsWith('def_')) {
        try {
          final defPost = ForumPost.defaultPosts.firstWhere((p) => p.id == postId);
          await createForumPost(defPost);
        } catch (postSyncErr) {
          debugPrint("⚠️ Could not pre-sync default post $postId: $postSyncErr");
        }
      }

      // 2. Clean parentCommentId. If replying to a default comment (e.g. 'def_comm_1'), pre-sync parent comment
      String? cleanParentId = (parentCommentId != null && parentCommentId.trim().isNotEmpty)
          ? parentCommentId.trim()
          : null;

      if (cleanParentId != null && cleanParentId.startsWith('def_')) {
        try {
          ForumComment? targetDefComm;
          for (var p in ForumPost.defaultPosts) {
            for (var c in p.comments) {
              if (c.id == cleanParentId) {
                targetDefComm = c;
                break;
              }
              for (var r in c.replies) {
                if (r.id == cleanParentId) {
                  targetDefComm = r;
                  break;
                }
              }
            }
          }
          if (targetDefComm != null) {
            final Map<String, dynamic> defCommData = {
              'id': targetDefComm.id,
              'post_id': postId,
              'parent_comment_id': null,
              'author_name': targetDefComm.authorName,
              'author_title': targetDefComm.authorTitle,
              'author_avatar': targetDefComm.authorAvatar,
              'is_verified_expert': targetDefComm.isVerifiedExpert,
              'content': targetDefComm.content,
              'upvotes': targetDefComm.upvotes,
              'created_at': targetDefComm.dateTime.toUtc().toIso8601String(),
            };
            if (userId != null) defCommData['user_id'] = userId;
            await client.from('forum_comments').upsert(defCommData, onConflict: 'id');
          }
        } catch (commSyncErr) {
          debugPrint("⚠️ Could not pre-sync default comment $cleanParentId: $commSyncErr");
          cleanParentId = null;
        }
      }

      final Map<String, dynamic> data = {
        'id': comment.id,
        'post_id': postId,
        'parent_comment_id': cleanParentId,
        'author_name': comment.authorName,
        'author_title': comment.authorTitle,
        'author_avatar': comment.authorAvatar,
        'is_verified_expert': comment.isVerifiedExpert,
        'content': comment.content,
        'upvotes': comment.upvotes,
        'created_at': comment.dateTime.toUtc().toIso8601String(),
      };
      if (userId != null) {
        data['user_id'] = userId;
      }
      await client.from('forum_comments').upsert(data, onConflict: 'id');
      debugPrint("💬 Forum comment/reply ${comment.id} (parentId: $cleanParentId) synced directly to Supabase.");
    } catch (e) {
      debugPrint("⚠️ Failed to create forum comment in Supabase: $e");
      rethrow;
    }
  }

  /// Fetch forum posts with pagination support
  Future<List<ForumPost>> fetchForumPostsPaginated({int page = 0, int pageSize = 10}) async {
    if (!_isInitialized) return [];
    try {
      final int from = page * pageSize;
      final int to = from + pageSize - 1;

      final postsData = await client
          .from('forum_posts')
          .select()
          .order('created_at', ascending: false)
          .range(from, to);

      if (postsData.isEmpty) return [];

      final List<String> postIds = postsData.map<String>((p) => p['id'] as String).toList();
      final commentsData = await client
          .from('forum_comments')
          .select()
          .inFilter('post_id', postIds)
          .order('created_at', ascending: true);

      final Map<String, ForumComment> commentMap = {};
      final List<ForumComment> allComments = [];

      for (var c in commentsData) {
        final commentId = c['id'] as String;
        final commentObj = ForumComment(
          id: commentId,
          authorName: c['author_name'] ?? 'Gardener',
          authorTitle: c['author_title'] ?? 'Gardener',
          authorAvatar: c['author_avatar'] as String? ?? c['author_avatar_url'] as String?,
          isVerifiedExpert: c['is_verified_expert'] ?? false,
          content: c['content'] ?? '',
          dateTime: DateTime.tryParse(c['created_at'] ?? '') ?? DateTime.now(),
          upvotes: c['upvotes'] ?? 0,
          replies: [],
        );
        commentMap[commentId] = commentObj;
        allComments.add(commentObj);
      }

      final Map<String, List<ForumComment>> postCommentsMap = {};
      for (int i = 0; i < commentsData.length; i++) {
        final cData = commentsData[i];
        final commentObj = allComments[i];
        final postId = cData['post_id'] as String;
        final parentId = cData['parent_comment_id'] as String?;

        if (parentId != null && commentMap.containsKey(parentId)) {
          commentMap[parentId]!.replies.add(commentObj);
        } else {
          postCommentsMap.putIfAbsent(postId, () => []).add(commentObj);
        }
      }

      final List<ForumPost> posts = [];
      for (var p in postsData) {
        final postId = p['id'] as String;
        final List<String> tags = List<String>.from(p['tags'] ?? []);
        final List<String> attachedImages = List<String>.from(p['attached_image_paths'] ?? []);

        posts.add(ForumPost(
          id: postId,
          authorName: p['author_name'] ?? 'Gardener',
          authorTitle: p['author_title'] ?? 'Gardener',
          authorAvatar: p['author_avatar'] as String? ?? p['author_avatar_url'] as String?,
          isVerifiedExpert: p['is_verified_expert'] ?? false,
          category: p['category'] ?? 'General',
          title: p['title'] ?? '',
          content: p['content'] ?? '',
          tags: tags,
          upvotes: p['upvotes'] ?? 0,
          comments: postCommentsMap[postId] ?? [],
          attachedImagePaths: attachedImages,
          diagnosisName: p['diagnosis_name'],
          dateTime: DateTime.tryParse(p['created_at'] ?? '') ?? DateTime.now(),
        ));
      }

      // Fetch user's upvoted posts and comments directly from Supabase cloud database
      final upvotedPostIds = await fetchUserUpvotedPostIds();
      final upvotedCommentIds = await fetchUserUpvotedCommentIds();

      for (var post in posts) {
        post.isUpvoted = upvotedPostIds.contains(post.id);
        _applyCommentUpvoteState(post.comments, upvotedCommentIds);
      }

      // Cache paginated posts to SQLite
      await DatabaseService.saveForumPosts(posts);

      return posts;
    } catch (e) {
      debugPrint('⚠️ Failed to fetch paginated forum posts: $e — returning local cache.');
      final localPosts = await DatabaseService.getForumPosts();
      if (localPosts.isNotEmpty) {
        final int from = page * pageSize;
        if (from >= localPosts.length) return [];
        final int to = (from + pageSize > localPosts.length) ? localPosts.length : from + pageSize;
        return localPosts.sublist(from, to);
      }
      return [];
    }
  }

  /// Report a forum post for moderation
  Future<void> reportForumPost({
    required String postId,
    required String reporterName,
    required String reason,
  }) async {
    if (!_isInitialized) return;
    try {
      await client.from('forum_reports').insert({
        'post_id': postId,
        'reporter_name': reporterName,
        'reason': reason,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('🚩 Post reported: $postId by $reporterName');
    } catch (e) {
      debugPrint('⚠️ Failed to report post: $e');
    }
  }

  /// Update a forum post's upvotes count
  Future<void> updateForumPostUpvotes(String postId, int upvotes) async {
    if (!_isInitialized) return;
    try {
      await client.from('forum_posts').update({
        'upvotes': upvotes,
      }).eq('id', postId);
    } catch (e) {
      debugPrint("⚠️ Failed to update forum post upvotes in Supabase: $e");
    }
  }

  /// Update a forum comment's upvotes count
  Future<void> updateForumCommentUpvotes(String commentId, int upvotes) async {
    if (!_isInitialized) return;
    try {
      await client.from('forum_comments').update({
        'upvotes': upvotes,
      }).eq('id', commentId);
    } catch (e) {
      debugPrint("⚠️ Failed to update forum comment upvotes in Supabase: $e");
    }
  }

  // ── Owner / Admin Content Management ────────────────────────────────────

  /// Permanently deletes a forum post and any associated images from Supabase Storage.
  Future<void> deleteForumPost(String postId) async {
    if (!_isInitialized) return;
    try {
      // First fetch post to retrieve attached image paths
      final response = await client
          .from('forum_posts')
          .select('attached_image_paths')
          .eq('id', postId)
          .maybeSingle();

      if (response != null && response['attached_image_paths'] != null) {
        final List<String> images = List<String>.from(response['attached_image_paths']);
        if (images.isNotEmpty) {
          await ImageService.deleteStorageFilesByUrls(images);
        }
      }

      await client.from('forum_posts').delete().eq('id', postId);
      debugPrint('🗑️ Forum post $postId deleted along with its storage images.');
    } catch (e) {
      debugPrint('⚠️ Failed to delete forum post: $e');
    }
  }

  /// Deletes a user profile and all associated user images (avatar & post images) from Supabase Storage.
  Future<void> deleteUserProfile(String userId) async {
    if (!_isInitialized) return;
    try {
      // 1. Fetch user profile to check avatar URL
      final profile = await client
          .from('user_profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (profile != null && profile['avatar_url'] != null) {
        final avatarUrl = profile['avatar_url'] as String;
        if (avatarUrl.isNotEmpty) {
          await ImageService.deleteStorageFileByUrl(avatarUrl);
        }
      }

      // 2. Fetch all user posts to delete post images from storage
      final userPosts = await client
          .from('forum_posts')
          .select('id, attached_image_paths')
          .eq('user_id', userId);

      for (var post in userPosts) {
        if (post['attached_image_paths'] != null) {
          final List<String> images = List<String>.from(post['attached_image_paths']);
          if (images.isNotEmpty) {
            await ImageService.deleteStorageFilesByUrls(images);
          }
        }
      }

      // 3. Delete user posts (comments cascade via DB foreign key)
      await client.from('forum_posts').delete().eq('user_id', userId);

      // 4. Delete user profile row
      await client.from('user_profiles').delete().eq('id', userId);

      debugPrint("🗑️ User profile $userId and associated storage images deleted.");
    } catch (e) {
      debugPrint("⚠️ Failed to delete user profile and images: $e");
    }
  }

  /// Updates editable content fields of an existing forum post.
  Future<void> updateForumPost(
    String postId, {
    required String title,
    required String content,
    required String category,
    required List<String> tags,
  }) async {
    if (!_isInitialized) return;
    try {
      await client.from('forum_posts').update({
        'title': title,
        'content': content,
        'category': category,
        'tags': tags,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', postId);
      debugPrint('✏️ Forum post $postId updated.');
    } catch (e) {
      debugPrint('⚠️ Failed to update forum post: $e');
    }
  }

  /// Permanently deletes a forum comment (replies cascade via DB foreign key).
  Future<void> deleteForumComment(String commentId) async {
    if (!_isInitialized) return;
    try {
      await client.from('forum_comments').delete().eq('id', commentId);
      debugPrint('🗑️ Forum comment $commentId deleted.');
    } catch (e) {
      debugPrint('⚠️ Failed to delete forum comment: $e');
    }
  }

  /// Updates the text content of an existing forum comment.
  Future<void> updateForumComment(String commentId, String newContent) async {
    if (!_isInitialized) return;
    try {
      await client.from('forum_comments').update({
        'content': newContent,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', commentId);
      debugPrint('✏️ Forum comment $commentId updated.');
    } catch (e) {
      debugPrint('⚠️ Failed to update forum comment: $e');
    }
  }

  /// Sync user profile to Supabase user_profiles table.
  /// Columns: id, username, avatar_url, role, gemini_api_key (admin only), joined_at, updated_at.
  Future<void> syncUserProfile({
    required String id,
    required String username,
    String avatarUrl = '',
    String role = 'user',
    String? geminiApiKey,
    bool isNewUser = false,
  }) async {
    if (!_isInitialized) return;
    try {
      final Map<String, dynamic> data = {
        'id': id,
        'username': username,
        'avatar_url': avatarUrl,
        'role': role,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (isNewUser) {
        data['joined_at'] = DateTime.now().toUtc().toIso8601String();
      }
      // Only admins can write gemini_api_key
      if (role == 'admin' && geminiApiKey != null) {
        data['gemini_api_key'] = geminiApiKey;
      }
      await client.from('user_profiles').upsert(
        data,
        onConflict: 'id',
        ignoreDuplicates: false,
      );
      debugPrint("👤 Successfully synced user profile to Supabase: $username (role: $role)");
    } catch (e) {
      debugPrint("⚠️ Failed to sync user profile: $e");
    }
  }

  /// Fetches the global Gemini API key stored by the admin in their profile.
  /// Returns null if no admin has set a key yet.
  Future<String?> fetchGlobalGeminiKey() async {
    if (!_isInitialized) return null;
    try {
      final response = await client
          .from('user_profiles')
          .select('gemini_api_key')
          .eq('role', 'admin')
          .not('gemini_api_key', 'is', null)
          .limit(1)
          .maybeSingle();
      final key = response?['gemini_api_key'] as String?;
      if (key != null && key.isNotEmpty) {
        debugPrint("🔑 Fetched global Gemini API key from admin profile.");
        return key;
      }
      return null;
    } catch (e) {
      debugPrint("⚠️ Failed to fetch global Gemini key: $e");
      return null;
    }
  }

  /// Allows the admin user to update the global Gemini API key.
  Future<bool> updateAdminGeminiKey(String userId, String newKey) async {
    if (!_isInitialized) return false;
    try {
      await client
          .from('user_profiles')
          .update({
            'gemini_api_key': newKey,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId)
          .eq('role', 'admin');
      debugPrint("✅ Admin Gemini API key updated successfully.");
      return true;
    } catch (e) {
      debugPrint("⚠️ Failed to update admin Gemini key: $e");
      return false;
    }
  }

  // ── Shop & Affiliation Supabase APIs ────────────────────────────────

  /// Fetches shop products from the Supabase shop_products table.
  /// Falls back to local [ShopProduct.defaultProducts] on any error.
  Future<List<ShopProduct>> fetchShopProducts() async {
    if (!_isInitialized) {
      debugPrint('🔌 Supabase not configured. Using offline default products.');
      return ShopProduct.defaultProducts;
    }
    try {
      final response = await client
          .from('shop_products')
          .select()
          .order('review_count', ascending: false)
          .limit(50);

      if (response.isEmpty) {
        debugPrint('🛍️ shop_products table is empty. Using local defaults.');
        return ShopProduct.defaultProducts;
      }

      final remoteProducts = response
          .map((item) => ShopProduct.fromJson(item))
          .toList();

      final defaultMap = {for (var p in ShopProduct.defaultProducts) p.id: p};

      // Always prioritize our verified local catalog items with pristine asset photos and valid ASINs
      final List<ShopProduct> merged = [];
      for (var defaultProd in ShopProduct.defaultProducts) {
        merged.add(defaultProd);
      }
      for (var remote in remoteProducts) {
        if (!defaultMap.containsKey(remote.id)) {
          merged.add(remote);
        }
      }

      debugPrint('🛍️ Loaded ${merged.length} products (authoritative local catalog prioritized).');
      return merged;
    } catch (e) {
      debugPrint('⚠️ shop_products fetch failed: $e. Using local defaults.');
      return ShopProduct.defaultProducts;
    }
  }


  /// Ensures the public Supabase Storage bucket 'shop_products' exists.
  Future<void> ensureShopStorageBucket() async {
    if (!_isInitialized) return;
    try {
      final buckets = await client.storage.listBuckets();
      final exists = buckets.any((b) => b.name == 'shop_products');
      if (!exists) {
        await client.storage.createBucket(
          'shop_products',
          const BucketOptions(public: true),
        );
        debugPrint("🪣 Created public Supabase Storage bucket 'shop_products'");
      }
    } catch (e) {
      debugPrint("⚠️ Supabase Storage bucket check/creation skipped: $e");
    }
  }

  /// Seeds default products to Supabase shop_products table if it exists and is empty.
  Future<void> seedShopProductsIfEmpty() async {
    if (!_isInitialized) return;
    await ensureShopStorageBucket();
    try {
      final countResponse = await client
          .from('shop_products')
          .select('id')
          .limit(1);

      if (countResponse.isNotEmpty) {
        debugPrint("📚 Supabase shop catalog already seeded.");
        return;
      }

      debugPrint("🚚 Seeding Supabase shop_products table with default catalog...");
      final List<Map<String, dynamic>> records =
          ShopProduct.defaultProducts.map((p) => p.toJson()).toList();

      await client.from('shop_products').insert(records);
      debugPrint("🌱 Successfully seeded ${records.length} shop products into Supabase!");
    } catch (e) {
      debugPrint("⚠️ Supabase shop catalog seeding failed/skipped (table might not exist): $e");
    }
  }

  /// Logs an affiliate redirect click event to Supabase click analytics.
  Future<void> logShopClick(String productId) async {
    if (!_isInitialized) return;
    try {
      final userId = client.auth.currentUser?.id ?? 'anonymous';
      await client.from('shop_clicks').insert({
        'product_id': productId,
        'user_id': userId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint("📊 Click logged for product: $productId by user: $userId");
    } catch (e) {
      debugPrint("⚠️ Click analytics logging failed/skipped (table might not exist): $e");
    }
  }
}
