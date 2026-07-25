class AppConstants {
  // ── Database & Asset Configuration ──────────────────────
  static const String treatmentDataPath = 'assets/data/treatment_data.json';
  
  // ── Supabase Configuration ────────────────────────────────
  // These placeholders serve as fallbacks if the user has not configured their own in Settings
  static const String defaultSupabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://ljvsigniwvpbmhhxphen.supabase.co');
  static const String defaultSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'sb_publishable_w5MxUBgJjs9zFDcuGhYUHw_cjcZuiB8');

  // ── Gemini Configuration ────────────────────────────────
  static const String defaultGeminiModel = 'gemini-2.5-flash';
  static const String defaultGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'YOUR_GEMINI_API_KEY');
  
  // ── Shared Preferences Keys ──────────────────────────────
  static const String keyScanHistory = 'scan_history';
  static const String keySupabaseUrl = 'supabase_url';
  static const String keySupabaseAnonKey = 'supabase_anon_key';

  // ── Structured Prompt Templates for Gemini ─────────────────
  
  /// Low-token prompt used to quickly identify plant species and disease/health issues.
  static const String geminiDetectionPrompt = 
      "Analyze the image and determine if it represents a plant, leaf, crop, or agricultural subject.\n"
      "Return ONLY a JSON object with keys 'is_plant' (boolean), 'species' (string), and 'disease' (string). "
      "Do NOT include any markdown code blocks, curly quotes, backticks, or additional text. Just raw JSON.\n\n"
      "Example if it is a plant:\n"
      "{\"is_plant\": true, \"species\": \"Tomato\", \"disease\": \"Early Blight\"}\n\n"
      "Example if it is NOT a plant (e.g. human face, car, animal, random object, text, etc.):\n"
      "{\"is_plant\": false, \"species\": \"Unknown\", \"disease\": \"Unknown\"}\n\n"
      "If the plant leaf is completely healthy, return \"Healthy\" as the disease.";

  /// Detailed generation prompt when database lookup is a miss.
  static String geminiDiagnosisPrompt(String species, String disease) {
    return "You are a master botanist and plant pathologist. Write a professional, highly detailed, and complete agricultural report for a $species leaf showing signs of '$disease'.\n"
        "Return the report in a strict JSON format with the following keys. Do NOT include markdown code blocks, backticks, or any text outside the JSON:\n\n"
        "{\n"
        "  \"name\": \"$disease\",\n"
        "  \"species\": \"$species\",\n"
        "  \"severity\": \"Low, Moderate, High, or Critical\",\n"
        "  \"confidence\": 0.95,\n"
        "  \"description\": \"Provide a thorough, highly professional explanation of this issue and its impact on the plant.\",\n"
        "  \"symptoms\": [\n"
        "    \"Detailed symptom description 1...\",\n"
        "    \"Detailed symptom description 2...\",\n"
        "    \"Detailed symptom description 3...\"\n"
        "  ],\n"
        "  \"treatment\": [\n"
        "    \"Step-by-step immediate treatment step 1...\",\n"
        "    \"Step-by-step immediate treatment step 2...\",\n"
        "    \"Step-by-step immediate treatment step 3...\"\n"
        "  ],\n"
        "  \"prevention\": [\n"
        "    \"Long-term prevention guideline 1...\",\n"
        "    \"Long-term prevention guideline 2...\",\n"
        "    \"Long-term prevention guideline 3...\"\n"
        "  ]\n"
        "}";
  }

  /// Prompt for plant species identification mode.
  static String geminiIdentifyPrompt() {
    return "You are a master botanist. Identify the plant species in this image.\n"
        "Return the result in a strict JSON format with the following keys. Do NOT include markdown code blocks, backticks, or any text outside the JSON:\n\n"
        "{\n"
        "  \"commonName\": \"Common name of the plant (e.g. Monstera Deliciosa)\",\n"
        "  \"scientificName\": \"Scientific name (e.g. Monstera deliciosa)\",\n"
        "  \"family\": \"Botanical family name (e.g. Araceae)\",\n"
        "  \"description\": \"Brief elegant description of the plant and its features.\",\n"
        "  \"careDifficulty\": \"Easy, Medium, or Hard\",\n"
        "  \"wateringFrequencyDays\": 7,\n"
        "  \"fertilizingFrequencyDays\": 30,\n"
        "  \"lightRequirement\": \"Bright Indirect Light, Full Sun, or Low Light\",\n"
        "  \"toxicity\": \"Toxic to cats & dogs or Safe for pets\",\n"
        "  \"confidence\": 0.95\n"
        "}";
  }
}
