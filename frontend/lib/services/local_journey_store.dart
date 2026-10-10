import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journey_model.dart';

/// P5 – Offline-local journey persistence.
///
/// Stores up to [maxLocalJourneys] completed journeys in SharedPreferences so
/// the history tab shows past trips even when the backend is unreachable.
/// Data is keyed per [userId] so different users on the same device stay
/// isolated.  Backend journey data always takes precedence; this store is
/// used only as a fallback / supplement.
class LocalJourneyStore {
  static const String _keyPrefix = 'local_journeys_';
  static const int maxLocalJourneys = 50;

  final String userId;

  LocalJourneyStore({required this.userId});

  String get _prefsKey => '$_keyPrefix$userId';

  /// Loads all locally-cached journeys for this user.
  /// Returns an empty list on any error.
  Future<List<ActiveJourney>> loadJourneys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ActiveJourney.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('[LocalJourneyStore] loadJourneys error: $e');
      return [];
    }
  }

  /// Saves [journey] to local storage.
  /// Keeps the list sorted by start time (newest first) and trims to
  /// [maxLocalJourneys] entries to bound storage use.
  Future<void> saveJourney(ActiveJourney journey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await loadJourneys();

      // Remove any existing entry with the same journeyId (update semantics)
      existing.removeWhere((j) => j.journeyId == journey.journeyId);

      // Insert at front (newest first)
      existing.insert(0, journey);

      // Trim to max
      final trimmed = existing.take(maxLocalJourneys).toList();

      final encoded = jsonEncode(trimmed.map((j) => j.toJson()).toList());
      await prefs.setString(_prefsKey, encoded);
    } catch (e) {
      debugPrint('[LocalJourneyStore] saveJourney error: $e');
    }
  }

  /// Removes a specific journey by ID from local storage.
  Future<void> deleteJourney(String journeyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await loadJourneys();
      existing.removeWhere((j) => j.journeyId == journeyId);
      final encoded = jsonEncode(existing.map((j) => j.toJson()).toList());
      await prefs.setString(_prefsKey, encoded);
    } catch (e) {
      debugPrint('[LocalJourneyStore] deleteJourney error: $e');
    }
  }

  /// Clears all locally-cached journeys for this user.
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (e) {
      debugPrint('[LocalJourneyStore] clearAll error: $e');
    }
  }
}
