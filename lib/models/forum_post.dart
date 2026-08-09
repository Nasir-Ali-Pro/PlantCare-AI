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
}
