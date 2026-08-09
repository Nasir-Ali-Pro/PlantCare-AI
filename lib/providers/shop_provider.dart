import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';
import '../models/shop_product.dart';
import '../services/api/supabase_service.dart';
import '../services/database_service.dart';

class ShopProvider extends ChangeNotifier {
  // State
  List<ShopProduct> _products = [];
  List<String> _favoriteIds = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortMode = 'Popularity'; // Popularity, Rating, Price: Low to High, Price: High to Low

  // Getters
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get sortMode => _sortMode;

  List<ShopProduct> get allProducts => _products;

  /// Returns the catalog of products after applying active search, category filters, and sorting.
  List<ShopProduct> get products {
    var list = _products.where((p) {
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    // Sort the list
    switch (_sortMode) {
      case 'Rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Price: Low to High':
        list.sort((a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)));
        break;
      case 'Price: High to Low':
        list.sort((a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)));
        break;
      case 'Popularity':
      default:
        list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }
    return list;
  }

  /// Returns only the products in the user's wishlist/favorites.
  List<ShopProduct> get wishlist {
    return _products.where((p) => _favoriteIds.contains(p.id)).toList();
  }

  // ── Initialization ────────────────────────────────────────

  ShopProvider() {
    loadProducts();
  }

  /// Load catalog products from Supabase and wishlist from SQLite database.
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load favorites from SQLite
      _favoriteIds = await DatabaseService.getFavoriteProductIds();

      // Load products from Supabase (falls back to local defaults on error/miss)
      _products = await SupabaseService().fetchShopProducts();
    } catch (e) {
      debugPrint("🚨 Error in ShopProvider initialization: $e");
      // Fallback
      _products = ShopProduct.defaultProducts;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Favorites Actions ─────────────────────────────────────

  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  Future<void> toggleFavorite(String productId) async {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
      await DatabaseService.removeFavoriteProductId(productId);
    } else {
      _favoriteIds.add(productId);
      await DatabaseService.addFavoriteProductId(productId);
    }
    notifyListeners();
  }

  // ── Filter & Search Setters ───────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortMode(String mode) {
    _sortMode = mode;
    notifyListeners();
  }

  // ── Helper Price Parser ───────────────────────────────────

  double _parsePrice(String priceString) {
    // Standardize price representation e.g. "$14.99" -> 14.99
    final cleaned = priceString.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  // ── Deep Linking & Click Tracking ─────────────────────────

  /// Logs click analytics and attempts to launch the Amazon Shopping App directly (deep link)
  /// before falling back to the browser redirect.
  Future<void> logClickAndLaunch(String productId, String asin) async {
    // 1. Await the analytics call so failures are caught, not silently swallowed
    try {
      await SupabaseService().logShopClick(productId);
    } catch (e) {
      debugPrint('⚠️ Click analytics failed (non-fatal): $e');
    }

    // 2. Build deep link URIs — affiliate tag comes from AppConstants (single source of truth)
    final String deepLinkUrl = 'amzn://dp/$asin';
    final String webUrl = 'https://www.amazon.com/dp/$asin?tag=${AppConstants.affiliateTag}';

    final Uri deepUri = Uri.parse(deepLinkUrl);
    final Uri webUri = Uri.parse(webUrl);

    try {
      // Try launching official Amazon App directly
      final launched = await launchUrl(deepUri, mode: LaunchMode.externalNonBrowserApplication);
      if (!launched) {
        // Fallback to external browser
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("⚠️ Deep link launch failed, opening web URL: $e");
      // Fallback
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (err) {
        debugPrint("🚨 Browser launch failed: $err");
      }
    }
  }
}
