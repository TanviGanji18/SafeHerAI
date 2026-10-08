import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journey_model.dart';

class FirebaseService {
  static bool _isFirebaseAvailable = false;

  static Future<void> initializeIfPossible() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isFirebaseAvailable = true;
      debugPrint('[FirebaseService] Firebase initialized successfully.');
    } catch (e) {
      _isFirebaseAvailable = false;
      debugPrint('[FirebaseService] Firebase not initialized (offline/dev fallback): $e');
    }
  }

  static bool get isAvailable => _isFirebaseAvailable;

  static FirebaseAuth get auth => FirebaseAuth.instance;

  // 1. Sync Journey to Cloud Firestore
  static Future<void> syncJourney(ActiveJourney journey) async {
    if (!_isFirebaseAvailable) return;
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('journeys').doc(journey.journeyId).set(
        journey.toJson(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[FirebaseService] Firestore journey sync note: $e');
    }
  }

  // 2. Sync Feedback to Cloud Firestore for future analysis
  static Future<void> syncFeedback({
    required String journeyId,
    required String userId,
    required JourneyFeedback feedback,
    required String routeId,
    required double safetyScore,
    required bool emergencyOccurred,
  }) async {
    if (!_isFirebaseAvailable) return;
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('journey_feedback').doc(journeyId).set({
        'journey_id': journeyId,
        'user_id': userId,
        'route_id': routeId,
        'safety_score': safetyScore,
        'emergency_occurred': emergencyOccurred,
        ...feedback.toJson(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirebaseService] Firestore feedback sync note: $e');
    }
  }

  // 3. Record Emergency SOS Event in Cloud Firestore
  static Future<void> syncSOSEvent({
    required String journeyId,
    required String userId,
    required double lat,
    required double lon,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isFirebaseAvailable) return;
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('sos_events').add({
        'journey_id': journeyId,
        'user_id': userId,
        'latitude': lat,
        'longitude': lon,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      });
    } catch (e) {
      debugPrint('[FirebaseService] Firestore SOS sync note: $e');
    }
  }

  // 4. Retrieve Real Stored Journeys from Cloud Firestore
  static Future<List<ActiveJourney>> getJourneysForUser(String userId) async {
    if (!_isFirebaseAvailable) return [];
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('journeys')
          .where('user_id', isEqualTo: userId)
          .get();
      final list = snapshot.docs
          .map((doc) => ActiveJourney.fromJson(doc.data()))
          .toList();
      list.sort((a, b) => b.startTime.compareTo(a.startTime));
      return list;
    } catch (e) {
      debugPrint('[FirebaseService] Firestore getJourneys note: $e');
      return [];
    }
  }
}
