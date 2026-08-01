import 'package:flutter_test/flutter_test.dart';
import 'package:plantcare_app/models/shop_product.dart';

void main() {
  group('ShopProduct Model Tests', () {
    test('Default products list is non-empty and has verified ASINs', () {
      final products = ShopProduct.defaultProducts;
      expect(products.isNotEmpty, isTrue);
      expect(products.length, greaterThanOrEqualTo(10));

      for (final product in products) {
        expect(product.id, isNotEmpty);
        expect(product.title, isNotEmpty);
        expect(product.description, isNotEmpty);
        expect(product.price, startsWith('\$'));
        expect(product.rating, greaterThanOrEqualTo(1.0));
        expect(product.rating, lessThanOrEqualTo(5.0));
        expect(product.reviewCount, greaterThan(0));
        expect(product.imageUrl, startsWith('http'));
        expect(product.asin, isNotEmpty);
        expect(product.category, isNotEmpty);
      }
    });

    test('affiliateUrl generates proper Amazon link with tag 83847-20', () {
      const product = ShopProduct(
        id: 'test_1',
        title: 'Test Neem Oil',
        description: 'Organic Neem Oil',
        price: '\$14.99',
        rating: 4.6,
        reviewCount: 100,
        imageUrl: 'https://m.media-amazon.com/images/I/test.jpg',
        asin: 'B004QAWGIO',
        category: 'Pest & Disease Control',
      );

      expect(
        product.affiliateUrl,
        equals('https://www.amazon.com/dp/B004QAWGIO?tag=83847-20'),
      );
    });

    test('toJson and fromJson roundtrip serialization', () {
      const product = ShopProduct(
        id: 'test_neem',
        title: 'Southern Ag Triple Action Neem Oil',
        description: 'Fungicide and Insecticide',
        price: '\$14.99',
        rating: 4.6,
        reviewCount: 3420,
        imageUrl: 'https://m.media-amazon.com/images/I/71Z5oBB9jYL.jpg',
        asin: 'B004QAWGIO',
        category: 'Pest & Disease Control',
      );

      final json = product.toJson();
      expect(json['id'], equals('test_neem'));
      expect(json['title'], equals('Southern Ag Triple Action Neem Oil'));
      expect(json['asin'], equals('B004QAWGIO'));
      expect(json['category'], equals('Pest & Disease Control'));

      final restored = ShopProduct.fromJson(json);
      expect(restored.id, equals(product.id));
      expect(restored.title, equals(product.title));
      expect(restored.price, equals(product.price));
      expect(restored.rating, equals(product.rating));
      expect(restored.reviewCount, equals(product.reviewCount));
      expect(restored.imageUrl, equals(product.imageUrl));
      expect(restored.asin, equals(product.asin));
      expect(restored.category, equals(product.category));
    });

    test('copyWith updates properties correctly', () {
      const product = ShopProduct(
        id: 'test_1',
        title: 'Original Title',
        description: 'Desc',
        price: '\$10.00',
        rating: 4.0,
        reviewCount: 50,
        imageUrl: 'https://example.com/img.jpg',
        asin: 'B000000000',
        category: 'Tools',
      );

      final updated = product.copyWith(
        title: 'Updated Title',
        price: '\$12.99',
        rating: 4.8,
      );

      expect(updated.id, equals('test_1'));
      expect(updated.title, equals('Updated Title'));
      expect(updated.price, equals('\$12.99'));
      expect(updated.rating, equals(4.8));
      expect(updated.asin, equals('B000000000'));
    });
  });
}
