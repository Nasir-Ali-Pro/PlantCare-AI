import 'package:flutter_test/flutter_test.dart';
import 'package:plantcare_app/models/garden_plant.dart';

void main() {
  group('JournalEntry Model Tests', () {
    test('JournalEntry initializes with unique non-null ID', () {
      final entry = JournalEntry(note: 'Watered plant with 250ml water');
      expect(entry.id, isNotEmpty);
      expect(entry.note, equals('Watered plant with 250ml water'));
      expect(entry.dateTime, isNotNull);
    });

    test('JournalEntry serialization and deserialization', () {
      final entry = JournalEntry(
        id: 'entry_123',
        note: 'Pruned yellow leaves',
        milestone: 'First bloom',
      );

      final json = entry.toJson();
      expect(json['id'], equals('entry_123'));
      expect(json['note'], equals('Pruned yellow leaves'));
      expect(json['milestone'], equals('First bloom'));

      final restored = JournalEntry.fromJson(json);
      expect(restored.id, equals('entry_123'));
      expect(restored.note, equals('Pruned yellow leaves'));
      expect(restored.milestone, equals('First bloom'));
    });
  });

  group('GardenPlant Model & Health Logic Tests', () {
    test('computedHealthScore returns 100 for newly acquired and watered plant', () {
      final plant = GardenPlant(
        id: 'plant_1',
        nickname: 'Monster',
        species: 'Monstera Deliciosa',
        scientificName: 'Monstera deliciosa',
        imagePath: '/path/to/img.jpg',
        dateAcquired: DateTime.now(),
        lastWatered: DateTime.now(),
        lastFertilized: DateTime.now(),
        journal: [],
        healthScore: 100,
      );

      expect(plant.computedHealthScore, equals(100));
      expect(plant.needsWatering, isFalse);
      expect(plant.needsFertilizing, isFalse);
    });

    test('computedHealthScore decays correctly when watering is overdue', () {
      final now = DateTime.now();
      // Overdue watering by 5 days (watering frequency is 7 days, last watered 12 days ago)
      final plant = GardenPlant(
        id: 'plant_2',
        nickname: 'Fiddle',
        species: 'Fiddle Leaf Fig',
        scientificName: 'Ficus lyrata',
        imagePath: '/path/to/img.jpg',
        dateAcquired: now.subtract(const Duration(days: 30)),
        lastWatered: now.subtract(const Duration(days: 12)),
        lastFertilized: now,
        journal: [],
        wateringFrequencyDays: 7,
        healthScore: 100,
      );

      expect(plant.needsWatering, isTrue);
      // Overdue 5 days * 2 pts per day = 10 pts penalty -> 90
      expect(plant.computedHealthScore, equals(90));
    });

    test('careUrgency calculates higher value for overdue plants', () {
      final now = DateTime.now();
      final freshPlant = GardenPlant(
        id: 'p1',
        nickname: 'Fresh',
        species: 'Pothos',
        scientificName: 'Epipremnum aureum',
        imagePath: '',
        dateAcquired: now,
        lastWatered: now,
        lastFertilized: now,
        journal: [],
      );

      final thirstyPlant = GardenPlant(
        id: 'p2',
        nickname: 'Thirsty',
        species: 'Pothos',
        scientificName: 'Epipremnum aureum',
        imagePath: '',
        dateAcquired: now,
        lastWatered: now.subtract(const Duration(days: 14)),
        lastFertilized: now,
        journal: [],
        wateringFrequencyDays: 7,
      );

      expect(thirstyPlant.careUrgency, greaterThan(freshPlant.careUrgency));
    });

    test('GardenPlant JSON roundtrip serialization', () {
      final now = DateTime.now();
      final plant = GardenPlant(
        id: 'plant_99',
        nickname: 'Sunny',
        species: 'Sunflower',
        scientificName: 'Helianthus annuus',
        imagePath: '/path/to/sunflower.jpg',
        dateAcquired: now,
        lastWatered: now,
        lastFertilized: now,
        wateringFrequencyDays: 3,
        fertilizingFrequencyDays: 14,
        notes: 'Needs full direct sunlight',
        healthScore: 95,
        journal: [JournalEntry(note: 'Planted seed')],
      );

      final json = plant.toJson();
      expect(json['id'], equals('plant_99'));
      expect(json['nickname'], equals('Sunny'));
      expect(json['species'], equals('Sunflower'));
      expect(json['healthScore'], equals(95));
      expect(json['journal'], isA<List>());

      final restored = GardenPlant.fromJson(json);
      expect(restored.id, equals('plant_99'));
      expect(restored.nickname, equals('Sunny'));
      expect(restored.species, equals('Sunflower'));
      expect(restored.healthScore, equals(95));
      expect(restored.journal.length, equals(1));
      expect(restored.journal.first.note, equals('Planted seed'));
    });
  });
}
