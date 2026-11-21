import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _initError;
  String? get initError => _initError;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isInitialized = true;
      debugPrint('[FirebaseService] Firebase successfully initialized.');
    } catch (e) {
      _initError = e.toString();
      debugPrint('[FirebaseService] Firebase initialization notice: $e');
      // Set initialized true if an app was already present
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
      }
    }
  }
}
