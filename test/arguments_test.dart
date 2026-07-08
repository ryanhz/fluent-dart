// Ported from fluent.js fluent-bundle/test/arguments_test.js

import 'package:fluent/fluent.dart';
import 'package:test/test.dart';

class CustomType extends FluentValue<String> {
	CustomType() : super("CUSTOM");
	@override
	String toString() => value;
}

void main() {
	group('Variables in values', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('''foo = Foo { \$num }
bar = { foo }
baz =
    .attr = Baz Attribute { \$num }
qux = { "a" ->
   *[a]     Baz Variant A { \$num }
}''');
		});

		test('can be used in the message value', () {
			List<Error> errs = [];
			expect(bundle.format("foo", args: {'num': 3}, errors: errs), "Foo 3");
			expect(errs.length, 0);
		});

		test('can be used in the message value which is referenced', () {
			List<Error> errs = [];
			expect(bundle.format("bar", args: {'num': 3}, errors: errs), "Foo 3");
			expect(errs.length, 0);
		});

		test('can be used in an attribute', () {
			List<Error> errs = [];
			expect(bundle.format("baz", args: {'num': 3}, attribute: "attr", errors: errs), "Baz Attribute 3");
			expect(errs.length, 0);
		});

		test('can be used in a variant', () {
			List<Error> errs = [];
			expect(bundle.format("qux", args: {'num': 3}, errors: errs), "Baz Variant A 3");
			expect(errs.length, 0);
		});
	});

	group('Variables in selectors', () {
		test('can be used as a selector', () {
			FluentBundle bundle = FluentBundle("en-US");
			bundle.addMessages('''foo = { \$num ->
   *[3] Foo
}''');
			List<Error> errs = [];
			expect(bundle.format("foo", args: {'num': 3}, errors: errs), "Foo");
			expect(errs.length, 0);
		});
	});

	group('Variables in function calls', () {
		test('can be a positional argument', () {
			FluentBundle bundle = FluentBundle("en-US");
			bundle.addMessages('foo = { NUMBER(\$num) }');
			List<Error> errs = [];
			expect(bundle.format("foo", args: {'num': 3}, errors: errs), "3");
			expect(errs.length, 0);
		});
	});

	group('Variables simple errors', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('foo = { \$arg }');
		});

		test("falls back to the argument's name if it's missing", () {
			List<Error> errs = [];
			expect(bundle.format("foo", args: {}, errors: errs), "{\$arg}");
			expect(errs.length, 1);
		});

		test('cannot be a list', () {
			List<Error> errs = [];
			expect(bundle.format("foo", args: {'arg': [1, 2, 3]}, errors: errs), "{\$arg}");
			expect(errs.length, 1);
			expect(errs[0], isA<UnsupportedError>());
		});

		test('cannot be a map', () {
			List<Error> errs = [];
			expect(bundle.format("foo", args: {'arg': {'prop': 1}}, errors: errs), "{\$arg}");
			expect(errs.length, 1);
			expect(errs[0], isA<UnsupportedError>());
		});

		test('cannot be a boolean', () {
			List<Error> errs = [];
			expect(bundle.format("foo", args: {'arg': true}, errors: errs), "{\$arg}");
			expect(errs.length, 1);
			expect(errs[0], isA<UnsupportedError>());
		});

		test('cannot be null', () {
			List<Error> errs = [];
			expect(bundle.format("foo", args: {'arg': null}, errors: errs), "{\$arg}");
			expect(errs.length, 1);
			expect(errs[0], isA<UnsupportedError>());
		});
	});

	group('Variables and strings', () {
		test('can be a string', () {
			FluentBundle bundle = FluentBundle("en-US");
			bundle.addMessages('foo = { \$arg }');
			List<Error> errs = [];
			expect(bundle.format("foo", args: {'arg': "Argument"}, errors: errs), "Argument");
			expect(errs.length, 0);
		});
	});

	group('Variables and numbers', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('foo = { \$arg }');
		});

		test('can be a number', () {
			List<Error> errs = [];
			expect(bundle.format("foo", args: {'arg': 1}, errors: errs), "1");
			expect(errs.length, 0);
		});

		test('can be a FluentNumber', () {
			List<Error> errs = [];
			FluentValue arg = FluentNumber(1, minimumFractionDigits: 2);
			expect(bundle.format("foo", args: {'arg': arg}, errors: errs), "1.00");
			expect(errs.length, 0);
		});
	});

	group('Variables and dates', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('foo = { \$arg }');
		});

		test('can be a DateTime', () {
			List<Error> errs = [];
			DateTime arg = DateTime.parse("2016-09-29");
			// intl separates the time from the AM/PM marker with a narrow no-break space (U+202F).
			String expected = "September 29, 2016 12:00:00${String.fromCharCode(0x202F)}AM";
			expect(bundle.format("foo", args: {'arg': arg}, errors: errs), expected);
			expect(errs.length, 0);
		});

		test('can be a FluentDateTime', () {
			List<Error> errs = [];
			DateTime localDate = DateTime(2016, 9, 29, 12);
			FluentValue arg = FluentDateTime(localDate, pattern: "EEEE");
			expect(bundle.format("foo", args: {'arg': arg}, errors: errs), "Thursday");
			expect(errs.length, 0);
		});
	});

	group('Custom argument types', () {
		late FluentBundle bundle;
		late Map<String, dynamic> args;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('''foo = { \$arg }
bar = { foo }''');
			args = {'arg': CustomType()};
		});

		test('interpolation', () {
			List<Error> errs = [];
			expect(bundle.format("foo", args: args, errors: errs), "CUSTOM");
			expect(errs.length, 0);
		});

		test('nested interpolation', () {
			List<Error> errs = [];
			expect(bundle.format("bar", args: args, errors: errs), "CUSTOM");
			expect(errs.length, 0);
		});
	});
}
