import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/constants/app_constants.dart';

class GeminiService {
  GenerativeModel? _model;
  GenerativeModel? _chatModel;

  bool get isConfigured => _model != null;

  GenerativeModel get generativeModel {
    if (_model == null) {
      throw Exception("Gemini API key is not configured. Please add your key in Settings.");
    }
    return _model!;
  }

  /// Initializes the Gemini API client using the provided key
  void init(String apiKey) {
    if (apiKey.isEmpty) return;
    
    _model = GenerativeModel(
      model: AppConstants.defaultGeminiModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
    _chatModel = GenerativeModel(
      model: AppConstants.defaultGeminiModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'text/plain',
      ),
      systemInstruction: Content.system(
        "You are a master botanist and agricultural expert. Provide highly accurate, friendly, and structured advice about plant care, soil, disease prevention, and watering.\n"
        "Keep answers extremely brief, concise, and precise, answering only what is asked without any unnecessary introductory pleasantries, meta-commentary, or wordy explanations to avoid token waste. Keep formatting clear and compact.\n"
        "Always respond in natural, conversational plain text. Do NOT use JSON structures, curly braces, brackets, or key-value pairs. Strictly output raw, clean natural text without any special JSON formatting, brackets, or coding syntax. Do not output anything inside curly braces {} or square brackets [].\n"
        "Do not use markdown styling like asterisks or hashes (no stars, no bold, no italic, no headings) in your responses.\n\n"
        "RECOMMENDATION RULE: If the user asks about, mentions, or could benefit from any agricultural products (like fertilizers, potting soils, pruning shears, moisture meters, grow lights, self-watering pots, pest control/fungicides/neem oil), you should recommend one or more appropriate products from our catalog and include their direct Amazon link. Always use this exact link format: https://www.amazon.com/dp/ASIN?tag=83847-20 (replacing ASIN with the actual ASIN of the product).\n"
        "Our Catalog:\n"
        "1. Southern Ag Triple Action Neem Oil (Fungus/mildew/rust/mites/aphids/whiteflies). ASIN: B004QAWGIO. Link: https://www.amazon.com/dp/B004QAWGIO?tag=83847-20\n"
        "2. Bonide Systemic Houseplant Insect Control (Systemic insecticide for gnats, thrips, scale, aphids). ASIN: B000BX1HKI. Link: https://www.amazon.com/dp/B000BX1HKI?tag=83847-20\n"
        "3. Miracle-Gro Water Soluble Plant Food (All-purpose nutrient fertilizer for leafy growth). ASIN: B000F6XGZ0. Link: https://www.amazon.com/dp/B000F6XGZ0?tag=83847-20\n"
        "4. Espoma Organic Potting Soil Mix (Premium potting soil with mycorrhizae for root health). ASIN: B002Y08J3E. Link: https://www.amazon.com/dp/B002Y08J3E?tag=83847-20\n"
        "5. Fiskars Micro-Tip Pruning Shears (For trimming, deadheading, and pruning leaves/stems). ASIN: B01MU8CP1W. Link: https://www.amazon.com/dp/B01MU8CP1W?tag=83847-20\n"
        "6. VIVOSUN 3-in-1 Soil Moisture & pH Meter (To check soil moisture/prevent overwatering). ASIN: B0184O6W4E. Link: https://www.amazon.com/dp/B0184O6W4E?tag=83847-20\n"
        "7. SANSI 15W LED Grow Light Bulb (Full-spectrum grow light bulb for indoor lighting). ASIN: B07BRKT56T. Link: https://www.amazon.com/dp/B07BRKT56T?tag=83847-20\n"
        "8. Self-Watering Pots 3-Pack (Double-layer containers to prevent overwatering/root rot). ASIN: B085C7Y367. Link: https://www.amazon.com/dp/B085C7Y367?tag=83847-20\n"
        "9. Houseplant Care Manual by David Longman (Step-by-step care guide book). ASIN: 1545805561. Link: https://www.amazon.com/dp/1545805561?tag=83847-20\n\n"
        "CRITICAL RULE: If the user asks a question that is NOT related to agriculture, gardening, botany, plants, crops, soil, farming, or plant care, you must NOT answer the question. You MUST only reply with exactly these words: 'Sorry, this is not my field.' and absolutely nothing else. Do not provide any context, explanations, greetings, or other text."
      ),
    );
    debugPrint("☁️ Gemini API Service initialized successfully!");
  }


  /// Conversation AI chat with history
  Future<String> chatWithAssistant({
    required List<Content> history,
    required String newMessage,
  }) async {
    if (_chatModel == null) {
      throw Exception("Gemini API Key is not set. Please add your key in Settings.");
    }

    final contents = [...history, Content.text(newMessage)];
    final response = await _chatModel!.generateContent(contents);
    return response.text ?? "I'm sorry, I couldn't generate a response.";
  }
}
