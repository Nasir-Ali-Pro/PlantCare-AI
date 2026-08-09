// ignore_for_file: prefer_constructors_over_static_methods

class ForumComment {
  final String id;
  final String authorName;
  final String authorTitle;
  final String? authorAvatar;
  final bool isVerifiedExpert;
  // Mutable so owners/admin can edit in-place without rebuilding the entire list
  String content;
  final DateTime dateTime;
  int upvotes;
  bool isUpvoted;
  final List<ForumComment> replies;

  ForumComment({
    required this.id,
    required this.authorName,
    required this.authorTitle,
    this.authorAvatar,
    this.isVerifiedExpert = false,
    required this.content,
    required this.dateTime,
    this.upvotes = 0,
    this.isUpvoted = false,
    List<ForumComment>? replies,
  }) : replies = List<ForumComment>.from(replies ?? []);

  // ── Serialization ─────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_name': authorName,
        'author_title': authorTitle,
        'author_avatar': authorAvatar,
        'is_verified_expert': isVerifiedExpert,
        'content': content,
        'date_time': dateTime.toIso8601String(),
        'upvotes': upvotes,
        'is_upvoted': isUpvoted,
        'replies': replies.map((r) => r.toJson()).toList(),
      };

  factory ForumComment.fromJson(Map<String, dynamic> json) => ForumComment(
        id: json['id'] as String,
        authorName: json['author_name'] as String,
        authorTitle: json['author_title'] as String? ?? 'Member',
        authorAvatar: json['author_avatar'] as String?,
        isVerifiedExpert: json['is_verified_expert'] as bool? ?? false,
        content: json['content'] as String,
        dateTime: DateTime.parse(json['date_time'] as String),
        upvotes: json['upvotes'] as int? ?? 0,
        isUpvoted: json['is_upvoted'] as bool? ?? false,
        replies: (json['replies'] as List<dynamic>?)
                ?.map((r) => ForumComment.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
      );

  ForumComment copyWith({
    String? id,
    String? authorName,
    String? authorTitle,
    String? authorAvatar,
    bool? isVerifiedExpert,
    String? content,
    DateTime? dateTime,
    int? upvotes,
    bool? isUpvoted,
    List<ForumComment>? replies,
  }) =>
      ForumComment(
        id: id ?? this.id,
        authorName: authorName ?? this.authorName,
        authorTitle: authorTitle ?? this.authorTitle,
        authorAvatar: authorAvatar ?? this.authorAvatar,
        isVerifiedExpert: isVerifiedExpert ?? this.isVerifiedExpert,
        content: content ?? this.content,
        dateTime: dateTime ?? this.dateTime,
        upvotes: upvotes ?? this.upvotes,
        isUpvoted: isUpvoted ?? this.isUpvoted,
        replies: replies ?? List<ForumComment>.from(this.replies),
      );
}

class ForumPost {
  final String id;
  final String authorName;
  final String authorTitle;
  final String? authorAvatar;
  final bool isVerifiedExpert;
  // Mutable so owners/admin can edit in-place without rebuilding the entire list
  String category;
  String title;
  String content;
  List<String> tags;
  int upvotes;
  bool isUpvoted;
  final List<ForumComment> comments;
  final List<String> attachedImagePaths;
  final String? diagnosisName;
  final DateTime dateTime;

  ForumPost({
    required this.id,
    required this.authorName,
    required this.authorTitle,
    this.authorAvatar,
    this.isVerifiedExpert = false,
    required this.category,
    required this.title,
    required this.content,
    required this.tags,
    required this.upvotes,
    this.isUpvoted = false,
    required this.comments,
    required this.attachedImagePaths,
    this.diagnosisName,
    required this.dateTime,
  });

  // ── Serialization ─────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_name': authorName,
        'author_title': authorTitle,
        'author_avatar': authorAvatar,
        'is_verified_expert': isVerifiedExpert,
        'category': category,
        'title': title,
        'content': content,
        'tags': tags,
        'upvotes': upvotes,
        'is_upvoted': isUpvoted,
        'comments': comments.map((c) => c.toJson()).toList(),
        'attached_image_paths': attachedImagePaths,
        'diagnosis_name': diagnosisName,
        'date_time': dateTime.toIso8601String(),
      };

  factory ForumPost.fromJson(Map<String, dynamic> json) => ForumPost(
        id: json['id'] as String,
        authorName: json['author_name'] as String,
        authorTitle: json['author_title'] as String? ?? 'Member',
        authorAvatar: json['author_avatar'] as String?,
        isVerifiedExpert: json['is_verified_expert'] as bool? ?? false,
        category: json['category'] as String? ?? 'General',
        title: json['title'] as String,
        content: json['content'] as String,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
        upvotes: json['upvotes'] as int? ?? 0,
        isUpvoted: json['is_upvoted'] as bool? ?? false,
        comments: (json['comments'] as List<dynamic>?)
                ?.map((c) => ForumComment.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        attachedImagePaths:
            (json['attached_image_paths'] as List<dynamic>?)?.cast<String>() ??
                const [],
        diagnosisName: json['diagnosis_name'] as String?,
        dateTime: DateTime.parse(json['date_time'] as String),
      );

  ForumPost copyWith({
    String? id,
    String? authorName,
    String? authorTitle,
    String? authorAvatar,
    bool? isVerifiedExpert,
    String? category,
    String? title,
    String? content,
    List<String>? tags,
    int? upvotes,
    bool? isUpvoted,
    List<ForumComment>? comments,
    List<String>? attachedImagePaths,
    String? diagnosisName,
    DateTime? dateTime,
  }) =>
      ForumPost(
        id: id ?? this.id,
        authorName: authorName ?? this.authorName,
        authorTitle: authorTitle ?? this.authorTitle,
        authorAvatar: authorAvatar ?? this.authorAvatar,
        isVerifiedExpert: isVerifiedExpert ?? this.isVerifiedExpert,
        category: category ?? this.category,
        title: title ?? this.title,
        content: content ?? this.content,
        tags: tags ?? List<String>.from(this.tags),
        upvotes: upvotes ?? this.upvotes,
        isUpvoted: isUpvoted ?? this.isUpvoted,
        comments: comments ?? List<ForumComment>.from(this.comments),
        attachedImagePaths:
            attachedImagePaths ?? List<String>.from(this.attachedImagePaths),
        diagnosisName: diagnosisName ?? this.diagnosisName,
        dateTime: dateTime ?? this.dateTime,
      );

  // ── Default Curated Community Posts ────────────────────────

  static List<ForumPost> get defaultPosts => [
        ForumPost(
          id: 'def_post_1',
          authorName: 'Elena Rostova',
          authorTitle: 'Botanical Member',
          isVerifiedExpert: false,
          category: 'Disease Diagnosis',
          title: 'Help! My Monstera Deliciosa leaves are turning yellow with brown spots',
          content:
              'I\'ve had this Monstera for 8 months. Recently the lower leaves started developing yellow halos around brown necrotic patches. I water once a week. Is this early blight, overwatering, or a fungal infection?',
          tags: ['#monstera', '#yellowleaves', '#help', '#diagnosis'],
          upvotes: 14,
          isUpvoted: false,
          attachedImagePaths: [],
          dateTime: DateTime.now().subtract(const Duration(hours: 18)),
          comments: [
            ForumComment(
              id: 'def_comm_1',
              authorName: 'Dr. Marcus Vance',
              authorTitle: 'Senior Plant Pathologist',
              isVerifiedExpert: true,
              content:
                  'This classic pattern with yellow halos indicates fungal leaf spot (Cercospora) combined with mild root moisture stress. Reduce watering frequency to once every 10–12 days, isolate the plant, and apply copper fungicide spray twice a week.',
              dateTime: DateTime.now().subtract(const Duration(hours: 14)),
              upvotes: 8,
              replies: [
                ForumComment(
                  id: 'def_reply_1',
                  authorName: 'Elena Rostova',
                  authorTitle: 'Botanical Member',
                  content:
                      'Thank you Dr. Vance! I applied copper fungicide today and trimmed the heavily infected lower leaf. Fingers crossed!',
                  dateTime: DateTime.now().subtract(const Duration(hours: 10)),
                  upvotes: 3,
                ),
              ],
            ),
            ForumComment(
              id: 'def_comm_2',
              authorName: 'Chloe Green',
              authorTitle: 'Indoor Jungle Enthusiast',
              content:
                  'Make sure you check the undersides of the leaves for spider mites too! High ambient humidity helps prevent fungal spores from traveling.',
              dateTime: DateTime.now().subtract(const Duration(hours: 12)),
              upvotes: 4,
            ),
          ],
        ),
        ForumPost(
          id: 'def_post_2',
          authorName: 'Julian Thorne',
          authorTitle: 'Certified Master Gardener',
          isVerifiedExpert: true,
          category: 'Tips & Tricks',
          title: 'Ultimate Organic Pest Control Recipe: Neem Oil + Soap Ratio Guide',
          content:
              'Hey fellow plant parents! Here is my tried-and-tested organic pesticide spray for spider mites, thrips, and aphids:\n\n• 1 Gallon lukewarm distilled water\n• 1.5 tbsp pure cold-pressed Neem Oil\n• 1 tsp liquid Castile/Insecticidal soap (emulsifier)\n\nMix thoroughly and spray during evening hours to avoid leaf scorch under direct sun!',
          tags: ['#organic', '#neemoil', '#pestcontrol', '#guide'],
          upvotes: 29,
          isUpvoted: true,
          attachedImagePaths: [],
          dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
          comments: [
            ForumComment(
              id: 'def_comm_3',
              authorName: 'Aisha Patel',
              authorTitle: 'Urban Gardener',
              content:
                  'Saved! Does this work on fungus gnats in the soil as a drench?',
              dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
              upvotes: 5,
              replies: [
                ForumComment(
                  id: 'def_reply_2',
                  authorName: 'Julian Thorne',
                  authorTitle: 'Certified Master Gardener',
                  isVerifiedExpert: true,
                  content:
                      'For gnats in soil, Mosquito Bits (BTI) or a 1:4 hydrogen peroxide soil drench works much better than neem drench!',
                  dateTime: DateTime.now().subtract(const Duration(days: 1)),
                  upvotes: 7,
                ),
              ],
            ),
          ],
        ),
        ForumPost(
          id: 'def_post_3',
          authorName: 'Liam Sterling',
          authorTitle: 'Pothos Collector',
          isVerifiedExpert: false,
          category: 'General',
          title: 'Propagating Variegated Pothos in Water — 3 Week Roots Progress Update!',
          content:
              'Cut 4 node cuttings from my mother Marble Queen Pothos 21 days ago. Placed near an east-facing window with indirect morning light. Look at these robust white primary roots growing!',
          tags: ['#pothos', '#propagation', '#waterpropagation'],
          upvotes: 21,
          isUpvoted: false,
          attachedImagePaths: [],
          dateTime: DateTime.now().subtract(const Duration(days: 2)),
          comments: [
            ForumComment(
              id: 'def_comm_4',
              authorName: 'Maya Lin',
              authorTitle: 'Botanical Member',
              content:
                  'Beautiful roots! When are you planning to transfer them into potting soil?',
              dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 18)),
              upvotes: 4,
              replies: [
                ForumComment(
                  id: 'def_reply_3',
                  authorName: 'Liam Sterling',
                  authorTitle: 'Pothos Collector',
                  content:
                      'Once secondary branch roots reach about 2 inches long! Usually takes another week.',
                  dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 12)),
                  upvotes: 2,
                ),
              ],
            ),
          ],
        ),
        ForumPost(
          id: 'def_post_4',
          authorName: 'Sofia Chen',
          authorTitle: 'Rare Aroid Specialist',
          isVerifiedExpert: false,
          category: 'Marketplace',
          title: 'Rare Pink Princess Philodendron Cuttings Available for Trade/Sale',
          content:
              'Rooted 3-node cuttings with high pink variegation. Freshly potted in premium aroid bark mix. Open to trades for Monstera Albo or local pickup.',
          tags: ['#marketplace', '#philodendron', '#pinkprincess', '#trade'],
          upvotes: 18,
          isUpvoted: false,
          attachedImagePaths: [],
          dateTime: DateTime.now().subtract(const Duration(days: 3)),
          comments: [
            ForumComment(
              id: 'def_comm_5',
              authorName: 'David Miller',
              authorTitle: 'Plant Enthusiast',
              content:
                  'Interested! Sent you a private message about trading for my Monstera Albo top cutting.',
              dateTime: DateTime.now().subtract(const Duration(days: 2, hours: 20)),
              upvotes: 3,
            ),
          ],
        ),
      ];
}

