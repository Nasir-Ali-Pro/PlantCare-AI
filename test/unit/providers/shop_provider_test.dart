import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:plantcare_app/providers/shop_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ShopProvider Tests', () {
    test('Default products are loaded on provider initialization', () async {
      final provider = ShopProvider();
      await provider.loadProducts();

      expect(provider.allProducts.isNotEmpty, isTrue);
      expect(provider.products.isNotEmpty, isTrue);
      expect(provider.selectedCategory, equals('All'));
      expect(provider.sortMode, equals('Popularity'));
    });

    test('Category filtering filters products correctly', () async {
      final provider = ShopProvider();
      await provider.loadProducts();

      provider.setSelectedCategory('Pest & Disease Control');

      final filtered = provider.products;
      expect(filtered.isNotEmpty, isTrue);
      expect(filtered.every((p) => p.category == 'Pest & Disease Control'), isTrue);
      expect(filtered.length, lessThan(provider.allProducts.length));
    });

    test('Search query filters products by title, description or category', () async {
      final provider = ShopProvider();
      await provider.loadProducts();

      provider.setSearchQuery('Neem');

      final searchResults = provider.products;
      expect(searchResults.isNotEmpty, isTrue);
      expect(
        searchResults.every(
          (p) =>
              p.title.toLowerCase().contains('neem') ||
              p.description.toLowerCase().contains('neem') ||
              p.category.toLowerCase().contains('neem'),
        ),
        isTrue,
      );
    });

    test('Sorting by Price: Low to High works correctly', () async {
      final provider = ShopProvider();
      await provider.loadProducts();

      provider.setSortMode('Price: Low to High');

      final sorted = provider.products;
      for (int i = 0; i < sorted.length - 1; i++) {
        final priceA = double.parse(sorted[i].price.replaceAll(RegExp(r'[^\d.]'), ''));
        final priceB = double.parse(sorted[i + 1].price.replaceAll(RegExp(r'[^\d.]'), ''));
        expect(priceA, lessThanOrEqualTo(priceB));
      }
    });

    test('Sorting by Rating works correctly', () async {
      final provider = ShopProvider();
      await provider.loadProducts();

      provider.setSortMode('Rating');

      final sorted = provider.products;
      for (int i = 0; i < sorted.length - 1; i++) {
        expect(sorted[i].rating, greaterThanOrEqualTo(sorted[i + 1].rating));
      }
    });

    test('Wishlist starts empty when no favorites toggled', () async {
      final provider = ShopProvider();
      await provider.loadProducts();

      expect(provider.wishlist, isEmpty);
    });
  });
}
