import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/garden_plant.dart';
import '../models/diagnosis_report.dart';
import '../models/chat_message_model.dart';
import '../models/forum_post.dart';

class DatabaseService {
  static Database? _database;
  // Completer serialises concurrent first-access calls so _initDatabase()
  // is only ever executed once, even if two callers race before the DB is open.
  static Completer<Database>? _initCompleter;

  /// Private constructor to prevent instantiation
  DatabaseService._();

  static Future<Database> get _db async {
    if (_database != null) return _database!;
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<Database>();
    try {
      final db = await _initDatabase();
      _database = db;
      _initCompleter!.complete(db);
    } catch (e, st) {
      final c = _initCompleter!;
      _initCompleter = null;
      c.completeError(e, st);
      rethrow;
    }
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathString = p.join(dbPath, 'plantcare_local.db');
    final db = await openDatabase(
      pathString,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE garden_plants(
            id TEXT PRIMARY KEY,
            nickname TEXT,
            species TEXT,
            scientificName TEXT,
            imagePath TEXT,
            dateAcquired TEXT,
            lastWatered TEXT,
            lastFertilized TEXT,
            wateringFrequencyDays INTEGER,
            fertilizingFrequencyDays INTEGER,
            notes TEXT,
            healthScore INTEGER,
            healthHistory TEXT,
            journal TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE diagnosis_reports(
            id TEXT PRIMARY KEY,
            source TEXT,
            plantName TEXT,
            diseaseName TEXT,
            confidence REAL,
            severity TEXT,
            description TEXT,
            symptoms TEXT,
            treatment TEXT,
            prevention TEXT,
            imagePath TEXT,
            dateTime TEXT,
            isOfflineResult INTEGER,
            localCritiqueExplanation TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE shop_favorites(
            id TEXT PRIMARY KEY
          )
        ''');
        await db.execute('''
          CREATE TABLE chat_messages(
            id TEXT PRIMARY KEY,
            text TEXT NOT NULL,
            isUser INTEGER NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE forum_posts(
            id TEXT PRIMARY KEY,
            author_name TEXT,
            author_title TEXT,
            author_avatar TEXT,
            is_verified_expert INTEGER,
            category TEXT,
            title TEXT,
            content TEXT,
            tags TEXT,
            upvotes INTEGER,
            is_upvoted INTEGER,
            attached_image_paths TEXT,
            diagnosis_name TEXT,
            created_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE forum_comments(
            id TEXT PRIMARY KEY,
            post_id TEXT,
            parent_comment_id TEXT,
            author_name TEXT,
            author_title TEXT,
            author_avatar TEXT,
            is_verified_expert INTEGER,
            content TEXT,
            upvotes INTEGER,
            is_upvoted INTEGER,
            created_at TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS shop_favorites(
              id TEXT PRIMARY KEY
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS chat_messages(
              id TEXT PRIMARY KEY,
              text TEXT NOT NULL,
              isUser INTEGER NOT NULL,
              timestamp TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS forum_posts(
              id TEXT PRIMARY KEY,
              author_name TEXT,
              author_title TEXT,
              author_avatar TEXT,
              is_verified_expert INTEGER,
              category TEXT,
              title TEXT,
              content TEXT,
              tags TEXT,
              upvotes INTEGER,
              is_upvoted INTEGER,
              attached_image_paths TEXT,
              diagnosis_name TEXT,
              created_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS forum_comments(
              id TEXT PRIMARY KEY,
              post_id TEXT,
              parent_comment_id TEXT,
              author_name TEXT,
              author_title TEXT,
              author_avatar TEXT,
              is_verified_expert INTEGER,
              content TEXT,
              upvotes INTEGER,
              is_upvoted INTEGER,
              created_at TEXT
            )
          ''');
        }
      },
    );
    await _checkAndMigrateLegacyData(db);
    return db;
  }

  /// Runs on first database load/access to migrate legacy JSON data from SharedPreferences
  static Future<void> _checkAndMigrateLegacyData(Database db) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Migrate plants
      if (prefs.containsKey('db_plants_list')) {
        final jsonStr = prefs.getString('db_plants_list');
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final List<dynamic> decoded = json.decode(jsonStr);
          final plants = decoded.map((e) => GardenPlant.fromJson(e)).toList();
          for (var plant in plants) {
            await db.insert(
              'garden_plants',
              _plantToMap(plant),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          debugPrint("🚚 Migrated ${plants.length} legacy plants to SQLite!");
        }
        await prefs.remove('db_plants_list');
      }

      // Migrate reports
      if (prefs.containsKey('db_reports_list')) {
        final jsonStr = prefs.getString('db_reports_list');
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final List<dynamic> decoded = json.decode(jsonStr);
          final reports = decoded.map((e) => DiagnosisReport.fromJson(e)).toList();
          for (var report in reports) {
            await db.insert(
              'diagnosis_reports',
              _reportToMap(report),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          debugPrint("🚚 Migrated ${reports.length} legacy reports to SQLite!");
        }
        await prefs.remove('db_reports_list');
      }
    } catch (e) {
      debugPrint("⚠️ Legacy data migration failed: $e");
    }
  }

  // ── Plants Persistence ──────────────────────────────────────────────

  /// Loads all garden plants from SQLite
  static Future<List<GardenPlant>> getPlants() async {
    try {
      final db = await _db;
      final List<Map<String, dynamic>> maps = await db.query('garden_plants', orderBy: 'dateAcquired DESC');
      return maps.map((map) => _mapToPlant(map)).toList();
    } catch (e) {
      debugPrint("🚨 Error reading plants from SQLite: $e");
      return [];
    }
  }

  /// Saves the complete list of garden plants to SQLite
  static Future<void> savePlants(List<GardenPlant> plants) async {
    try {
      final db = await _db;
      final batch = db.batch();
      for (var plant in plants) {
        batch.insert('garden_plants', _plantToMap(plant), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint("🚨 Error saving plants list to SQLite: $e");
    }
  }

  /// Saves or updates a single plant in SQLite.
  /// Re-throws on failure so callers can surface the error to the user.
  static Future<void> savePlant(GardenPlant plant) async {
    final db = await _db;
    await db.insert('garden_plants', _plantToMap(plant), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Deletes a plant from SQLite by ID
  static Future<void> deletePlant(String id) async {
    try {
      final db = await _db;
      await db.delete('garden_plants', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint("🚨 Error deleting plant from SQLite: $e");
    }
  }

  /// Clears all plants from SQLite
  static Future<void> clearPlants() async {
    try {
      final db = await _db;
      await db.delete('garden_plants');
    } catch (e) {
      debugPrint("🚨 Error clearing plants: $e");
    }
  }

  // ── Diagnosis Reports Persistence ───────────────────────────────────

  /// Loads all diagnosis reports from SQLite
  static Future<List<DiagnosisReport>> getReports() async {
    try {
      final db = await _db;
      final List<Map<String, dynamic>> maps = await db.query('diagnosis_reports', orderBy: 'dateTime DESC');
      return maps.map((map) => _mapToReport(map)).toList();
    } catch (e) {
      debugPrint("🚨 Error reading reports from SQLite: $e");
      return [];
    }
  }

  /// Saves the complete list of reports to SQLite
  static Future<void> saveReports(List<DiagnosisReport> reports) async {
    try {
      final db = await _db;
      final batch = db.batch();
      for (var report in reports) {
        batch.insert('diagnosis_reports', _reportToMap(report), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint("🚨 Error saving reports list to SQLite: $e");
    }
  }

  /// Saves or updates a single report in SQLite
  static Future<void> saveReport(DiagnosisReport report) async {
    try {
      final db = await _db;
      await db.insert('diagnosis_reports', _reportToMap(report), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint("🚨 Error saving report to SQLite: $e");
    }
  }

  /// Deletes a report from SQLite by ID
  static Future<void> deleteReport(String id) async {
    try {
      final db = await _db;
      await db.delete('diagnosis_reports', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint("🚨 Error deleting report from SQLite: $e");
    }
  }

  /// Clears all reports from SQLite
  static Future<void> clearReports() async {
    try {
      final db = await _db;
      await db.delete('diagnosis_reports');
    } catch (e) {
      debugPrint("🚨 Error clearing reports: $e");
    }
  }

  // ── Mapper Helpers ──────────────────────────────────────────────────

  static Map<String, dynamic> _plantToMap(GardenPlant plant) {
    return {
      'id': plant.id,
      'nickname': plant.nickname,
      'species': plant.species,
      'scientificName': plant.scientificName,
      'imagePath': plant.imagePath,
      'dateAcquired': plant.dateAcquired.toIso8601String(),
      'lastWatered': plant.lastWatered.toIso8601String(),
      'lastFertilized': plant.lastFertilized.toIso8601String(),
      'wateringFrequencyDays': plant.wateringFrequencyDays,
      'fertilizingFrequencyDays': plant.fertilizingFrequencyDays,
      'notes': plant.notes,
      'healthScore': plant.healthScore,
      'healthHistory': json.encode(plant.healthHistory),
      'journal': json.encode(plant.journal.map((e) => e.toJson()).toList()),
    };
  }

  static GardenPlant _mapToPlant(Map<String, dynamic> map) {
    List<int> history = [];
    try {
      if (map['healthHistory'] != null) {
        history = List<int>.from(json.decode(map['healthHistory'] as String));
      }
    } catch (_) {}

    List<JournalEntry> journal = [];
    try {
      if (map['journal'] != null) {
        final List<dynamic> decoded = json.decode(map['journal'] as String);
        journal = decoded.map((e) => JournalEntry.fromJson(e)).toList();
      }
    } catch (_) {}

    return GardenPlant(
      id: map['id'] as String? ?? '',
      nickname: map['nickname'] as String? ?? '',
      species: map['species'] as String? ?? '',
      scientificName: map['scientificName'] as String? ?? '',
      imagePath: map['imagePath'] as String? ?? '',
      dateAcquired: map['dateAcquired'] != null ? DateTime.parse(map['dateAcquired'] as String) : DateTime.now(),
      lastWatered: map['lastWatered'] != null ? DateTime.parse(map['lastWatered'] as String) : DateTime.now(),
      lastFertilized: map['lastFertilized'] != null ? DateTime.parse(map['lastFertilized'] as String) : DateTime.now(),
      wateringFrequencyDays: map['wateringFrequencyDays'] as int? ?? 7,
      fertilizingFrequencyDays: map['fertilizingFrequencyDays'] as int? ?? 30,
      notes: map['notes'] as String? ?? '',
      healthScore: map['healthScore'] as int? ?? 100,
      healthHistory: history,
      journal: journal,
    );
  }

  static Map<String, dynamic> _reportToMap(DiagnosisReport report) {
    return {
      'id': report.id,
      'source': report.source,
      'plantName': report.plantName,
      'diseaseName': report.diseaseName,
      'confidence': report.confidence,
      'severity': report.severity,
      'description': report.description,
      'symptoms': json.encode(report.symptoms),
      'treatment': json.encode(report.treatment),
      'prevention': json.encode(report.prevention),
      'imagePath': report.imagePath,
      'dateTime': report.dateTime.toIso8601String(),
      'isOfflineResult': report.isOfflineResult ? 1 : 0,
      'localCritiqueExplanation': report.localCritiqueExplanation,
    };
  }

  static DiagnosisReport _mapToReport(Map<String, dynamic> map) {
    List<String> symptoms = [];
    try {
      if (map['symptoms'] != null) {
        symptoms = List<String>.from(json.decode(map['symptoms'] as String));
      }
    } catch (_) {}

    List<String> treatment = [];
    try {
      if (map['treatment'] != null) {
        treatment = List<String>.from(json.decode(map['treatment'] as String));
      }
    } catch (_) {}

    List<String> prevention = [];
    try {
      if (map['prevention'] != null) {
        prevention = List<String>.from(json.decode(map['prevention'] as String));
      }
    } catch (_) {}

    return DiagnosisReport(
      id: map['id'] as String? ?? '',
      source: map['source'] as String? ?? '',
      plantName: map['plantName'] as String? ?? '',
      diseaseName: map['diseaseName'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: map['severity'] as String? ?? '',
      description: map['description'] as String? ?? '',
      symptoms: symptoms,
      treatment: treatment,
      prevention: prevention,
      imagePath: map['imagePath'] as String? ?? '',
      dateTime: map['dateTime'] != null ? DateTime.parse(map['dateTime'] as String) : DateTime.now(),
      isOfflineResult: (map['isOfflineResult'] as int?) == 1,
      localCritiqueExplanation: map['localCritiqueExplanation'] as String?,
    );
  }

  // ── Shop Favorites Persistence ──────────────────────────────────────

  static Future<List<String>> getFavoriteProductIds() async {
    try {
      final db = await _db;
      final List<Map<String, dynamic>> maps = await db.query('shop_favorites');
      return maps.map((map) => map['id'] as String).toList();
    } catch (e) {
      debugPrint("🚨 Error reading shop favorites from SQLite: $e");
      return [];
    }
  }

  static Future<void> addFavoriteProductId(String id) async {
    try {
      final db = await _db;
      await db.insert(
        'shop_favorites',
        {'id': id},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      debugPrint("🚨 Error adding shop favorite to SQLite: $e");
    }
  }

  static Future<void> removeFavoriteProductId(String id) async {
    try {
      final db = await _db;
      await db.delete(
        'shop_favorites',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint("🚨 Error removing shop favorite from SQLite: $e");
    }
  }

  // ── Chat Message Persistence ────────────────────────────────────────

  /// Saves a single chat message to SQLite for session persistence.
  static Future<void> saveChatMessage(ChatMessageModel msg) async {
    try {
      final db = await _db;
      await db.insert(
        'chat_messages',
        msg.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint("🚨 Error saving chat message to SQLite: $e");
    }
  }

  /// Loads the last 50 chat messages from SQLite ordered by timestamp ascending.
  static Future<List<ChatMessageModel>> getChatMessages() async {
    try {
      final db = await _db;
      final List<Map<String, dynamic>> maps = await db.query(
        'chat_messages',
        orderBy: 'timestamp ASC',
        limit: 50,
      );
      return maps.map(ChatMessageModel.fromMap).toList();
    } catch (e) {
      debugPrint("🚨 Error reading chat messages from SQLite: $e");
      return [];
    }
  }

  /// Clears all persisted chat messages.
  static Future<void> clearChatMessages() async {
    try {
      final db = await _db;
      await db.delete('chat_messages');
    } catch (e) {
      debugPrint("🚨 Error clearing chat messages from SQLite: $e");
    }
  }

  // ── Forum Persistence ─────────────────────────────────────────────

  /// Saves a single forum post to local SQLite storage.
  static Future<void> saveForumPost(ForumPost post) async {
    try {
      final db = await _db;
      await db.insert(
        'forum_posts',
        {
          'id': post.id,
          'author_name': post.authorName,
          'author_title': post.authorTitle,
          'author_avatar': post.authorAvatar,
          'is_verified_expert': post.isVerifiedExpert ? 1 : 0,
          'category': post.category,
          'title': post.title,
          'content': post.content,
          'tags': json.encode(post.tags),
          'upvotes': post.upvotes,
          'is_upvoted': post.isUpvoted ? 1 : 0,
          'attached_image_paths': json.encode(post.attachedImagePaths),
          'diagnosis_name': post.diagnosisName,
          'created_at': post.dateTime.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint("🚨 Error saving forum post to SQLite: $e");
    }
  }

  /// Saves a list of forum posts and their comments recursively into SQLite.
  static Future<void> saveForumPosts(List<ForumPost> posts) async {
    try {
      final db = await _db;
      final batch = db.batch();
      for (var post in posts) {
        batch.insert(
          'forum_posts',
          {
            'id': post.id,
            'author_name': post.authorName,
            'author_title': post.authorTitle,
            'author_avatar': post.authorAvatar,
            'is_verified_expert': post.isVerifiedExpert ? 1 : 0,
            'category': post.category,
            'title': post.title,
            'content': post.content,
            'tags': json.encode(post.tags),
            'upvotes': post.upvotes,
            'is_upvoted': post.isUpvoted ? 1 : 0,
            'attached_image_paths': json.encode(post.attachedImagePaths),
            'diagnosis_name': post.diagnosisName,
            'created_at': post.dateTime.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        _batchSaveComments(batch, post.id, null, post.comments);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint("🚨 Error saving forum posts batch to SQLite: $e");
    }
  }

  static void _batchSaveComments(
      Batch batch, String postId, String? parentCommentId, List<ForumComment> comments) {
    for (var c in comments) {
      batch.insert(
        'forum_comments',
        {
          'id': c.id,
          'post_id': postId,
          'parent_comment_id': parentCommentId,
          'author_name': c.authorName,
          'author_title': c.authorTitle,
          'author_avatar': c.authorAvatar,
          'is_verified_expert': c.isVerifiedExpert ? 1 : 0,
          'content': c.content,
          'upvotes': c.upvotes,
          'is_upvoted': c.isUpvoted ? 1 : 0,
          'created_at': c.dateTime.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (c.replies.isNotEmpty) {
        _batchSaveComments(batch, postId, c.id, c.replies);
      }
    }
  }

  /// Saves a single forum comment or reply into SQLite.
  static Future<void> saveForumComment(
      String postId, String? parentCommentId, ForumComment comment) async {
    try {
      final db = await _db;
      final cleanParentId = (parentCommentId != null && parentCommentId.trim().isNotEmpty)
          ? parentCommentId.trim()
          : null;
      await db.insert(
        'forum_comments',
        {
          'id': comment.id,
          'post_id': postId,
          'parent_comment_id': cleanParentId,
          'author_name': comment.authorName,
          'author_title': comment.authorTitle,
          'author_avatar': comment.authorAvatar,
          'is_verified_expert': comment.isVerifiedExpert ? 1 : 0,
          'content': comment.content,
          'upvotes': comment.upvotes,
          'is_upvoted': comment.isUpvoted ? 1 : 0,
          'created_at': comment.dateTime.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint("💾 Saved forum comment/reply ${comment.id} (parentId: $cleanParentId) to local SQLite.");
    } catch (e) {
      debugPrint("🚨 Error saving forum comment to SQLite: $e");
    }
  }

  /// Loads all cached forum posts and reconstructs nested comment/reply trees from SQLite.
  static Future<List<ForumPost>> getForumPosts() async {
    try {
      final db = await _db;
      final postsData = await db.query('forum_posts', orderBy: 'created_at DESC');
      if (postsData.isEmpty) {
        debugPrint("🚚 Seeding local SQLite with default curated forum posts & comments...");
        final defaults = ForumPost.defaultPosts;
        await saveForumPosts(defaults);
        return defaults;
      }

      final commentsData = await db.query('forum_comments', orderBy: 'created_at ASC');

      final Map<String, ForumComment> commentMap = {};
      final List<ForumComment> allComments = [];

      for (var c in commentsData) {
        final commentId = c['id'] as String;
        final commentObj = ForumComment(
          id: commentId,
          authorName: c['author_name'] as String? ?? 'Gardener',
          authorTitle: c['author_title'] as String? ?? 'Gardener',
          authorAvatar: c['author_avatar'] as String?,
          isVerifiedExpert: (c['is_verified_expert'] as int?) == 1,
          content: c['content'] as String? ?? '',
          dateTime: DateTime.tryParse(c['created_at'] as String? ?? '') ?? DateTime.now(),
          upvotes: (c['upvotes'] as int?) ?? 0,
          isUpvoted: (c['is_upvoted'] as int?) == 1,
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
        final rawParentId = cData['parent_comment_id'] as String?;
        final parentId = (rawParentId != null && rawParentId.trim().isNotEmpty) ? rawParentId.trim() : null;

        if (parentId != null && commentMap.containsKey(parentId)) {
          commentMap[parentId]!.replies.add(commentObj);
        } else {
          postCommentsMap.putIfAbsent(postId, () => []).add(commentObj);
        }
      }

      final List<ForumPost> posts = [];
      for (var p in postsData) {
        final postId = p['id'] as String;
        List<String> tags = [];
        if (p['tags'] != null && (p['tags'] as String).isNotEmpty) {
          try {
            tags = List<String>.from(json.decode(p['tags'] as String));
          } catch (_) {}
        }
        List<String> attachedImages = [];
        if (p['attached_image_paths'] != null && (p['attached_image_paths'] as String).isNotEmpty) {
          try {
            attachedImages = List<String>.from(json.decode(p['attached_image_paths'] as String));
          } catch (_) {}
        }

        posts.add(ForumPost(
          id: postId,
          authorName: p['author_name'] as String? ?? 'Gardener',
          authorTitle: p['author_title'] as String? ?? 'Gardener',
          authorAvatar: p['author_avatar'] as String?,
          isVerifiedExpert: (p['is_verified_expert'] as int?) == 1,
          category: p['category'] as String? ?? 'General',
          title: p['title'] as String? ?? '',
          content: p['content'] as String? ?? '',
          tags: tags,
          upvotes: (p['upvotes'] as int?) ?? 0,
          isUpvoted: (p['is_upvoted'] as int?) == 1,
          comments: postCommentsMap[postId] ?? [],
          attachedImagePaths: attachedImages,
          diagnosisName: p['diagnosis_name'] as String?,
          dateTime: DateTime.tryParse(p['created_at'] as String? ?? '') ?? DateTime.now(),
        ));
      }

      return posts;
    } catch (e) {
      debugPrint("🚨 Error reading forum posts from SQLite: $e");
      return [];
    }
  }
}
