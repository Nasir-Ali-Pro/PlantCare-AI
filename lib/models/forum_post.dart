class ForumComment {
  final String id;
  final String authorName;
  final String authorTitle;
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
    this.isVerifiedExpert = false,
    required this.content,
    required this.dateTime,
    this.upvotes = 0,
    this.isUpvoted = false,
    List<ForumComment>? replies,
  }) : replies = List<ForumComment>.from(replies ?? []);
}

class ForumPost {
  final String id;
  final String authorName;
  final String authorTitle;
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
}
