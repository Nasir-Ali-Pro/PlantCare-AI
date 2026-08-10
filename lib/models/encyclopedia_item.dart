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
  final String imageUrl; // Dedicated high-resolution plant profile image
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

  /// Verified plant profile image URLs for all encyclopedia species
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
      imageUrl: 'https://images.pexels.com/photos/1327838/pexels-photo-1327838.jpeg?auto=compress&cs=tinysrgb&w=800',
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
      imageUrl: 'https://images.pexels.com/photos/2286776/pexels-photo-2286776.jpeg?auto=compress&cs=tinysrgb&w=800',
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
      imageUrl: 'https://images.pexels.com/photos/102104/pexels-photo-102104.jpeg?auto=compress&cs=tinysrgb&w=800',
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
      imageUrl: 'https://images.pexels.com/photos/1434254/pexels-photo-1434254.jpeg?auto=compress&cs=tinysrgb&w=800',
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
      imageUrl: 'https://images.pexels.com/photos/547263/pexels-photo-547263.jpeg?auto=compress&cs=tinysrgb&w=800',
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
      imageUrl: 'https://images.pexels.com/photos/708777/pexels-photo-708777.jpeg?auto=compress&cs=tinysrgb&w=800',
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
      imageUrl: 'https://images.pexels.com/photos/89778/strawberries-frisch-ripe-sweet-89778.jpeg?auto=compress&cs=tinysrgb&w=800',
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
      imageUrl: 'https://images.pexels.com/photos/3097770/pexels-photo-3097770.jpeg?auto=compress&cs=tinysrgb&w=800',
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
      imageUrl: 'https://images.pexels.com/photos/212372/pexels-photo-212372.jpeg?auto=compress&cs=tinysrgb&w=800',
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
      imageUrl: 'https://images.pexels.com/photos/4503751/pexels-photo-4503751.jpeg?auto=compress&cs=tinysrgb&w=800',
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
      imageUrl: 'https://images.pexels.com/photos/736230/pexels-photo-736230.jpeg?auto=compress&cs=tinysrgb&w=800',
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
      imageUrl: 'https://images.pexels.com/photos/1382393/pexels-photo-1382393.jpeg?auto=compress&cs=tinysrgb&w=800',
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
      imageUrl: 'https://images.pexels.com/photos/1166869/pexels-photo-1166869.jpeg?auto=compress&cs=tinysrgb&w=800',
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
      imageUrl: 'https://images.pexels.com/photos/1087902/pexels-photo-1087902.jpeg?auto=compress&cs=tinysrgb&w=800',
      funFacts: [
        'Pinching off flower buds promotes bushy leaf growth and extends the harvest season.',
        'In Italian tradition, placing a pot of basil on a balcony signifies readiness for romance!'
      ],
    ),
  ];
}
