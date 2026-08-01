import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mime/mime.dart';

import '../core/constants/app_constants.dart';
import '../models/diagnosis_report.dart';
import 'api/gemini_service.dart';
import 'api/supabase_service.dart';

class PlantDiagnosisOrchestrator {
  final GeminiService _geminiService;
  final SupabaseService _supabaseService = SupabaseService();

  PlantDiagnosisOrchestrator({
    required GeminiService geminiService,
  }) : _geminiService = geminiService;

  Future<void> init() async {
    // No-op or load initial state if needed
  }

  /// The intelligent Supabase-cached diagnostic pipeline
  Future<DiagnosisReport> diagnose({
    required dynamic imageFile,
    Function(String)? onStatusUpdate,
  }) async {
    final String reportId = 'rep_${DateTime.now().millisecondsSinceEpoch}';

    if (!_geminiService.isConfigured) {
      throw Exception("Gemini API key is not configured. Please add your key in Settings.");
    }

    // ── Step 1: Detect Species and Disease Name (Low-Token Query) ──
    onStatusUpdate?.call("Detecting plant species and health markers...");
    final detectionResult = await _detectSpeciesAndDisease(imageFile);
    
    final bool isPlant = detectionResult['is_plant'] == true || detectionResult['is_plant']?.toString().toLowerCase() == 'true';
    if (!isPlant) {
      throw Exception("NOT_A_PLANT: Please upload a clear photo of a plant, leaf, or crop to begin diagnosis.");
    }

    final String species = detectionResult['species'] ?? 'Unknown Plant';
    final String disease = detectionResult['disease'] ?? 'Healthy';

    // ── Step 2: Query Supabase Database for existing expert template ──
    if (_supabaseService.isConfigured) {
      onStatusUpdate?.call("Checking pathology database...");
      final cachedReport = await _supabaseService.fetchDiseaseReport(
        plantName: species,
        diseaseName: disease,
        reportId: reportId,
        imagePath: imageFile.path,
      );
      
      if (cachedReport != null) {
        return cachedReport;
      }
    }

    // ── Step 3: Cache Miss - Request full generation and save to database ──
    onStatusUpdate?.call("Generating detailed pathology report...");
    final fullReport = await _generateFullReport(imageFile, species, disease, reportId);

    // Save back to cloud database to cache for all other users
    if (_supabaseService.isConfigured) {
      await _supabaseService.saveDiseaseReport(fullReport);
    }

    return fullReport;
  }

  /// Identify the plant species using Gemini Vision
  Future<DiagnosisReport> identify({
    required dynamic imageFile,
    Function(String)? onStatusUpdate,
  }) async {
    final String reportId = 'rep_${DateTime.now().millisecondsSinceEpoch}';

    if (!_geminiService.isConfigured) {
      throw Exception("Gemini API key is not configured. Please add your key in Settings.");
    }

    onStatusUpdate?.call("Identifying plant species...");
    
    final imageBytes = await imageFile.readAsBytes();
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

    final content = [
      Content.multi([
        TextPart(AppConstants.geminiIdentifyPrompt()),
        DataPart(mimeType, imageBytes),
      ])
    ];

    try {
      final response = await _geminiService.generativeModel.generateContent(content);
      final rawText = response.text;

      if (rawText == null || rawText.isEmpty) {
        throw Exception("Failed to identify plant characteristics.");
      }

      final cleanJson = _cleanJsonText(rawText);
      final Map<String, dynamic> data = json.decode(cleanJson);

      final String commonName = data['commonName'] ?? 'Unknown Plant';
      final String scientificName = data['scientificName'] ?? 'Unknown Scientific Name';
      
      return DiagnosisReport(
        id: reportId,
        source: "Botanical Species ID",
        plantName: commonName,
        diseaseName: "Identified Species", // Key identifier for ID vs Diagnosis
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.90,
        severity: data['careDifficulty'] ?? "Medium",
        description: data['description'] ?? "Identified plant species.",
        symptoms: [scientificName], // reuse lists cleanly
        treatment: [
          "Watering Frequency: every ${data['wateringFrequencyDays'] ?? 7} days",
          "Fertilizing Frequency: every ${data['fertilizingFrequencyDays'] ?? 30} days",
        ],
        prevention: [
          "Light Requirement: ${data['lightRequirement'] ?? 'Indirect Light'}",
          "Toxicity: ${data['toxicity'] ?? 'Safe'}",
        ],
        imagePath: imageFile.path,
        dateTime: DateTime.now(),
        isOfflineResult: false,
        localCritiqueExplanation: cleanJson, // save full json data
      );
    } catch (e) {
      debugPrint("⚠️ Plant identification failed: $e");
      rethrow;
    }
  }

  /// Queries Gemini with a light prompt to extract only the plant name and disease name.
  Future<Map<String, dynamic>> _detectSpeciesAndDisease(dynamic imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

    final content = [
      Content.multi([
        TextPart(AppConstants.geminiDetectionPrompt),
        DataPart(mimeType, imageBytes),
      ])
    ];

    try {
      final response = await _geminiService.generativeModel.generateContent(content);
      final rawText = response.text;
      
      if (rawText == null || rawText.isEmpty) {
        throw Exception("Failed to identify plant characteristics.");
      }

      final cleanJson = _cleanJsonText(rawText);
      final Map<String, dynamic> parsed = json.decode(cleanJson);
      
      return {
        'is_plant': parsed['is_plant'] ?? true,
        'species': parsed['species']?.toString() ?? 'Unknown Plant',
        'disease': parsed['disease']?.toString() ?? 'Healthy',
      };
    } catch (e) {
      debugPrint("⚠️ Low-token detection query failed: $e");
      rethrow;
    }
  }

  /// Queries Gemini to generate a complete pathological report based on the identified plant and disease
  Future<DiagnosisReport> _generateFullReport(
    dynamic imageFile,
    String species,
    String disease,
    String reportId,
  ) async {
    final prompt = AppConstants.geminiDiagnosisPrompt(species, disease);
    
    // We pass the image along to ensure Gemini builds the description, symptoms, and severity 
    // exactly matching the visual state of the leaf uploaded.
    final imageBytes = await imageFile.readAsBytes();
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart(mimeType, imageBytes),
      ])
    ];

    try {
      final response = await _geminiService.generativeModel.generateContent(content);
      final rawText = response.text;

      if (rawText == null || rawText.isEmpty) {
        throw Exception("Failed to generate complete pathology report.");
      }

      final cleanJson = _cleanJsonText(rawText);
      final Map<String, dynamic> data = json.decode(cleanJson);

      return DiagnosisReport(
        id: reportId,
        source: "Botanical Analysis Report",
        plantName: data['species'] ?? species,
        diseaseName: data['name'] ?? disease,
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.85,
        severity: data['severity'] ?? "Moderate",
        description: data['description'] ?? "No description generated.",
        symptoms: List<String>.from(data['symptoms'] ?? []),
        treatment: List<String>.from(data['treatment'] ?? []),
        prevention: List<String>.from(data['prevention'] ?? []),
        imagePath: imageFile.path,
        dateTime: DateTime.now(),
        isOfflineResult: false,
      );
    } catch (e) {
      debugPrint("⚠️ Full pathological report generation failed: $e");
      rethrow;
    }
  }

  /// Utility to clean markdown fenced block codes (e.g. ```json ... ```)
  String _cleanJsonText(String rawText) {
    var cleaned = rawText.trim();
    if (cleaned.startsWith('```')) {
      final index = cleaned.indexOf('\n');
      if (index != -1) {
        cleaned = cleaned.substring(index).trim();
      }
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3).trim();
    }
    return cleaned;
  }
}
