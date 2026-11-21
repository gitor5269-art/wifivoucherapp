import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initAuthListener();
  }

  FirebaseAuth? get _auth {
    if (FirebaseService().isInitialized) {
      try {
        return FirebaseAuth.instance;
      } catch (e) {
        debugPrint('[AuthService] FirebaseAuth instance not available: $e');
      }
    }
    return null;
  }

  final ValueNotifier<String?> currentAdminEmailNotifier =
      ValueNotifier<String?>(null);

  bool get isAuthenticated => currentAdminEmailNotifier.value != null;
  String? get currentAdminEmail => currentAdminEmailNotifier.value;

  void _initAuthListener() {
    try {
      _auth?.authStateChanges().listen((User? user) {
        currentAdminEmailNotifier.value = user?.email;
      });
    } catch (e) {
      debugPrint('[AuthService] authStateChanges listener notice: $e');
    }
  }

  /// Sign in admin using email and password
  Future<void> signIn({required String email, required String password}) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty) {
      throw Exception('Please enter admin email address.');
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(cleanEmail)) {
      throw Exception('Please enter a valid email format.');
    }
    if (cleanPassword.isEmpty) {
      throw Exception('Please enter your password.');
    }
    if (cleanPassword.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final auth = _auth;
    if (auth == null) {
      final initError = FirebaseService().initError;
      throw Exception(
        initError == null
            ? 'Firebase Authentication is unavailable. Check your Firebase setup and connection.'
            : 'Firebase could not initialize: $initError',
      );
    }

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );
      currentAdminEmailNotifier.value = credential.user?.email;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] FirebaseAuthException: ${e.code}');
      if (e.code == 'user-not-found') {
        throw Exception('No administrator found with this email.');
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Incorrect password. Please try again.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address format.');
      } else if (e.code == 'user-disabled') {
        throw Exception('This administrator account has been disabled.');
      } else if (e.code == 'operation-not-allowed') {
        throw Exception(
          'Email/password sign-in is not enabled for this Firebase project.',
        );
      } else if (e.code == 'network-request-failed') {
        throw Exception('Network error. Check your connection and try again.');
      }
      throw Exception(e.message ?? 'Authentication failed.');
    } catch (e) {
      debugPrint('[AuthService] Unexpected auth error: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Secure logout
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('[AuthService] Sign out error: $e');
    }
    currentAdminEmailNotifier.value = null;
  }
}
