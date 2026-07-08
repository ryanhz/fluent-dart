// Ported from fluent.js fluent-bundle/test/errors_test.js

import 'package:fluent/fluent.dart';
import 'package:test/test.dart';

void main() {
	late FluentBundle bundle;

	setUp(() {
		bundle = FluentBundle("en-US");
		bundle.addMessages('foo = {\$one} and {\$two}');
	});

	test('reports into an array, accumulating across calls', () {
		List<Error> errors = [];

		String? val1 = bundle.format("foo", args: {}, errors: errors);
		expect(val1, "{\$one} and {\$two}");
		expect(errors.length, 2);

		String? val2 = bundle.format("foo", args: {}, errors: errors);
		expect(val2, "{\$one} and {\$two}");
		expect(errors.length, 4);
	});

	test('throws the first error when no errors list is given', () {
		expect(() => bundle.format("foo", args: {}), throwsA(isA<Error>()));
	});
}
