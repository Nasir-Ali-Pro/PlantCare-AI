import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:plantcare_app/providers/chat_provider.dart';
import 'package:plantcare_app/providers/garden_provider.dart';
import 'package:plantcare_app/screens/chat/chat_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Widget createChatScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => GardenProvider()),
      ],
      child: const MaterialApp(
        home: ChatScreen(),
      ),
    );
  }

  group('ChatScreen Widget Tests', () {
    testWidgets('ChatScreen renders header title and subtitle', (tester) async {
      await tester.pumpWidget(createChatScreen());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('AI Care Assistant'), findsOneWidget);
      expect(find.text('Plants & Gardening Expert'), findsOneWidget);
      expect(find.byIcon(Icons.cleaning_services_rounded), findsOneWidget);
    });

    testWidgets('Quick prompt suggestion chips render and are present', (tester) async {
      await tester.pumpWidget(createChatScreen());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Why are my plant leaves turning yellow?'), findsOneWidget);
      expect(find.text('How often should I water my succulents?'), findsOneWidget);
    });

    testWidgets('TextField input allows typing messages', (tester) async {
      await tester.pumpWidget(createChatScreen());
      await tester.pump(const Duration(milliseconds: 500));

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'How do I prune a Monstera?');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('How do I prune a Monstera?'), findsOneWidget);
    });
  });
}
