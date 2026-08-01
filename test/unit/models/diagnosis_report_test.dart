import 'package:flutter_test/flutter_test.dart';
import 'package:plantcare_app/models/diagnosis_report.dart';

void main() {
  group('DiagnosisReport Model Tests', () {
    test('DiagnosisReport initializes with all required fields', () {
      final now = DateTime.now();
      final report = DiagnosisReport(
        id: 'rep_001',
        source: 'Gemini Cloud AI',
        plantName: 'Tomato',
        diseaseName: 'Early Blight',
        confidence: 0.95,
        severity: 'High',
        description: 'Fungal disease causing brown concentric rings on lower leaves.',
        symptoms: ['Brown spots with concentric rings', 'Yellowing margins'],
        treatment: ['Apply Southern Ag Triple Action Neem Oil', 'Remove infected leaves'],
        prevention: ['Avoid overhead watering', 'Ensure proper spacing'],
        imagePath: '/path/to/leaf.jpg',
        dateTime: now,
      );

      expect(report.id, equals('rep_001'));
      expect(report.plantName, equals('Tomato'));
      expect(report.diseaseName, equals('Early Blight'));
      expect(report.confidence, equals(0.95));
      expect(report.severity, equals('High'));
      expect(report.symptoms.length, equals(2));
      expect(report.treatment.length, equals(2));
      expect(report.prevention.length, equals(2));
    });

    test('DiagnosisReport.unrecognized factory creates valid fallback report', () {
      final report = DiagnosisReport.unrecognized(
        id: 'rep_unk',
        imagePath: '/path/to/car.jpg',
        message: 'The uploaded image is not a plant leaf.',
      );

      expect(report.id, equals('rep_unk'));
      expect(report.diseaseName, equals('Unrecognized Item'));
      expect(report.plantName, equals('Unknown Species'));
      expect(report.isOfflineResult, isTrue);
      expect(report.needsVerification, isTrue);
      expect(report.description, equals('The uploaded image is not a plant leaf.'));
    });

    test('DiagnosisReport JSON roundtrip serialization', () {
      final now = DateTime.now();
      final report = DiagnosisReport(
        id: 'rep_123',
        source: 'Gemini Cloud AI',
        plantName: 'Rose',
        diseaseName: 'Black Spot',
        confidence: 0.92,
        severity: 'Moderate',
        description: 'Black lesions on upper leaf surfaces.',
        symptoms: ['Black circular spots'],
        treatment: ['Prune diseased stems'],
        prevention: ['Keep foliage dry'],
        imagePath: '/path/to/rose.jpg',
        dateTime: now,
      );

      final json = report.toJson();
      expect(json['id'], equals('rep_123'));
      expect(json['plantName'], equals('Rose'));
      expect(json['diseaseName'], equals('Black Spot'));
      expect(json['confidence'], equals(0.92));

      final restored = DiagnosisReport.fromJson(json);
      expect(restored.id, equals(report.id));
      expect(restored.plantName, equals(report.plantName));
      expect(restored.diseaseName, equals(report.diseaseName));
      expect(restored.confidence, equals(report.confidence));
      expect(restored.symptoms, equals(report.symptoms));
      expect(restored.treatment, equals(report.treatment));
    });
  });
}
