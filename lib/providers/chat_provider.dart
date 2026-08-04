import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/api/gemini_service.dart';
import '../models/diagnosis_report.dart';
import '../models/chat_message_model.dart';
import '../services/database_service.dart';
import '../core/utils/error_utils.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatProvider extends ChangeNotifier {
  final GeminiService _gemini = GeminiService();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  DiagnosisReport? _activeConsultationReport;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  DiagnosisReport? get activeConsultationReport => _activeConsultationReport;

  ChatProvider() {
    _loadPersistedMessages();
  }

  /// Load last 50 messages from SQLite on startup so conversation persists across sessions.
  Future<void> _loadPersistedMessages() async {
    try {
      final saved = await DatabaseService.getChatMessages();
      if (saved.isEmpty) {
        _messages.add(ChatMessage(
          text: "Hello! I am your PlantCare AI Assistant. 🌿\n\nAsk me anything about your garden, plant health, watering schedules, or pest control. How can I help you today?",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      } else {
        // Restore persisted messages
        for (final m in saved) {
          _messages.add(ChatMessage(
            text: m.text,
            isUser: m.isUser,
            timestamp: m.timestamp,
          ));
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Failed to load persisted chat messages: $e');
      _messages.add(ChatMessage(
        text: "Hello! I am your PlantCare AI Assistant. 🌿\n\nAsk me anything about your garden, plant health, watering schedules, or pest control. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  void init(String apiKey) {
    _gemini.init(apiKey);
  }

  /// Sends a message, triggers typing state, calls GeminiService and updates state
  Future<void> sendMessage(String text, {String? gardenContext}) async {
    if (text.trim().isEmpty) return;

    // 1. Add user message
    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _isTyping = true;
    notifyListeners();

    // Persist user message
    _persistMessage(userMsg);

    try {
      // 2. Map message list to Google Generative AI Content objects for history context!
      final historyContents = <Content>[];

      if (_activeConsultationReport != null) {
        final rep = _activeConsultationReport!;
        final diagnosisContext = "Context: I am consulting you as the AI Plant Doctor about my ${rep.plantName} which has ${rep.diseaseName} (Severity: ${rep.severity}). Description: ${rep.description}. Symptoms: ${rep.symptoms.join(', ')}. Treatments: ${rep.treatment.join(', ')}.";
        historyContents.add(Content('user', [
          TextPart(diagnosisContext)
        ]));
        historyContents.add(Content('model', [
          TextPart("Understood. I will act as the AI Plant Doctor and answer your questions specifically about this diagnosis and treatment of ${rep.diseaseName} for your ${rep.plantName}.")
        ]));
      } else if (gardenContext != null && gardenContext.isNotEmpty) {
        historyContents.add(Content('user', [
          TextPart("Here is context about my current garden plants: $gardenContext")
        ]));
        historyContents.add(Content('model', [
          TextPart("Understood! I will customize my advice based on your current garden plants.")
        ]));
      }

      // Convert the last 6 messages to history (excluding the very first welcome message)
      final historyMessages = _messages.length > 8
          ? _messages.sublist(_messages.length - 7, _messages.length - 1)
          : _messages.sublist(1, _messages.length - 1);

      for (var msg in historyMessages) {
        if (msg.isUser) {
          historyContents.add(Content('user', [TextPart(msg.text)]));
        } else {
          historyContents.add(Content('model', [TextPart(msg.text)]));
        }
      }

      // 3. Ask Gemini
      var responseText = await _gemini.chatWithAssistant(
        history: historyContents,
        newMessage: text,
      );

      // Sanitize off-topic responses to be exactly the requested wording
      final cleanLower = responseText.toLowerCase().trim();
      if (cleanLower.contains("sorry") && cleanLower.contains("not my field")) {
        responseText = "Sorry, this is not my field.";
      }

      // 4. Add assistant response
      final aiMsg = ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMsg);
      _persistMessage(aiMsg);
    } catch (e) {
      final userFriendlyText = AppErrorUtils.getUserFriendlyMessage(e);
      final errMsg = ChatMessage(
        text: userFriendlyText,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(errMsg);
      _persistMessage(errMsg);
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  /// Persist a single message to SQLite asynchronously (fire-and-forget).
  void _persistMessage(ChatMessage msg) {
    final model = ChatMessageModel(
      id: '${msg.timestamp.millisecondsSinceEpoch}_${msg.isUser ? 1 : 0}',
      text: msg.text,
      isUser: msg.isUser,
      timestamp: msg.timestamp,
    );
    DatabaseService.saveChatMessage(model).catchError((e) {
      debugPrint('⚠️ Failed to persist chat message: $e');
    });
  }

  void startDoctorConsultation(DiagnosisReport report) {
    _activeConsultationReport = report;
    _messages.clear();

    final text = "Hello! I am your AI Plant Doctor. 🩺\n\n"
        "I've loaded the diagnosis report for your **${report.plantName}** which was diagnosed with **${report.diseaseName}** (${report.severity} severity).\n\n"
        "Here is a summary of recommended treatments:\n"
        "${report.treatment.map((t) => '• $t').join('\n')}\n\n"
        "How can I help you treat or manage this condition?";

    _messages.add(ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void clearConsultation() {
    _activeConsultationReport = null;
    clearChat();
  }

  Future<void> clearChat() async {
    _activeConsultationReport = null;
    _messages.clear();
    // Clear persisted messages from SQLite too
    try {
      await DatabaseService.clearChatMessages();
    } catch (e) {
      debugPrint('⚠️ Failed to clear persisted chat: $e');
    }
    _messages.add(ChatMessage(
      text: "Chat cleared! How can I help you with your plants today? 🌸",
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}
