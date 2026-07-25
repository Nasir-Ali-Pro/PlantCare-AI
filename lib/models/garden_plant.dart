import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────
// Journal Entry Model
// ─────────────────────────────────────────────────────────────

class JournalEntry {
  /// Always non-null UUID — prevents Dismissible key collisions
  final String id;
  final DateTime dateTime;
  final String note;
  final String? imagePath;
  final String? milestone;

  JournalEntry({
    String? id,
    DateTime? dateTime,
    required this.note,
    this.imagePath,
    this.milestone,
  })  : id = id?.isNotEmpty == true ? id! : const Uuid().v4(),
        dateTime = dateTime ?? DateTime.now();

  JournalEntry copyWith({
    String? note,
    String? imagePath,
    String? milestone,
  }) {
    return JournalEntry(
      id: id,
      dateTime: dateTime,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      milestone: milestone ?? this.milestone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'note': note,
      'imagePath': imagePath,
      'milestone': milestone,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String?;
    return JournalEntry(
      // Guarantee non-null id — generate fresh UUID for legacy null/empty IDs
      id: (rawId != null && rawId.isNotEmpty) ? rawId : const Uuid().v4(),
      dateTime: json['dateTime'] != null ? DateTime.tryParse(json['dateTime']) : null,
      note: json['note'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      milestone: json['milestone'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Garden Plant Model
// ─────────────────────────────────────────────────────────────

class GardenPlant {
  final String id;
  final String nickname;
  final String species;
  final String scientificName;
  final String imagePath;
  final DateTime dateAcquired;
  DateTime lastWatered;
  DateTime lastFertilized;
  final int wateringFrequencyDays;
  final int fertilizingFrequencyDays;
  final String notes;

  /// Base health score — set at creation, boosted by care actions.
  /// Use [computedHealthScore] for display to incorporate time-based decay.
  int healthScore;

  List<JournalEntry> journal;
  final List<int> healthHistory;

  GardenPlant({
    required this.id,
    required this.nickname,
    required this.species,
    required this.scientificName,
    required this.imagePath,
    required this.dateAcquired,
    required this.lastWatered,
    required this.lastFertilized,
    required this.journal,
    this.wateringFrequencyDays = 7,
    this.fertilizingFrequencyDays = 30,
    this.notes = '',
    this.healthScore = 100,
    List<int>? healthHistory,
  }) : healthHistory = healthHistory?.isNotEmpty == true
            ? healthHistory!
            : [healthScore.clamp(0, 100)];

  // ── Computed Health with Time-Based Decay ─────────────────

  /// Returns the actual current health score after applying overdue penalties:
  /// - Overdue watering:    -2 pts per day, max -60 pts
  /// - Overdue fertilizing: -1 pt per day,  max -30 pts
  ///
  /// The base [healthScore] is unchanged — this is a pure derived getter.
  int get computedHealthScore {
    int score = healthScore;

    final now = DateTime.now();

    final wateringDue = lastWatered.add(Duration(days: wateringFrequencyDays));
    final overdueWaterDays = now.difference(wateringDue).inDays;
    if (overdueWaterDays > 0) {
      score -= (overdueWaterDays * 2).clamp(0, 60);
    }

    final fertDue = lastFertilized.add(Duration(days: fertilizingFrequencyDays));
    final overdueFertDays = now.difference(fertDue).inDays;
    if (overdueFertDays > 0) {
      score -= (overdueFertDays * 1).clamp(0, 30);
    }

    return score.clamp(0, 100);
  }

  // ── Care Status Getters ───────────────────────────────────

  bool get needsWatering {
    final nextWaterDate = lastWatered.add(Duration(days: wateringFrequencyDays));
    return DateTime.now().isAfter(nextWaterDate);
  }

  int get daysUntilWatering {
    final nextWaterDate = lastWatered.add(Duration(days: wateringFrequencyDays));
    final diff = nextWaterDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get needsFertilizing {
    final nextFertDate = lastFertilized.add(Duration(days: fertilizingFrequencyDays));
    return DateTime.now().isAfter(nextFertDate);
  }

  int get daysUntilFertilizing {
    final nextFertDate = lastFertilized.add(Duration(days: fertilizingFrequencyDays));
    final diff = nextFertDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Combined urgency score (0.0–2.0+) for sorting — higher = more urgent.
  double get careUrgency {
    double urgency = 0.0;
    final waterHours = lastWatered
        .add(Duration(days: wateringFrequencyDays))
        .difference(DateTime.now())
        .inHours;
    final fertHours = lastFertilized
        .add(Duration(days: fertilizingFrequencyDays))
        .difference(DateTime.now())
        .inHours;

    if (waterHours <= 0) {
      urgency += 1.0 + (waterHours.abs() / 24.0 * 0.1);
    } else {
      urgency += (1.0 - waterHours / (wateringFrequencyDays * 24.0)).clamp(0.0, 1.0);
    }
    if (fertHours <= 0) {
      urgency += 0.5;
    } else {
      urgency += (0.5 - fertHours / (fertilizingFrequencyDays * 24.0) * 0.5).clamp(0.0, 0.5);
    }
    return urgency;
  }

  // ── copyWith ─────────────────────────────────────────────

  GardenPlant copyWith({
    String? nickname,
    String? species,
    String? scientificName,
    String? imagePath,
    DateTime? lastWatered,
    DateTime? lastFertilized,
    int? wateringFrequencyDays,
    int? fertilizingFrequencyDays,
    String? notes,
    int? healthScore,
    List<JournalEntry>? journal,
    List<int>? healthHistory,
  }) {
    return GardenPlant(
      id: id,
      nickname: nickname ?? this.nickname,
      species: species ?? this.species,
      scientificName: scientificName ?? this.scientificName,
      imagePath: imagePath ?? this.imagePath,
      dateAcquired: dateAcquired,
      lastWatered: lastWatered ?? this.lastWatered,
      lastFertilized: lastFertilized ?? this.lastFertilized,
      wateringFrequencyDays: wateringFrequencyDays ?? this.wateringFrequencyDays,
      fertilizingFrequencyDays: fertilizingFrequencyDays ?? this.fertilizingFrequencyDays,
      notes: notes ?? this.notes,
      healthScore: healthScore ?? this.healthScore,
      journal: journal ?? List.from(this.journal),
      healthHistory: healthHistory ?? List.from(this.healthHistory),
    );
  }

  // ── Serialization ─────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'species': species,
      'scientificName': scientificName,
      'imagePath': imagePath,
      'dateAcquired': dateAcquired.toIso8601String(),
      'lastWatered': lastWatered.toIso8601String(),
      'lastFertilized': lastFertilized.toIso8601String(),
      'wateringFrequencyDays': wateringFrequencyDays,
      'fertilizingFrequencyDays': fertilizingFrequencyDays,
      'notes': notes,
      'healthScore': healthScore,
      'journal': journal.map((e) => e.toJson()).toList(),
      'healthHistory': healthHistory,
    };
  }

  factory GardenPlant.fromJson(Map<String, dynamic> json) {
    final int score = (json['healthScore'] as int?) ?? 100;
    final rawHistory = (json['healthHistory'] as List?)
        ?.map((e) => (e as num).toInt())
        .toList();

    return GardenPlant(
      id: json['id'] as String? ?? const Uuid().v4(),
      nickname: json['nickname'] as String? ?? '',
      species: json['species'] as String? ?? '',
      scientificName: json['scientificName'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      dateAcquired: json['dateAcquired'] != null
          ? DateTime.tryParse(json['dateAcquired']) ?? DateTime.now()
          : DateTime.now(),
      lastWatered: json['lastWatered'] != null
          ? DateTime.tryParse(json['lastWatered']) ?? DateTime.now()
          : DateTime.now(),
      lastFertilized: json['lastFertilized'] != null
          ? DateTime.tryParse(json['lastFertilized']) ?? DateTime.now()
          : DateTime.now(),
      wateringFrequencyDays: (json['wateringFrequencyDays'] as int?) ?? 7,
      fertilizingFrequencyDays: (json['fertilizingFrequencyDays'] as int?) ?? 30,
      notes: json['notes'] as String? ?? '',
      healthScore: score,
      journal: (json['journal'] as List?)
              ?.map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      // Guard against empty history from legacy data
      healthHistory: (rawHistory != null && rawHistory.isNotEmpty) ? rawHistory : [score],
    );
  }
}
