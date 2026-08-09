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
    required this.funFacts,
  });

  /// Hardcoded high-quality mock data for the 14 PlantVillage supported species + typical house plants
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
        funFacts: [
          'Strawberries are the only fruit that wear their seeds on the outside—an average strawberry has about 200 seeds.',
          'Strawberries are actually members of the Rose family!'
        ],
      )
    ];
}
