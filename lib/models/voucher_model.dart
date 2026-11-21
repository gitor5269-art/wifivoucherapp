import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VoucherModel {
  final String id;
  final String code;
  final String duration;
  final String status; // 'UNUSED' or 'USED'
  final DateTime createdAt;
  final String createdBy;
  final DateTime? updatedAt;

  const VoucherModel({
    required this.id,
    required this.code,
    required this.duration,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
  });

  bool get isUnused => status.toUpperCase() == 'UNUSED';
  bool get isUsed => status.toUpperCase() == 'USED';

  String get formattedCreatedAt {
    return DateFormat('yyyy-MM-dd HH:mm').format(createdAt);
  }

  String get formattedDateOnly {
    return DateFormat('yyyy-MM-dd').format(createdAt);
  }

  String get formattedUpdatedAt {
    if (updatedAt == null) return 'Never';
    return DateFormat('yyyy-MM-dd HH:mm').format(updatedAt!);
  }

  String toCopyString({bool includeDuration = true}) {
    if (includeDuration) {
      return 'Voucher Code: $code\nDuration: $duration';
    }
    return code;
  }

  String toPrintString() {
    return '''WiFi VOUCHER

Voucher Code: $code
Duration: $duration
Status: $status

Date Generated: $formattedCreatedAt''';
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'duration': duration,
      'status': status.toUpperCase(),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory VoucherModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) {
        return val.toDate();
      } else if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      } else if (val is int) {
        return DateTime.fromMillisecondsSinceEpoch(val);
      }
      return DateTime.now();
    }

    return VoucherModel(
      id: docId,
      code: (map['code'] as String?)?.toUpperCase().trim() ?? '',
      duration: map['duration'] as String? ?? '1 Hour',
      status: (map['status'] as String?)?.toUpperCase().trim() ?? 'UNUSED',
      createdAt: parseDate(map['createdAt']),
      createdBy: map['createdBy'] as String? ?? 'Admin',
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  VoucherModel copyWith({
    String? id,
    String? code,
    String? duration,
    String? status,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
  }) {
    return VoucherModel(
      id: id ?? this.id,
      code: code ?? this.code,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
