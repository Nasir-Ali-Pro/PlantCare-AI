import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:plantcare_app/providers/shop_provider.dart';
import 'package:plantcare_app/screens/shop/shop_screen.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 404;
  @override
  int get contentLength => 0;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return const Stream<List<int>>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  HttpOverrides.global = _TestHttpOverrides();

  Widget createShopScreen(ShopProvider provider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
      ],
      child: const MaterialApp(
        home: ShopScreen(),
      ),
    );
  }

  group('ShopScreen Widget Tests', () {
    testWidgets('ShopScreen renders title, search field, tab bar and product cards', (tester) async {
      final provider = ShopProvider();
      await provider.loadProducts();

      await tester.pumpWidget(createShopScreen(provider));
      await tester.pump(const Duration(seconds: 2));

      // Check AppBar Title
      expect(find.text('Affiliate Shop 🛒'), findsOneWidget);

      // Check Tabs
      expect(find.text('Browse'), findsOneWidget);
      expect(find.text('Wishlist'), findsOneWidget);

      // Check Search bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search supplies...'), findsOneWidget);

      // Check Verified badges on loaded products
      expect(find.text('Verified'), findsWidgets);
    });

    testWidgets('Search input filters product items', (tester) async {
      final provider = ShopProvider();
      await provider.loadProducts();

      await tester.pumpWidget(createShopScreen(provider));
      await tester.pump(const Duration(seconds: 2));

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Neem');
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Neem'), findsWidgets);
    });

    testWidgets('Switching to Wishlist tab shows empty state initially', (tester) async {
      final provider = ShopProvider();
      await provider.loadProducts();

      await tester.pumpWidget(createShopScreen(provider));
      await tester.pump(const Duration(seconds: 2));

      // Tap Wishlist Tab
      final wishlistTab = find.text('Wishlist');
      await tester.tap(wishlistTab);
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Your wishlist is empty'), findsOneWidget);
    });
  });
}
