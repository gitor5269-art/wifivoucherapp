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

  String _validatedEmail(String email, {required String emptyMessage}) {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      throw Exception(emptyMessage);
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(cleanEmail)) {
      throw Exception('Please enter a valid email format.');
    }
    return cleanEmail;
  }

  String _validatedPassword(String password) {
    final cleanPassword = password.trim();
    if (cleanPassword.isEmpty) {
      throw Exception('Please enter your password.');
    }
    if (cleanPassword.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    return cleanPassword;
  }

  FirebaseAuth _requireAuth() {
    final auth = _auth;
    if (auth != null) return auth;

    final initError = FirebaseService().initError;
    throw Exception(
      initError == null
          ? 'Firebase Authentication is unavailable. Check your Firebase setup and connection.'
          : 'Firebase could not initialize: $initError',
    );
  }

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
    final cleanEmail = _validatedEmail(
      email,
      emptyMessage: 'Please enter admin email address.',
    );
    final cleanPassword = _validatedPassword(password);
    final auth = _requireAuth();

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

  /// Creates a Firebase account and signs the new user in.
  Future<void> createAccount({
    required String email,
    required String password,
  }) async {
    final cleanEmail = _validatedEmail(
      email,
      emptyMessage: 'Please enter email address.',
    );
    final cleanPassword = _validatedPassword(password);
    final auth = _requireAuth();

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );
      currentAdminEmailNotifier.value = credential.user?.email;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] FirebaseAuthException: ${e.code}');
      final message = switch (e.code) {
        'email-already-in-use' => 'An account already exists for this email.',
        'invalid-email' => 'Please enter a valid email address.',
        'weak-password' => 'Password must be at least 6 characters.',
        'operation-not-allowed' =>
          'Email/password sign-in is not enabled for this Firebase project.',
        'network-request-failed' =>
          'Network error. Check your connection and try again.',
        _ => e.message ?? 'Account creation failed.',
      };
      throw Exception(message);
    } catch (e) {
      debugPrint('[AuthService] Unexpected account creation error: $e');
      throw Exception('Account creation failed: ${e.toString()}');
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
