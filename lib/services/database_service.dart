import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/garden_plant.dart';
import '../models/diagnosis_report.dart';
import '../models/chat_message_model.dart';

class DatabaseService {
  static Database? _database;

  /// Private constructor to prevent instantiation
  DatabaseService._();

  static Future<Database> get _db async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathString = p.join(dbPath, 'plantcare_local.db');
    final db = await openDatabase(
      pathString,
      version: 3,
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

  /// Saves or updates a single plant in SQLite
  static Future<void> savePlant(GardenPlant plant) async {
    try {
      final db = await _db;
      await db.insert('garden_plants', _plantToMap(plant), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint("🚨 Error saving plant to SQLite: $e");
    }
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
}
