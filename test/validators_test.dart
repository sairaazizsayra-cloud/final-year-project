import 'package:flutter_test/flutter_test.dart';
import 'package:keychain_shop/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('bad'), isNotNull);
      expect(Validators.email('user@example.com'), isNull);
    });

    test('password', () {
      expect(Validators.password('123'), isNotNull);
      expect(Validators.password('secret1'), isNull);
    });

    test('confirmPassword', () {
      expect(Validators.confirmPassword('a', 'b'), isNotNull);
      expect(Validators.confirmPassword('same', 'same'), isNull);
    });

    test('phone', () {
      expect(Validators.phone('123'), isNotNull);
      expect(Validators.phone('03001234567'), isNull);
    });

    test('name', () {
      expect(Validators.name('A'), isNotNull);
      expect(Validators.name('Ali'), isNull);
    });
  });
}
