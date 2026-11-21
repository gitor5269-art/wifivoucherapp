import 'package:flutter_test/flutter_test.dart';
import 'package:wifivoucherapp/models/voucher_model.dart';

void main() {
  group('VoucherModel Tests', () {
    test('creates voucher model with correct default values and formats', () {
      final now = DateTime(2026, 11, 21, 14, 30);
      final voucher = VoucherModel(
        id: 'test_123',
        code: 'X7K9P2',
        duration: '3 Hours',
        status: 'UNUSED',
        createdAt: now,
        createdBy: 'admin@wifivoucher.com',
      );

      expect(voucher.code, 'X7K9P2');
      expect(voucher.duration, '3 Hours');
      expect(voucher.isUnused, isTrue);
      expect(voucher.isUsed, isFalse);
      expect(voucher.formattedDateOnly, '2026-11-21');
      expect(voucher.toCopyString(includeDuration: true), 'Voucher Code: X7K9P2\nDuration: 3 Hours');
      expect(voucher.toCopyString(includeDuration: false), 'X7K9P2');

      final printStr = voucher.toPrintString();
      expect(printStr, contains('WiFi VOUCHER'));
      expect(printStr, contains('Voucher Code: X7K9P2'));
      expect(printStr, contains('Duration: 3 Hours'));
      expect(printStr, contains('Status: UNUSED'));
    });

    test('updates status and copyWith correctly', () {
      final now = DateTime(2026, 11, 21, 14, 30);
      final voucher = VoucherModel(
        id: 'test_123',
        code: 'X7K9P2',
        duration: '1 Hour',
        status: 'UNUSED',
        createdAt: now,
        createdBy: 'admin@wifivoucher.com',
      );

      final updated = voucher.copyWith(status: 'USED', updatedAt: now);
      expect(updated.isUsed, isTrue);
      expect(updated.isUnused, isFalse);
      expect(updated.status, 'USED');
      expect(updated.updatedAt, isNotNull);
    });

    test('toMap and fromMap parse fields reliably', () {
      final now = DateTime.now();
      final original = VoucherModel(
        id: 'vouch_abc',
        code: 'K9P2X7',
        duration: '1 Day',
        status: 'UNUSED',
        createdAt: now,
        createdBy: 'admin@wifivoucher.com',
      );

      final map = original.toMap();
      final parsed = VoucherModel.fromMap(map, 'vouch_abc');

      expect(parsed.id, 'vouch_abc');
      expect(parsed.code, 'K9P2X7');
      expect(parsed.duration, '1 Day');
      expect(parsed.status, 'UNUSED');
      expect(parsed.createdBy, 'admin@wifivoucher.com');
    });
  });
}
