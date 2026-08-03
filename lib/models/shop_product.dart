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

  // Supabase CDN Storage public URL helper for shop product images
  static String _img(String photoId, String productId) =>
      'https://ljvsigniwvpbmhhxphen.supabase.co/storage/v1/object/public/shop_products/$productId.jpg';

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
      imageUrl: _img('photo-1574671235952-f6c15a4ebf33', 'prod_neem_oil'),
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
      imageUrl: _img('photo-1601004890657-d6f7b3beefbc', 'prod_systemic_pest'),
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
      imageUrl: _img('photo-1592503254549-d83d24a492cf', 'prod_copper_fungicide'),
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
      imageUrl: _img('photo-1530836369250-ef72a3f5cda8', 'prod_insect_soap'),
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
      imageUrl: _img('photo-1416879595882-3373a0480b5b', 'prod_miracle_gro'),
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
      imageUrl: _img('photo-1585421514738-01798e348b17', 'prod_soil_mix'),
      asin: 'B002Y08J3E',
      category: 'Fertilizers & Soil',
    ),
    ShopProduct(
      id: 'prod_perlite',
      title: 'Organic Perlite by Gardenera (1 Qt)',
      description:
          'Professional-grade horticultural perlite for improving soil drainage, aeration, and root health. Essential for preventing root rot in succulent, cactus, and houseplant mixes. Lightweight and pH-neutral — mix at a 20-30% ratio.',
      price: '\$9.95',
      rating: 4.6,
      reviewCount: 3150,
      imageUrl: _img('photo-1484318571209-661cf29a69d3', 'prod_perlite'),
      asin: 'B08HM3DWG3',
      category: 'Fertilizers & Soil',
    ),
    ShopProduct(
      id: 'prod_osmocote',
      title: 'Osmocote Smart-Release Plant Food Plus',
      description:
          'America\'s #1 brand of slow-release fertilizer. Each granule is coated with a semi-permeable resin that releases nutrients based on soil temperature — feeding plants for up to 6 months with a single application. Works for all indoor and outdoor plants, in containers and in-ground.',
      price: '\$19.97',
      rating: 4.7,
      reviewCount: 28400,
      imageUrl: _img('photo-1444930694458-01babf71870c', 'prod_osmocote'),
      asin: 'B000UJVGX0',
      category: 'Fertilizers & Soil',
    ),
    ShopProduct(
      id: 'prod_foxfarm_soil',
      title: 'FoxFarm Ocean Forest Potting Soil',
      description:
          'The premium potting mix trusted by professional growers. A powerful blend of earthworm castings, bat guano, sea-going fish and crab meal, aged forest products, and sphagnum peat moss. pH adjusted at 6.3–6.8 for optimum plant performance and vigorous growth from start to finish.',
      price: '\$21.99',
      rating: 4.7,
      reviewCount: 19200,
      imageUrl: _img('photo-1515150144380-bca9f1650049', 'prod_foxfarm_soil'),
      asin: 'B00L0AOKYO',
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
      imageUrl: _img('photo-1416575890019-c4e4cb6af4cd', 'prod_fiskars_shears'),
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
      imageUrl: _img('photo-1620912167809-e21c7f0e56c6', 'prod_garden_gloves'),
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
      imageUrl: _img('photo-1523348837708-15d4a09cfac2', 'prod_moisture_meter'),
      asin: 'B014MJ8J2U',
      category: 'Watering Equipment',
    ),
    ShopProduct(
      id: 'prod_watering_can',
      title: 'Mkono 1.6L Long Spout Indoor Watering Can',
      description:
          'Elegant rose-gold stainless steel watering can with a precision long spout for accurate root-zone watering of indoor plants, terrariums, and hanging baskets. 1.6L capacity. Rust-proof and lightweight — the perfect windowsill companion.',
      price: '\$19.99',
      rating: 4.6,
      reviewCount: 5280,
      imageUrl: _img('photo-1525498128493-380d1990a112', 'prod_watering_can'),
      asin: 'B07NJ5P7XJ',
      category: 'Watering Equipment',
    ),

    // ── Pots & Containers ──────────────────────────────────────────────────
    ShopProduct(
      id: 'prod_self_watering_pots',
      title: 'Lechuza Classico Self-Watering Planter',
      description:
          'Premium German-engineered self-watering planter with a sub-irrigation reservoir that keeps roots consistently moist. Sleek matte finish in multiple colors. Internal water level indicator shows exactly when to refill — no more wilted plants.',
      price: '\$29.99',
      rating: 4.7,
      reviewCount: 2840,
      imageUrl: _img('photo-1485955900006-10f4d324d411', 'prod_self_watering_pots'),
      asin: 'B01LXQPJVL',
      category: 'Pots & Containers',
    ),
    ShopProduct(
      id: 'prod_hanging_pots',
      title: 'La Jolie Muse Hanging Planter Pots (2-Pack)',
      description:
          'Stylish weather-resistant hanging planters with a concrete-texture finish. Built-in drainage holes prevent root rot. Includes adjustable hanging rope. Perfect for trailing plants like pothos, ivy, string of pearls, and spider plants.',
      price: '\$21.99',
      rating: 4.7,
      reviewCount: 1840,
      imageUrl: _img('photo-1463554050456-f2ed7d3fec09', 'prod_hanging_pots'),
      asin: 'B07BRCPNZX',
      category: 'Pots & Containers',
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
      imageUrl: _img('photo-1558618666-fcd25c85cd64', 'prod_grow_light'),
      asin: 'B07BRKT56T',
      category: 'Indoor Growing',
    ),
    ShopProduct(
      id: 'prod_propagation_station',
      title: 'Mkono Plant Propagation Station (5 Tubes)',
      description:
          'Minimalist borosilicate glass propagation station with a modern wood frame. Five hanging test tubes let you root cuttings in water and watch roots develop in real time. Works great with pothos, herbs, succulents, and tropical cuttings.',
      price: '\$22.99',
      rating: 4.6,
      reviewCount: 3280,
      imageUrl: _img('photo-1517191434949-5e90cd67d2b6', 'prod_propagation_station'),
      asin: 'B07WFPWFMR',
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
      imageUrl: _img('photo-1457530378978-8bac673b8062', 'prod_superthrive'),
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
      imageUrl: _img('photo-1549893072-4bc678117f95', 'prod_rooting_powder'),
      asin: 'B000BX1HGC',
      category: 'Indoor Growing',
    ),
    ShopProduct(
      id: 'prod_aerogarden',
      title: 'AeroGarden Harvest Indoor Garden',
      description:
          'Grow fresh herbs, salad greens, and vegetables year-round with no soil needed. The patented hydroponic system delivers nutrients directly to roots for up to 5x faster growth than soil. Full-spectrum LED panel included. Holds 6 pods — grow basil, mint, parsley, cherry tomatoes, and more indoors.',
      price: '\$89.95',
      rating: 4.6,
      reviewCount: 35800,
      imageUrl: _img('photo-1552944150-6dd1180e5999', 'prod_aerogarden'),
      asin: 'B07PGL273N',
      category: 'Indoor Growing',
    ),
    ShopProduct(
      id: 'prod_jobes_spikes',
      title: "Jobe's Fertilizer Spikes for Houseplants",
      description:
          'Pre-measured fertilizer spikes that deliver nutrients directly to the root zone — no mess, no smell, and no guesswork. Each spike releases a continuous supply of nutrients for 2 months. Simply push into damp soil near the plant roots every 30 days. Works for all indoor potted plants.',
      price: '\$7.49',
      rating: 4.5,
      reviewCount: 12600,
      imageUrl: _img('photo-1509423350716-97f9360b4e09', 'prod_jobes_spikes'),
      asin: 'B000UGBGSO',
      category: 'Fertilizers & Soil',
    ),
  ];
}
