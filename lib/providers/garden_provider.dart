import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/garden_plant.dart';
import '../services/security_service.dart';
import '../services/database_service.dart';
import '../services/api/supabase_service.dart';
import '../services/notification_service.dart';

class GardenProvider extends ChangeNotifier {
  static const String _securitySalt = 'PlantCareAI_Secure_Cryptographic_Salt_2026';

  List<GardenPlant> _plants = [];
  
  bool _isLoggedIn = false;
  bool _isGuest = false;
  String _username = 'Green Gardener';
  String _email = '';
  String _avatarUrl = '';
  String _role = 'user';
  final bool _hasIntegrityViolation = false;
  bool _isOfflineOnly = false;
  DateTime? _joinedAt;
  
  int _careStreak = 0;
  DateTime? _lastCareDate;
  int _scanCount = 0;
  bool _hasDiseasedScan = false;

  // ── Notification Reminder Time State ──────────────────────
  int _reminderHour = 9;
  int _reminderMinute = 0;

  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;

  List<GardenPlant> get plants => _plants;
  
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  String get username => _username;
  String get email => _email;
  String get avatarUrl => _avatarUrl;
  String get role => _role;
  bool get isAdmin => _role == 'admin';
  bool get hasIntegrityViolation => _hasIntegrityViolation;
  bool get isOfflineOnly => _isOfflineOnly;
  DateTime? get joinedAt => _joinedAt;
  
  int get careStreak => _careStreak;
  int get scanCount => _scanCount;

  GardenProvider() {
    _loadGardenData();
  }

  // ── App Lifecycle Init ───────────────────────────────────

  /// Requests notification permissions at startup (Android 13+, iOS).
  /// Call this once after the first frame from main.dart.
  Future<void> requestNotificationPermissions() async {
    await NotificationService().requestPermissions();
  }

  // ── Reminder Time Management ─────────────────────────────

  /// Updates and persists the global daily reminder time, then reschedules
  /// all plant reminders to fire at the new time.
  Future<void> setReminderTime(int hour, int minute) async {
    _reminderHour = hour;
    _reminderMinute = minute;
    await NotificationService().saveReminderTime(hour, minute);
    // Reschedule every enabled plant at the new time
    await NotificationService().rescheduleAllReminders(_plants);
    notifyListeners();
  }

  // ── Per-Plant Notification Toggle ────────────────────────

  /// Enables or disables push reminders for a single plant.
  /// When disabled, any pending notifications for that plant are cancelled.
  /// When re-enabled, reminders are rescheduled from the plant's last care dates.
  Future<void> togglePlantNotifications(String plantId) async {
    final index = _plants.indexWhere((p) => p.id == plantId);
    if (index == -1) return;

    final plant = _plants[index];
    final newEnabled = !plant.notificationsEnabled;
    final updated = plant.copyWith(notificationsEnabled: newEnabled);

    await DatabaseService.savePlant(updated);
    _plants[index] = updated;

    if (newEnabled) {
      // Re-schedule both reminders anchored to last care dates
      await NotificationService().scheduleWateringReminder(
        updated.id, updated.nickname, updated.wateringFrequencyDays,
        fromDate: updated.lastWatered,
      );
      await NotificationService().scheduleFertilizingReminder(
        updated.id, updated.nickname, updated.fertilizingFrequencyDays,
        fromDate: updated.lastFertilized,
      );
      debugPrint('🔔 Reminders ENABLED for "${updated.nickname}"');
    } else {
      await NotificationService().cancelReminders(updated.id);
      debugPrint('🔔 Reminders DISABLED for "${updated.nickname}"');
    }

    notifyListeners();
  }

  // ── Persistence & Database Migration ──────────────────────

  Future<void> _loadGardenData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Plants from SharedPreferences-backed DatabaseService
      _plants = await DatabaseService.getPlants();

      // Load Simple Configurations
      _isLoggedIn = prefs.getBool('pref_logged_in') ?? false;
      _isGuest = prefs.getBool('pref_is_guest') ?? false;
      _username = prefs.getString('pref_username') ?? 'Green Gardener';
      _email = _isLoggedIn ? (prefs.getString('auth_email') ?? '') : '';
      _avatarUrl = prefs.getString('pref_avatar_url') ?? '';
      _role = prefs.getString('pref_role') ?? 'user';
      _isOfflineOnly = prefs.getBool('pref_offline_only') ?? false;

      final joinedAtStr = prefs.getString('pref_joined_at');
      if (joinedAtStr != null) {
        _joinedAt = DateTime.tryParse(joinedAtStr);
      }

      _careStreak = prefs.getInt('pref_care_streak') ?? 0;
      final lastCareStr = prefs.getString('pref_last_care_date');
      if (lastCareStr != null) {
        _lastCareDate = DateTime.tryParse(lastCareStr);
      }
      _scanCount = prefs.getInt('pref_scan_count') ?? 0;

      final reports = await DatabaseService.getReports();
      _hasDiseasedScan = reports.any((r) => r.diseaseName.toLowerCase() != 'healthy' && r.diseaseName.toLowerCase() != 'unknown');

      // ── Load saved reminder time ──────────────────────────
      _reminderHour = prefs.getInt('notif_reminder_hour') ?? 9;
      _reminderMinute = prefs.getInt('notif_reminder_minute') ?? 0;

      notifyListeners();

      // ── Cold-start: reschedule all reminders ──────────────
      // OS may have cancelled pending notifications after device reboot
      // or background task termination. Reschedule every enabled plant.
      await NotificationService().rescheduleAllReminders(_plants);
    } catch (e) {
      debugPrint("⚠️ Error loading garden data: $e");
    }
  }

  Future<void> syncProfileToSupabase() async {
    if (!SupabaseService().isConfigured) return;
    try {
      final currentUser = SupabaseService().client.auth.currentUser;
      if (currentUser != null) {
        final prefs = await SharedPreferences.getInstance();
        final String? geminiKey = _role == 'admin' ? prefs.getString('gemini_api_key') : null;
        await SupabaseService().syncUserProfile(
          id: currentUser.id,
          username: _username,
          avatarUrl: _avatarUrl,
          role: _role,
          geminiApiKey: geminiKey,
        );
      }
    } catch (e) {
      debugPrint("⚠️ Failed to sync profile to Supabase: $e");
    }
  }

  Future<void> registerUser(String name, String email, String password) async {
    final sanitizedEmail = email.trim().toLowerCase();
    
    if (!SupabaseService().isConfigured) {
      throw Exception("Supabase is not configured. Unable to register.");
    }
    
    // Supabase Auth SignUp — password is stored securely in auth.users by Supabase
    final authResponse = await SupabaseService().client.auth.signUp(
      email: sanitizedEmail,
      password: password,
    );
    
    if (authResponse.user == null) {
      throw Exception("Registration failed. Please check your details.");
    }
    
    final userId = authResponse.user!.id;
    final sanitizedName = SecurityService.sanitize(name);
    
    // Sync profile row — role defaults to 'user'
    await SupabaseService().syncUserProfile(
      id: userId,
      username: sanitizedName,
      avatarUrl: '',
      role: 'user',
      isNewUser: true,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_email', sanitizedEmail);
    await prefs.setString('auth_name', sanitizedName);
    
    // Automatically log in after registration
    await loginUser(sanitizedName, role: 'user');
  }

  Future<void> authenticateUser(String email, String password) async {
    final sanitizedEmail = email.trim().toLowerCase();
    
    if (!SupabaseService().isConfigured) {
      throw Exception("Supabase is not configured. Unable to log in.");
    }
    
    // Supabase Auth SignIn — validates credentials, returns session
    final authResponse = await SupabaseService().client.auth.signInWithPassword(
      email: sanitizedEmail,
      password: password,
    );
    
    if (authResponse.user == null || authResponse.session == null) {
      throw Exception("Invalid email or password.");
    }
    
    final userId = authResponse.user!.id;
    final prefs = await SharedPreferences.getInstance();
    
    // Retrieve existing profile — username, avatar_url, role, gemini_api_key
    String displayName = 'Green Gardener';
    String resolvedRole = 'user';
    String avatarToSync = '';
    
    try {
      final existingProfile = await SupabaseService().client
          .from('user_profiles')
          .select('username, avatar_url, role, gemini_api_key')
          .eq('id', userId)
          .maybeSingle();
          
      if (existingProfile != null) {
        displayName = existingProfile['username'] as String? ?? 'Green Gardener';
        resolvedRole = existingProfile['role'] as String? ?? 'user';
        avatarToSync = existingProfile['avatar_url'] as String? ?? '';
        
        if (avatarToSync.isNotEmpty) {
          await prefs.setString('pref_avatar_url', avatarToSync);
          _avatarUrl = avatarToSync;
        }
        
        // If admin, persist their Gemini key locally so it can be used app-wide
        if (resolvedRole == 'admin') {
          final geminiKey = existingProfile['gemini_api_key'] as String?;
          if (geminiKey != null && geminiKey.isNotEmpty) {
            await prefs.setString('gemini_api_key', geminiKey);
            debugPrint("🔑 Admin Gemini key loaded from Supabase.");
          }
        }
      }
    } catch (profileFetchErr) {
      debugPrint("⚠️ Could not fetch existing profile: $profileFetchErr");
    }
    
    await prefs.setString('auth_email', sanitizedEmail);
    await prefs.setString('auth_name', displayName);
    
    // Sync profile back to ensure updated_at is fresh
    final String? geminiKey = resolvedRole == 'admin' ? prefs.getString('gemini_api_key') : null;
    await SupabaseService().syncUserProfile(
      id: userId,
      username: displayName,
      avatarUrl: avatarToSync,
      role: resolvedRole,
      geminiApiKey: geminiKey,
    );
    
    // Successful login!
    await loginUser(displayName, role: resolvedRole);
  }

  /// Admin-only: update the global Gemini API key in Supabase + local prefs.
  /// Returns true on success. Shows error in debug log on failure.
  Future<bool> updateAdminGeminiKey(String newKey) async {
    if (!isAdmin) return false;
    final currentUser = SupabaseService().client.auth.currentUser;
    if (currentUser == null) return false;
    
    final success = await SupabaseService().updateAdminGeminiKey(currentUser.id, newKey);
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gemini_api_key', newKey);
      debugPrint("✅ Admin Gemini key saved locally and to Supabase.");
    }
    return success;
  }

  /// Fetches the global Gemini key from the admin profile in Supabase.
  /// Regular users call this so they can use the admin-configured key.
  Future<String?> loadGlobalGeminiKey() async {
    return SupabaseService().fetchGlobalGeminiKey();
  }

  Future<void> setOfflineOnly(bool value) async {
    _isOfflineOnly = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_offline_only', value);
    notifyListeners();
  }

  Future<String> exportBackup() async {
    // Read clean, updated list from database
    final allPlants = await DatabaseService.getPlants();

    final Map<String, dynamic> backupData = {
      'plants': allPlants.map((e) => e.toJson()).toList(),
      'username': _username,
      'exportTime': DateTime.now().toIso8601String(),
    };
    
    final String backupJson = json.encode(backupData);
    
    // Symmetric encrypt backup (Confidentiality)
    final String encrypted = SecurityService.encrypt(backupJson, _securitySalt);
    
    // Add integrity signature (Integrity)
    final String signature = SecurityService.generateSignature(encrypted, _securitySalt);
    
    final Map<String, dynamic> package = {
      'payload': encrypted,
      'signature': signature,
    };
    
    return base64.encode(utf8.encode(json.encode(package)));
  }

  Future<void> importBackup(String backupBase64) async {
    try {
      final decodedPackage = utf8.decode(base64.decode(backupBase64.trim()));
      final Map<String, dynamic> package = json.decode(decodedPackage);
      
      final String payload = package['payload'] ?? '';
      final String signature = package['signature'] ?? '';
      
      // Verify integrity of payload first (Integrity)
      if (!SecurityService.verifySignature(payload, signature, _securitySalt)) {
        throw Exception('Backup package integrity check failed. The file is corrupt or tampered.');
      }
      
      // Decrypt (Confidentiality)
      final String decryptedJson = SecurityService.decrypt(payload, _securitySalt);
      if (decryptedJson.isEmpty) {
        throw Exception('Failed to decrypt backup data. Wrong security credentials.');
      }
      
      final Map<String, dynamic> backupData = json.decode(decryptedJson);
      
      // Load data
      final List<dynamic> plantsList = backupData['plants'] ?? [];
      final String userVal = backupData['username'] ?? 'Green Gardener';
      
      // Map to models
      final importedPlants = plantsList.map((e) => GardenPlant.fromJson(e)).toList();

      // Replace everything in SharedPreferences database (Availability & Integrity)
      await DatabaseService.clearPlants();
      await DatabaseService.savePlants(importedPlants);

      // Reschedule reminders for all imported plants
      for (var plant in importedPlants) {
        await NotificationService().scheduleWateringReminder(plant.id, plant.nickname, plant.wateringFrequencyDays);
        await NotificationService().scheduleFertilizingReminder(plant.id, plant.nickname, plant.fertilizingFrequencyDays);
      }

      _plants = importedPlants;
      _username = userVal;
      _isLoggedIn = true;
      _isGuest = false;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_logged_in', true);
      await prefs.setBool('pref_is_guest', false);
      await prefs.setString('pref_username', _username);
      
      notifyListeners();
    } catch (e) {
      throw Exception('Import failed: ${e.toString()}');
    }
  }

  Future<void> loginUser(String name, {String? role}) async {
    _isLoggedIn = true;
    _isGuest = false;
    _username = name;
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString('auth_email') ?? '';
    _avatarUrl = prefs.getString('pref_avatar_url') ?? '';
    
    if (role != null) {
      _role = role;
    } else {
      _role = prefs.getString('pref_role') ?? 'user';
    }
    
    await prefs.setBool('pref_logged_in', true);
    await prefs.setBool('pref_is_guest', false);
    await prefs.setString('pref_username', name);
    await prefs.setString('pref_role', _role);

    if (!prefs.containsKey('pref_joined_at')) {
      await prefs.setString('pref_joined_at', DateTime.now().toIso8601String());
      _joinedAt = DateTime.now();
    }

    await syncProfileToSupabase();
    notifyListeners();
  }

  Future<void> continueAsGuestUser() async {
    _isLoggedIn = false;
    _isGuest = true;
    _username = 'Guest Gardener';
    _email = '';
    _avatarUrl = '';
    _role = 'user';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_logged_in', false);
    await prefs.setBool('pref_is_guest', true);
    await prefs.setString('pref_username', 'Guest Gardener');
    await prefs.setString('pref_role', 'user');
    await prefs.remove('pref_avatar_url');

    // Supabase Auth Anonymous session + Guest Profile Sync
    if (SupabaseService().isConfigured) {
      try {
        if (SupabaseService().client.auth.currentSession == null) {
          await SupabaseService().client.auth.signInAnonymously();
        }
        final currentUser = SupabaseService().client.auth.currentUser;
        if (currentUser != null) {
          await SupabaseService().syncUserProfile(
            id: currentUser.id,
            username: 'Guest Gardener',
          );
        }
      } catch (authError) {
        debugPrint("⚠️ Supabase Guest session initialization failed: $authError");
      }
    }

    notifyListeners();
  }

  Future<void> logoutUser() async {
    _isLoggedIn = false;
    _isGuest = false;
    _username = 'Green Gardener';
    _email = '';
    _avatarUrl = '';
    _role = 'user';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_logged_in', false);
    await prefs.setBool('pref_is_guest', false);
    await prefs.setString('pref_username', 'Green Gardener');
    await prefs.setString('pref_role', 'user');
    await prefs.remove('pref_avatar_url');
    
    // Reset plants on logout
    _plants.clear();

    // Clear local database
    await DatabaseService.clearPlants();
    
    await prefs.remove('pref_onboarding_completed');

    // Supabase SignOut and re-signin anonymously to preserve anon role
    if (SupabaseService().isConfigured) {
      try {
        await SupabaseService().client.auth.signOut();
        await SupabaseService().client.auth.signInAnonymously();
      } catch (authError) {
        debugPrint("⚠️ Supabase signOut error: $authError");
      }
    }
    
    notifyListeners();
  }

  Future<void> updateAvatarUrl(String url) async {
    _avatarUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_avatar_url', url);
    await syncProfileToSupabase();
    notifyListeners();
  }

  // ── Garden Management Actions (Isar Transactions) ───────────

  String _generateId(String prefix) {
    return const Uuid().v4();
  }

  Future<void> addPlant({
    required String nickname,
    required String species,
    required String scientificName,
    required String imagePath,
    required int wateringFrequencyDays,
    required int fertilizingFrequencyDays,
    required String notes,
    int healthScore = 100,
  }) async {
    final plant = GardenPlant(
      id: _generateId('pl'),
      nickname: nickname,
      species: species,
      scientificName: scientificName,
      imagePath: imagePath,
      dateAcquired: DateTime.now(),
      lastWatered: DateTime.now(),
      lastFertilized: DateTime.now(),
      wateringFrequencyDays: wateringFrequencyDays,
      fertilizingFrequencyDays: fertilizingFrequencyDays,
      notes: notes,
      healthScore: healthScore,
      journal: [],
    );

    // Save plant in SharedPreferences database
    await DatabaseService.savePlant(plant);

    // Schedule reminders
    await NotificationService().scheduleWateringReminder(plant.id, plant.nickname, plant.wateringFrequencyDays);
    await NotificationService().scheduleFertilizingReminder(plant.id, plant.nickname, plant.fertilizingFrequencyDays);

    _plants.insert(0, plant);
    notifyListeners();
  }

  Future<void> deletePlant(String id) async {
    // Delete plant in SharedPreferences database
    await DatabaseService.deletePlant(id);

    // Cancel reminders
    await NotificationService().cancelReminders(id);

    _plants.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> waterPlant(String id) async {
    final index = _plants.indexWhere((p) => p.id == id);
    if (index != -1) {
      final plant = _plants[index];
      plant.lastWatered = DateTime.now();

      // Boost base health score on watering (+5, capped at 100)
      plant.healthScore = (plant.healthScore + 5).clamp(0, 100);

      // Record computed score (post-decay) into history for the chart
      final snapshot = plant.computedHealthScore;
      plant.healthHistory.add(snapshot);
      if (plant.healthHistory.length > 10) plant.healthHistory.removeAt(0);

      await DatabaseService.savePlant(plant);

      // Reschedule from today (lastWatered is now DateTime.now())
      await NotificationService().scheduleWateringReminder(
        plant.id,
        plant.nickname,
        plant.wateringFrequencyDays,
      );

      await updateCareStreak();
      notifyListeners();
    }
  }

  Future<void> fertilizePlant(String id) async {
    final index = _plants.indexWhere((p) => p.id == id);
    if (index != -1) {
      final plant = _plants[index];
      plant.lastFertilized = DateTime.now();

      // Boost base health on fertilizing (+3, capped at 100)
      plant.healthScore = (plant.healthScore + 3).clamp(0, 100);

      // Record the post-boost computed score into history
      final snapshot = plant.computedHealthScore;
      plant.healthHistory.add(snapshot);
      if (plant.healthHistory.length > 10) plant.healthHistory.removeAt(0);

      await DatabaseService.savePlant(plant);

      // Reschedule from today (lastFertilized is now DateTime.now())
      await NotificationService().scheduleFertilizingReminder(
        plant.id,
        plant.nickname,
        plant.fertilizingFrequencyDays,
      );

      await updateCareStreak();
      notifyListeners();
    }
  }

  Future<void> updateCareStreak() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    if (_lastCareDate == null) {
      _careStreak = 1;
    } else {
      final difference = DateTime(now.year, now.month, now.day)
          .difference(DateTime(_lastCareDate!.year, _lastCareDate!.month, _lastCareDate!.day))
          .inDays;

      if (difference == 1) {
        _careStreak += 1;
      } else if (difference > 1) {
        _careStreak = 1; // Reset
      }
    }

    _lastCareDate = now;
    await prefs.setInt('pref_care_streak', _careStreak);
    await prefs.setString('pref_last_care_date', _lastCareDate!.toIso8601String());
    notifyListeners();
  }

  /// Increments scan count for gamification achievements
  Future<void> incrementScanCount(bool isDiseased) async {
    final prefs = await SharedPreferences.getInstance();
    _scanCount += 1;
    await prefs.setInt('pref_scan_count', _scanCount);
    if (isDiseased) {
      _hasDiseasedScan = true;
    }
    notifyListeners();
  }

  /// Get achievements list
  List<Map<String, dynamic>> get achievements {
    final totalJournal = totalJournalEntries;
    return [
      {
        'id': 'ach_first_scan',
        'title': 'First Scan',
        'description': 'Diagnose or identify your first plant leaf.',
        'icon': Icons.qr_code_scanner_rounded,
        'isUnlocked': _scanCount > 0,
      },
      {
        'id': 'ach_green_thumb',
        'title': 'Green Thumb',
        'description': 'Add 3 or more plants to your collection.',
        'icon': Icons.yard_rounded,
        'isUnlocked': _plants.length >= 3,
      },
      {
        'id': 'ach_botanist',
        'title': 'Master Botanist',
        'description': 'Add 7 or more plants to your collection.',
        'icon': Icons.park_rounded,
        'isUnlocked': _plants.length >= 7,
      },
      {
        'id': 'ach_pest_fighter',
        'title': 'Pest Fighter',
        'description': 'Diagnose a diseased plant.',
        'icon': Icons.bug_report_rounded,
        'isUnlocked': _hasDiseasedScan,
      },
      {
        'id': 'ach_dedicated_carer',
        'title': 'Dedicated Carer',
        'description': 'Maintain a care streak of 3 or more days.',
        'icon': Icons.favorite_rounded,
        'isUnlocked': _careStreak >= 3,
      },
      {
        'id': 'ach_journalist',
        'title': 'Garden Journalist',
        'description': 'Log 5 or more journal progress entries.',
        'icon': Icons.menu_book_rounded,
        'isUnlocked': totalJournal >= 5,
      },
    ];
  }

  Future<void> addJournalEntry(String plantId, String note, {String? imagePath, String? milestone}) async {
    final index = _plants.indexWhere((p) => p.id == plantId);
    if (index != -1) {
      final plant = _plants[index];
      final entry = JournalEntry(
        id: _generateId('jr'),
        dateTime: DateTime.now(),
        note: note,
        imagePath: imagePath,
        milestone: milestone,
      );
      
      plant.journal.insert(0, entry);

      // Save plant in SharedPreferences database
      await DatabaseService.savePlant(plant);

      notifyListeners();
    }
  }

  // ── Stats Getters ────────────────────────────────────────

  int get thirstyPlantCount => _plants.where((p) => p.needsWatering).length;

  int get needsFertilizerCount => _plants.where((p) => p.needsFertilizing).length;

  int get needsCareCount {
    return _plants.where((p) => p.needsWatering || p.needsFertilizing).length;
  }

  double get averageHealthScore {
    if (_plants.isEmpty) return 100.0;
    final total = _plants.fold<int>(0, (sum, p) => sum + p.computedHealthScore);
    return total / _plants.length;
  }

  int get criticalPlantCount => _plants.where((p) => p.computedHealthScore < 40).length;

  int get totalJournalEntries => _plants.fold<int>(0, (sum, p) => sum + p.journal.length);

  // ── Update Plant ─────────────────────────────────────────

  Future<void> updatePlant(String id, {
    String? nickname,
    String? species,
    String? scientificName,
    String? imagePath,
    int? wateringFrequencyDays,
    int? fertilizingFrequencyDays,
    String? notes,
    int? healthScore,
  }) async {
    final index = _plants.indexWhere((p) => p.id == id);
    if (index != -1) {
      final old = _plants[index];
      final updated = old.copyWith(
        nickname: nickname,
        species: species,
        scientificName: scientificName,
        imagePath: imagePath,
        wateringFrequencyDays: wateringFrequencyDays,
        fertilizingFrequencyDays: fertilizingFrequencyDays,
        notes: notes,
        healthScore: healthScore,
      );

      await DatabaseService.savePlant(updated);

      // Reschedule reminders anchored to lastWatered/lastFertilized,
      // not DateTime.now(), so the due-date is accurate after a frequency change.
      await NotificationService().scheduleWateringReminder(
        updated.id,
        updated.nickname,
        updated.wateringFrequencyDays,
        fromDate: updated.lastWatered,
      );
      await NotificationService().scheduleFertilizingReminder(
        updated.id,
        updated.nickname,
        updated.fertilizingFrequencyDays,
        fromDate: updated.lastFertilized,
      );

      _plants[index] = updated;
      notifyListeners();
    }
  }

  /// Update a plant's health score directly (e.g., from diagnosis scan result).
  /// [scoreDelta] is added to the current base score (can be negative).
  Future<void> updateHealthFromDiagnosis(String plantId, int scoreDelta) async {
    final index = _plants.indexWhere((p) => p.id == plantId);
    if (index != -1) {
      final plant = _plants[index];
      plant.healthScore = (plant.healthScore + scoreDelta).clamp(0, 100);

      // Record the impact in history
      final snapshot = plant.computedHealthScore;
      plant.healthHistory.add(snapshot);
      if (plant.healthHistory.length > 10) plant.healthHistory.removeAt(0);

      await DatabaseService.savePlant(plant);
      notifyListeners();
    }
  }

  /// Manually override a plant's base health score (e.g., from the Edit sheet).
  Future<void> updateHealthScore(String plantId, int score) async {
    final index = _plants.indexWhere((p) => p.id == plantId);
    if (index != -1) {
      final plant = _plants[index];
      plant.healthScore = score.clamp(0, 100);

      plant.healthHistory.add(plant.computedHealthScore);
      if (plant.healthHistory.length > 10) plant.healthHistory.removeAt(0);

      await DatabaseService.savePlant(plant);
      notifyListeners();
    }
  }

  // ── Delete Journal Entry ─────────────────────────────────

  Future<void> deleteJournalEntry(String plantId, String entryId) async {
    final index = _plants.indexWhere((p) => p.id == plantId);
    if (index != -1) {
      final plant = _plants[index];
      plant.journal.removeWhere((e) => e.id == entryId);

      await DatabaseService.savePlant(plant);

      notifyListeners();
    }
  }
}
