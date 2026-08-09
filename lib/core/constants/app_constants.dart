class AppConstants {
  // ── Database & Asset Configuration ──────────────────────
  static const String treatmentDataPath = 'assets/data/treatment_data.json';

  // ── Amazon Affiliate Tag ──────────────────────────────────
  // Centralised here so it is consistent across the shop, AI recommendations,
  // and any future surface. Change this single value to rotate the tag.
  static const String affiliateTag = '83847-20';
  
  // ── Supabase Configuration ────────────────────────────────
  // Credentials are injected at build time via --dart-define.
  // The defaultValue is intentionally left empty so that no live credential
  // is ever baked into the app binary. The admin API-key flow (fetch from
  // Supabase → persist to SharedPreferences) continues to work unchanged.
  static const String defaultSupabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String defaultSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // ── Gemini Configuration ────────────────────────────────
  static const String defaultGeminiModel = 'gemini-3.6-flash';
  static const String defaultGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  
  // ── Shared Preferences Keys ──────────────────────────────
  static const String keyScanHistory = 'scan_history';
  static const String keySupabaseUrl = 'supabase_url';
  static const String keySupabaseAnonKey = 'supabase_anon_key';

  // ── Structured Prompt Templates for Gemini ─────────────────
  
  /// Step 1 detection prompt — identifies plant vs non-plant, species, and disease.
  static const String geminiDetectionPrompt = 
      "You are a professional plant pathologist and botanist with 20 years of field experience. Carefully examine the provided image.\n"
      "Your task: Determine if the image depicts any plant, leaf, stem, root, crop, flower, seedling, or any botanical subject.\n\n"
      "Return ONLY a raw JSON object (no markdown, no code blocks, no backticks, no extra text) with exactly these keys:\n"
      "- 'is_plant' (boolean): true if the image contains any plant or botanical subject. false for animals, humans, food (that is not a raw plant), vehicles, objects, empty scenes, etc.\n"
      "- 'species' (string): The most specific common name of the plant (e.g. 'Tomato', 'Rose', 'Peace Lily'). Use 'Unknown Plant' if species is indeterminate.\n"
      "- 'disease' (string): The most likely disease or condition name (e.g. 'Early Blight', 'Powdery Mildew'). Use 'Healthy' if the plant appears healthy.\n\n"
      "Examples:\n"
      "{\"is_plant\": true, \"species\": \"Tomato\", \"disease\": \"Early Blight\"}\n"
      "{\"is_plant\": true, \"species\": \"Monstera\", \"disease\": \"Healthy\"}\n"
      "{\"is_plant\": false, \"species\": \"Unknown\", \"disease\": \"Unknown\"}\n\n"
      "CRITICAL: If the image is a human face, animal, vehicle, food dish, building, or any non-botanical subject, you MUST return is_plant: false. Do not guess at plant species if you are not confident.";

  /// Step 2 full diagnosis prompt — generates a comprehensive, professional agronomic report.
  static String geminiDiagnosisPrompt(String species, String disease) {
    return "You are a senior plant pathologist and certified agronomist. Write an authoritative, detailed clinical report for a '$species' specimen showing signs of '$disease'.\n"
        "Your report must be professional, evidence-based, and immediately actionable for a grower.\n"
        "Return ONLY a raw JSON object (no markdown blocks, no backticks, no text outside the JSON) with these exact keys:\n\n"
        "{\n"
        "  \"name\": \"$disease\",\n"
        "  \"species\": \"$species\",\n"
        "  \"severity\": \"One of: Low, Moderate, High, or Critical — based on typical progression of this disease\",\n"
        "  \"confidence\": 0.92,\n"
        "  \"description\": \"Write 2-3 sentences: What causes this disease, how it spreads, and its overall agronomic impact on $species. Be specific and scientific but readable.\",\n"
        "  \"symptoms\": [\n"
        "    \"Observable symptom 1 with specific visual details (color, pattern, location on plant)\",\n"
        "    \"Observable symptom 2 describing progression or spread pattern\",\n"
        "    \"Observable symptom 3 covering secondary effects like wilting, stunted growth, or yield impact\"\n"
        "  ],\n"
        "  \"treatment\": [\n"
        "    \"Immediate action step 1 — be specific (product type, application rate, timing)\",\n"
        "    \"Immediate action step 2 — cultural practice or isolation measure\",\n"
        "    \"Immediate action step 3 — follow-up treatment or monitoring protocol\"\n"
        "  ],\n"
        "  \"prevention\": [\n"
        "    \"Long-term prevention guideline 1 — specific and actionable\",\n"
        "    \"Long-term prevention guideline 2 — environmental or cultural control\",\n"
        "    \"Long-term prevention guideline 3 — resistant variety or rotation strategy\"\n"
        "  ]\n"
        "}";
  }

  /// Species identification prompt — generates rich botanical profile from image.
  static String geminiIdentifyPrompt() {
    return "You are a world-class botanist and horticulturalist. Identify the plant species shown in this image with high precision.\n"
        "Return ONLY a raw JSON object (no markdown blocks, no backticks, no extra text) with these exact keys:\n\n"
        "{\n"
        "  \"commonName\": \"Most widely known common name (e.g. Snake Plant)\",\n"
        "  \"scientificName\": \"Full binomial scientific name (e.g. Dracaena trifasciata)\",\n"
        "  \"family\": \"Botanical family name (e.g. Asparagaceae)\",\n"
        "  \"description\": \"2-3 sentence elegant description: origin, notable characteristics, why it is popular as a houseplant or crop.\",\n"
        "  \"careDifficulty\": \"Exactly one of: Easy, Medium, or Hard\",\n"
        "  \"wateringFrequencyDays\": 10,\n"
        "  \"fertilizingFrequencyDays\": 30,\n"
        "  \"lightRequirement\": \"Exactly one of: Full Sun, Bright Indirect Light, or Low Light\",\n"
        "  \"toxicity\": \"Exactly one of: Toxic to pets & humans, Toxic to cats & dogs, or Safe for pets\",\n"
        "  \"confidence\": 0.94\n"
        "}";
  }
}
