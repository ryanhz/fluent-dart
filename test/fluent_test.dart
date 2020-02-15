import 'package:test/test.dart';

import 'package:fluent/fluent.dart';

void main() {
  test('adds one to input values', () {
    expect(2+4, 6);
    expect(() => 2/0, throwsException);
  });
}
