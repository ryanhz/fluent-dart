// Ported from fluent.js fluent-bundle/test/patterns_test.js

import 'package:fluent/fluent.dart';
import 'package:test/test.dart';

void main() {
	group('Simple string value', () {
		test('returns the value', () {
			FluentBundle bundle = FluentBundle("en-US");
			bundle.addMessages('foo = Foo');
			List<Error> errs = [];
			expect(bundle.format("foo", errors: errs), "Foo");
			expect(errs.length, 0);
		});
	});

	group('Complex string value', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('''foo = Foo
-bar = Bar

ref-message = { foo }
ref-term = { -bar }

ref-missing-message = { missing }
ref-missing-term = { -missing }''');
		});

		test('resolves the reference to a message', () {
			List<Error> errs = [];
			expect(bundle.format("ref-message", errors: errs), "Foo");
			expect(errs.length, 0);
		});

		test('resolves the reference to a term', () {
			List<Error> errs = [];
			expect(bundle.format("ref-term", errors: errs), "Bar");
			expect(errs.length, 0);
		});

		test('returns the id if a message reference is missing', () {
			List<Error> errs = [];
			expect(bundle.format("ref-missing-message", errors: errs), "{missing}");
			expect(errs.length, 1);
		});

		test('returns the id if a term reference is missing', () {
			List<Error> errs = [];
			expect(bundle.format("ref-missing-term", errors: errs), "{-missing}");
			expect(errs.length, 1);
		});
	});

	group('Complex string referencing a message with no value', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('''foo =
    .attr = Foo Attr
bar = { foo } Bar''');
		});

		// Unlike fluent.js (which resolves a null value to the "{???}"
		// placeholder plus a reported error), FluentBundle.format returns null
		// outright when the message has no top-level value.
		test('returns null when trying to format a message with no value', () {
			List<Error> errs = [];
			expect(bundle.format("foo", errors: errs), null);
			expect(errs.length, 0);
		});

		test('formats the attribute', () {
			List<Error> errs = [];
			expect(bundle.format("foo", attribute: "attr", errors: errs), "Foo Attr");
			expect(errs.length, 0);
		});

		test('falls back to id when the referenced message has no value', () {
			List<Error> errs = [];
			expect(bundle.format("bar", errors: errs), "{foo} Bar");
			expect(errs.length, 1);
		});
	});

	group('Cyclic reference', () {
		test('returns ???', () {
			FluentBundle bundle = FluentBundle("en-US");
			bundle.addMessages('''foo = { bar }
bar = { foo }''');
			List<Error> errs = [];
			expect(bundle.format("foo", errors: errs), "{???}");
			expect(errs.length, 1);
			expect(errs[0], isA<RangeError>());
		});
	});

	group('Cyclic self-reference', () {
		test('returns ???', () {
			FluentBundle bundle = FluentBundle("en-US");
			bundle.addMessages('foo = { foo }');
			List<Error> errs = [];
			expect(bundle.format("foo", errors: errs), "{???}");
			expect(errs.length, 1);
			expect(errs[0], isA<RangeError>());
		});
	});

	group('Cyclic self-reference in a member', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('''foo =
    { \$sel ->
       *[a] { foo }
        [b] Bar
    }
bar = { foo }''');
		});

		test('returns ??? for the recursive member', () {
			List<Error> errs = [];
			expect(bundle.format("foo", args: {'sel': "a"}, errors: errs), "{???}");
			expect(errs.length, 1);
			expect(errs[0], isA<RangeError>());
		});

		test('returns the other member if requested', () {
			List<Error> errs = [];
			expect(bundle.format("foo", args: {'sel': "b"}, errors: errs), "Bar");
			expect(errs.length, 0);
		});
	});

	group('Cyclic reference in a selector', () {
		test('returns the default variant', () {
			FluentBundle bundle = FluentBundle("en-US");
			bundle.addMessages('''-foo =
    { -bar.attr ->
       *[a] Foo
    }
-bar = Bar
    .attr = { -foo }

foo = { -foo }''');
			List<Error> errs = [];
			expect(bundle.format("foo", errors: errs), "Foo");
			expect(errs.length, 1);
			expect(errs[0], isA<RangeError>());
		});
	});

	group('Cyclic self-reference in a selector', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('''-foo =
    { -bar.attr ->
       *[a] Foo
    }
    .attr = a

-bar =
    { -foo.attr ->
      *[a] Bar
    }
    .attr = { -foo }

foo = { -foo }
bar = { -bar }''');
		});

		test('returns the default variant', () {
			List<Error> errs = [];
			expect(bundle.format("foo", errors: errs), "Foo");
			expect(errs.length, 1);
			expect(errs[0], isA<RangeError>());
		});

		test('can reference an attribute', () {
			List<Error> errs = [];
			expect(bundle.format("bar", errors: errs), "Bar");
			expect(errs.length, 0);
		});
	});
}
