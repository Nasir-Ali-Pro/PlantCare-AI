import '../core/constants/app_constants.dart';

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

  /// Generates the standard Amazon affiliate redirect link using the centralised tag.
  String get affiliateUrl =>
      'https://www.amazon.com/dp/$asin?tag=${AppConstants.affiliateTag}';

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

  // Local high-definition shop product images helper.
  // Assets are keyed by productId only.
  static String _img(String productId) =>
      'assets/images/shop/$productId.jpg';

  static final List<ShopProduct> defaultProducts = [
    // ── Pest & Disease Control ─────────────────────────────────────────────
    ShopProduct(
      id: 'prod_neem_oil',
      title: 'Southern Ag Triple Action Neem Oil',
      description:
          'OMRI-listed cold-pressed neem oil concentrate — the ultimate 3-in-1 organic solution. Controls fungal diseases (powdery mildew, rust, black spot), sap-sucking insects (aphids, whiteflies, spider mites), and soft-bodied pests in a single application. Ideal for vegetables, herbs, and ornamentals.',
      price: '\$14.99',
      rating: 4.6,
      reviewCount: 3420,
      imageUrl: _img('prod_neem_oil'),
      asin: 'B004QAWGIO',
      category: 'Pest & Disease Control',
    ),
    ShopProduct(
      id: 'prod_systemic_pest',
      title: 'Bonide Systemic Houseplant Insect Control',
      description:
          'Granular systemic insecticide that absorbs through roots for inside-out plant protection lasting up to 8 weeks. Defends against aphids, scale, thrips, fungus gnats, and whiteflies — no spraying required. Sprinkle on soil and water in.',
      price: '\$11.95',
      rating: 4.7,
      reviewCount: 1890,
      imageUrl: _img('prod_systemic_pest'),
      asin: 'B000BX1HKI',
      category: 'Pest & Disease Control',
    ),
    ShopProduct(
      id: 'prod_copper_fungicide',
      title: 'Bonide Copper Fungicide Spray',
      description:
          'Broad-spectrum copper-based fungicide and bactericide approved for organic gardening. Controls blight, leaf curl, powdery mildew, downy mildew, anthracnose, and fire blight. Ready-to-use formula — no mixing required.',
      price: '\$16.97',
      rating: 4.5,
      reviewCount: 2870,
      imageUrl: _img('prod_copper_fungicide'),
      asin: 'B000BQKRSS',
      category: 'Pest & Disease Control',
    ),
    ShopProduct(
      id: 'prod_insect_soap',
      title: 'Safer Brand Insect Killing Soap Concentrate',
      description:
          'OMRI-listed insecticidal soap that kills soft-bodied insects on contact — no residue left behind after drying. Effective against aphids, mites, whiteflies, mealybugs, leafhoppers, and more. Safe for vegetables, fruits, and ornamentals. Makes up to 6 gallons of ready-to-spray solution.',
      price: '\$9.97',
      rating: 4.4,
      reviewCount: 6820,
      imageUrl: _img('prod_insect_soap'),
      asin: 'B00CPKH8XI',
      category: 'Pest & Disease Control',
    ),

    // ── Fertilizers & Soil ─────────────────────────────────────────────────
    ShopProduct(
      id: 'prod_miracle_gro',
      title: 'Miracle-Gro Water Soluble All Purpose Plant Food',
      description:
          'The most trusted fertilizer brand for 60+ years. Complete NPK formula (24-8-16) feeds instantly for lush foliage, vibrant blooms, and vigorous vegetables. Works on all houseplants, flowers, vegetables, and shrubs. Feeds up to 600 sq. ft. per pack.',
      price: '\$8.49',
      rating: 4.8,
      reviewCount: 82500,
      imageUrl: _img('prod_miracle_gro'),
      asin: 'B000F6XGZ0',
      category: 'Fertilizers & Soil',
    ),
    ShopProduct(
      id: 'prod_soil_mix',
      title: 'Espoma Organic Potting Soil Mix',
      description:
          'Premium all-natural organic potting mix enriched with Myco-tone mycorrhizae for stronger root development and better drought resistance. Contains sphagnum peat moss, perlite, and earthworm castings. Ideal for indoor containers.',
      price: '\$12.99',
      rating: 4.5,
      reviewCount: 4210,
      imageUrl: _img('prod_soil_mix'),
      asin: 'B002Y08J3E',
      category: 'Fertilizers & Soil',
    ),

    // ── Gardening Tools ────────────────────────────────────────────────────
    ShopProduct(
      id: 'prod_fiskars_shears',
      title: 'Fiskars Micro-Tip Pruning Shears',
      description:
          'Award-winning precision micro-tip pruning scissors with hardened steel non-stick blade for clean, quick cuts every time. Ergonomic soft-grip handles reduce hand fatigue. Perfect for deadheading, trimming dead leaves, and shaping potted plants.',
      price: '\$13.58',
      rating: 4.8,
      reviewCount: 15400,
      imageUrl: _img('prod_fiskars_shears'),
      asin: 'B01MU8CP1W',
      category: 'Gardening Tools',
    ),
    ShopProduct(
      id: 'prod_garden_gloves',
      title: 'COOLJOB Gardening Gloves (6 Pairs)',
      description:
          'Breathable rubber-coated safety work gloves with textured grip for secure handling of soil, pots, and tools. Form-fitting design for excellent dexterity while planting or weeding. Machine washable. Great value 6-pair pack for everyday garden use.',
      price: '\$13.99',
      rating: 4.5,
      reviewCount: 9200,
      imageUrl: _img('prod_garden_gloves'),
      asin: 'B08863XWN2',
      category: 'Gardening Tools',
    ),

    // ── Watering Equipment ─────────────────────────────────────────────────
    ShopProduct(
      id: 'prod_moisture_meter',
      title: 'XLUX Soil Moisture Meter',
      description:
          'Simple, accurate, no-battery-needed soil moisture sensor. Instantly reads moisture level on a clear 1-10 scale — take the guesswork out of watering and prevent root rot. Perfect for houseplants, succulents, vegetables, and outdoor garden beds.',
      price: '\$10.99',
      rating: 4.5,
      reviewCount: 51300,
      imageUrl: _img('prod_moisture_meter'),
      asin: 'B014MJ8J2U',
      category: 'Watering Equipment',
    ),


    // ── Indoor Growing ─────────────────────────────────────────────────────
    ShopProduct(
      id: 'prod_grow_light',
      title: 'SANSI 15W LED Grow Light Bulb',
      description:
          'Full-spectrum COC LED grow bulb engineered for indoor plant growth. Emits 380-780nm spectrum mimicking natural sunlight. Fits standard E26 socket, uses ceramic heatsink for cool operation and 50,000-hour lifespan.',
      price: '\$17.99',
      rating: 4.7,
      reviewCount: 4700,
      imageUrl: _img('prod_grow_light'),
      asin: 'B07BRKT56T',
      category: 'Indoor Growing',
    ),
    ShopProduct(
      id: 'prod_superthrive',
      title: 'SUPERthrive Plant Vitamin Solution',
      description:
          'A legendary, non-toxic vitamin solution used by professional gardeners for over 80 years. Contains Vitamin B1 and kelp to reduce transplant shock, promote strong root development, and revive stressed plants. A small amount goes a very long way — just a few drops per gallon.',
      price: '\$12.49',
      rating: 4.6,
      reviewCount: 14700,
      imageUrl: _img('prod_superthrive'),
      asin: 'B000OM82J0',
      category: 'Indoor Growing',
    ),
    ShopProduct(
      id: 'prod_rooting_powder',
      title: 'Bonide Bontone II Rooting Powder',
      description:
          'The go-to rooting hormone for plant propagation. Contains Indole-3-butyric acid (IBA) to stimulate rapid root development in cuttings, bulbs, and corms. Simply dip the dampened stem end into the powder before planting. Works on pothos, philodendrons, woody shrubs, and most ornamentals.',
      price: '\$6.49',
      rating: 4.5,
      reviewCount: 8950,
      imageUrl: _img('prod_rooting_powder'),
      asin: 'B000BX1HGC',
      category: 'Indoor Growing',
    ),
    ShopProduct(
      id: 'prod_pruning_gloves',
      title: 'Thornproof Leather Gardening Gloves',
      description:
          'Heavy-duty cowhide leather gloves with extended gauntlet cuffs to protect hands and forearms from thorns, brambles, and prickly plants. Ergonomic keystone thumb design ensures natural grip while handling rose bushes, cacti, and heavy tools.',
      price: '\$18.99',
      rating: 4.8,
      reviewCount: 4120,
      imageUrl: _img('prod_pruning_gloves'),
      asin: 'B073Z1P5QC',
      category: 'Gardening Tools',
    ),
    ShopProduct(
      id: 'prod_plant_food_spikes',
      title: 'Miracle-Gro Indoor Plant Food Spikes',
      description:
          'Feeds all indoor houseplants including pothos, monstera, and ferns for up to 2 full months. Contains micronutrients to encourage vibrant green foliage and root growth. Safe for all potted plants when used as directed.',
      price: '\$6.99',
      rating: 4.7,
      reviewCount: 15800,
      imageUrl: _img('prod_plant_food_spikes'),
      asin: 'B001V57M52',
      category: 'Fertilizers & Soil',
    ),
    ShopProduct(
      id: 'prod_leaf_shine',
      title: 'Miracle-Gro Leaf Shine Spray & Cleaner',
      description:
          'Water-based foliage spray that creates a natural, glossy shine on hard-surfaced houseplant leaves. Cleans away dust, water spots, and mineral buildup while keeping stomata unclogged for healthy leaf transpiration.',
      price: '\$9.49',
      rating: 4.6,
      reviewCount: 6420,
      imageUrl: _img('prod_leaf_shine'),
      asin: 'B000OWB4O6',
      category: 'Pest & Disease Control',
    ),
  ];
}
