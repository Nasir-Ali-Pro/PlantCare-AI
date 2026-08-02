class ShopProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String asin;
  final String category;

  const ShopProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.asin,
    required this.category,
  });

  /// Generates the standard Amazon affiliate redirect link with tag 83847-20
  String get affiliateUrl => 'https://www.amazon.com/dp/$asin?tag=83847-20';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'rating': rating,
      'review_count': reviewCount,
      'image_url': imageUrl,
      'asin': asin,
      'category': category,
    };
  }

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    return ShopProduct(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
      asin: json['asin'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }

  ShopProduct copyWith({
    String? id,
    String? title,
    String? description,
    String? price,
    double? rating,
    int? reviewCount,
    String? imageUrl,
    String? asin,
    String? category,
  }) {
    return ShopProduct(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      imageUrl: imageUrl ?? this.imageUrl,
      asin: asin ?? this.asin,
      category: category ?? this.category,
    );
  }

  // Unsplash CDN helper — produces a stable, hotlink-friendly URL
  static String _img(String photoId) =>
      'https://images.unsplash.com/$photoId'
      '?w=400&auto=format&fit=crop&q=80';

  static final List<ShopProduct> defaultProducts = [
    // ── Pest & Disease Control ─────────────────────────────────
    ShopProduct(
      id: 'prod_neem_oil',
      title: 'Southern Ag Triple Action Neem Oil',
      description:
          'OMRI-listed cold-pressed neem oil concentrate — the ultimate 3-in-1 organic solution. Controls fungal diseases (powdery mildew, rust, black spot), sap-sucking insects (aphids, whiteflies, spider mites), and soft-bodied pests in a single application. Highly effective on vegetables, herbs, and ornamentals.',
      price: '\$14.99',
      rating: 4.6,
      reviewCount: 3420,
      imageUrl: _img('photo-1574671235952-f6c15a4ebf33'),
      asin: 'B004QAWGIO',
      category: 'Pest & Disease Control',
    ),
    ShopProduct(
      id: 'prod_systemic_pest',
      title: 'Bonide Systemic Houseplant Insect Control',
      description:
          'Granular systemic insecticide that absorbs through roots for inside-out plant protection lasting up to 8 weeks. One application defends the entire plant against aphids, scale, thrips, fungus gnats, and whiteflies — no spraying required. Simply sprinkle on soil and water in.',
      price: '\$11.95',
      rating: 4.7,
      reviewCount: 1890,
      imageUrl: _img('photo-1601004890657-d6f7b3beefbc'),
      asin: 'B000BX1HKI',
      category: 'Pest & Disease Control',
    ),
    ShopProduct(
      id: 'prod_copper_fungicide',
      title: 'Bonide Copper Fungicide Spray',
      description:
          'Broad-spectrum copper-based fungicide and bactericide approved for organic gardening. Controls blight, leaf curl, powdery mildew, downy mildew, anthracnose, and fire blight on vegetables, fruits, and ornamentals. Ready-to-use formula — no mixing required.',
      price: '\$16.97',
      rating: 4.5,
      reviewCount: 2870,
      imageUrl: _img('photo-1592503254549-d83d24a492cf'),
      asin: 'B000BQKRSS',
      category: 'Pest & Disease Control',
    ),

    // ── Fertilizers & Soil ────────────────────────────────────
    ShopProduct(
      id: 'prod_miracle_gro',
      title: 'Miracle-Gro Water Soluble All Purpose Plant Food',
      description:
          'The most trusted fertilizer brand for 60+ years. This complete NPK formula (24-8-16) feeds plant roots and leaves instantly for lush foliage, vibrant blooms, and vigorous vegetables. Works on all houseplants, flowers, vegetables, and shrubs. Feeds up to 600 sq. ft. per pack.',
      price: '\$8.49',
      rating: 4.8,
      reviewCount: 82500,
      imageUrl: _img('photo-1416879595882-3373a0480b5b'),
      asin: 'B000F6XGZ0',
      category: 'Fertilizers & Soil',
    ),
    ShopProduct(
      id: 'prod_soil_mix',
      title: 'Espoma Organic Potting Soil Mix',
      description:
          'Premium all-natural organic potting mix enriched with Myco-tone mycorrhizae for stronger root development and better drought resistance. Contains sphagnum peat moss, perlite, and earthworm castings. Perfectly balanced for moisture retention and drainage — ideal for indoor containers.',
      price: '\$12.99',
      rating: 4.5,
      reviewCount: 4210,
      imageUrl: _img('photo-1585421514738-01798e348b17'),
      asin: 'B002Y08J3E',
      category: 'Fertilizers & Soil',
    ),
    ShopProduct(
      id: 'prod_perlite',
      title: 'Organic Perlite by Gardenera (1 Qt)',
      description:
          'Professional-grade horticultural perlite for improving soil drainage, aeration, and root health. Essential amendment for preventing root rot in succulent, cactus, and houseplant mixes. Lightweight and pH-neutral — mix with any potting soil at a 20-30% ratio.',
      price: '\$9.95',
      rating: 4.6,
      reviewCount: 3150,
      imageUrl: _img('photo-1484318571209-661cf29a69d3'),
      asin: 'B08HM3DWG3',
      category: 'Fertilizers & Soil',
    ),

    // ── Gardening Tools ────────────────────────────────────────
    ShopProduct(
      id: 'prod_fiskars_shears',
      title: 'Fiskars Micro-Tip Pruning Shears',
      description:
          'Award-winning precision micro-tip pruning scissors with hardened steel non-stick blade for clean, quick cuts every time. Ergonomic soft-grip handles reduce hand fatigue. Perfect for deadheading flowers, trimming dead leaves, and shaping potted plants. Easy push-button opening.',
      price: '\$13.58',
      rating: 4.8,
      reviewCount: 15400,
      imageUrl: _img('photo-1416575890019-c4e4cb6af4cd'),
      asin: 'B01MU8CP1W',
      category: 'Gardening Tools',
    ),
    ShopProduct(
      id: 'prod_hand_trowel',
      title: 'Fiskars Ergo Gardening Hand Trowel',
      description:
          'Ergonomically designed heavy-duty cast aluminum trowel with a comfortable soft-grip handle for reduced wrist fatigue. Graduated measurements on the blade help with precise planting depth. Rust-resistant and ideal for transplanting, digging, and loosening soil in pots and beds.',
      price: '\$8.99',
      rating: 4.8,
      reviewCount: 3820,
      imageUrl: _img('photo-1564419320461-6870880221ad'),
      asin: 'B00002N5HG',
      category: 'Gardening Tools',
    ),
    ShopProduct(
      id: 'prod_garden_gloves',
      title: 'COOLJOB Gardening Gloves (6 Pairs)',
      description:
          'Breathable rubber-coated safety work gloves with textured grip for secure handling of soil, pots, and tools. Form-fitting design for excellent dexterity while planting or weeding. Machine washable. Available in multiple sizes — great value 6-pair pack for everyday garden use.',
      price: '\$13.99',
      rating: 4.5,
      reviewCount: 8650,
      imageUrl: _img('photo-1620912167809-e21c7f0e56c6'),
      asin: 'B07GVDB7V1',
      category: 'Gardening Tools',
    ),

    // ── Watering Equipment ─────────────────────────────────────
    ShopProduct(
      id: 'prod_moisture_meter',
      title: 'XLUX Soil Moisture Meter',
      description:
          'Simple, accurate, no-battery-needed soil moisture sensor. Instantly reads moisture level on a clear 1-10 scale — take the guesswork out of watering and prevent root rot from overwatering. Perfect for all houseplants, succulents, vegetables, and outdoor garden beds.',
      price: '\$10.99',
      rating: 4.5,
      reviewCount: 47800,
      imageUrl: _img('photo-1523348837708-15d4a09cfac2'),
      asin: 'B00FJFLJMS',
      category: 'Watering Equipment',
    ),
    ShopProduct(
      id: 'prod_watering_can',
      title: 'Mkono 1.6L Long Spout Indoor Watering Can',
      description:
          'Elegant rose-gold stainless steel watering can with a precision long spout for accurate root-zone watering of indoor plants, terrariums, and hanging baskets. 1.6L capacity reduces refill trips. Rust-proof and lightweight — the perfect desk or windowsill companion.',
      price: '\$19.99',
      rating: 4.6,
      reviewCount: 5280,
      imageUrl: _img('photo-1525498128493-380d1990a112'),
      asin: 'B07NJ5P7XJ',
      category: 'Watering Equipment',
    ),

    // ── Pots & Containers ──────────────────────────────────────
    ShopProduct(
      id: 'prod_self_watering_pots',
      title: 'Lechuza Classico Self-Watering Planter',
      description:
          'Premium German-engineered self-watering planter with a sub-irrigation reservoir that keeps roots consistently moist without waterlogging. Sleek matte finish in multiple colors. The internal water level indicator shows exactly when to refill — no more guessing or wilted plants.',
      price: '\$29.99',
      rating: 4.7,
      reviewCount: 2840,
      imageUrl: _img('photo-1485955900006-10f4d324d411'),
      asin: 'B01LXQPJVL',
      category: 'Pots & Containers',
    ),
    ShopProduct(
      id: 'prod_hanging_pots',
      title: 'La Jolie Muse Hanging Planter Pots (2-Pack)',
      description:
          'Stylish weather-resistant hanging planters with a concrete-texture finish that blends seamlessly with modern interior décor. Built-in drainage holes prevent root rot. Includes adjustable hanging rope. Perfect for trailing plants like pothos, ivy, string of pearls, and spider plants.',
      price: '\$21.99',
      rating: 4.7,
      reviewCount: 1840,
      imageUrl: _img('photo-1463554050456-f2ed7d3fec09'),
      asin: 'B07BRCPNZX',
      category: 'Pots & Containers',
    ),

    // ── Indoor Growing ─────────────────────────────────────────
    ShopProduct(
      id: 'prod_grow_light',
      title: 'SANSI 15W LED Grow Light Bulb',
      description:
          'Full-spectrum COC LED grow bulb engineered for indoor plant growth. Emits a balanced 380-780nm spectrum that mimics natural sunlight for photosynthesis, flowering, and fruiting. Fits standard E26 socket, uses ceramic heatsink for cool operation and 50,000-hour lifespan. Ideal for any room.',
      price: '\$17.99',
      rating: 4.7,
      reviewCount: 4700,
      imageUrl: _img('photo-1558618666-fcd25c85cd64'),
      asin: 'B07BRKT56T',
      category: 'Indoor Growing',
    ),
    ShopProduct(
      id: 'prod_propagation_station',
      title: 'Mkono Plant Propagation Station (5 Tubes)',
      description:
          'Minimalist borosilicate glass propagation station with a modern wood frame. Includes 5 hanging test tubes for rooting cuttings in water — watch roots develop in real time. A beautiful and functional piece for plant lovers. Works great with pothos, herbs, succulents, and tropical cuttings.',
      price: '\$22.99',
      rating: 4.6,
      reviewCount: 3280,
      imageUrl: _img('photo-1517191434949-5e90cd67d2b6'),
      asin: 'B07WFPWFMR',
      category: 'Indoor Growing',
    ),
  ];
}
