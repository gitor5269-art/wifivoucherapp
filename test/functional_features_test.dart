import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifivoucherapp/models/voucher_model.dart';
import 'package:wifivoucherapp/services/auth_service.dart';
import 'package:wifivoucherapp/services/voucher_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('1. Admin Authentication Tests', () {
    final authService = AuthService();

    test('Rejects empty email or password', () async {
      expect(
        () => authService.signIn(email: '', password: 'password123'),
        throwsA(
          predicate((e) => e.toString().contains('Please enter admin email')),
        ),
      );

      expect(
        () =>
            authService.signIn(email: 'invalid-email', password: 'password123'),
        throwsA(predicate((e) => e.toString().contains('valid email format'))),
      );

      expect(
        () =>
            authService.signIn(email: 'admin@wifivoucher.com', password: '123'),
        throwsA(
          predicate((e) => e.toString().contains('at least 6 characters')),
        ),
      );
    });

    test('Rejects login when Firebase Authentication is unavailable', () async {
      await expectLater(
        authService.signIn(email: 'admin@example.com', password: 'password123'),
        throwsA(
          predicate(
            (error) => error.toString().contains(
              'Firebase Authentication is unavailable',
            ),
          ),
        ),
      );
      expect(authService.isAuthenticated, isFalse);
    });

    test('Rejects registration with invalid email or password', () async {
      expect(
        () => authService.createAccount(
          email: 'invalid-email',
          password: 'password123',
        ),
        throwsA(predicate((e) => e.toString().contains('valid email format'))),
      );
      expect(
        () => authService.createAccount(
          email: 'newadmin@example.com',
          password: '123',
        ),
        throwsA(
          predicate((e) => e.toString().contains('at least 6 characters')),
        ),
      );
    });

    test(
      'Rejects registration when Firebase Authentication is unavailable',
      () {
        expect(
          () => authService.createAccount(
            email: 'newadmin@example.com',
            password: 'password123',
          ),
          throwsA(
            predicate(
              (error) => error.toString().contains(
                'Firebase Authentication is unavailable',
              ),
            ),
          ),
        );
        expect(authService.isAuthenticated, isFalse);
      },
    );

    test('Logout clears session and updates auth state', () async {
      await authService.signOut();

      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentAdminEmail, isNull);
    });
  });

  group('2 & 3. Voucher Generation & Firestore Logic Tests', () {
    final voucherService = VoucherService();

    test(
      'Generates single voucher with clean, unambiguous unique code',
      () async {
        final voucher = await voucherService.generateSingleVoucher(
          duration: '1 Hour',
          adminEmail: 'admin@wifivoucher.com',
        );

        expect(voucher.code.length, 6);
        expect(voucher.duration, '1 Hour');
        expect(voucher.status, 'UNUSED');
        expect(voucher.createdBy, 'admin@wifivoucher.com');

        // Verify ambiguous characters (0, O, 1, I, L) are NEVER in generated codes
        expect(voucher.code.contains('0'), isFalse);
        expect(voucher.code.contains('O'), isFalse);
        expect(voucher.code.contains('1'), isFalse);
        expect(voucher.code.contains('I'), isFalse);
        expect(voucher.code.contains('L'), isFalse);
      },
    );

    test(
      'Generates small batch of unique vouchers (e.g. 5 vouchers)',
      () async {
        final batch = await voucherService.generateBatchVouchers(
          count: 5,
          duration: '3 Hours',
          adminEmail: 'admin@wifivoucher.com',
        );

        expect(batch.length, 5);
        final uniqueCodes = batch.map((v) => v.code).toSet();
        expect(uniqueCodes.length, 5, reason: 'All batch codes must be unique');

        for (final v in batch) {
          expect(v.duration, '3 Hours');
          expect(v.status, 'UNUSED');
        }
      },
    );

    test('Prevents duplicate voucher codes', () async {
      final existingCode = voucherService.vouchers.first.code;
      final isDup = await voucherService.isCodeDuplicate(existingCode);
      expect(isDup, isTrue);

      final isNotDup = await voucherService.isCodeDuplicate('ZZZZZZ99');
      expect(isNotDup, isFalse);
    });
  });

  group('4. Voucher Management & Status Updating Tests', () {
    final voucherService = VoucherService();

    test('Toggles voucher status from UNUSED to USED and back', () async {
      final voucher = voucherService.vouchers.first;
      expect(voucher.isUnused, isTrue);

      await voucherService.updateVoucherStatus(voucher.id, 'USED');
      final updatedVoucher = voucherService.vouchers.firstWhere(
        (v) => v.id == voucher.id,
      );
      expect(updatedVoucher.isUsed, isTrue);
      expect(updatedVoucher.isUnused, isFalse);

      await voucherService.updateVoucherStatus(voucher.id, 'UNUSED');
      final revertedVoucher = voucherService.vouchers.firstWhere(
        (v) => v.id == voucher.id,
      );
      expect(revertedVoucher.isUnused, isTrue);
    });

    test('Deletes voucher record permanently', () async {
      final initialCount = voucherService.vouchers.length;
      final voucherToDelete = voucherService.vouchers.last;

      await voucherService.deleteVoucher(voucherToDelete.id);
      expect(voucherService.vouchers.length, initialCount - 1);
      expect(
        voucherService.vouchers.any((v) => v.id == voucherToDelete.id),
        isFalse,
      );
    });
  });

  group('5. Copy Voucher Functionality Tests', () {
    test('Formats individual and batch copy strings correctly', () {
      final v1 = VoucherModel(
        id: 'v1',
        code: 'A7B8C9',
        duration: '3 Hours',
        status: 'UNUSED',
        createdAt: DateTime(2026, 11, 21),
        createdBy: 'admin@wifivoucher.com',
      );

      // Code with duration format (as specified in requirement 5)
      expect(
        v1.toCopyString(includeDuration: true),
        'Voucher Code: A7B8C9\nDuration: 3 Hours',
      );

      // Code only
      expect(v1.toCopyString(includeDuration: false), 'A7B8C9');
    });
  });

  group('6. Print Formatting & Layout Tests', () {
    test('Builds printable text matching approved format', () {
      final voucher = VoucherModel(
        id: 'v_print',
        code: 'X7K9P2',
        duration: '3 Hours',
        status: 'UNUSED',
        createdAt: DateTime(2026, 11, 21, 14, 30),
        createdBy: 'admin@wifivoucher.com',
      );

      final printText = voucher.toPrintString();
      expect(printText, contains('WiFi VOUCHER'));
      expect(printText, contains('Voucher Code: X7K9P2'));
      expect(printText, contains('Duration: 3 Hours'));
      expect(printText, contains('Status: UNUSED'));
      expect(printText, contains('Date Generated: 2026-11-21 14:30'));
    });
  });

  group('7. Dashboard Real Statistics Tests', () {
    final voucherService = VoucherService();

    test(
      'Calculates live database statistics accurately (Total, Unused, Used)',
      () {
        final stats = voucherService.getStatistics();
        final total = stats['total']!;
        final unused = stats['unused']!;
        final used = stats['used']!;

        expect(total, equals(unused + used));
        expect(total, equals(voucherService.vouchers.length));
      },
    );
  });
}
