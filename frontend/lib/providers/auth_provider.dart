import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService apiService;
  UserProfile? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({required this.apiService});

  UserProfile? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address. Please register first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid password or credentials. Please check and try again.';
      case 'email-already-in-use':
        return 'This email address is already in use by another account.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'The email address is not formatted correctly.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in Firebase Console.';
      case 'network-request-failed':
        return 'Network error connecting to Firebase. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication failed (${e.code}). Please try again.';
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Ensure Firebase is initialized
      if (!FirebaseService.isAvailable) {
        await FirebaseService.initializeIfPossible();
      }
      if (!FirebaseService.isAvailable) {
        throw Exception('Firebase is not available. Please verify network and Firebase setup.');
      }

      // 2. Sign in with Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to retrieve authenticated user from Firebase.');
      }

      // 3. Obtain Firebase ID token
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Failed to obtain Firebase ID token.');
      }

      // 4. Exchange Firebase ID token with FastAPI backend
      final res = await apiService.authenticateFirebase(idToken);
      _user = res.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // If backend token exchange fails, revert Firebase sign-in so state remains consistent
      try {
        if (FirebaseService.isAvailable && FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance.signOut();
        }
      } catch (_) {}

      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String fullName,
    String? phone,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Ensure Firebase is initialized
      if (!FirebaseService.isAvailable) {
        await FirebaseService.initializeIfPossible();
      }
      if (!FirebaseService.isAvailable) {
        throw Exception('Firebase is not available. Please verify network and Firebase setup.');
      }

      // 2. Create Firebase Auth user
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create Firebase user account.');
      }

      // 3. Update Firebase user's displayName with fullName
      if (fullName.trim().isNotEmpty) {
        await firebaseUser.updateDisplayName(fullName.trim());
        await firebaseUser.reload();
      }

      // 4. Obtain Firebase ID token
      final idToken = await firebaseUser.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Failed to obtain Firebase ID token.');
      }

      // 5. Exchange Firebase ID token with FastAPI backend
      final res = await apiService.authenticateFirebase(idToken);

      // 6. Store returned UserProfile/session preserving fullName and emergency phone
_user = res.user.copyWith(
  fullName: fullName.trim().isNotEmpty ? fullName.trim() : null,
  phone: (phone != null && phone.trim().isNotEmpty) ? phone.trim() : null,
);

// 7. Persist the personal emergency phone in the FastAPI backend
if (!isGuest && phone != null && phone.trim().isNotEmpty) {
  try {
    final updatedProfile = await apiService.updateProfile(
      userId: _user!.id,
      fullName: fullName.trim(),
      phone: phone.trim(),
    );

    _user = updatedProfile;
  } catch (e) {
    debugPrint('[AuthProvider] Failed to persist registration profile: $e');
  }
}
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // If backend token exchange fails, revert Firebase sign-in so state remains consistent
      try {
        if (FirebaseService.isAvailable && FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance.signOut();
        }
      } catch (_) {}

      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  bool get isGuest => _user == null || _user?.id == 'guest_user' || _user?.email == 'guest@safeher.ai';

  void continueAsGuest() {
    _user = UserProfile(
      id: 'guest_user',
      email: 'guest@safeher.ai',
      fullName: 'Guest Traveler',
      phone: '+919490616555',
      createdAt: DateTime.now().toIso8601String(),
    );
    notifyListeners();
  }

  Future<bool> updateProfile({required String fullName, String? phone}) async {
    if (_user == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (FirebaseService.isAvailable && FirebaseAuth.instance.currentUser != null) {
        try {
          await FirebaseAuth.instance.currentUser!.updateDisplayName(fullName.trim());
          await FirebaseAuth.instance.currentUser!.reload();
        } catch (e) {
          debugPrint('[AuthProvider] Firebase updateDisplayName note: $e');
        }
      }

      if (!isGuest) {
        try {
          await apiService.updateProfile(
            userId: _user!.id,
            fullName: fullName.trim(),
            phone: phone?.trim(),
          );
        } catch (e) {
          debugPrint('[AuthProvider] Backend updateProfile note: $e');
        }
      }

      _user = _user!.copyWith(
        fullName: fullName.trim(),
        phone: (phone != null && phone.trim().isNotEmpty) ? phone.trim() : null,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (FirebaseService.isAvailable) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      debugPrint('[AuthProvider] Firebase signOut note: $e');
    }
    _user = null;
    apiService.authToken = null;
    notifyListeners();
  }
}
