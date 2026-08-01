import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:plantcare_app/providers/chat_provider.dart';
import 'package:plantcare_app/models/diagnosis_report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ChatProvider Tests', () {
    test('ChatProvider starts with welcome message or loaded history', () {
      final provider = ChatProvider();
      expect(provider.isTyping, isFalse);
      expect(provider.activeConsultationReport, isNull);
    });

    test('startDoctorConsultation populates active consultation report and initial prompt', () {
      final provider = ChatProvider();
      final report = DiagnosisReport(
        id: 'rep_test',
        source: 'Gemini Cloud AI',
        plantName: 'Tomato',
        diseaseName: 'Early Blight',
        confidence: 0.95,
        severity: 'High',
        description: 'Fungal leaf spot issue',
        symptoms: ['Dark concentric spots'],
        treatment: ['Apply Southern Ag Triple Action Neem Oil'],
        prevention: ['Avoid overhead watering'],
        imagePath: '/path/to/img.jpg',
        dateTime: DateTime.now(),
      );

      provider.startDoctorConsultation(report);

      expect(provider.activeConsultationReport, equals(report));
      expect(provider.messages.isNotEmpty, isTrue);
      expect(provider.messages.first.text, contains('AI Plant Doctor'));
      expect(provider.messages.first.text, contains('Tomato'));
      expect(provider.messages.first.text, contains('Early Blight'));
    });

    test('clearConsultation resets active report and chat messages', () {
      final provider = ChatProvider();
      final report = DiagnosisReport(
        id: 'rep_test',
        source: 'Gemini Cloud AI',
        plantName: 'Monstera',
        diseaseName: 'Healthy',
        confidence: 0.99,
        severity: 'Low',
        description: 'Plant is thriving',
        symptoms: ['Green glossy leaves'],
        treatment: ['Continue regular care'],
        prevention: ['Bright indirect light'],
        imagePath: '/path/to/img.jpg',
        dateTime: DateTime.now(),
      );

      provider.startDoctorConsultation(report);
      expect(provider.activeConsultationReport, isNotNull);

      provider.clearConsultation();
      expect(provider.activeConsultationReport, isNull);
    });
  });
}
