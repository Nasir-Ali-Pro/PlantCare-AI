import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:plantcare_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('PlantCareApp boots up smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PlantCareApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PlantCareApp), findsOneWidget);
  });
}
