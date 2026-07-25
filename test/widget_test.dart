import 'package:flutter_test/flutter_test.dart';
import 'package:plantcare_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize SQLite FFI database factory for host-based tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('PlantCare AI App Smoke Test', (WidgetTester tester) async {
    // Mock SharedPreferences to avoid asynchronous loading timer issue in tests
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlantCareApp());
 
    // Pump finite frames to let asynchronous initialization settle without looping on the infinite particle animation
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
 
    // Verify that the HomeScreen is displayed by checking for the app title
    expect(find.text('PlantCare'), findsOneWidget);
  });
}

