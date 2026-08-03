import 'package:flutter_test/flutter_test.dart';
import 'package:plantcare_app/models/forum_post.dart';

void main() {
  group('ForumPost & ForumComment Model Unit Tests', () {
    test('ForumPost fields can be updated in-place', () {
      final post = ForumPost(
        id: 'post-1',
        authorName: 'TestUser',
        authorTitle: 'Botanical Member',
        category: 'General',
        title: 'Original Title',
        content: 'Original Content',
        tags: ['#tag1'],
        upvotes: 5,
        comments: [],
        attachedImagePaths: [],
        dateTime: DateTime.now(),
      );

      post.title = 'Updated Title';
      post.content = 'Updated Content';
      post.category = 'Diseases';
      post.tags = ['#tag1', '#updated'];

      expect(post.title, equals('Updated Title'));
      expect(post.content, equals('Updated Content'));
      expect(post.category, equals('Diseases'));
      expect(post.tags, equals(['#tag1', '#updated']));
    });

    test('ForumComment content can be updated in-place', () {
      final comment = ForumComment(
        id: 'comment-1',
        authorName: 'Commenter',
        authorTitle: 'Botanical Member',
        content: 'Initial Comment Text',
        dateTime: DateTime.now(),
      );

      comment.content = 'Edited Comment Text';
      expect(comment.content, equals('Edited Comment Text'));
    });

    test('ForumComment supports nested replies structure', () {
      final reply = ForumComment(
        id: 'comment-2',
        authorName: 'Replier',
        authorTitle: 'Botanical Member',
        content: 'Reply text',
        dateTime: DateTime.now(),
      );

      final parent = ForumComment(
        id: 'comment-1',
        authorName: 'ParentCommenter',
        authorTitle: 'Botanical Member',
        content: 'Parent text',
        dateTime: DateTime.now(),
        replies: [reply],
      );

      expect(parent.replies.length, equals(1));
      expect(parent.replies.first.id, equals('comment-2'));
    });
  });
}
