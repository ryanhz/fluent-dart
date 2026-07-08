// Ported from fluent.js fluent-bundle/test/attributes_test.js

import 'package:fluent/fluent.dart';
import 'package:test/test.dart';

void main() {
	group('Attributes missing', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('''foo = Foo
bar = Bar
    .attr = Bar Attribute
baz = { foo } Baz
qux = { foo } Qux
    .attr = Qux Attribute

ref-foo = { foo.missing }
ref-bar = { bar.missing }
ref-baz = { baz.missing }
ref-qux = { qux.missing }''');
		});

		test('falls back to id.attr for entities with string values and no attributes', () {
			List<Error> errs = [];
			expect(bundle.format("ref-foo", errors: errs), "{foo.missing}");
			expect(errs.length, 1);
		});

		test('falls back to id.attr for entities with string values and other attributes', () {
			List<Error> errs = [];
			expect(bundle.format("ref-bar", errors: errs), "{bar.missing}");
			expect(errs.length, 1);
		});

		test('falls back to id.attr for entities with pattern values and no attributes', () {
			List<Error> errs = [];
			expect(bundle.format("ref-baz", errors: errs), "{baz.missing}");
			expect(errs.length, 1);
		});

		test('falls back to id.attr for entities with pattern values and other attributes', () {
			List<Error> errs = [];
			expect(bundle.format("ref-qux", errors: errs), "{qux.missing}");
			expect(errs.length, 1);
		});
	});

	group('Attributes with string values', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('''foo = Foo
    .attr = Foo Attribute
bar = { foo } Bar
    .attr = Bar Attribute

ref-foo = { foo.attr }
ref-bar = { bar.attr }''');
		});

		test('can be referenced for entities with string values', () {
			List<Error> errs = [];
			expect(bundle.format("ref-foo", errors: errs), "Foo Attribute");
			expect(errs.length, 0);
		});

		test('can be formatted directly for entities with string values', () {
			List<Error> errs = [];
			expect(bundle.format("foo", attribute: "attr", errors: errs), "Foo Attribute");
			expect(errs.length, 0);
		});

		test('can be referenced for entities with pattern values', () {
			List<Error> errs = [];
			expect(bundle.format("ref-bar", errors: errs), "Bar Attribute");
			expect(errs.length, 0);
		});

		test('can be formatted directly for entities with pattern values', () {
			List<Error> errs = [];
			expect(bundle.format("bar", attribute: "attr", errors: errs), "Bar Attribute");
			expect(errs.length, 0);
		});
	});

	group('Attributes with simple pattern values', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('''foo = Foo
bar = Bar
    .attr = { foo } Attribute
baz = { foo } Baz
    .attr = { foo } Attribute
qux = Qux
    .attr = { qux } Attribute

ref-bar = { bar.attr }
ref-baz = { baz.attr }
ref-qux = { qux.attr }''');
		});

		test('can be referenced for entities with string values', () {
			List<Error> errs = [];
			expect(bundle.format("ref-bar", errors: errs), "Foo Attribute");
			expect(errs.length, 0);
		});

		test('can be formatted directly for entities with string values', () {
			List<Error> errs = [];
			expect(bundle.format("bar", attribute: "attr", errors: errs), "Foo Attribute");
			expect(errs.length, 0);
		});

		test('can be referenced for entities with simple pattern values', () {
			List<Error> errs = [];
			expect(bundle.format("ref-baz", errors: errs), "Foo Attribute");
			expect(errs.length, 0);
		});

		test('can be formatted directly for entities with simple pattern values', () {
			List<Error> errs = [];
			expect(bundle.format("baz", attribute: "attr", errors: errs), "Foo Attribute");
			expect(errs.length, 0);
		});

		test('works with self-references', () {
			List<Error> errs = [];
			expect(bundle.format("ref-qux", errors: errs), "Qux Attribute");
			expect(errs.length, 0);
		});

		test('can be formatted directly when it uses a self-reference', () {
			List<Error> errs = [];
			expect(bundle.format("qux", attribute: "attr", errors: errs), "Qux Attribute");
			expect(errs.length, 0);
		});
	});

	group('Attributes with values with select expressions', () {
		late FluentBundle bundle;

		setUp(() {
			bundle = FluentBundle("en-US");
			bundle.addMessages('''foo = Foo
    .attr = { "a" ->
                [a] A
               *[b] B
            }

ref-foo = { foo.attr }''');
		});

		test('can be referenced', () {
			List<Error> errs = [];
			expect(bundle.format("ref-foo", errors: errs), "A");
			expect(errs.length, 0);
		});

		test('can be formatted directly', () {
			List<Error> errs = [];
			expect(bundle.format("foo", attribute: "attr", errors: errs), "A");
			expect(errs.length, 0);
		});
	});
}
