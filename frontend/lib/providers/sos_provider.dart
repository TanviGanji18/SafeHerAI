import 'package:flutter/foundation.dart';
import '../models/sos_model.dart';
import '../services/api_service.dart';

class SOSProvider with ChangeNotifier {
  final ApiService apiService;

  bool _isTriggering = false;
  SOSResponse? _lastAlert;
  List<TrustedContact> _contacts = [];
  String? _errorMessage;

  SOSProvider({required this.apiService});

  bool get isTriggering => _isTriggering;
  SOSResponse? get lastAlert => _lastAlert;
  List<TrustedContact> get contacts => _contacts;
  String? get errorMessage => _errorMessage;

  Future<bool> triggerEmergency({
    required double lat,
    required double lon,
    int? batteryLevel,
    String? message,
    String? currentRouteId,
  }) async {
    _isTriggering = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiService.triggerSOS(
        lat: lat,
        lon: lon,
        batteryLevel: batteryLevel,
        message: message,
        currentRouteId: currentRouteId,
      );
      _lastAlert = res;
      _isTriggering = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isTriggering = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadContacts(String userId) async {
    try {
      _contacts = await apiService.getContacts(userId: userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading contacts: $e');
    }
  }

  Future<bool> addContact(String userId, TrustedContact contact) async {
    try {
      final created = await apiService.addContact(contact, userId: userId);
      _contacts.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding contact: $e');
      return false;
    }
  }

  Future<bool> updateContact(String userId, String contactId, TrustedContact contact) async {
    try {
      final updated = await apiService.updateContact(contactId, contact, userId: userId);
      final idx = _contacts.indexWhere((c) => c.id == contactId);
      if (idx != -1) {
        _contacts[idx] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating contact: $e');
      return false;
    }
  }

  Future<bool> deleteContact(String userId, String contactId) async {
    try {
      final success = await apiService.deleteContact(contactId, userId: userId);
      if (success) {
        _contacts.removeWhere((c) => c.id == contactId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting contact: $e');
      return false;
    }
  }
}
