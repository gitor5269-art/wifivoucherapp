import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/voucher_model.dart';
import 'firebase_service.dart';

class VoucherService {
  static final VoucherService _instance = VoucherService._internal();
  factory VoucherService() => _instance;
  VoucherService._internal() {
    _loadLocalVouchers().then((_) {
      _initStream();
    });
  }

  static const String collectionName = 'vouchers';
  static const String _prefsKey = 'cached_wifi_vouchers';

  // In-memory cache synced with LocalStorage & Firestore
  final List<VoucherModel> _cachedVouchers = [];
  final StreamController<List<VoucherModel>> _vouchersStreamController =
      StreamController<List<VoucherModel>>.broadcast();

  Stream<List<VoucherModel>> get vouchersStream => _vouchersStreamController.stream;
  List<VoucherModel> get vouchers => List.unmodifiable(_cachedVouchers);

  FirebaseFirestore? get _firestore {
    if (FirebaseService().isInitialized) {
      try {
        return FirebaseFirestore.instance;
      } catch (e) {
        debugPrint('[VoucherService] Firestore instance not available: $e');
      }
    }
    return null;
  }

  /// Loads locally saved vouchers on startup so data is persisted across refreshes
  Future<void> _loadLocalVouchers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_prefsKey);
      if (rawList != null && rawList.isNotEmpty) {
        final List<VoucherModel> loaded = [];
        for (final raw in rawList) {
          try {
            final Map<String, dynamic> map = jsonDecode(raw);
            loaded.add(VoucherModel(
              id: map['id'] ?? 'vouch_${DateTime.now().millisecondsSinceEpoch}',
              code: (map['code'] ?? '').toString().toUpperCase(),
              duration: map['duration'] ?? '1 Hour',
              status: (map['status'] ?? 'UNUSED').toString().toUpperCase(),
              createdAt: map['createdAt'] != null
                  ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
                  : DateTime.now(),
              createdBy: map['createdBy'] ?? 'admin@wifivoucher.com',
              updatedAt: map['updatedAt'] != null
                  ? DateTime.tryParse(map['updatedAt'])
                  : null,
            ));
          } catch (e) {
            debugPrint('[VoucherService] Error parsing cached item: $e');
          }
        }

        if (loaded.isNotEmpty) {
          loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _cachedVouchers.clear();
          _cachedVouchers.addAll(loaded);
          _vouchersStreamController.add(List.unmodifiable(_cachedVouchers));
          debugPrint('[VoucherService] Loaded ${loaded.length} vouchers from local storage.');
        }
      }
    } catch (e) {
      debugPrint('[VoucherService] Error loading local storage: $e');
    }
  }

  /// Persists current cache to local storage
  Future<void> _persistToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> serialized = _cachedVouchers.map((v) {
        return jsonEncode({
          'id': v.id,
          'code': v.code,
          'duration': v.duration,
          'status': v.status,
          'createdAt': v.createdAt.toIso8601String(),
          'createdBy': v.createdBy,
          'updatedAt': v.updatedAt?.toIso8601String(),
        });
      }).toList();
      await prefs.setStringList(_prefsKey, serialized);
    } catch (e) {
      debugPrint('[VoucherService] Error persisting to local storage: $e');
    }
  }

  void _initStream() {
    if (_firestore != null) {
      try {
        _firestore!
            .collection(collectionName)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen(
          (snapshot) {
            final List<VoucherModel> firestoreVouchers = [];
            for (final doc in snapshot.docs) {
              try {
                firestoreVouchers.add(VoucherModel.fromMap(doc.data(), doc.id));
              } catch (e) {
                debugPrint('[VoucherService] Error parsing doc ${doc.id}: $e');
              }
            }

            // Merge with local cache so locally generated items are never lost
            final firestoreIds = firestoreVouchers.map((v) => v.id).toSet();
            final firestoreCodes = firestoreVouchers.map((v) => v.code).toSet();

            for (final local in _cachedVouchers) {
              if (!firestoreIds.contains(local.id) && !firestoreCodes.contains(local.code)) {
                firestoreVouchers.add(local);
              }
            }

            firestoreVouchers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            _cachedVouchers.clear();
            _cachedVouchers.addAll(firestoreVouchers);
            _vouchersStreamController.add(List.unmodifiable(_cachedVouchers));
            _persistToLocalStorage();
          },
          onError: (error) {
            debugPrint('[VoucherService] Firestore snapshot notice: $error');
            // Keep existing data, never wipe out
            _vouchersStreamController.add(List.unmodifiable(_cachedVouchers));
          },
        );
      } catch (e) {
        debugPrint('[VoucherService] Error setting up Firestore listener: $e');
      }
    }
  }

  /// Characters used to generate easy-to-read codes.
  /// Omits ambiguous characters: 0, O, 1, I, L to prevent user confusion.
  static const String _codeCharset = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Generates a random, readable 6-character code (e.g. "X7K9P2")
  String _generateRandomCode({int length = 6}) {
    final random = Random.secure();
    return List.generate(
      length,
      (index) => _codeCharset[random.nextInt(_codeCharset.length)],
    ).join();
  }

  /// Checks whether a voucher code already exists in Firestore or local cache
  Future<bool> isCodeDuplicate(String code) async {
    final cleanCode = code.toUpperCase().trim();

    // 1. Instant check in local cache (O(N) in memory)
    if (_cachedVouchers.any((v) => v.code == cleanCode)) {
      return true;
    }

    // 2. Check in Firestore with 1.2s timeout to avoid hanging when cloud is unreachable
    if (_firestore != null) {
      try {
        final query = await _firestore!
            .collection(collectionName)
            .where('code', isEqualTo: cleanCode)
            .limit(1)
            .get()
            .timeout(const Duration(milliseconds: 1200));
        return query.docs.isNotEmpty;
      } catch (e) {
        debugPrint('[VoucherService] Duplicate check offline/timeout notice: $e');
      }
    }
    return false;
  }

  /// Generates a guaranteed unique code
  Future<String> generateUniqueCode() async {
    for (int attempt = 0; attempt < 50; attempt++) {
      final code = _generateRandomCode(length: 6);
      final isDup = await isCodeDuplicate(code);
      if (!isDup) {
        return code;
      }
    }
    // Fallback if multiple collisions occur: add extra character
    return _generateRandomCode(length: 7);
  }

  /// Generates a single voucher and saves immediately
  Future<VoucherModel> generateSingleVoucher({
    required String duration,
    required String adminEmail,
  }) async {
    final code = await generateUniqueCode();
    final now = DateTime.now();
    final docId = 'vouch_${now.millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    final voucher = VoucherModel(
      id: docId,
      code: code,
      duration: duration,
      status: 'UNUSED',
      createdAt: now,
      createdBy: adminEmail,
    );

    await _saveVouchersToStore([voucher]);
    return voucher;
  }

  /// Generates a batch of vouchers (e.g. 5, 10, 20) and saves immediately
  Future<List<VoucherModel>> generateBatchVouchers({
    required int count,
    required String duration,
    required String adminEmail,
  }) async {
    final List<VoucherModel> batchVouchers = [];
    final Set<String> batchCodes = {};
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      String code = await generateUniqueCode();
      while (batchCodes.contains(code)) {
        code = await generateUniqueCode();
      }
      batchCodes.add(code);

      final docId = 'vouch_${now.millisecondsSinceEpoch}_${i}_${Random().nextInt(9999)}';
      batchVouchers.add(
        VoucherModel(
          id: docId,
          code: code,
          duration: duration,
          status: 'UNUSED',
          createdAt: now.add(Duration(milliseconds: i)),
          createdBy: adminEmail,
        ),
      );
    }

    await _saveVouchersToStore(batchVouchers);
    return batchVouchers;
  }

  /// Saves vouchers immediately to local storage and asynchronously syncs to Firestore
  Future<void> _saveVouchersToStore(List<VoucherModel> newVouchers) async {
    // 1. Instantly update memory cache
    for (final v in newVouchers) {
      if (!_cachedVouchers.any((existing) => existing.id == v.id)) {
        _cachedVouchers.insert(0, v);
      }
    }
    _vouchersStreamController.add(List.unmodifiable(_cachedVouchers));

    // 2. Instantly persist to local storage
    await _persistToLocalStorage();

    // 3. Sync to Cloud Firestore with non-blocking 2.5s timeout
    if (_firestore != null) {
      try {
        final batch = _firestore!.batch();
        for (final v in newVouchers) {
          final docRef = _firestore!.collection(collectionName).doc(v.id);
          batch.set(docRef, v.toMap());
        }
        await batch.commit().timeout(const Duration(milliseconds: 2500));
        debugPrint('[VoucherService] Successfully synced ${newVouchers.length} vouchers to Firestore');
      } catch (e) {
        debugPrint('[VoucherService] Firestore background sync notice (saved locally): $e');
      }
    }
  }

  /// Updates status of a voucher (UNUSED <-> USED)
  Future<void> updateVoucherStatus(String docId, String newStatus) async {
    final cleanStatus = newStatus.toUpperCase();
    final now = DateTime.now();

    // Update local cache immediately
    final index = _cachedVouchers.indexWhere((v) => v.id == docId);
    if (index != -1) {
      _cachedVouchers[index] = _cachedVouchers[index].copyWith(
        status: cleanStatus,
        updatedAt: now,
      );
      _vouchersStreamController.add(List.unmodifiable(_cachedVouchers));
      await _persistToLocalStorage();
    }

    // Sync to Firestore
    if (_firestore != null) {
      try {
        await _firestore!.collection(collectionName).doc(docId).update({
          'status': cleanStatus,
          'updatedAt': Timestamp.fromDate(now),
        }).timeout(const Duration(milliseconds: 2500));
      } catch (e) {
        debugPrint('[VoucherService] Firestore update status notice: $e');
      }
    }
  }

  /// Deletes a voucher record
  Future<void> deleteVoucher(String docId) async {
    _cachedVouchers.removeWhere((v) => v.id == docId);
    _vouchersStreamController.add(List.unmodifiable(_cachedVouchers));
    await _persistToLocalStorage();

    if (_firestore != null) {
      try {
        await _firestore!.collection(collectionName).doc(docId).delete().timeout(const Duration(milliseconds: 2500));
      } catch (e) {
        debugPrint('[VoucherService] Firestore delete notice: $e');
      }
    }
  }

  /// Refreshes data from Firestore if available
  Future<void> refresh() async {
    if (_firestore != null) {
      try {
        final query = await _firestore!
            .collection(collectionName)
            .orderBy('createdAt', descending: true)
            .get()
            .timeout(const Duration(milliseconds: 2500));

        final List<VoucherModel> firestoreVouchers = [];
        for (final doc in query.docs) {
          firestoreVouchers.add(VoucherModel.fromMap(doc.data(), doc.id));
        }

        final firestoreIds = firestoreVouchers.map((v) => v.id).toSet();
        for (final local in _cachedVouchers) {
          if (!firestoreIds.contains(local.id)) {
            firestoreVouchers.add(local);
          }
        }

        firestoreVouchers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _cachedVouchers.clear();
        _cachedVouchers.addAll(firestoreVouchers);
        _vouchersStreamController.add(List.unmodifiable(_cachedVouchers));
        await _persistToLocalStorage();
      } catch (e) {
        debugPrint('[VoucherService] Refresh notice: $e');
      }
    }
  }

  /// Computes dynamic statistics from live records
  Map<String, int> getStatistics() {
    int total = _cachedVouchers.length;
    int unused = _cachedVouchers.where((v) => v.isUnused).length;
    int used = _cachedVouchers.where((v) => v.isUsed).length;
    return {
      'total': total,
      'unused': unused,
      'used': used,
    };
  }
}
