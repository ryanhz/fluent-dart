// Ported from fluent.js fluent-bundle/test/functions_test.js

import 'package:fluent/fluent.dart';
import 'package:test/test.dart';

// Mirrors fluent.js's `IDENTITY: args => args[0]` test function. Dart resolves
// positional call arguments to their raw wrapped value (String/num/DateTime),
// so IDENTITY re-wraps whatever it receives back into a FluentValue.
dynamic identity(dynamic value) {
	if (value is FluentValue) return value;
	if (value is num) return FluentNumber(value);
	if (value is DateTime) return FluentDateTime(value);
	return FluentString(value.toString());
}

void main() {
	group('Functions missing', () {
		test('falls back to the name of the function', () {
			FluentBundle bundle = FluentBundle("en-US");
			bundle.addMessages('foo = { MISSING("Foo") }');
			List<Error> errs = [];
			expect(bundle.format("foo", errors: errs), "{MISSING()}");
			expect(errs.length, 1);
		});
	});

	group('Functions arguments', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US", functions: {'IDENTITY': identity});
			bundle.addMessages('''foo = Foo
    .attr = Attribute
pass-string        = { IDENTITY("a") }
pass-number        = { IDENTITY(1) }
pass-message       = { IDENTITY(foo) }
pass-variable      = { IDENTITY(\$var) }
pass-function-call = { IDENTITY(IDENTITY(1)) }''');
		});

		test('accepts strings', () {
			List<Error> errs = [];
			expect(bundle.format("pass-string", errors: errs), "a");
			expect(errs.length, 0);
		});

		test('accepts numbers', () {
			List<Error> errs = [];
			expect(bundle.format("pass-number", errors: errs), "1");
			expect(errs.length, 0);
		});

		test('accepts entities', () {
			List<Error> errs = [];
			expect(bundle.format("pass-message", errors: errs), "Foo");
			expect(errs.length, 0);
		});

		test('accepts variables', () {
			List<Error> errs = [];
			expect(bundle.format("pass-variable", args: {'var': "Variable"}, errors: errs), "Variable");
			expect(errs.length, 0);
		});

		test('accepts function calls', () {
			List<Error> errs = [];
			expect(bundle.format("pass-function-call", errors: errs), "1");
			expect(errs.length, 0);
		});
	});
}
