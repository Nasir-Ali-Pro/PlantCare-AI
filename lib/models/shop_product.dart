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

  static const List<ShopProduct> defaultProducts = [
    ShopProduct(
      id: 'prod_neem_oil',
      title: 'Southern Ag Triple Action Neem Oil',
      description: 'Organic cold-pressed neem oil concentrate. Serves as an all-in-one insecticide, fungicide, and miticide. Controls rust, powdery mildew, black spot, spider mites, aphids, whiteflies, and other leaf-damaging pests.',
      price: '\$14.99',
      rating: 4.6,
      reviewCount: 3420,
      imageUrl: 'https://images.unsplash.com/photo-1604762524889-3e2fdf464403?q=80&w=600&auto=format&fit=crop',
      asin: 'B004QAWGIO',
      category: 'Pest & Disease Control',
    ),
    ShopProduct(
      id: 'prod_systemic_pest',
      title: 'Bonide Systemic Houseplant Insect Control',
      description: 'Granular systemic insect control that provides protection up to 8 weeks. Absorbed through roots to protect the entire plant from inside out. Highly effective against aphids, scale, thrips, fungus gnats, and whiteflies.',
      price: '\$11.95',
      rating: 4.7,
      reviewCount: 1890,
      imageUrl: 'https://images.unsplash.com/photo-1592150621744-aca64f48394a?q=80&w=600&auto=format&fit=crop',
      asin: 'B000BX1HKI',
      category: 'Pest & Disease Control',
    ),
    ShopProduct(
      id: 'prod_miracle_gro',
      title: 'Miracle-Gro Water Soluble Plant Food',
      description: 'Instant foliar feeding and root nourishment for all house plants, vegetables, flowers, and shrubs. Rich in essential nutrients to promote lush green foliage, strong root development, and beautiful blooms.',
      price: '\$8.49',
      rating: 4.8,
      reviewCount: 8250,
      imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?q=80&w=600&auto=format&fit=crop',
      asin: 'B000F6XGZ0',
      category: 'Fertilizers & Soil',
    ),
    ShopProduct(
      id: 'prod_soil_mix',
      title: 'Espoma Organic Potting Soil Mix (4 qt)',
      description: 'Curated premium organic potting soil blend enhanced with Myco-tone mycorrhizae. Provides excellent aeration, water retention, and essential nutrient uptake for indoor container plants and potted herbs.',
      price: '\$12.99',
      rating: 4.5,
      reviewCount: 4210,
      imageUrl: 'https://images.unsplash.com/photo-1463936575829-25148e1db1b8?q=80&w=600&auto=format&fit=crop',
      asin: 'B002Y08J3E',
      category: 'Fertilizers & Soil',
    ),
    ShopProduct(
      id: 'prod_fiskars_shears',
      title: 'Fiskars Micro-Tip Pruning Shears',
      description: 'Award-winning precision non-stick micro-tip pruning scissors. Engineered for clean, quick cuts on stems and leaves. Ideal for deadheading, trimming dead leaves, and promoting healthy bushier plant growth.',
      price: '\$13.58',
      rating: 4.8,
      reviewCount: 15400,
      imageUrl: 'https://images.unsplash.com/photo-1589051030485-26824d2713d9?q=80&w=600&auto=format&fit=crop',
      asin: 'B01MU8CP1W',
      category: 'Gardening Tools',
    ),
    ShopProduct(
      id: 'prod_garden_gloves',
      title: 'Gardening Gloves with Fingertip Claws',
      description: 'Heavy duty, puncture-resistant protective garden work gloves. Features integrated ABS plastic claws on one hand for quick digging, planting seeds, and raking soil without separate hand trowels.',
      price: '\$9.99',
      rating: 4.4,
      reviewCount: 2200,
      imageUrl: 'https://images.unsplash.com/photo-1617155093730-a8bf47be792d?q=80&w=600&auto=format&fit=crop',
      asin: 'B01MY7DNDH',
      category: 'Gardening Tools',
    ),
    ShopProduct(
      id: 'prod_moisture_meter',
      title: 'VIVOSUN 3-in-1 Soil Moisture & pH Meter',
      description: 'High precision soil moisture, sunlight intensity, and pH level tester. No batteries required. Help prevent overwatering, root rot, and check if your soil acidity levels match your plant requirements.',
      price: '\$10.99',
      rating: 4.5,
      reviewCount: 6310,
      imageUrl: 'https://images.unsplash.com/photo-1599839619421-26c7104b0870?q=80&w=600&auto=format&fit=crop',
      asin: 'B0184O6W4E',
      category: 'Watering Equipment',
    ),
    ShopProduct(
      id: 'prod_watering_can',
      title: 'Union Products 2-Gallon Classic Watering Can',
      description: 'Classic durable blow-molded plastic watering container. Features dual handles for comfortable control and a 2-gallon capacity to minimize refills. Ideal for indoor and outdoor plants.',
      price: '\$15.89',
      rating: 4.4,
      reviewCount: 10228,
      imageUrl: 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?q=80&w=600&auto=format&fit=crop',
      asin: 'B000BQWWJK',
      category: 'Watering Equipment',
    ),
    ShopProduct(
      id: 'prod_self_watering_pots',
      title: 'Self-Watering Pots for Indoor Plants (3-Pack)',
      description: 'Elegant minimalist 3-pack self-watering planters with double-layer design and water level indicator gauge. Ensures roots are aerated and watered continuously for up to 14 days without daily watering.',
      price: '\$18.99',
      rating: 4.5,
      reviewCount: 1419,
      imageUrl: 'https://images.unsplash.com/photo-1485955900006-10f4d324d411?q=80&w=600&auto=format&fit=crop',
      asin: 'B085C7Y367',
      category: 'Pots & Containers',
    ),
    ShopProduct(
      id: 'prod_grow_light',
      title: 'SANSI 15W LED Grow Light Bulb',
      description: 'Full-spectrum indoor daylight horticultural grow bulb. Fits standard E26 sockets. Uses ceramic heat-sink technology for long lifespans. Emits a clean white light perfect for living rooms and offices.',
      price: '\$16.99',
      rating: 4.7,
      reviewCount: 4700,
      imageUrl: 'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?q=80&w=600&auto=format&fit=crop',
      asin: 'B07BRKT56T',
      category: 'Indoor Growing',
    ),
    ShopProduct(
      id: 'prod_plant_book',
      title: 'The Houseplant Care Manual by David Longman',
      description: 'A comprehensive, step-by-step masterclass guide on watering, feeding, diagnosing diseases, and propagation of over 100 indoor houseplants. Includes color photographs and expert botanical instructions.',
      price: '\$19.95',
      rating: 4.6,
      reviewCount: 310,
      imageUrl: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=600&auto=format&fit=crop',
      asin: '1545805561',
      category: 'Books & Guides',
    ),
    ShopProduct(
      id: 'prod_modern_sprout',
      title: 'Modern Sprout Self-Watering Glass Herb Kit',
      description: 'Chic passive hydroponic self-watering glass mason jar grow kit. Features organic non-GMO herb seeds, grow medium, and a coco-coir wick system. Perfect for growing fresh kitchen herbs on window sills.',
      price: '\$24.00',
      rating: 4.3,
      reviewCount: 520,
      imageUrl: 'https://images.unsplash.com/photo-1530968464165-7a1861cbaf9f?q=80&w=600&auto=format&fit=crop',
      asin: 'B01C0A4O0Q',
      category: 'Pots & Containers',
    ),
    ShopProduct(
      id: 'prod_hand_trowel',
      title: 'Fiskars Ergo Gardening Hand Trowel',
      description: 'Ergonomically designed heavy-duty cast aluminum hand trowel. Ideal for digging, planting seeds, turning up soil, and transplanting flowers without hand or wrist fatigue.',
      price: '\$8.99',
      rating: 4.8,
      reviewCount: 3820,
      imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?q=80&w=600&auto=format&fit=crop',
      asin: 'B004S0PGPM',
      category: 'Gardening Tools',
    ),
    ShopProduct(
      id: 'prod_hanging_pots',
      title: 'La Jolie Muse Hanging Planter Pots (2-Pack)',
      description: 'Stylish weather-resistant indoor/outdoor concrete-patterned hanging pots. Built-in drainage holes to prevent root rot. Perfect for ivy, ferns, spider plants, and pothos.',
      price: '\$21.99',
      rating: 4.7,
      reviewCount: 1840,
      imageUrl: 'https://images.unsplash.com/photo-1525498128493-380d1990a112?q=80&w=600&auto=format&fit=crop',
      asin: 'B083Q7J12W',
      category: 'Pots & Containers',
    ),
    ShopProduct(
      id: 'prod_drip_system',
      title: 'Raindrip Automatic Container Drip Watering Kit',
      description: 'Complete automatic irrigation system with digital timer for patio container plants and raised garden beds. Conservatively waters up to 20 plants directly at the root zone.',
      price: '\$34.99',
      rating: 4.4,
      reviewCount: 1120,
      imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?q=80&w=600&auto=format&fit=crop',
      asin: 'B00J2NRUBI',
      category: 'Watering Equipment',
    ),
  ];
}
