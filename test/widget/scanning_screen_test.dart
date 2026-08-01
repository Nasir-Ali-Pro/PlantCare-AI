import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:plantcare_app/providers/diagnosis_provider.dart';
import 'package:plantcare_app/providers/garden_provider.dart';
import 'package:plantcare_app/screens/scanning/scanning_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Widget createScanningScreen(DiagnosisProvider diagnosisProvider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: diagnosisProvider),
        ChangeNotifierProvider(create: (_) => GardenProvider()),
      ],
      child: const MaterialApp(
        home: ScanningScreen(),
      ),
    );
  }

  group('ScanningScreen Widget Tests', () {
    testWidgets('ScanningScreen shows progress text when analyzing', (tester) async {
      final provider = DiagnosisProvider();
      await tester.pumpWidget(createScanningScreen(provider));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Analyzing...'), findsOneWidget);
      expect(find.text('Cancel Diagnosis'), findsOneWidget);
    });
  });
}
