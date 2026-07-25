import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/constants/app_constants.dart';
import '../models/diagnosis_report.dart';
import '../services/api/gemini_service.dart';
import '../services/api/supabase_service.dart';
import '../services/diagnosis_orchestrator.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';

enum ScanMode {
  diagnose,
  identify,
}

enum DiagnosisState {
  idle,
  loadingImage,
  analyzingLocal,
  verifyingCloud,
  success,
  error,
}

class DiagnosisProvider extends ChangeNotifier {
  // Services
  final GeminiService _gemini = GeminiService();
  late PlantDiagnosisOrchestrator _orchestrator;

  // State Variables
  DiagnosisState _state = DiagnosisState.idle;
  ScanMode _scanMode = ScanMode.diagnose;
  String? _errorMessage;
  dynamic _selectedImage;
  DiagnosisReport? _currentReport;
  
  List<DiagnosisReport> _history = [];
  String _geminiApiKey = '';
  String _supabaseUrl = '';
  String _supabaseAnonKey = '';
  final bool _hasIntegrityViolation = false;
  
  // UI Loading message
  String _statusMessage = '';

  // Getters
  ScanMode get scanMode => _scanMode;
  DiagnosisState get state => _state;
  String? get errorMessage => _errorMessage;
  dynamic get selectedImage => _selectedImage;
  DiagnosisReport? get currentReport => _currentReport;
  List<DiagnosisReport> get history => _history;
  String get geminiApiKey => _geminiApiKey;
  String get supabaseUrl => _supabaseUrl;
  String get supabaseAnonKey => _supabaseAnonKey;
  String get statusMessage => _statusMessage;
  bool get hasIntegrityViolation => _hasIntegrityViolation;

  bool get isGeminiConfigured => _gemini.isConfigured;
  bool get isSupabaseConfigured => SupabaseService().isConfigured;
  
  bool get isBusy => 
      _state == DiagnosisState.loadingImage || 
      _state == DiagnosisState.analyzingLocal || 
      _state == DiagnosisState.verifyingCloud;

  DiagnosisProvider() {
    _orchestrator = PlantDiagnosisOrchestrator(
      geminiService: _gemini,
    );
    _loadSettingsAndHistory();
  }

  // ── Settings & History Management ─────────────────────

  Future<void> _loadSettingsAndHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Gemini API Key
      _geminiApiKey = prefs.getString('gemini_api_key') ?? AppConstants.defaultGeminiApiKey;
      if (_geminiApiKey.isEmpty) {
        _geminiApiKey = AppConstants.defaultGeminiApiKey;
        await prefs.setString('gemini_api_key', _geminiApiKey);
      }
      if (_geminiApiKey.isNotEmpty && _geminiApiKey != 'YOUR_GEMINI_API_KEY') {
        _gemini.init(_geminiApiKey);
      }

      // Load Supabase Configurations
      _supabaseUrl = prefs.getString(AppConstants.keySupabaseUrl) ?? AppConstants.defaultSupabaseUrl;
      _supabaseAnonKey = prefs.getString(AppConstants.keySupabaseAnonKey) ?? AppConstants.defaultSupabaseAnonKey;

      if (_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) {
        await SupabaseService().init(_supabaseUrl, _supabaseAnonKey);
        
        final role = prefs.getString('pref_role') ?? 'user';
        if (role != 'admin') {
          await _fetchCentralApiKeyFromSupabase();
        }
      }

      // Load History from SharedPreferences-backed DatabaseService
      _history = await DatabaseService.getReports();

      // Sort history descending
      _history.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      notifyListeners();
    } catch (e) {
      debugPrint("⚠️ Error loading history or settings: $e");
    }
  }

  Future<void> _fetchCentralApiKeyFromSupabase() async {
    try {
      if (SupabaseService().isConfigured) {
        final response = await SupabaseService().client
            .from('user_profiles')
            .select('gemini_api_key')
            .eq('role', 'admin')
            .limit(1)
            .maybeSingle();

        if (response != null && response['gemini_api_key'] != null) {
          final String centralKey = response['gemini_api_key'] as String;
          if (centralKey.isNotEmpty) {
            _geminiApiKey = centralKey;
            _gemini.init(_geminiApiKey);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('gemini_api_key', _geminiApiKey);
            debugPrint("🔑 Loaded central API key from Supabase admin profile: $_geminiApiKey");
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ Failed to fetch central API key from Supabase: $e");
    }
  }

  Future<void> fetchCentralApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('pref_role') ?? 'user';
    if (role != 'admin' && SupabaseService().isConfigured) {
      await _fetchCentralApiKeyFromSupabase();
      notifyListeners();
    }
  }

  Future<void> setGeminiApiKey(String apiKey) async {
    _geminiApiKey = apiKey.trim();
    _gemini.init(_geminiApiKey);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _geminiApiKey);
    
    final role = prefs.getString('pref_role') ?? 'user';
    if (role == 'admin' && SupabaseService().isConfigured) {
      try {
        final currentUser = SupabaseService().client.auth.currentUser;
        if (currentUser != null) {
          await SupabaseService().client.from('user_profiles').update({
            'gemini_api_key': _geminiApiKey,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('id', currentUser.id);
          debugPrint("🔑 Pushed central API key to Supabase user_profiles table!");
        }
      } catch (e) {
        debugPrint("⚠️ Failed to sync central API key to Supabase: $e");
      }
    }
    
    notifyListeners();
  }

  Future<void> setSupabaseConfig(String url, String anonKey) async {
    _supabaseUrl = url.trim();
    _supabaseAnonKey = anonKey.trim();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keySupabaseUrl, _supabaseUrl);
    await prefs.setString(AppConstants.keySupabaseAnonKey, _supabaseAnonKey);
    
    await SupabaseService().init(_supabaseUrl, _supabaseAnonKey);
    
    final role = prefs.getString('pref_role') ?? 'user';
    if (role != 'admin') {
      await _fetchCentralApiKeyFromSupabase();
    }
    
    notifyListeners();
  }

  // ── Core Diagnosis Workflows ───────────────────────────

  /// Triggers image picker and automatically launches diagnosis pipeline
  Future<void> selectAndDiagnose(ImageSource source) async {
    if (isBusy) {
      debugPrint("⚠️ Scan pipeline is busy. Ignoring request.");
      return;
    }
    _state = DiagnosisState.loadingImage;
    _statusMessage = 'Selecting image...';
    _errorMessage = null;
    notifyListeners();

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1000, 
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        _state = DiagnosisState.idle;
        notifyListeners();
        return;
      }

      if (kIsWeb) {
        _selectedImage = pickedFile;
      } else {
        // Save picked file locally in documents directory to persist in history!
        final File tempFile = File(pickedFile.path);
        final appDocDir = await getApplicationDocumentsDirectory();
        final String localFileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File localFile = await tempFile.copy('${appDocDir.path}/$localFileName');

        _selectedImage = localFile;
      }
      
      // Start pipeline
      await _runDiagnosisPipeline();
    } catch (e) {
      _state = DiagnosisState.error;
      _errorMessage = 'Failed to select image: ${e.toString()}';
      notifyListeners();
    }
  }

  void setScanMode(ScanMode mode) {
    _scanMode = mode;
    notifyListeners();
  }

  /// Run intelligent classification pipeline
  Future<void> _runDiagnosisPipeline() async {
    if (_selectedImage == null) return;

    // Check connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasNoInternet = connectivityResult.contains(ConnectivityResult.none);
    if (hasNoInternet) {
      _state = DiagnosisState.error;
      _errorMessage = 'No internet connection. Please verify your network and try again.';
      notifyListeners();
      return;
    }

    _state = DiagnosisState.analyzingLocal;
    _statusMessage = _scanMode == ScanMode.identify 
        ? 'Identifying plant species...'
        : 'Detecting plant species and health markers...';
    notifyListeners();

    try {
      // Run orchestrator
      DiagnosisReport report;
      if (_scanMode == ScanMode.identify) {
        report = await _orchestrator.identify(
          imageFile: _selectedImage!,
          onStatusUpdate: (status) {
            _statusMessage = status;
            if (status.contains("Generating") || status.contains("Checking")) {
              _state = DiagnosisState.verifyingCloud;
            } else {
              _state = DiagnosisState.analyzingLocal;
            }
            notifyListeners();
          },
        );
      } else {
        report = await _orchestrator.diagnose(
          imageFile: _selectedImage!,
          onStatusUpdate: (status) {
            _statusMessage = status;
            if (status.contains("Generating") || status.contains("Checking")) {
              _state = DiagnosisState.verifyingCloud;
            } else {
              _state = DiagnosisState.analyzingLocal;
            }
            notifyListeners();
          },
        );
      }

      if (kIsWeb) {
        try {
          final originalBytes = await _selectedImage.readAsBytes();
          final compressedBytes = await ImageService.compressBytes(originalBytes);
          final base64String = base64Encode(compressedBytes);
          report = report.copyWith(imagePath: 'data:image/jpeg;base64,$base64String');
        } catch (webImageError) {
          debugPrint("⚠️ Failed to convert diagnostic image to base64 on web: $webImageError");
        }
      }

      // Save report in SharedPreferences database
      await DatabaseService.saveReport(report);

      _currentReport = report;
      _history.insert(0, report); 
      
      _state = DiagnosisState.success;
      notifyListeners();
    } catch (e) {
      _state = DiagnosisState.error;
      _errorMessage = 'Analysis failed: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    await DatabaseService.clearReports();

    _history.clear();
    notifyListeners();
  }

  Future<void> deleteHistoryItem(String id) async {
    await DatabaseService.deleteReport(id);

    _history.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void reset() {
    _state = DiagnosisState.idle;
    _currentReport = null;
    _selectedImage = null;
    _errorMessage = null;
    notifyListeners();
  }
}
