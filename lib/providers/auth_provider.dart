import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:taxi_app/core/constants/feature_flags.dart';
import 'package:taxi_app/core/services/auth_service.dart';
import 'package:taxi_app/core/services/user_firestore_service.dart';
import 'package:taxi_app/core/utils/user_role.dart';
import 'package:taxi_app/models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth, this._users) {
    _authSub = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  final AuthService _auth;
  final UserFirestoreService _users;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  User? _firebaseUser;
  AppUser? _appUser;
  String? _verificationId;
  String? _errorMessage;
  bool _busy = false;
  UserRole _signupRole = UserRole.user;
  AppUser? get appUser => _appUser;
  User? get firebaseUser => _firebaseUser;
  String? get verificationId => _verificationId;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _busy;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  bool get isAuthenticated =>
      _firebaseUser != null && _appUser != null;

  bool get hasSession => _appUser != null;

  UserRole get signupRole => _signupRole;

  void setSignupRole(UserRole role) {
    _signupRole = role;
    notifyListeners();
  }

  Future<void> _onAuthStateChanged(User? user) async {
    final prevUid = _firebaseUser?.uid;
    _firebaseUser = user;
    await _profileSub?.cancel();
    _profileSub = null;
    // Only clear _appUser when the user actually changes (sign-out or different user).
    if (user?.uid != prevUid) {
      _appUser = null;
    }
    if (user != null) {
      _profileSub = _users.watchUser(user.uid).listen((profile) {
        _appUser = profile;
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  /// Call after user enters their name to create/load Firestore profile.
  Future<void> completeProfileAfterSignIn({String? displayName}) async {
    final u = _firebaseUser;
    if (u == null) return;
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _appUser = await _users.ensureUserProfile(
        firebaseUser: u,
        desiredRole: _signupRole,
        displayName: displayName,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> requestOtp(String e164Phone) async {
    if (!FeatureFlags.phoneOtpEnabled) {
      _errorMessage = 'Phone sign-in is not enabled yet.';
      notifyListeners();
      return;
    }
    _busy = true;
    _errorMessage = null;
    _verificationId = null;
    notifyListeners();
    final completer = Completer<void>();
    await _auth.verifyPhoneNumber(
      phoneNumber: e164Phone,
      verificationCompleted: (cred) async {
        try {
          await _auth.signInWithCredential(cred);
          // Don't complete profile here - let user enter name in ProfileSetupScreen
        } catch (e) {
          _errorMessage = e.toString();
        } finally {
          _busy = false;
          notifyListeners();
        }
        if (!completer.isCompleted) completer.complete();
      },
      verificationFailed: (e) {
        _errorMessage = e.message ?? e.code;
        _busy = false;
        notifyListeners();
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (verificationId, _) {
        _verificationId = verificationId;
        _busy = false;
        notifyListeners();
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (id) {
        _verificationId = id;
        _busy = false;
        notifyListeners();
      },
    );
    await completer.future.catchError((_) {});
  }

  Future<void> verifyOtp(String smsCode) async {
    if (!FeatureFlags.phoneOtpEnabled) {
      _errorMessage = 'Phone sign-in is not enabled yet.';
      notifyListeners();
      return;
    }
    final vid = _verificationId;
    if (vid == null) {
      _errorMessage = 'Request OTP first';
      notifyListeners();
      return;
    }
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: smsCode.trim(),
      );
      final result = await _auth.signInWithCredential(cred);
      // Set immediately so callers don't have to wait for authStateChanges stream.
      _firebaseUser = result.user;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? e.code;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // ==================== Email/Password Sign Up ====================
  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate inputs
      if (email.trim().isEmpty) {
        throw FirebaseAuthException(
          code: 'INVALID_EMAIL',
          message: 'Email is required',
        );
      }
      if (password.isEmpty) {
        throw FirebaseAuthException(
          code: 'WEAK_PASSWORD',
          message: 'Password is required',
        );
      }
      if (password != confirmPassword) {
        throw FirebaseAuthException(
          code: 'PASSWORD_MISMATCH',
          message: 'Passwords do not match',
        );
      }
      if (password.length < 6) {
        throw FirebaseAuthException(
          code: 'WEAK_PASSWORD',
          message: 'Password must be at least 6 characters',
        );
      }

      await _auth.signUpWithEmailPassword(email: email, password: password);
      await completeProfileAfterSignIn();
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // ==================== Email/Password Sign In ====================
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (email.trim().isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'MISSING_FIELDS',
          message: 'Email and password are required',
        );
      }

      await _auth.signInWithEmailPassword(email: email, password: password);
      await completeProfileAfterSignIn();
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // ==================== Google Sign In ====================
  Future<void> signInWithGoogle() async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.signInWithGoogle();
      await completeProfileAfterSignIn();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'CANCELLED') {
        _errorMessage = _getErrorMessage(e);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // ==================== Helper Methods ====================
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'The password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'account-exists-with-different-credential':
        return 'Account already exists with different sign-in method.';
      case 'INVALID_EMAIL':
        return 'Email is required.';
      case 'WEAK_PASSWORD':
        return 'Password must be at least 6 characters.';
      case 'PASSWORD_MISMATCH':
        return 'Passwords do not match.';
      case 'MISSING_FIELDS':
        return 'Email and password are required.';
      case 'CANCELLED':
        return 'Sign in was cancelled.';
      case 'GOOGLE_SIGN_IN_ERROR':
        return 'Failed to sign in with Google.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  Future<void> logout() async {
    await _profileSub?.cancel();
    _profileSub = null;
    await _auth.signOut();
    _appUser = null;
    _firebaseUser = null;
    _verificationId = null;
    notifyListeners();
  }

  // Future<void> registerAsDriver() async {
  //   final uid = _firebaseUser?.uid;
  //   if (uid == null) {
  //     _errorMessage = null;
  //     notifyListeners();
  //     return;
  //   }
  //   _busy = true;
  //   notifyListeners();
  //   try {
  //     await _users.updateRole(uid, UserRole.driver);
  //     await _users.setApproved(uid, false);
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //   } finally {
  //     _busy = false;
  //     notifyListeners();
  //   }
  // }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
