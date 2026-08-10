class EncyclopediaItem {
  final String id;
  final String commonName;
  final String scientificName;
  final String category; // e.g. "Vegetable", "Flower", "Succulent", "Herb", "Fruit"
  final String careDifficulty; // "Easy", "Medium", "Hard"
  final String sunlight; // "Full Sun", "Partial Shade", "Low Light"
  final String watering; // "High", "Moderate", "Low"
  final String idealSoil;
  final String nativeRegion;
  final String toxicity; // Description of pet/child toxicity
  final String description;
  final String imageUrl; // Dedicated high-resolution Unsplash plant image
  final List<String> funFacts;

  EncyclopediaItem({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.category,
    required this.careDifficulty,
    required this.sunlight,
    required this.watering,
    required this.idealSoil,
    required this.nativeRegion,
    required this.toxicity,
    required this.description,
    required this.imageUrl,
    required this.funFacts,
  });

  /// High-quality encyclopedia data with matching dedicated Unsplash plant images
  static final List<EncyclopediaItem> defaultItems = [
    EncyclopediaItem(
      id: 'ep_1',
      commonName: 'Tomato',
      scientificName: 'Solanum lycopersicum',
      category: 'Vegetable',
      careDifficulty: 'Medium',
      sunlight: 'Full Sun',
      watering: 'Moderate',
      idealSoil: 'Loamy, well-draining, rich in organic matter (pH 6.0-6.8)',
      nativeRegion: 'South America (Andes)',
      toxicity: 'Foliage and stems are toxic to cats and dogs (solanine); ripe fruit is safe.',
      description: 'Tomatoes are tender, warm-season annuals that produce sweet, juicy fruits. They are a staple of backyard gardens and require sturdy staking as they grow.',
      imageUrl: 'https://images.unsplash.com/photo-1592841200221-a6898f307baa?q=80&w=800&auto=format&fit=crop',
      funFacts: [
        'Botanically, tomatoes are berries and thus fruits, but they are culinarily used as vegetables.',
        'The largest tomato plant on record was grown in a greenhouse in Florida and reached over 65 feet long!'
      ],
    ),
    EncyclopediaItem(
      id: 'ep_2',
      commonName: 'Potato',
      scientificName: 'Solanum tuberosum',
      category: 'Vegetable',
      careDifficulty: 'Medium',
      sunlight: 'Full Sun',
      watering: 'Moderate',
      idealSoil: 'Sandy, loose, well-drained soil (pH 5.0-6.0)',
      nativeRegion: 'South American Andes',
      toxicity: 'Green parts of the plant and green tubers contain solanine, which is highly toxic to humans and pets.',
      description: 'Potatoes are starch-rich tuberous root crops that grow completely underground. They are highly productive and enjoy cool-season soil hilling.',
      imageUrl: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?q=80&w=800&auto=format&fit=crop',
      funFacts: [
        'Potatoes were the first vegetable ever to be grown in outer space, aboard the Space Shuttle Columbia in 1995.',
        'There are over 4,000 native varieties of potatoes, mostly found in the Andes.'
      ],
    ),
    EncyclopediaItem(
      id: 'ep_3',
      commonName: 'Apple',
      scientificName: 'Malus domestica',
      category: 'Fruit Tree',
      careDifficulty: 'Hard',
      sunlight: 'Full Sun',
      watering: 'Moderate',
      idealSoil: 'Clay-loam, moist but well-drained (pH 6.0-7.0)',
      nativeRegion: 'Central Asia',
      toxicity: 'Apple seeds contain amygdalin, which releases cyanide when chewed; highly toxic in large quantities.',
      description: 'Apple trees are deciduous orchard trees that require winter chilling hours to successfully set fruit. They are prone to fungal scab but reward growers with fresh, crisp fruit.',
      imageUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?q=80&w=800&auto=format&fit=crop',
      funFacts: [
        'It takes about 36 apples to make one gallon of apple cider.',
        'Archeologists have found evidence that humans have been eating apples since at least 6500 B.C.'
      ],
    ),
    EncyclopediaItem(
      id: 'ep_4',
      commonName: 'Bell Pepper',
      scientificName: 'Capsicum annuum',
      category: 'Vegetable',
      careDifficulty: 'Easy',
      sunlight: 'Full Sun',
      watering: 'Moderate',
      idealSoil: 'Sandy-loam, moist, highly organic soil (pH 6.2-7.0)',
      nativeRegion: 'Central & South America',
      toxicity: 'Leaves and stems are mildly toxic to pets; the pepper fruit is entirely safe.',
      description: 'Bell peppers are warm-season vegetables that change color from green to red, yellow, or orange as they mature. They are sweet and contain high amounts of Vitamin C.',
      imageUrl: 'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?q=80&w=800&auto=format&fit=crop',
      funFacts: [
        'Bell peppers are the only member of the Capsicum family that do not produce capsaicin, meaning they have 0 Scoville Heat Units.',
        'Red bell peppers are simply green peppers that have been left on the vine longer to ripen.'
      ],
    ),
    EncyclopediaItem(
      id: 'ep_5',
      commonName: 'Corn',
      scientificName: 'Zea mays',
      category: 'Vegetable',
      careDifficulty: 'Medium',
      sunlight: 'Full Sun',
      watering: 'High',
      idealSoil: 'Loamy, deep, fertile soil with high nitrogen (pH 5.8-7.0)',
      nativeRegion: 'Mexico',
      toxicity: 'Non-toxic to pets and children.',
      description: 'Corn is a tall annual cereal grass that produces ears containing sweet kernels. It is wind-pollinated and grows best in blocks rather than single rows.',
      imageUrl: 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?q=80&w=800&auto=format&fit=crop',
      funFacts: [
        'An average ear of corn has an even number of rows, usually 16, and contains about 800 kernels.',
        'Corn is grown on every continent except Antarctica.'
      ],
    ),
    EncyclopediaItem(
      id: 'ep_6',
      commonName: 'Grapevine',
      scientificName: 'Vitis vinifera',
      category: 'Fruit Vine',
      careDifficulty: 'Hard',
      sunlight: 'Full Sun',
      watering: 'Low',
      idealSoil: 'Gravelly, deep, well-draining soil (pH 5.5-6.5)',
      nativeRegion: 'Mediterranean & Middle East',
      toxicity: 'Grapes and raisins are highly toxic to dogs and can cause acute kidney failure.',
      description: 'Grapes are climbing woody vines that produce bunches of sweet table or wine berries. They require extensive annual winter pruning and robust trellis support.',
      imageUrl: 'https://images.unsplash.com/photo-1537640538966-79f369143f8f?q=80&w=800&auto=format&fit=crop',
      funFacts: [
        'Vitis vinifera grapevines can live for over 100 years with proper root care.',
        'It takes about 2.5 pounds of grapes to produce one standard 750ml bottle of wine.'
      ],
    ),
    EncyclopediaItem(
      id: 'ep_7',
      commonName: 'Strawberry',
      scientificName: 'Fragaria × ananassa',
      category: 'Fruit',
      careDifficulty: 'Easy',
      sunlight: 'Full Sun',
      watering: 'Moderate',
      idealSoil: 'Rich, sandy-loam, moist and acidic (pH 5.5-6.5)',
      nativeRegion: 'Europe / North America',
      toxicity: 'Non-toxic to cats, dogs, and children.',
      description: 'Strawberries are low-growing herbaceous perennials that produce runners and juicy, bright red berries. They are ideal for ground cover or hanging pots.',
      imageUrl: 'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?q=80&w=800&auto=format&fit=crop',
      funFacts: [
        'Strawberries are the only fruit that wear their seeds on the outside—an average strawberry has about 200 seeds.',
        'Strawberries are actually members of the Rose family!'
      ],
    ),
    EncyclopediaItem(
      id: 'ep_8',
      commonName: 'Monstera Deliciosa',
      scientificName: 'Monstera deliciosa',
      category: 'Houseplant',
      careDifficulty: 'Easy',
      sunlight: 'Bright Indirect Light',
      watering: 'Moderate',
      idealSoil: 'Peat-based, well-draining potting mix (pH 5.5-7.0)',
      nativeRegion: 'Tropical Rainforests of Southern Mexico',
      toxicity: 'Contains insoluble calcium oxalates; toxic to cats and dogs if chewed.',
      description: 'The Swiss Cheese Plant is famous for its iconic perforated split leaves. It thrives indoors with sturdy support like a moss pole.',
      imageUrl: 'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?q=80&w=800&auto=format&fit=crop',
      funFacts: [
        'The holes in Monstera leaves are called fenestrations and help the plant withstand heavy tropical rains.',
        'In the wild, Monstera produces edible tropical fruits that taste like a blend of banana and pineapple!'
      ],
    ),
    EncyclopediaItem(
      id: 'ep_9',
      commonName: 'Snake Plant',
      scientificName: 'Sansevieria trifasciata',
      category: 'Succulent',
      careDifficulty: 'Easy',
      sunlight: 'Low Light',
      watering: 'Low',
      idealSoil: 'Cactus or succulent potting mix with perlite (pH 5.5-7.5)',
      nativeRegion: 'West Africa',
      toxicity: 'Mildly toxic to cats and dogs due to saponins; causes nausea if consumed.',
      description: 'Snake Plant is an indestructible air-purifying houseplant featuring sword-like upright leaves with yellow margins.',
      imageUrl: 'https://images.unsplash.com/photo-1593482892290-f54927ae1bf6?q=80&w=800&auto=format&fit=crop',
      funFacts: [
        'Snake plants perform CAM photosynthesis, releasing oxygen into your bedroom during the night.',
        'They can go up to 4 to 6 weeks without watering during winter months.'
      ],
    ),
    EncyclopediaItem(
      id: 'ep_10',
      commonName: 'Peace Lily',
      scientificName: 'Spathiphyllum wallisii',
      category: 'Houseplant',
      careDifficulty: 'Easy',
      sunlight: 'Low Light',
      watering: 'Moderate',
      idealSoil: 'Rich, moisture-retentive, well-draining potting soil (pH 5.8-6.5)',
      nativeRegion: 'Tropical Americas',
      toxicity: 'Toxic to pets due to calcium oxalate crystals.',
      description: 'Peace Lilies are graceful indoor plants known for their glossy green foliage and pure white spathe blooms.',
      imageUrl: 'https://images.unsplash.com/photo-1593691509543-c55fb32e7355?q=80&w=800&auto=format&fit=crop',
      funFacts: [
        'Peace Lilies dramatically drop their leaves when thirsty, instantly perking back up within an hour of watering.',
        'Ranked by NASA as one of the top air-purifying indoor plants for removing formaldehyde and benzene.'
      ],
    ),
    EncyclopediaItem(
      id: 'ep_11',
      commonName: 'Garden Rose',
      scientificName: 'Rosa rubiginosa',
      category: 'Flower',
      careDifficulty: 'Medium',
      sunlight: 'Full Sun',
      watering: 'Moderate',
      idealSoil: 'Deep, fertile, well-drained clay-loam (pH 6.0-6.5)',
      nativeRegion: 'Europe and Western Asia',
      toxicity: 'Non-toxic to pets; thorns can cause mechanical irritation.',
      description: 'Roses are woody perennial flowering shrubs prized for their fragrant multi-petaled blooms and classic garden elegance.',
      imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=800&auto=format&fit=crop',
      funFacts: [
        'Fossilized rose leaves dating back 35 million years have been discovered in North America.',
        'Rose hips (the fruit of the rose) contain higher concentrations of Vitamin C than oranges!'
      ],
    ),
    EncyclopediaItem(
      id: 'ep_12',
      commonName: 'Aloe Vera',
      scientificName: 'Aloe barbadensis miller',
      category: 'Succulent',
      careDifficulty: 'Easy',
      sunlight: 'Full Sun',
      watering: 'Low',
      idealSoil: 'Gritty, fast-draining cactus mix (pH 7.0-8.5)',
      nativeRegion: 'Arabian Peninsula',
      toxicity: 'Toxic to pets if latex layer under skin is ingested; inner gel is non-toxic.',
      description: 'Aloe Vera is a medicinal succulent with thick fleshy leaves filled with soothing, clear cooling gel.',
      imageUrl: 'https://images.unsplash.com/photo-1596547609652-9cf5d8d76921?q=80&w=800&auto=format&fit=crop',
      funFacts: [
        'Aloe vera gel has been used for over 4,000 years to treat minor skin burns and wounds.',
        'Ancient Egyptians called Aloe Vera the "Plant of Immortality".'
      ],
    ),
    EncyclopediaItem(
      id: 'ep_13',
      commonName: 'English Lavender',
      scientificName: 'Lavandula angustifolia',
      category: 'Herb',
      careDifficulty: 'Medium',
      sunlight: 'Full Sun',
      watering: 'Low',
      idealSoil: 'Lean, rocky, alkaline, well-drained soil (pH 6.7-7.5)',
      nativeRegion: 'Mediterranean',
      toxicity: 'Mildly toxic to pets in large quantities (linalool).',
      description: 'Lavender is a aromatic evergreen shrub with silvery foliage and spikes of fragrant violet-purple blossoms.',
      imageUrl: 'https://images.unsplash.com/photo-1528183429752-a97d0bf99b5a?q=80&w=800&auto=format&fit=crop',
      funFacts: [
        'The name Lavender comes from the Latin word "lavare", which means "to wash".',
        'Lavender essential oil is proven to promote relaxation and improve sleep quality.'
      ],
    ),
    EncyclopediaItem(
      id: 'ep_14',
      commonName: 'Sweet Basil',
      scientificName: 'Ocimum basilicum',
      category: 'Herb',
      careDifficulty: 'Easy',
      sunlight: 'Full Sun',
      watering: 'Moderate',
      idealSoil: 'Moist, rich, well-drained organic soil (pH 6.0-7.0)',
      nativeRegion: 'Central Africa & Southeast Asia',
      toxicity: 'Completely non-toxic to cats, dogs, and humans.',
      description: 'Sweet Basil is an aromatic culinary herb with tender green leaves essential for pestos and Mediterranean cuisine.',
      imageUrl: 'https://images.unsplash.com/photo-1608686207856-001b95cf60ca?q=80&w=800&auto=format&fit=crop',
      funFacts: [
        'Pinching off flower buds promotes bushy leaf growth and extends the harvest season.',
        'In Italian tradition, placing a pot of basil on a balcony signifies readiness for romance!'
      ],
    ),
  ];
}
